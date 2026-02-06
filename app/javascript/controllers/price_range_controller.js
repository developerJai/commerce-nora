import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["min", "max", "minInput", "maxInput", "minLabel", "maxLabel"]

  connect() {
    // Initialize labels and hidden fields without triggering form submission
    this.update()
  }

  activateMin() {
    this.minTarget.classList.add("z-20")
    this.maxTarget.classList.remove("z-20")
  }

  activateMax() {
    this.maxTarget.classList.add("z-20")
    this.minTarget.classList.remove("z-20")
  }

  // Called on input (while dragging) – updates labels and hidden fields visually only.
  // Does NOT dispatch any event, so the form will not auto-submit mid-drag.
  update() {
    const min = parseFloat(this.minTarget.value)
    const max = parseFloat(this.maxTarget.value)

    const clampedMin = Math.min(min, max)
    const clampedMax = Math.max(min, max)

    this.minTarget.value = clampedMin
    this.maxTarget.value = clampedMax

    if (this.hasMinLabelTarget) this.minLabelTarget.textContent = this.format(clampedMin)
    if (this.hasMaxLabelTarget) this.maxLabelTarget.textContent = this.format(clampedMax)

    // Only populate hidden fields when the user has narrowed the range
    // from the full catalog bounds. When at the extremes, leave blank
    // so no price filter param is sent to the backend.
    const catalogMin = parseFloat(this.minTarget.min)
    const catalogMax = parseFloat(this.maxTarget.max)

    if (this.hasMinInputTarget) {
      this.minInputTarget.value = (clampedMin > catalogMin) ? clampedMin : ''
    }
    if (this.hasMaxInputTarget) {
      this.maxInputTarget.value = (clampedMax < catalogMax) ? clampedMax : ''
    }
  }

  // Called on change (mouseup / touchend) – syncs final values, then the
  // native change event continues to bubble up to the form where the
  // filters controller picks it up and schedules a submit.
  commit() {
    this.update()
  }

  format(value) {
    const rounded = Math.round(value)
    return `₹${rounded.toLocaleString('en-IN')}`
  }
}
