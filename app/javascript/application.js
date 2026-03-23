// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Track the current visit action so turbo:load can decide whether to scroll
let currentVisitAction = null

document.addEventListener("turbo:visit", (event) => {
  currentVisitAction = event.detail.action
})

document.addEventListener("turbo:load", () => {
  // Only scroll to top on forward navigation (advance/replace)
  // Never scroll on restore (back/forward button) — let Turbo handle it
  if (currentVisitAction && currentVisitAction !== "restore") {
    window.scrollTo(0, 0)

    // Clear infinite scroll page tracking on fresh navigation so the set
    // doesn't grow unbounded across different product list visits.
    if (window._infiniteScrollLoadedPages) {
      window._infiniteScrollLoadedPages.clear()
    }
    window._infiniteScrollLastUpdated = null
  }
  currentVisitAction = null
})

// Clean up infinite scroll artifacts before Turbo caches the page snapshot.
// Sentinels and skeleton loaders are transient DOM nodes that should not be
// persisted in the snapshot — they'll be recreated when the controller reconnects.
document.addEventListener("turbo:before-cache", () => {
  document.querySelectorAll('.infinite-scroll-sentinel, [data-sentinel="true"], .skeleton-loader').forEach(el => el.remove())
})
