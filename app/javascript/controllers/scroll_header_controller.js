import { Controller } from "@hotwired/stimulus"

// Hides/shows mobile filter/sort header on scroll
export default class extends Controller {
  static targets = ["header"]

  connect() {
    this.lastScrollY = window.scrollY
    this.ticking = false
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.handleScroll, { passive: true })
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
  }

  handleScroll() {
    if (!this.ticking) {
      window.requestAnimationFrame(() => {
        this.updateHeader()
        this.ticking = false
      })
      this.ticking = true
    }
  }

  updateHeader() {
    const currentScrollY = window.scrollY
    
    // Only apply on mobile (when header is visible)
    if (window.innerWidth >= 1024) return
    
    // Don't hide if near top
    if (currentScrollY < 100) {
      this.headerTarget.style.transform = "translateY(0)"
      this.lastScrollY = currentScrollY
      return
    }

    if (currentScrollY > this.lastScrollY) {
      // Scrolling down - hide header
      this.headerTarget.style.transform = "translateY(-100%)"
    } else {
      // Scrolling up - show header
      this.headerTarget.style.transform = "translateY(0)"
    }

    this.lastScrollY = currentScrollY
  }
}
