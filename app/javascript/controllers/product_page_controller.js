import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToTop = this.scrollToTop.bind(this)

    this.scrollToTop()
    document.addEventListener("turbo:load", this.scrollToTop)
    document.addEventListener("turbo:render", this.scrollToTop)
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.scrollToTop)
    document.removeEventListener("turbo:render", this.scrollToTop)
  }

  scrollToTop() {
    window.requestAnimationFrame(() => {
      window.scrollTo({ top: 0, left: 0, behavior: "auto" })
    })
  }
}
