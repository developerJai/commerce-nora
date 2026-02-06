import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    updateUrl: String,
    addUrl: String,
    currentQuantity: Number,
    maxStock: Number
  }

  connect() {
    this.busy = false
  }

  // Add item to cart (quantity = 1)
  add(event) {
    event.preventDefault()
    if (this.busy || !this.hasAddUrlValue) return
    this.submitRequest(this.addUrlValue, 'POST', {})
  }

  // Increase quantity by 1
  increment(event) {
    event.preventDefault()
    if (this.busy) return

    const newQuantity = this.currentQuantityValue + 1
    if (this.hasMaxStockValue && newQuantity > this.maxStockValue) return

    this.updateQuantity(newQuantity)
  }

  // Decrease quantity by 1 (removes when quantity reaches 0)
  decrement(event) {
    event.preventDefault()
    if (this.busy) return

    const newQuantity = Math.max(0, this.currentQuantityValue - 1)
    this.updateQuantity(newQuantity)
  }

  // Submit form (for "Add to Bag" button with form)
  submitForm(event) {
    event.preventDefault()
    if (this.busy) return

    const form = event.target.closest('form') || this.element.querySelector('form')
    if (!form) return

    const formData = new FormData(form)
    this.submitRequest(form.action, 'POST', {}, formData)
  }

  // --- Private helpers ---

  updateQuantity(quantity) {
    if (!this.hasUpdateUrlValue) return
    this.submitRequest(this.updateUrlValue, 'PATCH', { quantity })
  }

  submitRequest(url, method, data = {}, formData = null) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (!csrfToken) return

    this.busy = true
    this.disableButtons()

    const body = formData || this.buildFormData(data)

    fetch(url, {
      method: method,
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: body
    })
    .then(response => {
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      return response.text()
    })
    .then(html => {
      // Turbo stream will replace this controller's DOM entirely,
      // so a fresh controller instance with correct data takes over.
      Turbo.renderStreamMessage(html)
      this.animateCartIcon()
    })
    .catch(error => {
      console.error('Cart operation error:', error)
      // Re-enable buttons only on error (on success, DOM is replaced)
      this.busy = false
      this.enableButtons()
    })
  }

  buildFormData(data) {
    const fd = new FormData()
    for (const [key, value] of Object.entries(data)) {
      fd.append(key, value)
    }
    return fd
  }

  disableButtons() {
    this.element.querySelectorAll('button').forEach(btn => {
      btn.disabled = true
      btn.classList.add('opacity-50', 'pointer-events-none')
    })
  }

  enableButtons() {
    this.element.querySelectorAll('button').forEach(btn => {
      btn.disabled = false
      btn.classList.remove('opacity-50', 'pointer-events-none')
    })
  }

  animateCartIcon() {
    document.querySelectorAll('[data-cart-icon-wrapper]').forEach(wrapper => {
      wrapper.style.animation = 'cart-bounce 0.6s cubic-bezier(0.68, -0.55, 0.265, 1.55)'
      setTimeout(() => { wrapper.style.animation = '' }, 600)
    })
  }
}

// Global animation helper for wishlist (used by button_to forms)
window.animateWishlistIcon = function() {
  document.querySelectorAll('[data-wishlist-icon-wrapper]').forEach(wrapper => {
    wrapper.style.animation = 'wishlist-pulse 0.6s ease-out'
    setTimeout(() => { wrapper.style.animation = '' }, 600)
  })
}
