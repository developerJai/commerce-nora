import { Controller } from "@hotwired/stimulus"

// Keeps the bottom nav bar in sync with the current page.
// Uses data-turbo-permanent to persist across Turbo Drive navigations.
// This controller updates the active tab highlight, show/hide state,
// and syncs the cart count badge from the new page's response.
export default class extends Controller {
  static targets = ["tab"]
  static values = { hideOn: Array }

  connect() {
    this.update()
    document.addEventListener("turbo:load", this.update)
    document.addEventListener("turbo:before-render", this.syncCartCount)
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.update)
    document.removeEventListener("turbo:before-render", this.syncCartCount)
  }

  // Before Turbo swaps the page, grab the fresh cart count from the new body
  // and inject it into our permanent nav (which Turbo will preserve).
  syncCartCount = (event) => {
    const newBody = event.detail.newBody
    if (!newBody) return

    const freshBadge = newBody.querySelector("#mobile-cart-count")
    const currentBadge = this.element.querySelector("#mobile-cart-count")
    if (freshBadge && currentBadge) {
      currentBadge.innerHTML = freshBadge.innerHTML
    }
  }

  update = () => {
    const path = window.location.pathname

    // Show/hide nav based on current page
    const shouldHide = this.hideOnValue.some(pattern => {
      if (pattern.endsWith("/")) return path.startsWith(pattern) && path !== pattern.slice(0, -1)
      return path.startsWith(pattern)
    })

    this.element.classList.toggle("hidden", shouldHide)
    const spacer = document.getElementById("mobile-bottom-nav-spacer")
    if (spacer) spacer.classList.toggle("hidden", shouldHide)

    // Update active tab
    const ACTIVE = "text-rose-800"
    const INACTIVE = "text-stone-400"

    this.tabTargets.forEach(tab => {
      const tabPath = tab.dataset.path
      const isActive = tabPath === "/"
        ? path === "/"
        : path === tabPath || path.startsWith(tabPath + "/")

      tab.classList.toggle(ACTIVE, isActive)
      tab.classList.toggle(INACTIVE, !isActive)
    })
  }
}
