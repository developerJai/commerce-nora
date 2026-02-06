import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 400 } }

  connect() {
    this.timer = null
  }

  disconnect() {
    this.clear()
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
