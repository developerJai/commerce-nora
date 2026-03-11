import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pagination", "loadMoreContainer", "noMore"]

  connect() {
    // EMERGENCY BRAKE: Detect infinite reconnection loop
    if (!window._infiniteScrollConnectCount) {
      window._infiniteScrollConnectCount = 0
      window._infiniteScrollFirstConnect = Date.now()
    }
    
    window._infiniteScrollConnectCount++
    const elapsed = Date.now() - window._infiniteScrollFirstConnect
    
    // If more than 5 connects in 2 seconds, something is wrong - STOP
    if (window._infiniteScrollConnectCount > 5 && elapsed < 2000) {
      return
    }
    
    // Reset counter after 3 seconds
    if (elapsed > 3000) {
      window._infiniteScrollConnectCount = 1
      window._infiniteScrollFirstConnect = Date.now()
    }
    
    // Prevent multiple rapid connections
    if (this.connectTimeout) {
      clearTimeout(this.connectTimeout)
    }
    
    this.isLoading = false
    this.lastUpdated = null
    
    // Preserve loaded pages across reconnections
    if (!window._infiniteScrollLoadedPages) {
      window._infiniteScrollLoadedPages = new Set()
    }
    this.loadedPages = window._infiniteScrollLoadedPages
    
    // Small delay to ensure DOM is ready
    this.connectTimeout = setTimeout(() => {
      this.setupObserver()
    }, 300)
  }

  disconnect() {
    if (this.connectTimeout) {
      clearTimeout(this.connectTimeout)
    }
    
    this.cleanup()
  }

  paginationTargetConnected() {
    const updated = this.paginationTarget.dataset.updated
    
    // Only reset if this is a new update
    if (updated && updated !== this.lastUpdated) {
      this.lastUpdated = updated
      this.cleanup()
      setTimeout(() => this.setupObserver(), 100)
    }
  }

  cleanup() {
    if (this.observer) {
      this.observer.disconnect()
      this.observer = null
    }
    this.removeSentinel()
  }

  getPaginationData() {
    if (!this.hasPaginationTarget) {
      return { nextUrl: '', hasNext: false }
    }
    
    return {
      nextUrl: this.paginationTarget.dataset.nextUrl || '',
      hasNext: this.paginationTarget.dataset.hasNext === 'true'
    }
  }

  setupObserver() {
    const { nextUrl, hasNext } = this.getPaginationData()
    
    // Show no more message if no next page
    if (!hasNext) {
      this.showNoMoreMessage()
      return
    }

    // Don't setup if already loading
    if (!nextUrl || this.isLoading) {
      return
    }

    // Check if we already loaded this page
    if (this.loadedPages.has(nextUrl)) {
      return
    }

    // Hide no more message and load more button when setting up observer
    this.hideNoMoreMessage()
    this.hideLoadMoreButton()

    // Create sentinel
    this.createSentinel()

    // Setup intersection observer
    const isMobile = window.innerWidth <= 768
    const rootMargin = isMobile ? '100px' : '200px'

    this.observer = new IntersectionObserver((entries) => {
      const entry = entries[0]
      
      if (entry.isIntersecting && !this.isLoading) {
        // Immediately stop observing
        if (this.observer) {
          this.observer.disconnect()
          this.observer = null
        }
        
        this.loadNextPage(nextUrl)
      }
    }, {
      root: null,
      rootMargin: rootMargin,
      threshold: 0
    })

    this.observer.observe(this.sentinel)
  }

  createSentinel() {
    // Remove any existing sentinel
    this.removeSentinel()

    // Create new sentinel
    this.sentinel = document.createElement('div')
    this.sentinel.className = 'infinite-scroll-sentinel'
    this.sentinel.style.cssText = 'height: 20px; visibility: hidden;'
    this.sentinel.setAttribute('data-sentinel', 'true')

    // Insert after the wrapper element - BUT check parent exists
    if (!this.element.parentNode) {
      return
    }
    
    this.element.parentNode.insertBefore(this.sentinel, this.element.nextSibling)
  }

  async loadNextPage(url) {
    // Multiple guards against duplicate loading
    if (this.isLoading) {
      return
    }

    if (this.loadedPages.has(url)) {
      return
    }

    if (!url) {
      return
    }
    
    // Mark as loading immediately
    this.isLoading = true
    this.loadedPages.add(url)
    this.showLoadingIndicator()

    try {
      const controller = new AbortController()
      const timeoutId = setTimeout(() => controller.abort(), 15000)

      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'X-Requested-With': 'XMLHttpRequest'
        },
        signal: controller.signal
      })

      clearTimeout(timeoutId)

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }

      const html = await response.text()
      
      if (html && html.trim().length > 0) {
        Turbo.renderStreamMessage(html)
      }

    } catch (error) {
      // Remove from loaded pages so it can be retried
      this.loadedPages.delete(url)
      
      let errorMessage = 'Failed to load more products.'
      if (error.name === 'AbortError') {
        errorMessage = 'Request timed out.'
      }

      this.showError(errorMessage)
    } finally {
      this.isLoading = false
      this.hideLoadingIndicator()
    }
  }

  showLoadingIndicator() {
    const grid = document.getElementById('products-grid')
    if (!grid || document.querySelector('.skeleton-loader')) return

    const skeletonHTML = `
      <div class="skeleton-loader col-span-2 sm:col-span-2 md:col-span-3 mt-4">
        <div class="grid grid-cols-2 sm:grid-cols-2 md:grid-cols-3 gap-3 sm:gap-4 lg:gap-5">
          ${this.createSkeletonCard()}
          ${this.createSkeletonCard()}
          ${this.createSkeletonCard()}
        </div>
      </div>
    `
    grid.insertAdjacentHTML('afterend', skeletonHTML)
  }

  hideLoadingIndicator() {
    const skeletons = document.querySelectorAll('.skeleton-loader')
    skeletons.forEach(skeleton => skeleton.remove())
  }

  createSkeletonCard() {
    return `
      <div class="bg-white rounded-lg border border-stone-200 overflow-hidden animate-pulse">
        <div class="aspect-square bg-stone-200"></div>
        <div class="p-3 space-y-2">
          <div class="h-4 bg-stone-200 rounded w-3/4"></div>
          <div class="h-3 bg-stone-200 rounded w-1/2"></div>
          <div class="h-4 bg-stone-200 rounded w-1/3"></div>
        </div>
      </div>
    `
  }

  showError(message) {
    const grid = document.getElementById('products-grid')
    if (!grid) return

    // Show load more button as fallback
    this.showLoadMoreButton()

    const errorHTML = `
      <div class="error-message col-span-full mt-4 p-4 text-center text-red-600 bg-red-50 border border-red-200 rounded-lg">
        <div class="flex items-center justify-center gap-2">
          <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path>
          </svg>
          <span>${message}</span>
        </div>
      </div>
    `
    grid.insertAdjacentHTML('afterend', errorHTML)

    setTimeout(() => {
      const error = document.querySelector('.error-message')
      if (error) error.remove()
    }, 5000)
  }

  showLoadMoreButton() {
    if (this.hasLoadMoreContainerTarget) {
      this.loadMoreContainerTarget.style.display = 'block'
    }
  }

  hideLoadMoreButton() {
    if (this.hasLoadMoreContainerTarget) {
      this.loadMoreContainerTarget.style.display = 'none'
    }
  }

  showNoMoreMessage() {
    if (this.hasMoreTarget) {
      this.noMoreTarget.style.display = 'block'
    }
    this.hideLoadMoreButton()
  }

  hideNoMoreMessage() {
    if (this.hasMoreTarget) {
      this.noMoreTarget.style.display = 'none'
    }
  }

  removeSentinel() {
    if (this.sentinel) {
      if (this.observer) {
        this.observer.unobserve(this.sentinel)
      }
      if (this.sentinel.parentNode) {
        this.sentinel.remove()
      }
      this.sentinel = null
    }
    
    // Also remove any orphaned sentinels
    const orphans = document.querySelectorAll('[data-sentinel="true"]')
    orphans.forEach(el => el.remove())
  }
}
