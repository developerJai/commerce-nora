import { Controller } from "@hotwired/stimulus"

// Keeps the permanent bottom nav in sync with the current page.
// - Highlights the active tab based on URL
// - Hides nav on pages like product show and checkout
export default class extends Controller {
  static targets = ["tab"]
  static values = { hideOn: Array }

  connect() {
    this.update()
    document.addEventListener("turbo:load", this.update)
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.update)
  }

  update = () => {
    const path = window.location.pathname

    // Show/hide nav based on current page
    const shouldHide = this.hideOnValue.some(pattern => {
      // "/products/" hides /products/:id but not /products
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
