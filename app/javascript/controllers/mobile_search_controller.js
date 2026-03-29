import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "input", "results", "clearButton", "emptyState"]

  connect() {
    this.timeout = null
    this.isOpen = false
    this._savedScrollY = 0
    this.boundKeydown = this.handleKeydown.bind(this)

    // Listen for open requests from trigger buttons
    this.boundOpen = () => this.open()
    document.addEventListener('mobile-search:open', this.boundOpen)

    // Close overlay on Turbo navigation (e.g., user taps a result link)
    this.boundTurboVisit = () => { if (this.isOpen) this.forceClose() }
    document.addEventListener('turbo:visit', this.boundTurboVisit)

    // Ensure overlay is hidden on connect (accessibility)
    this.overlayTarget.setAttribute('aria-hidden', 'true')
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
    document.removeEventListener('keydown', this.boundKeydown)
    document.removeEventListener('mobile-search:open', this.boundOpen)
    document.removeEventListener('turbo:visit', this.boundTurboVisit)
  }

  open() {
    if (this.isOpen) return
    this.isOpen = true

    this._savedScrollY = window.scrollY

    // Step 1: Make overlay interactive and focus input — SYNCHRONOUS within tap gesture
    // Overlay is at opacity:0 (from CSS) + pointer-events-none
    // Removing pointer-events-none makes it interactive; opacity:0 still allows iOS focus
    this.overlayTarget.classList.remove('pointer-events-none')
    this.overlayTarget.setAttribute('aria-hidden', 'false')
    this.inputTarget.focus()

    // Step 2: Animate overlay in AND lock scroll in the same frame
    // This ensures the body jump from position:fixed is never visible
    // because the overlay goes opaque in the same paint
    requestAnimationFrame(() => {
      this.overlayTarget.classList.add('mobile-search-visible')

      // Lock body scroll — overlay now covers viewport so jump is invisible
      document.body.style.position = 'fixed'
      document.body.style.top = `-${this._savedScrollY}px`
      document.body.style.left = '0'
      document.body.style.right = '0'
      document.body.style.overflow = 'hidden'

      // Hide bottom nav (if exists — native apps don't have it)
      const bottomNav = document.getElementById('mobile-bottom-nav')
      if (bottomNav) bottomNav.style.display = 'none'
    })

    // Show empty state if no query
    this.toggleEmptyState()
    document.addEventListener('keydown', this.boundKeydown)
  }

  close() {
    if (!this.isOpen) return
    this.isOpen = false

    // Dismiss keyboard first
    this.inputTarget.blur()

    // Unlock scroll BEFORE fade-out so the page restores underneath
    document.body.style.position = ''
    document.body.style.top = ''
    document.body.style.left = ''
    document.body.style.right = ''
    document.body.style.overflow = ''
    window.scrollTo(0, this._savedScrollY)

    // Restore bottom nav
    const bottomNav = document.getElementById('mobile-bottom-nav')
    if (bottomNav) bottomNav.style.display = ''

    // Animate out
    this.overlayTarget.classList.remove('mobile-search-visible')

    setTimeout(() => {
      this.overlayTarget.classList.add('pointer-events-none')
      this.overlayTarget.setAttribute('aria-hidden', 'true')

      // Reset for next open
      this.inputTarget.value = ''
      this.resultsTarget.innerHTML = ''
      this.resultsTarget.classList.add('hidden')
      if (this.hasEmptyStateTarget) this.emptyStateTarget.classList.remove('hidden')
      if (this.hasClearButtonTarget) this.clearButtonTarget.classList.add('hidden')
    }, 300)

    document.removeEventListener('keydown', this.boundKeydown)
  }

  // Immediate close without animation (for Turbo navigations)
  forceClose() {
    this.isOpen = false
    this.inputTarget.blur()
    this.overlayTarget.classList.remove('mobile-search-visible')
    this.overlayTarget.classList.add('pointer-events-none')
    this.overlayTarget.setAttribute('aria-hidden', 'true')
    document.body.style.position = ''
    document.body.style.top = ''
    document.body.style.left = ''
    document.body.style.right = ''
    document.body.style.overflow = ''
    window.scrollTo(0, this._savedScrollY)
    const bottomNav = document.getElementById('mobile-bottom-nav')
    if (bottomNav) bottomNav.style.display = ''
    document.removeEventListener('keydown', this.boundKeydown)
    this.inputTarget.value = ''
    this.resultsTarget.innerHTML = ''
    this.resultsTarget.classList.add('hidden')
    if (this.hasEmptyStateTarget) this.emptyStateTarget.classList.remove('hidden')
    if (this.hasClearButtonTarget) this.clearButtonTarget.classList.add('hidden')
  }

  search() {
    const query = this.inputTarget.value.trim()
    this.updateClearButton()
    this.toggleEmptyState()

    if (this.timeout) clearTimeout(this.timeout)

    if (query.length < 2) {
      this.resultsTarget.innerHTML = ''
      this.resultsTarget.classList.add('hidden')
      return
    }

    this.timeout = setTimeout(() => this.fetchSuggestions(query), 200)
  }

  async fetchSuggestions(query) {
    this.showLoadingState()

    try {
      const response = await fetch(`/search/suggestions?q=${encodeURIComponent(query)}`, {
        headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' }
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
        <div class="px-5 py-16 text-center">
          <svg class="w-12 h-12 mx-auto mb-4" style="color: #333;" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
          <p class="text-stone-400 text-sm">No results found for "<span style="color: #D4AF37;">${this.escapeHtml(query)}</span>"</p>
          <p class="text-stone-600 text-xs mt-2">Try a different search term</p>
        </div>
      `
      this.resultsTarget.classList.remove('hidden')
      return
    }

    let html = ''
    let rowIndex = 0

    if (categories.length > 0) {
      html += `<div class="px-5 pt-5 pb-2"><p class="text-xs font-medium uppercase tracking-widest" style="color: #D4AF37;">Categories</p></div>`
      categories.forEach(cat => {
        html += `
          <a href="/categories/${cat.slug}" data-turbo-frame="_top" data-action="click->mobile-search#close"
             class="search-result-row flex items-center gap-3 px-5 py-3 border-b border-stone-800/50 active:bg-stone-800/30 transition" style="animation-delay: ${rowIndex * 40}ms;">
            <div class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0" style="background: rgba(212, 175, 55, 0.1); border: 1px solid rgba(212, 175, 55, 0.2);">
              <svg class="w-4 h-4" style="color: #D4AF37;" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6z"/>
              </svg>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-stone-100 truncate">${this.escapeHtml(cat.name)}</p>
              <p class="text-xs text-stone-500">${cat.products_count} products</p>
            </div>
            <svg class="w-4 h-4 text-stone-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 5l7 7-7 7"/></svg>
          </a>
        `
        rowIndex++
      })
    }

    if (products.length > 0) {
      html += `<div class="px-5 pt-5 pb-2"><p class="text-xs font-medium uppercase tracking-widest" style="color: #D4AF37;">Products</p></div>`
      products.forEach(product => {
        const stockBadge = product.in_stock
          ? '<span class="text-xs text-emerald-400">In Stock</span>'
          : '<span class="text-xs text-red-400">Out of Stock</span>'

        html += `
          <a href="/products/${product.slug}" data-turbo-frame="_top" data-action="click->mobile-search#close"
             class="search-result-row flex items-center gap-3 px-5 py-3 border-b border-stone-800/50 active:bg-stone-800/30 transition" style="animation-delay: ${rowIndex * 40}ms;">
            <div class="w-12 h-12 rounded-lg overflow-hidden flex-shrink-0 border border-stone-700" style="background: #1a1a1a;">
              ${product.image
                ? `<img src="${product.image}" class="w-full h-full object-cover" alt="" loading="lazy">`
                : `<div class="w-full h-full flex items-center justify-center">
                    <svg class="w-5 h-5 text-stone-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                    </svg>
                  </div>`
              }
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-stone-100 truncate">${this.escapeHtml(product.name)}</p>
              <div class="flex items-center gap-2 mt-0.5">
                <span class="text-sm font-semibold" style="color: #D4AF37;">${product.price}</span>
                ${stockBadge}
              </div>
            </div>
            <svg class="w-4 h-4 text-stone-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 5l7 7-7 7"/></svg>
          </a>
        `
        rowIndex++
      })
    }

    if (variants.length > 0) {
      html += `<div class="px-5 pt-5 pb-2"><p class="text-xs font-medium uppercase tracking-widest" style="color: #D4AF37;">Variants</p></div>`
      variants.forEach(variant => {
        let stockClass = 'text-emerald-400'
        let stockText = 'In Stock'
        if (variant.stock_quantity === 0) {
          stockClass = 'text-red-400'
          stockText = 'Out of Stock'
        } else if (variant.stock_quantity <= 10) {
          stockClass = 'text-amber-400'
          stockText = `Only ${variant.stock_quantity} left`
        }

        html += `
          <a href="/products/${variant.product_slug}?variant=${variant.variant_param}" data-turbo-frame="_top" data-action="click->mobile-search#close"
             class="search-result-row flex items-center gap-3 px-5 py-3 border-b border-stone-800/50 active:bg-stone-800/30 transition" style="animation-delay: ${rowIndex * 40}ms;">
            <div class="w-12 h-12 rounded-lg overflow-hidden flex-shrink-0 border border-stone-700" style="background: #1a1a1a;">
              ${variant.image
                ? `<img src="${variant.image}" class="w-full h-full object-cover" alt="" loading="lazy">`
                : `<div class="w-full h-full flex items-center justify-center">
                    <svg class="w-5 h-5 text-stone-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"/>
                    </svg>
                  </div>`
              }
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-stone-100 truncate">${this.escapeHtml(variant.product_name)}</p>
              <p class="text-xs text-stone-500">${this.escapeHtml(variant.name)}</p>
              <div class="flex items-center gap-2 mt-0.5">
                <span class="text-sm font-semibold" style="color: #D4AF37;">${variant.price}</span>
                <span class="${stockClass} text-xs">${stockText}</span>
              </div>
            </div>
            <svg class="w-4 h-4 text-stone-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 5l7 7-7 7"/></svg>
          </a>
        `
        rowIndex++
      })
    }

    // View all results link
    html += `
      <div class="px-5 py-4">
        <a href="/products?q=${encodeURIComponent(query)}" data-turbo-frame="_top" data-action="click->mobile-search#close"
           class="block w-full py-3 text-center text-sm font-medium rounded-full border transition"
           style="color: #D4AF37; border-color: #D4AF37; background: rgba(212, 175, 55, 0.05);">
          View all results for "${this.escapeHtml(query)}"
        </a>
      </div>
    `

    this.resultsTarget.innerHTML = html
    this.resultsTarget.classList.remove('hidden')
  }

  showLoadingState() {
    let html = '<div class="px-5 pt-5 pb-2"><div class="h-3 w-24 search-shimmer rounded"></div></div>'
    for (let i = 0; i < 4; i++) {
      html += `
        <div class="px-5 py-3 flex items-center gap-3">
          <div class="w-12 h-12 search-shimmer flex-shrink-0 rounded-lg"></div>
          <div class="flex-1 space-y-2">
            <div class="h-3.5 w-3/4 search-shimmer rounded"></div>
            <div class="h-3 w-1/2 search-shimmer rounded"></div>
          </div>
        </div>
      `
    }
    this.resultsTarget.innerHTML = html
    this.resultsTarget.classList.remove('hidden')
  }

  clearInput() {
    this.inputTarget.value = ''
    this.resultsTarget.innerHTML = ''
    this.resultsTarget.classList.add('hidden')
    this.updateClearButton()
    this.toggleEmptyState()
    this.inputTarget.focus()
  }

  submitForm(event) {
    event.preventDefault()
    const query = this.inputTarget.value.trim()
    if (query.length > 0) {
      this.close()
      if (window.Turbo) {
        window.Turbo.visit(`/products?q=${encodeURIComponent(query)}`)
      } else {
        window.location.href = `/products?q=${encodeURIComponent(query)}`
      }
    }
  }

  updateClearButton() {
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.classList.toggle('hidden', this.inputTarget.value.length === 0)
    }
  }

  toggleEmptyState() {
    if (this.hasEmptyStateTarget) {
      const hasQuery = this.inputTarget.value.trim().length >= 2
      this.emptyStateTarget.classList.toggle('hidden', hasQuery)
      if (hasQuery) return
      this.resultsTarget.innerHTML = ''
      this.resultsTarget.classList.add('hidden')
    }
  }

  handleKeydown(event) {
    if (event.key === 'Escape') this.close()
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
