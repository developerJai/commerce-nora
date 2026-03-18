import { Controller } from "@hotwired/stimulus"

// Manages expandable parent category sections in the storefront filter sidebar.
// Each parent category can be toggled open/closed to reveal its subcategories.
export default class extends Controller {
  static targets = ["children", "arrow", "parentCheckbox", "parentName"]
  static values = { open: { type: Boolean, default: false } }

  connect() {
    this.render()
    this.updateVisualState()

    if (this.hasParentCheckboxTarget) {
      this._onParentChange = this.handleParentChange.bind(this)
      this.parentCheckboxTarget.addEventListener('change', this._onParentChange)
    }
    if (this.hasChildrenTarget) {
      this._onChildChange = this.handleChildChange.bind(this)
      this.childrenTarget.addEventListener('change', this._onChildChange)
    }
  }

  disconnect() {
    if (this.hasParentCheckboxTarget && this._onParentChange) {
      this.parentCheckboxTarget.removeEventListener('change', this._onParentChange)
    }
    if (this.hasChildrenTarget && this._onChildChange) {
      this.childrenTarget.removeEventListener('change', this._onChildChange)
    }
  }

  handleParentChange(event) {
    const isChecked = event.target.checked
    if (this.hasChildrenTarget) {
      this.childrenTarget.querySelectorAll('input[type="checkbox"]').forEach(cb => {
        cb.checked = isChecked
        this.updateChildLabel(cb)
      })
      if (isChecked && !this.openValue) {
        this.openValue = true
        this.render()
      }
    }
    this.updateVisualState()
  }

  handleChildChange(event) {
    if (event.target.type !== 'checkbox') return
    if (event.target.checked && !this.openValue) {
      this.openValue = true
      this.render()
    }
    this.updateChildLabel(event.target)
    this.updateVisualState()
  }

  toggle(event) {
    if (event.target.closest("label")) return
    this.openValue = !this.openValue
    this.render()
  }

  render() {
    if (this.hasChildrenTarget) {
      if (this.openValue) {
        this.childrenTarget.style.maxHeight = this.childrenTarget.scrollHeight + "px"
        this.childrenTarget.style.opacity = "1"
      } else {
        this.childrenTarget.style.maxHeight = "0px"
        this.childrenTarget.style.opacity = "0"
      }
    }
    if (this.hasArrowTarget) {
      this.arrowTarget.style.transform = this.openValue ? "rotate(90deg)" : "rotate(0deg)"
    }
  }

  updateVisualState() {
    const parentChecked = this.hasParentCheckboxTarget && this.parentCheckboxTarget.checked
    const anyChildChecked = this.hasChildrenTarget &&
      Array.from(this.childrenTarget.querySelectorAll('input[type="checkbox"]')).some(cb => cb.checked)
    const isSelected = parentChecked || anyChildChecked

    this.element.classList.toggle('bg-rose-50/60', isSelected)
    this.element.classList.toggle('hover:bg-stone-50', !isSelected)

    if (this.hasParentCheckboxTarget) {
      this.parentCheckboxTarget.classList.toggle('border-rose-800', parentChecked)
      this.parentCheckboxTarget.classList.toggle('border-stone-300', !parentChecked)
    }

    if (this.hasParentNameTarget) {
      this.parentNameTarget.classList.toggle('text-rose-900', parentChecked)
      this.parentNameTarget.classList.toggle('text-stone-700', !parentChecked)
    }
  }

  updateChildLabel(checkbox) {
    const label = checkbox.closest('label')
    if (!label) return
    label.classList.toggle('bg-rose-100/60', checkbox.checked)
    label.classList.toggle('hover:bg-white', !checkbox.checked)
  }
}
