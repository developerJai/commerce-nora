import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["min", "max", "minInput", "maxInput", "minLabel", "maxLabel"]

  connect() {
    // Initialize without triggering change event
    this.sync(null, true)
  }

  activateMin() {
    this.updateThumbOrder(this.minTarget)
  }

  activateMax() {
    this.updateThumbOrder(this.maxTarget)
  }

  sync(event, skipDispatch = false) {
    const min = parseFloat(this.minTarget.value)
    const max = parseFloat(this.maxTarget.value)

    const clampedMin = Math.min(min, max)
    const clampedMax = Math.max(min, max)

    this.minTarget.value = clampedMin
    this.maxTarget.value = clampedMax

    this.updateThumbOrder(event?.target, clampedMin, clampedMax)

    if (this.hasMinInputTarget) this.minInputTarget.value = clampedMin
    if (this.hasMaxInputTarget) this.maxInputTarget.value = clampedMax

    if (this.hasMinLabelTarget) this.minLabelTarget.textContent = this.format(clampedMin)
    if (this.hasMaxLabelTarget) this.maxLabelTarget.textContent = this.format(clampedMax)

    // Only dispatch change event on user interaction, not on initial connect
    if (!skipDispatch) {
      this.element.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }

  updateThumbOrder(activeTarget, clampedMin = null, clampedMax = null) {
    this.minTarget.classList.remove("z-20")
    this.maxTarget.classList.remove("z-20")

    if (activeTarget === this.minTarget) {
      this.minTarget.classList.add("z-20")
    } else if (activeTarget === this.maxTarget) {
      this.maxTarget.classList.add("z-20")
    } else {
      const minVal = clampedMin ?? parseFloat(this.minTarget.value)
      const maxVal = clampedMax ?? parseFloat(this.maxTarget.value)
      if (minVal >= maxVal - 1) {
        this.minTarget.classList.add("z-20")
      } else {
        this.maxTarget.classList.add("z-20")
      }
    }
  }

  format(value) {
    const rounded = Math.round(value)
    return `$${rounded.toLocaleString()}`
  }
}
