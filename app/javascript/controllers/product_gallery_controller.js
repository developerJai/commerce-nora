import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "thumbnail", "zoomContainer", "zoomImage"]

  selectImage(event) {
    const index = event.params.index

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
    // Only enable zoom on non-touch devices
    if (window.matchMedia("(hover: hover)").matches) {
      container.addEventListener("mousemove", this._handleZoom.bind(this))
      container.addEventListener("mouseleave", this._resetZoom.bind(this))
    }
  }

  _handleZoom(event) {
    const container = event.currentTarget
    const rect = container.getBoundingClientRect()
    const x = ((event.clientX - rect.left) / rect.width) * 100
    const y = ((event.clientY - rect.top) / rect.height) * 100

    // Find the currently visible slide's image
    this.slideTargets.forEach((slide) => {
      if (!slide.classList.contains("opacity-0")) {
        const img = slide.querySelector("img")
        if (img) {
          img.style.transformOrigin = `${x}% ${y}%`
          img.style.transform = "scale(2)"
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
}
