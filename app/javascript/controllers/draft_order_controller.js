import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "itemsContainer", 
    "subtotal", 
    "discountDisplay", 
    "shippingDisplay", 
    "total",
    "couponSelect",
    "couponInfo",
    "discountInput",
    "shippingInput"
  ]
  
  connect() {
    this.itemIndex = this.element.querySelectorAll('.order-item-row').length
    this.calculateTotal()
  }
  
  addItem() {
    const template = document.getElementById('order-item-template')
    const clone = template.content.cloneNode(true)
    
    clone.querySelectorAll('[name]').forEach(el => {
      el.name = el.name.replace('NEW_INDEX', this.itemIndex)
    })
    
    this.itemsContainerTarget.appendChild(clone)
    this.itemIndex++
    this.calculateTotal()
  }
  
  removeItem(event) {
    const row = event.target.closest('.order-item-row')
    const destroyCheckbox = row.querySelector('.destroy-checkbox')
    
    if (destroyCheckbox) {
      // Existing item - mark for destruction
      destroyCheckbox.checked = true
      row.style.display = 'none'
    } else {
      // New item - just remove
      row.remove()
    }
    
    this.calculateTotal()
  }
  
  updatePrice(event) {
    const select = event.target
    const row = select.closest('.order-item-row')
    const priceInput = row.querySelector('.price-input')
    const selectedOption = select.options[select.selectedIndex]
    
    if (selectedOption && selectedOption.dataset.price) {
      priceInput.value = parseFloat(selectedOption.dataset.price).toFixed(2)
    } else {
      priceInput.value = ''
    }
    
    this.updateLineTotal(row)
    this.calculateTotal()
  }
  
  updateLineTotal(row) {
    const quantity = parseFloat(row.querySelector('.quantity-input')?.value) || 0
    const price = parseFloat(row.querySelector('.price-input')?.value) || 0
    const lineTotal = row.querySelector('.line-total')
    
    if (lineTotal) {
      lineTotal.textContent = this.formatCurrency(quantity * price)
    }
  }
  
  applyCoupon() {
    const select = this.couponSelectTarget
    const selectedOption = select.options[select.selectedIndex]
    
    if (selectedOption && selectedOption.value) {
      const type = selectedOption.dataset.discountType
      const value = parseFloat(selectedOption.dataset.discountValue)
      
      let info = ''
      if (type === 'percentage') {
        info = `${value}% off your order`
      } else {
        info = `$${value.toFixed(2)} off your order`
      }
      
      if (this.hasCouponInfoTarget) {
        this.couponInfoTarget.textContent = info
        this.couponInfoTarget.classList.add('text-emerald-600')
      }
    } else {
      if (this.hasCouponInfoTarget) {
        this.couponInfoTarget.textContent = ''
      }
    }
    
    this.calculateTotal()
  }
  
  calculateTotal() {
    // Calculate subtotal from visible line items
    let subtotal = 0
    const rows = this.itemsContainerTarget.querySelectorAll('.order-item-row')
    
    rows.forEach(row => {
      if (row.style.display !== 'none') {
        const quantity = parseFloat(row.querySelector('.quantity-input')?.value) || 0
        const price = parseFloat(row.querySelector('.price-input')?.value) || 0
        subtotal += quantity * price
        
        // Update line total
        this.updateLineTotal(row)
      }
    })
    
    // Get discount
    let discount = 0
    
    // Coupon discount
    if (this.hasCouponSelectTarget) {
      const couponSelect = this.couponSelectTarget
      const selectedOption = couponSelect.options[couponSelect.selectedIndex]
      
      if (selectedOption && selectedOption.value) {
        const type = selectedOption.dataset.discountType
        const value = parseFloat(selectedOption.dataset.discountValue)
        
        if (type === 'percentage') {
          discount += subtotal * (value / 100)
        } else {
          discount += value
        }
      }
    }
    
    // Manual discount
    if (this.hasDiscountInputTarget) {
      discount += parseFloat(this.discountInputTarget.value) || 0
    }
    
    // Shipping
    let shipping = 0
    if (this.hasShippingInputTarget) {
      shipping = parseFloat(this.shippingInputTarget.value) || 0
    }
    
    // Calculate total
    const total = Math.max(0, subtotal - discount + shipping)
    
    // Update display
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = this.formatCurrency(subtotal)
    }
    if (this.hasDiscountDisplayTarget) {
      this.discountDisplayTarget.textContent = '-' + this.formatCurrency(discount)
    }
    if (this.hasShippingDisplayTarget) {
      this.shippingDisplayTarget.textContent = this.formatCurrency(shipping)
    }
    if (this.hasTotalTarget) {
      this.totalTarget.textContent = this.formatCurrency(total)
    }
  }
  
  formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }
}
