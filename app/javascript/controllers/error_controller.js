import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["errorMessage"]
  hideTimeout = null

  connect() {
    // Auto-hide after 3 sec
  }

  dismiss() {
    if (this.hasErrorMessageTarget) {
      // Cancel auto-hide if cross clicked
      clearTimeout(this.hideTimeout)

      // fade out
      this.errorMessageTarget.classList.add("opacity-0")
      setTimeout(() => this.errorMessageTarget.remove(), 500)
    }
  }
}