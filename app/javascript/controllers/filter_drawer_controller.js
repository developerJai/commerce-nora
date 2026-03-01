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
  }

  open() {
    this.isFilterOpen = true
    this.drawerTarget.classList.remove("translate-y-full")
    this.overlayTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    this.setupSwipeHandlers(this.drawerTarget)
  }

  close(event) {
    // Prevent closing if clicking inside the drawer content
    if (event && this.drawerTarget.contains(event.target) && !event.target.closest('[data-action*="close"]')) {
      return
    }
    
    this.isFilterOpen = false
    this.drawerTarget.classList.add("translate-y-full")
    this.overlayTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    this.resetDrawerPosition(this.drawerTarget)
  }

  openSort() {
    this.isSortOpen = true
    this.sortDrawerTarget.classList.remove("translate-y-full")
    this.overlayTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    this.setupSwipeHandlers(this.sortDrawerTarget)
  }

  closeSort(event) {
    // Prevent closing if clicking inside the drawer content
    if (event && this.sortDrawerTarget.contains(event.target) && !event.target.closest('[data-action*="close"]')) {
      return
    }
    
    this.isSortOpen = false
    this.sortDrawerTarget.classList.add("translate-y-full")
    this.overlayTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    this.resetDrawerPosition(this.sortDrawerTarget)
  }

  closeAny() {
    // Close whichever drawer is currently open
    if (this.isFilterOpen) {
      this.close()
    } else if (this.isSortOpen) {
      this.closeSort()
    }
  }

  setupSwipeHandlers(drawer) {
    drawer.addEventListener('touchstart', this.handleTouchStart.bind(this), { passive: true })
    drawer.addEventListener('touchmove', this.handleTouchMove.bind(this), { passive: false })
    drawer.addEventListener('touchend', this.handleTouchEnd.bind(this), { passive: true })
  }

  handleTouchStart(e) {
    this.touchStartY = e.touches[0].clientY
    this.isDragging = false
  }

  handleTouchMove(e) {
    if (!this.touchStartY) return

    this.touchCurrentY = e.touches[0].clientY
    const deltaY = this.touchCurrentY - this.touchStartY

    // Only allow dragging down
    if (deltaY > 0) {
      this.isDragging = true
      const drawer = e.currentTarget
      
      // Check if content is scrolled to top
      const scrollableContent = drawer.querySelector('[style*="overflow-y"]')
      if (scrollableContent && scrollableContent.scrollTop > 0) {
        return // Let the content scroll naturally
      }

      e.preventDefault()
      
      // Apply transform with resistance
      const resistance = 0.5
      const translateY = deltaY * resistance
      drawer.style.transform = `translateY(${translateY}px)`
      drawer.style.transition = 'none'
    }
  }

  handleTouchEnd(e) {
    if (!this.isDragging) return

    const deltaY = this.touchCurrentY - this.touchStartY
    const drawer = e.currentTarget
    const threshold = 100 // pixels to swipe down to close

    drawer.style.transition = ''

    if (deltaY > threshold) {
      // Close the drawer
      if (this.isFilterOpen) {
        this.close()
      } else if (this.isSortOpen) {
        this.closeSort()
      }
    } else {
      // Snap back to original position
      this.resetDrawerPosition(drawer)
    }

    this.touchStartY = 0
    this.touchCurrentY = 0
    this.isDragging = false
  }

  resetDrawerPosition(drawer) {
    drawer.style.transform = ''
    drawer.style.transition = ''
  }
}
