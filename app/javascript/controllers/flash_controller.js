import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 5000 } }

  connect() {
    if (this.delayValue > 0) {
      setTimeout(() => {
        this.dismiss()
      }, this.delayValue)
    }
  }

  dismiss() {
    this.element.classList.add('opacity-0', 'transition-opacity', 'duration-300')
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
