import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["progress"]
  static values = { timeout: { type: Number, default: 4000 } }

  connect() {
    // Small delay for smooth entry animation
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.enter()
        this.startTimer()
      })
    })
  }

  disconnect() {
    this.clearTimer()
  }

  close() {
    this.clearTimer()
    this.leave()
  }

  enter() {
    this.element.classList.remove("opacity-0", "scale-95", "translate-y-2")
    this.element.classList.add("opacity-100", "scale-100", "translate-y-0")
    
    // Start progress bar animation
    if (this.hasProgressTarget) {
      requestAnimationFrame(() => {
        this.progressTarget.style.width = "0%"
      })
    }
  }

  leave() {
    this.element.classList.remove("opacity-100", "scale-100", "translate-y-0")
    this.element.classList.add("opacity-0", "scale-95", "translate-x-full")

    setTimeout(() => {
      if (this.element.parentNode) {
        this.element.remove()
      }
    }, 300)
  }

  startTimer() {
    this.clearTimer()
    this.timer = setTimeout(() => {
      this.close()
    }, this.timeoutValue)
  }

  clearTimer() {
    if (this.timer) {
      clearTimeout(this.timer)
      this.timer = null
    }
  }
}
