import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  static values = { fixed: { type: Boolean, default: false } }

  connect() {
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)
    this._closeTimer = null
  }

  // ── Click-based toggle (used by dropdowns outside the nav) ──────────
  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")

    if (!this.menuTarget.classList.contains("hidden")) {
      if (this.fixedValue) {
        this._positionFixed()
      }
      document.addEventListener("click", this.closeOnClickOutside)
    } else {
      document.removeEventListener("click", this.closeOnClickOutside)
    }
  }

  hide(event) {
    if (event && this.element.contains(event.target)) {
      return
    }
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.closeOnClickOutside)
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
      document.removeEventListener("click", this.closeOnClickOutside)
    }
  }

  // ── Hover-based open/close (used by nav category dropdowns) ─────────
  open() {
    if (this._closeTimer) {
      clearTimeout(this._closeTimer)
      this._closeTimer = null
    }
    if (this.fixedValue) {
      this._positionFixed()
    }
    this.menuTarget.classList.remove("hidden")
  }

  close() {
    this._closeTimer = setTimeout(() => {
      this.menuTarget.classList.add("hidden")
      this._closeTimer = null
    }, 120)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside)
    if (this._closeTimer) clearTimeout(this._closeTimer)
  }

  _positionFixed() {
    const rect = this.element.getBoundingClientRect()
    this.menuTarget.style.position = "fixed"
    this.menuTarget.style.top = rect.bottom + "px"
    this.menuTarget.style.left = rect.left + "px"
    this.menuTarget.style.zIndex = "9999"
  }
}
