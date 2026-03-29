import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  intercept() {
    // dispatchEvent is synchronous — open() runs in this same call stack,
    // preserving the iOS user gesture trust chain for input.focus()
    document.dispatchEvent(new CustomEvent('mobile-search:open'))
  }
}
