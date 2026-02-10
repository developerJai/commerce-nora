import { Controller } from "@hotwired/stimulus"

// Manages expandable parent category sections in the storefront filter sidebar.
// Each parent category can be toggled open/closed to reveal its subcategories.
export default class extends Controller {
  static targets = ["children", "arrow"]
  static values = { open: { type: Boolean, default: false } }

  connect() {
    this.render()
  }

  toggle(event) {
    // Don't toggle when clicking the checkbox or label text
    if (event.target.closest("label")) return
    this.openValue = !this.openValue
    this.render()
  }

  render() {
    if (this.hasChildrenTarget) {
      if (this.openValue) {
        this.childrenTarget.style.maxHeight = this.childrenTarget.scrollHeight + "px"
        this.childrenTarget.style.opacity = "1"
      } else {
        this.childrenTarget.style.maxHeight = "0px"
        this.childrenTarget.style.opacity = "0"
      }
    }
    if (this.hasArrowTarget) {
      this.arrowTarget.style.transform = this.openValue ? "rotate(90deg)" : "rotate(0deg)"
    }
  }
}
