import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sellingPrice", "mrp", "errorMessage"]

  connect() {
    this.validatePrices()
  }

  validatePrices() {
    const sellingPrice = parseFloat(this.sellingPriceTarget.value) || 0
    const mrp = parseFloat(this.mrpTarget.value) || 0

    if (mrp > 0 && sellingPrice > 0 && mrp < sellingPrice) {
      this.showError()
      return false
    } else {
      this.hideError()
      return true
    }
  }

  showError() {
    this.sellingPriceTarget.classList.add("border-red-500", "focus:border-red-500", "focus:ring-red-500")
    this.sellingPriceTarget.classList.remove("border-gray-300", "focus:border-indigo-500", "focus:ring-indigo-500")
    
    this.mrpTarget.classList.add("border-red-500", "focus:border-red-500", "focus:ring-red-500")
    this.mrpTarget.classList.remove("border-gray-300", "focus:border-indigo-500", "focus:ring-indigo-500")
    
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = "MRP (Compare Price) cannot be less than Selling Price"
      this.errorMessageTarget.classList.remove("hidden")
    }
  }

  hideError() {
    this.sellingPriceTarget.classList.remove("border-red-500", "focus:border-red-500", "focus:ring-red-500")
    this.sellingPriceTarget.classList.add("border-gray-300", "focus:border-indigo-500", "focus:ring-indigo-500")
    
    this.mrpTarget.classList.remove("border-red-500", "focus:border-red-500", "focus:ring-red-500")
    this.mrpTarget.classList.add("border-gray-300", "focus:border-indigo-500", "focus:ring-indigo-500")
    
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.classList.add("hidden")
      this.errorMessageTarget.textContent = ""
    }
  }

  // Prevent form submission if validation fails
  submit(event) {
    if (!this.validatePrices()) {
      event.preventDefault()
      event.stopPropagation()
      
      // Scroll to the error
      this.sellingPriceTarget.scrollIntoView({ behavior: "smooth", block: "center" })
      this.sellingPriceTarget.focus()
      
      return false
    }
  }
}
