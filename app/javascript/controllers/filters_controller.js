import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 400 } }

  connect() {
    this.timer = null
    
    // Listen for turbo:frame-render to scroll to top after filter updates
    document.addEventListener('turbo:frame-render', this.handleFrameRender.bind(this))
  }

  disconnect() {
    this.clear()
    document.removeEventListener('turbo:frame-render', this.handleFrameRender.bind(this))
  }

  handleFrameRender(event) {
    // Only scroll if it's the products-content frame
    if (event.target.id === 'products-content') {
      // Scroll to the top of the products section smoothly
      const productsSection = document.getElementById('products-content')
      if (productsSection) {
        // Get the sticky header height to offset scroll
        const stickyHeader = document.querySelector('[data-scroll-header-target="header"]')
        const headerHeight = stickyHeader ? stickyHeader.offsetHeight : 0
        const offset = 70 + headerHeight // Reduced offset for less upward scroll
        
        const elementPosition = productsSection.getBoundingClientRect().top
        const offsetPosition = elementPosition + window.pageYOffset - offset
        
        window.scrollTo({
          top: offsetPosition,
          behavior: 'smooth'
        })
      }
    }
  }

  scheduleSubmit() {
    this.clear()
    this.timer = window.setTimeout(() => {
      this.element.requestSubmit()
    }, this.delayValue)
  }

  clear() {
    if (this.timer) {
      window.clearTimeout(this.timer)
      this.timer = null
    }
  }
}
