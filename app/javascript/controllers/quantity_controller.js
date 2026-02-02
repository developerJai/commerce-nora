import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  increase() {
    const input = this.inputTarget
    let value = parseInt(input.value) || 1
    if (value < 10) {
      input.value = value + 1
      this.syncFormQuantity(value + 1)
    }
  }

  decrease() {
    const input = this.inputTarget
    let value = parseInt(input.value) || 1
    if (value > 1) {
      input.value = value - 1
      this.syncFormQuantity(value - 1)
    }
  }

  syncFormQuantity(value) {
    const formQuantity = document.getElementById('form-quantity')
    if (formQuantity) {
      formQuantity.value = value
    }
  }
}
