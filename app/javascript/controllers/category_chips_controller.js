import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto-scroll the active chip into view
    const active = this.element.querySelector('.bg-rose-800')
    if (active) {
      requestAnimationFrame(() => {
        active.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' })
      })
    }
  }
}
