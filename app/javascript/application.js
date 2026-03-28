// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Disable default Turbo progress bar — replaced by jewellery loader
Turbo.setProgressBarDelay(Infinity)

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

// --- Jewellery page loader: show/hide on Turbo visits and auth form submissions ---
;(function () {
  const DELAY = 200 // only show loader if navigation takes longer than this (ms)
  let timer = null

  function show() {
    const el = document.getElementById("jewel-loader")
    if (el) { el.classList.add("active"); el.setAttribute("aria-hidden", "false") }
  }

  function hide() {
    clearTimeout(timer)
    timer = null
    const el = document.getElementById("jewel-loader")
    if (el) { el.classList.remove("active"); el.setAttribute("aria-hidden", "true") }
  }

  // Show loader on page navigations
  document.addEventListener("turbo:before-fetch-request", (event) => {
    // Don't show loader for turbo frame requests (e.g. modals, inline frames)
    if (event.target.closest && event.target.closest("turbo-frame")) return
    if (!timer) timer = setTimeout(show, DELAY)
  })

  // Show loader immediately on login/logout form submissions
  document.addEventListener("turbo:submit-start", (event) => {
    const form = event.target
    if (form && form.dataset.showLoader === "true") {
      clearTimeout(timer)
      show()
    }
  })

  document.addEventListener("turbo:load", hide)
  document.addEventListener("turbo:fetch-request-error", hide)
  // Hide loader after Turbo Stream responses (e.g. cart remove/update)
  // turbo:load only fires for full-page navigations, not stream responses
  document.addEventListener("turbo:before-stream-render", hide)
  // Hide loader after turbo frame navigations (e.g. coupon modal)
  document.addEventListener("turbo:frame-load", hide)
  document.addEventListener("turbo:frame-render", hide)
})()

// --- Mobile bottom nav: debounce rapid tab switches to prevent screen freeze ---
// When users tap tabs faster than the page can load, overlapping Turbo visits
// fight over the DOM and the WebView locks up. We block new nav taps until the
// current visit settles, and debounce within a 300ms window.
;(function () {
  const DEBOUNCE_MS = 300
  let lastNavTap = 0
  let navigating = false

  function isMobileNavLink(element) {
    return element.closest("[data-mobile-nav]") !== null
  }

  // Intercept clicks on mobile nav links before Turbo processes them
  document.addEventListener("turbo:click", (event) => {
    if (!isMobileNavLink(event.target)) return

    const now = Date.now()

    // Block if a visit is already in-flight or tapped too recently
    if (navigating || now - lastNavTap < DEBOUNCE_MS) {
      event.preventDefault()
      return
    }

    lastNavTap = now
    navigating = true

    // Dim the nav to give immediate visual feedback
    const nav = document.querySelector("[data-mobile-nav]")
    if (nav) nav.style.pointerEvents = "none"
  })

  // Re-enable nav once the page finishes loading
  document.addEventListener("turbo:load", () => {
    navigating = false
    const nav = document.querySelector("[data-mobile-nav]")
    if (nav) nav.style.pointerEvents = ""
  })

  // Also re-enable if the visit fails or is cancelled
  document.addEventListener("turbo:fetch-request-error", () => {
    navigating = false
    const nav = document.querySelector("[data-mobile-nav]")
    if (nav) nav.style.pointerEvents = ""
  })
})()
