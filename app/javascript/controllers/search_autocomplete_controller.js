import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "clearButton"]

  connect() {
    this.timeout = null
    this.boundClickOutside = this.clickOutside.bind(this)
    document.addEventListener('click', this.boundClickOutside)
    this.updateClearButton()
  }

  disconnect() {
    document.removeEventListener('click', this.boundClickOutside)
    if (this.timeout) clearTimeout(this.timeout)
    this.unlockBodyScroll()
  }

  search() {
    const query = this.inputTarget.value.trim()
    this.updateClearButton()

    if (this.timeout) clearTimeout(this.timeout)

    if (query.length < 2) {
      this.hideResults()
      return
    }

    // Debounce search
    this.timeout = setTimeout(() => {
      this.fetchSuggestions(query)
    }, 200)
  }

  clearInput() {
    this.inputTarget.value = ''
    this.hideResults()
    this.updateClearButton()
    this.inputTarget.focus()
  }

  updateClearButton() {
    if (this.hasClearButtonTarget) {
      if (this.inputTarget.value.length > 0) {
        this.clearButtonTarget.classList.remove('hidden')
      } else {
        this.clearButtonTarget.classList.add('hidden')
      }
    }
  }

  lockBodyScroll() {
    this._savedScrollY = window.scrollY
    document.body.style.position = 'fixed'
    document.body.style.top = `-${this._savedScrollY}px`
    document.body.style.left = '0'
    document.body.style.right = '0'
  }

  unlockBodyScroll() {
    if (document.body.style.position === 'fixed') {
      document.body.style.position = ''
      document.body.style.top = ''
      document.body.style.left = ''
      document.body.style.right = ''
      window.scrollTo(0, this._savedScrollY || 0)
    }
  }

  async fetchSuggestions(query) {
    try {
      const response = await fetch(`/search/suggestions?q=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.renderResults(data, query)
      }
    } catch (error) {
      console.error('Search error:', error)
    }
  }

  renderResults(data, query) {
    const { categories, products, variants } = data

    if (categories.length === 0 && products.length === 0 && variants.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="p-4 text-center text-gray-500 text-sm">
          No results found for "${this.escapeHtml(query)}"
        </div>
      `
      this.showResults()
      return
    }

    let html = ''

    // Categories
    if (categories.length > 0) {
      html += `
        <div class="px-3 py-2 bg-gray-50 text-xs font-semibold text-gray-500 uppercase tracking-wider">
          Categories
        </div>
      `
      categories.forEach(cat => {
        html += `
          <a href="/categories/${cat.slug}" data-turbo-frame="_top" class="flex items-center gap-3 px-4 py-2 hover:bg-gray-50 transition">
            <div class="w-8 h-8 bg-indigo-100 rounded-lg flex items-center justify-center flex-shrink-0">
              <svg class="w-4 h-4 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6z"/>
              </svg>
            </div>
            <div>
              <p class="text-sm font-medium text-gray-900">${this.escapeHtml(cat.name)}</p>
              <p class="text-xs text-gray-500">${cat.products_count} products</p>
            </div>
          </a>
        `
      })
    }

    // Products
    if (products.length > 0) {
      html += `
        <div class="px-3 py-2 bg-gray-50 text-xs font-semibold text-gray-500 uppercase tracking-wider border-t">
          Products
        </div>
      `
      products.forEach(product => {
        const stockBadge = product.in_stock
          ? '<span class="text-emerald-600 text-xs">In Stock</span>'
          : '<span class="text-red-600 text-xs">Out of Stock</span>'

        html += `
          <a href="/products/${product.slug}" data-turbo-frame="_top" class="flex items-center gap-3 px-4 py-2 hover:bg-gray-50 transition">
            <div class="w-10 h-10 bg-gray-100 rounded-lg overflow-hidden flex-shrink-0">
              ${product.image
                ? `<img src="${product.image}" class="w-full h-full object-cover" alt="" loading="lazy">`
                : `<div class="w-full h-full flex items-center justify-center">
                    <svg class="w-5 h-5 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                    </svg>
                  </div>`
              }
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900 truncate">${this.escapeHtml(product.name)}</p>
              <div class="flex items-center gap-2">
                <span class="text-sm font-bold text-gray-900">${product.price}</span>
                ${stockBadge}
              </div>
            </div>
          </a>
        `
      })
    }

    // Variants
    if (variants.length > 0) {
      html += `
        <div class="px-3 py-2 bg-gray-50 text-xs font-semibold text-gray-500 uppercase tracking-wider border-t">
          Product Variants
        </div>
      `
      variants.forEach(variant => {
        let stockClass = 'text-emerald-600'
        let stockText = 'In Stock'
        if (variant.stock_quantity === 0) {
          stockClass = 'text-red-600'
          stockText = 'Out of Stock'
        } else if (variant.stock_quantity <= 10) {
          stockClass = 'text-amber-600'
          stockText = `Only ${variant.stock_quantity} left`
        }

        html += `
          <a href="/products/${variant.product_slug}?variant=${variant.variant_param}" data-turbo-frame="_top" class="flex items-center gap-3 px-4 py-2 hover:bg-gray-50 transition">
            <div class="w-10 h-10 bg-gray-100 rounded-lg overflow-hidden flex-shrink-0">
              ${variant.image
                ? `<img src="${variant.image}" class="w-full h-full object-cover" alt="" loading="lazy">`
                : `<div class="w-full h-full flex items-center justify-center">
                    <svg class="w-5 h-5 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"/>
                    </svg>
                  </div>`
              }
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900 truncate">${this.escapeHtml(variant.product_name)}</p>
              <p class="text-xs text-gray-500">${this.escapeHtml(variant.name)}</p>
              <div class="flex items-center gap-2">
                <span class="text-sm font-bold text-gray-900">${variant.price}</span>
                <span class="${stockClass} text-xs">${stockText}</span>
              </div>
            </div>
          </a>
        `
      })
    }

    // View all results link
    html += `
      <a href="/products?q=${encodeURIComponent(query)}" data-turbo-frame="_top"
         class="block px-4 py-3 bg-rose-50 text-center text-sm font-medium text-rose-700 hover:bg-rose-100 transition">
        View all results for "${this.escapeHtml(query)}"
      </a>
    `

    this.resultsTarget.innerHTML = html
    this.showResults()
  }

  showResults() {
    this.resultsTarget.classList.remove('hidden')
    this.lockBodyScroll()
  }

  hideResults() {
    this.resultsTarget.classList.add('hidden')
    this.unlockBodyScroll()
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  submitForm(event) {
    // Let the form submit naturally when Enter is pressed
    // The keydown.enter action will trigger form submission
    this.hideResults()
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
