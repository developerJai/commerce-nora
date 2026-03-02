import { Controller } from "@hotwired/stimulus"

// Mobile bottom sheet drawers for filters and sorting.
export default class extends Controller {
  static targets = ["drawer", "sortDrawer", "overlay"]

  connect() {
    this.isFilterOpen = false
    this.isSortOpen = false
    this.touchStartY = 0
    this.touchCurrentY = 0
    this.isDragging = false
    this.scrollLocked = false
    this._boundStart = this.handleTouchStart.bind(this)
    this._boundMove = this.handleTouchMove.bind(this)
    this._boundEnd = this.handleTouchEnd.bind(this)
  }

  open() {
    this.isFilterOpen = true
    this.drawerTarget.classList.remove("translate-y-full")
    this.overlayTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    this.attachSwipe(this.drawerTarget)
  }

  close(event) {
    if (event && this.drawerTarget.contains(event.target) && !event.target.closest('[data-action*="close"]')) {
      return
    }
    this.isFilterOpen = false
    this.drawerTarget.classList.add("translate-y-full")
    this.overlayTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    this.resetDrawerPosition(this.drawerTarget)
    this.detachSwipe(this.drawerTarget)
  }

  openSort() {
    this.isSortOpen = true
    this.sortDrawerTarget.classList.remove("translate-y-full")
    this.overlayTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    this.attachSwipe(this.sortDrawerTarget)
  }

  closeSort(event) {
    if (event && this.sortDrawerTarget.contains(event.target) && !event.target.closest('[data-action*="close"]')) {
      return
    }
    this.isSortOpen = false
    this.sortDrawerTarget.classList.add("translate-y-full")
    this.overlayTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    this.resetDrawerPosition(this.sortDrawerTarget)
    this.detachSwipe(this.sortDrawerTarget)
  }

  closeAny() {
    if (this.isFilterOpen) {
      this.close()
    } else if (this.isSortOpen) {
      this.closeSort()
    }
  }

  // ── Swipe handling ──

  attachSwipe(drawer) {
    drawer.removeEventListener('touchstart', this._boundStart)
    drawer.removeEventListener('touchmove', this._boundMove)
    drawer.removeEventListener('touchend', this._boundEnd)
    drawer.addEventListener('touchstart', this._boundStart, { passive: true })
    drawer.addEventListener('touchmove', this._boundMove, { passive: false })
    drawer.addEventListener('touchend', this._boundEnd, { passive: true })
  }

  detachSwipe(drawer) {
    drawer.removeEventListener('touchstart', this._boundStart)
    drawer.removeEventListener('touchmove', this._boundMove)
    drawer.removeEventListener('touchend', this._boundEnd)
  }

  findScrollableParent(el, drawer) {
    while (el && el !== drawer) {
      const style = window.getComputedStyle(el)
      const overflow = style.overflowY
      if ((overflow === 'auto' || overflow === 'scroll') && el.scrollHeight > el.clientHeight) {
        return el
      }
      el = el.parentElement
    }
    return null
  }

  handleTouchStart(e) {
    this.touchStartY = e.touches[0].clientY
    this.touchCurrentY = this.touchStartY
    this.isDragging = false
    this.scrollLocked = false

    const drawer = e.currentTarget
    const scrollable = this.findScrollableParent(e.target, drawer)

    if (scrollable && scrollable.scrollTop > 0) {
      this.scrollLocked = true
    }

    this.touchStartedInHeader = !scrollable
  }

  handleTouchMove(e) {
    if (!this.touchStartY) return

    this.touchCurrentY = e.touches[0].clientY
    const deltaY = this.touchCurrentY - this.touchStartY
    const drawer = e.currentTarget

    if (this.scrollLocked) {
      const scrollable = this.findScrollableParent(e.target, drawer)
      if (scrollable && scrollable.scrollTop <= 0 && deltaY > 0) {
        this.scrollLocked = false
      } else {
        return
      }
    }

    if (deltaY > 10) {
      const scrollable = this.findScrollableParent(e.target, drawer)
      if (scrollable && scrollable.scrollTop > 0) {
        return
      }

      if (!this.isDragging) {
        this.isDragging = true
      }

      e.preventDefault()

      const resistance = 0.5
      const translateY = deltaY * resistance
      drawer.style.transform = `translateY(${translateY}px)`
      drawer.style.transition = 'none'
    }
  }

  handleTouchEnd(e) {
    const drawer = e.currentTarget

    if (!this.isDragging) {
      this.touchStartY = 0
      this.touchCurrentY = 0
      this.scrollLocked = false
      return
    }

    const deltaY = this.touchCurrentY - this.touchStartY
    const threshold = 100

    drawer.style.transition = ''

    if (deltaY > threshold) {
      if (this.isFilterOpen) {
        this.close()
      } else if (this.isSortOpen) {
        this.closeSort()
      }
    } else {
      this.resetDrawerPosition(drawer)
    }

    this.touchStartY = 0
    this.touchCurrentY = 0
    this.isDragging = false
    this.scrollLocked = false
  }

  resetDrawerPosition(drawer) {
    drawer.style.transform = ''
    drawer.style.transition = ''
  }
}
