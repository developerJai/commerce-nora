import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["countdown", "resendBtn", "timerText"]
  static values = { time: Number }

  connect() {
    this.timeLeft = this.timeValue || 0

    // 👇 if already expired
    if (this.timeLeft <= 0) {
      this.showButton()
      return
    }

    this.startTimer()
  }

  startTimer() {
    this.timer = setInterval(() => {
      this.timeLeft--

      this.countdownTarget.textContent = this.timeLeft

      if (this.timeLeft <= 0) {
        clearInterval(this.timer)
        this.showButton()
      }
    }, 1000)
  }

  showButton() {
    this.timerTextTarget.classList.add("hidden")
    this.resendBtnTarget.classList.remove("hidden")
  }
}