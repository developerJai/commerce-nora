import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "form"]

  connect() {
    // Listen for turbo:submit-end to update cart count
    document.addEventListener("turbo:submit-end", this.handleSubmit.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:submit-end", this.handleSubmit.bind(this))
  }

  handleSubmit(event) {
    // Update cart count from response header if present
    const cartCount = event.detail.fetchResponse?.response?.headers?.get("X-Cart-Count")
    if (cartCount && this.hasCountTarget) {
      this.countTarget.textContent = cartCount
    }
  }

  updateQuantity(event) {
    event.target.form.requestSubmit()
  }
}
