import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option", "price", "comparePrice", "discount", "selectedName", "variantInput", "stockStatus", "addToCartBtn", "form"]

  selectVariant(event) {
    const button = event.currentTarget
    const variantId = button.dataset.variantId
    const variantName = button.dataset.variantName
    const price = button.dataset.variantPrice
    const comparePrice = button.dataset.variantComparePrice
    const discount = button.dataset.variantDiscount
    const inStock = button.dataset.variantInStock === "true"
    const stock = parseInt(button.dataset.variantStock) || 0

    // Update option styles
    this.optionTargets.forEach(opt => {
      if (opt === button) {
        opt.classList.add("border-rose-500", "bg-rose-50", "text-rose-800")
        opt.classList.remove("border-stone-200", "text-stone-700", "hover:border-rose-300")
      } else {
        opt.classList.remove("border-rose-500", "bg-rose-50", "text-rose-800")
        opt.classList.add("border-stone-200", "text-stone-700", "hover:border-rose-300")
      }
    })

    // Update price display
    if (this.hasPriceTarget) {
      this.priceTarget.textContent = price
    }

    // Update compare price
    if (this.hasComparePriceTarget) {
      if (comparePrice) {
        this.comparePriceTarget.textContent = comparePrice
        this.comparePriceTarget.classList.remove("hidden")
      } else {
        this.comparePriceTarget.classList.add("hidden")
      }
    }

    // Update discount badge
    if (this.hasDiscountTarget) {
      if (discount) {
        this.discountTarget.textContent = discount
        this.discountTarget.classList.remove("hidden")
      } else {
        this.discountTarget.classList.add("hidden")
      }
    }

    // Update selected name
    if (this.hasSelectedNameTarget) {
      this.selectedNameTarget.textContent = variantName
    }

    // Update hidden input
    if (this.hasVariantInputTarget) {
      this.variantInputTarget.value = variantId
    }

    // Update form action
    if (this.hasFormTarget) {
      const currentAction = this.formTarget.action
      const newAction = currentAction.replace(/\/carts\/add\/\d+/, `/carts/add/${variantId}`)
      this.formTarget.action = newAction
    }

    // Update stock status
    if (this.hasStockStatusTarget) {
      let statusHtml = ""
      if (inStock) {
        if (stock > 0 && stock <= 5) {
          statusHtml = `
            <p class="text-sm text-amber-600 flex items-center gap-1.5">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
              </svg>
              Only ${stock} left in stock
            </p>
          `
        } else {
          statusHtml = `
            <p class="text-sm text-emerald-600 flex items-center gap-1.5">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
              </svg>
              In Stock
            </p>
          `
        }
      } else {
        statusHtml = `<p class="text-sm text-stone-500">Currently unavailable</p>`
      }
      this.stockStatusTarget.innerHTML = statusHtml
    }

    // Update add to cart button
    if (this.hasAddToCartBtnTarget) {
      if (inStock) {
        this.addToCartBtnTarget.disabled = false
        this.addToCartBtnTarget.classList.remove("bg-stone-200", "text-stone-500", "cursor-not-allowed")
        this.addToCartBtnTarget.classList.add("bg-rose-800", "text-white", "hover:bg-rose-900")
        this.addToCartBtnTarget.innerHTML = `
          <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"/>
          </svg>
          Add to Bag
        `
      } else {
        this.addToCartBtnTarget.disabled = true
        this.addToCartBtnTarget.classList.add("bg-stone-200", "text-stone-500", "cursor-not-allowed")
        this.addToCartBtnTarget.classList.remove("bg-rose-800", "text-white", "hover:bg-rose-900")
        this.addToCartBtnTarget.textContent = "Out of Stock"
      }
    }
  }
}
