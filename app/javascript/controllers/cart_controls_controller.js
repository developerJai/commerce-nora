import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  add(event) {
    const url = event.currentTarget.dataset.url
    this.submitRequest(url, 'POST', {})
  }

  update(event) {
    const url = event.currentTarget.dataset.url
    const quantity = parseInt(event.currentTarget.dataset.quantity)
    this.submitRequest(url, 'PATCH', { quantity: quantity })
  }

  submitRequest(url, method, data) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    
    const formData = new FormData()
    Object.keys(data).forEach(key => {
      formData.append(key, data[key])
    })

    fetch(url, {
      method: method,
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: formData
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Cart update error:', error)
    })
  }
}

// Global functions for cart operations
window.cartControlAdd = function(url) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content
  
  fetch(url, {
    method: 'POST',
    headers: {
      'X-CSRF-Token': csrfToken,
      'Accept': 'text/vnd.turbo-stream.html'
    }
  })
  .then(response => response.text())
  .then(html => {
    Turbo.renderStreamMessage(html)
  })
  .catch(error => {
    console.error('Cart add error:', error)
  })
}

window.cartControlUpdate = function(url, quantity) {
  updateCartQuantity(url, quantity)
}

// Main cart quantity update function
window.updateCartQuantity = function(url, quantity) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content
  
  const formData = new FormData()
  formData.append('quantity', quantity)
  
  fetch(url, {
    method: 'PATCH',
    headers: {
      'X-CSRF-Token': csrfToken,
      'Accept': 'text/vnd.turbo-stream.html'
    },
    body: formData
  })
  .then(response => response.text())
  .then(html => {
    Turbo.renderStreamMessage(html)
  })
  .catch(error => {
    console.error('Cart update error:', error)
  })
}

// Remove item from cart with confirmation
window.removeCartItem = function(url) {
  if (confirm('Remove this item from your cart?')) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    
    fetch(url, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'text/vnd.turbo-stream.html'
      }
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Cart remove error:', error)
    })
  }
}
