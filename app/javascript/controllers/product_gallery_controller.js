import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "thumbnail", "zoomContainer", "zoomImage"]

  connect() {
    this._currentIndex = 0
    this._lightbox = null
    this._scale = 1
    this._translateX = 0
    this._translateY = 0
    this._lastTouchDist = 0
    this._lastTouchCenter = null
    this._isDragging = false
    this._dragStart = { x: 0, y: 0 }
  }

  selectImage(event) {
    const index = event.params.index
    this._currentIndex = index

    // Update slides with opacity transition
    this.slideTargets.forEach((slide, i) => {
      if (i === index) {
        slide.classList.remove("opacity-0")
        slide.classList.add("opacity-100")
      } else {
        slide.classList.remove("opacity-100")
        slide.classList.add("opacity-0")
      }
    })

    // Update thumbnails
    this.thumbnailTargets.forEach((thumb, i) => {
      if (i === index) {
        thumb.classList.add("border-rose-500")
        thumb.classList.remove("border-stone-200", "border-transparent", "hover:border-rose-300")
      } else {
        thumb.classList.remove("border-rose-500")
        thumb.classList.add("border-stone-200", "hover:border-rose-300")
      }
    })
  }

  // Image zoom on hover (desktop only)
  zoomContainerTargetConnected(container) {
    if (window.matchMedia("(hover: hover)").matches) {
      // Desktop: hover zoom
      container.addEventListener("mousemove", this._handleZoom.bind(this))
      container.addEventListener("mouseleave", this._resetZoom.bind(this))
    } else {
      // Mobile: tap to open fullscreen lightbox
      container.addEventListener("click", this._openLightbox.bind(this))
    }
  }

  _handleZoom(event) {
    const container = event.currentTarget
    const rect = container.getBoundingClientRect()
    const x = ((event.clientX - rect.left) / rect.width) * 100
    const y = ((event.clientY - rect.top) / rect.height) * 100

    this.slideTargets.forEach((slide) => {
      if (!slide.classList.contains("opacity-0")) {
        const img = slide.querySelector("img")
        if (img) {
          img.style.transformOrigin = `${x}% ${y}%`
          img.style.transform = "scale(3)"
        }
      }
    })
  }

  _resetZoom() {
    this.slideTargets.forEach((slide) => {
      const img = slide.querySelector("img")
      if (img) {
        img.style.transformOrigin = "center center"
        img.style.transform = "scale(1)"
      }
    })
  }

  // ── Mobile fullscreen lightbox with pinch-to-zoom ──

  _openLightbox() {
    const images = this.slideTargets.map(slide => {
      const img = slide.querySelector("img")
      return img ? img.src : null
    }).filter(Boolean)

    if (!images.length) return

    this._scale = 1
    this._translateX = 0
    this._translateY = 0

    const overlay = document.createElement("div")
    overlay.style.cssText = "position:fixed;inset:0;z-index:9999;background:#000;display:flex;flex-direction:column;touch-action:none;user-select:none;"

    // Header
    const header = document.createElement("div")
    header.style.cssText = "position:absolute;top:0;left:0;right:0;z-index:2;display:flex;align-items:center;justify-content:space-between;padding:12px 16px;padding-top:calc(12px + env(safe-area-inset-top));"

    const counter = document.createElement("span")
    counter.style.cssText = "color:#fff;font-size:14px;font-weight:500;"
    counter.textContent = `${this._currentIndex + 1} / ${images.length}`

    const closeBtn = document.createElement("button")
    closeBtn.style.cssText = "width:36px;height:36px;border-radius:50%;background:rgba(255,255,255,0.15);border:none;display:flex;align-items:center;justify-content:center;cursor:pointer;backdrop-filter:blur(8px);"
    closeBtn.innerHTML = '<svg width="20" height="20" fill="none" stroke="#fff" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/></svg>'
    closeBtn.addEventListener("click", () => this._closeLightbox())

    header.appendChild(counter)
    header.appendChild(closeBtn)
    overlay.appendChild(header)

    // Image container
    const imageArea = document.createElement("div")
    imageArea.style.cssText = "flex:1;display:flex;align-items:center;justify-content:center;overflow:hidden;position:relative;"

    const imgWrapper = document.createElement("div")
    imgWrapper.style.cssText = "width:100%;height:100%;display:flex;align-items:center;justify-content:center;will-change:transform;"

    const img = document.createElement("img")
    img.src = images[this._currentIndex]
    img.style.cssText = "max-width:100%;max-height:100%;object-fit:contain;will-change:transform;transition:none;"
    img.draggable = false

    imgWrapper.appendChild(img)
    imageArea.appendChild(imgWrapper)
    overlay.appendChild(imageArea)

    // Thumbnail strip
    if (images.length > 1) {
      const strip = document.createElement("div")
      strip.style.cssText = "position:absolute;bottom:0;left:0;right:0;z-index:2;display:flex;gap:8px;padding:12px 16px;padding-bottom:calc(12px + env(safe-area-inset-bottom));overflow-x:auto;justify-content:center;"

      images.forEach((src, i) => {
        const thumb = document.createElement("button")
        thumb.style.cssText = `width:48px;height:48px;border-radius:8px;overflow:hidden;border:2px solid ${i === this._currentIndex ? '#D4AF37' : 'rgba(255,255,255,0.2)'};flex-shrink:0;padding:0;background:none;cursor:pointer;transition:border-color 0.2s;`
        const thumbImg = document.createElement("img")
        thumbImg.src = src
        thumbImg.style.cssText = "width:100%;height:100%;object-fit:cover;"
        thumbImg.draggable = false
        thumb.appendChild(thumbImg)
        thumb.addEventListener("click", () => {
          this._currentIndex = i
          img.src = images[i]
          this._resetLightboxTransform(img)
          counter.textContent = `${i + 1} / ${images.length}`
          strip.querySelectorAll("button").forEach((t, ti) => {
            t.style.borderColor = ti === i ? '#D4AF37' : 'rgba(255,255,255,0.2)'
          })
        })
        strip.appendChild(thumb)
      })
      overlay.appendChild(strip)
    }

    // Touch handlers for pinch-to-zoom and pan
    imageArea.addEventListener("touchstart", (e) => this._onTouchStart(e, img), { passive: false })
    imageArea.addEventListener("touchmove", (e) => this._onTouchMove(e, img), { passive: false })
    imageArea.addEventListener("touchend", (e) => this._onTouchEnd(e, img, images, counter, overlay), { passive: false })

    // Double-tap to zoom
    this._lastTapTime = 0
    imageArea.addEventListener("click", (e) => {
      if (e.target === closeBtn || e.target.closest("button")) return
      const now = Date.now()
      if (now - this._lastTapTime < 300) {
        // Double-tap
        if (this._scale > 1) {
          this._resetLightboxTransform(img)
        } else {
          this._scale = 2.5
          this._applyTransform(img)
        }
      }
      this._lastTapTime = now
    })

    // Swipe between images (only when not zoomed)
    this._swipeStartX = 0
    this._swipeStartY = 0

    document.body.appendChild(overlay)
    document.body.style.overflow = "hidden"
    this._lightbox = overlay
    this._lightboxImg = img
    this._lightboxImages = images
    this._lightboxCounter = counter
  }

  _closeLightbox() {
    if (this._lightbox) {
      this._lightbox.remove()
      this._lightbox = null
      document.body.style.overflow = ""
    }
  }

  _onTouchStart(e, img) {
    if (e.touches.length === 2) {
      e.preventDefault()
      this._lastTouchDist = this._getTouchDist(e.touches)
      this._lastTouchCenter = this._getTouchCenter(e.touches)
    } else if (e.touches.length === 1) {
      this._isDragging = true
      this._dragStart = {
        x: e.touches[0].clientX - this._translateX,
        y: e.touches[0].clientY - this._translateY
      }
      this._swipeStartX = e.touches[0].clientX
      this._swipeStartY = e.touches[0].clientY
    }
  }

  _onTouchMove(e, img) {
    if (e.touches.length === 2) {
      e.preventDefault()
      const dist = this._getTouchDist(e.touches)
      const center = this._getTouchCenter(e.touches)

      if (this._lastTouchDist > 0) {
        const delta = dist / this._lastTouchDist
        this._scale = Math.min(Math.max(this._scale * delta, 1), 5)
      }
      this._lastTouchDist = dist
      this._lastTouchCenter = center
      this._applyTransform(img)
    } else if (e.touches.length === 1 && this._isDragging && this._scale > 1) {
      e.preventDefault()
      this._translateX = e.touches[0].clientX - this._dragStart.x
      this._translateY = e.touches[0].clientY - this._dragStart.y
      this._applyTransform(img)
    }
  }

  _onTouchEnd(e, img, images, counter, overlay) {
    if (e.touches.length === 0) {
      // Snap back if zoomed below 1
      if (this._scale <= 1) {
        // Check for horizontal swipe to change image
        if (this._swipeStartX && images.length > 1) {
          const dx = e.changedTouches[0].clientX - this._swipeStartX
          const dy = e.changedTouches[0].clientY - this._swipeStartY
          if (Math.abs(dx) > 60 && Math.abs(dx) > Math.abs(dy) * 1.5) {
            if (dx < 0 && this._currentIndex < images.length - 1) {
              this._currentIndex++
            } else if (dx > 0 && this._currentIndex > 0) {
              this._currentIndex--
            }
            img.src = images[this._currentIndex]
            counter.textContent = `${this._currentIndex + 1} / ${images.length}`
            // Update thumbnail highlights
            overlay.querySelectorAll("div:last-child button").forEach((t, ti) => {
              t.style.borderColor = ti === this._currentIndex ? '#D4AF37' : 'rgba(255,255,255,0.2)'
            })
            // Also update main gallery
            this.selectImage({ params: { index: this._currentIndex } })
          }
        }
        this._resetLightboxTransform(img)
      }
      this._isDragging = false
      this._lastTouchDist = 0
    }
  }

  _getTouchDist(touches) {
    const dx = touches[0].clientX - touches[1].clientX
    const dy = touches[0].clientY - touches[1].clientY
    return Math.sqrt(dx * dx + dy * dy)
  }

  _getTouchCenter(touches) {
    return {
      x: (touches[0].clientX + touches[1].clientX) / 2,
      y: (touches[0].clientY + touches[1].clientY) / 2
    }
  }

  _applyTransform(img) {
    img.style.transform = `translate(${this._translateX}px, ${this._translateY}px) scale(${this._scale})`
  }

  _resetLightboxTransform(img) {
    this._scale = 1
    this._translateX = 0
    this._translateY = 0
    img.style.transition = "transform 0.2s ease"
    this._applyTransform(img)
    setTimeout(() => { img.style.transition = "none" }, 200)
  }
}
