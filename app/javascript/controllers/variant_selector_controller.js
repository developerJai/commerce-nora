import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "price", "comparePrice", "discount"]
  static values = { 
    variants: Array 
  }

  connect() {
    this.updateDisplay()
  }

  select(event) {
    const variantId = event.target.value
    const variant = this.variantsValue.find(v => v.id == variantId)
    
    if (variant) {
      // Update form action
      if (this.hasFormTarget) {
        const action = this.formTarget.action.replace(/\/\d+$/, `/${variantId}`)
        this.formTarget.action = action
      }

      // Update price display
      if (this.hasPriceTarget) {
        this.priceTarget.textContent = `₹${variant.price}`
      }

      if (this.hasComparePriceTarget && variant.compare_at_price) {
        this.comparePriceTarget.textContent = `₹${variant.compare_at_price}`
        this.comparePriceTarget.classList.remove('hidden')
      } else if (this.hasComparePriceTarget) {
        this.comparePriceTarget.classList.add('hidden')
      }
    }

    // Update visual selection
    this.element.querySelectorAll('label').forEach(label => {
      label.classList.remove('border-indigo-500', 'bg-indigo-50')
      label.classList.add('border-gray-200')
    })
    
    event.target.closest('label').classList.remove('border-gray-200')
    event.target.closest('label').classList.add('border-indigo-500', 'bg-indigo-50')
  }

  updateDisplay() {
    const selected = this.element.querySelector('input[type="radio"]:checked')
    if (selected) {
      this.select({ target: selected })
    }
  }
}
