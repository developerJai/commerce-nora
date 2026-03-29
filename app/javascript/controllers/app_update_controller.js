import { Controller } from "@hotwired/stimulus"

// Manages smart app update notifications for Hotwire Native apps.
//
// Force updates: shown immediately, non-dismissable.
// Normal updates: shown with probability logic to avoid spamming users.
//   - 30% chance on first few page loads
//   - Guaranteed after 5+ navigations without seeing the prompt
//   - Once dismissed, won't show again in the session
export default class extends Controller {
  static values = {
    platform: String,
    currentVersion: String,
    checkUrl: String
  }

  connect() {
    this.pageViews = parseInt(sessionStorage.getItem("app_update_views") || "0", 10) + 1
    sessionStorage.setItem("app_update_views", this.pageViews)

    // Force updates always check immediately; normal updates respect session dismissal
    this.checkForUpdate()
  }

  async checkForUpdate() {
    if (!this.platformValue || !this.currentVersionValue) return

    try {
      const url = `${this.checkUrlValue}?platform=${this.platformValue}&current_version=${this.currentVersionValue}`
      const response = await fetch(url, { credentials: "same-origin" })
      if (!response.ok) return

      const data = await response.json()
      if (!data.update_available) return

      if (data.force_update) {
        this.showForceUpdate(data)
      } else {
        this.maybeShowNormalUpdate(data)
      }
    } catch (e) {
      // Silently fail — update checks should never break the app
    }
  }

  showForceUpdate(data) {
    // Try native bridge first
    this.sendNativeBridge(data)

    // Always show web modal as fallback (force updates are critical)
    this.renderForceModal(data)
  }

  maybeShowNormalUpdate(data) {
    // Already dismissed this session
    if (sessionStorage.getItem("app_update_dismissed") === "true") return

    // Smart frequency: 30% chance or guaranteed after 5 page views
    const shouldShow = this.pageViews >= 5 || Math.random() < 0.3
    if (!shouldShow) return

    // Try native bridge
    this.sendNativeBridge(data)

    // Show web modal
    this.renderNormalModal(data)
  }

  sendNativeBridge(data) {
    const message = {
      type: "app_update",
      force: data.force_update,
      version: data.latest_version,
      releaseNotes: data.release_notes,
      storeUrl: data.store_url
    }

    // iOS WKWebView bridge
    if (window.webkit?.messageHandlers?.nativeApp) {
      window.webkit.messageHandlers.nativeApp.postMessage(message)
    }

    // Android WebView bridge
    if (window.NativeApp?.handleMessage) {
      window.NativeApp.handleMessage(JSON.stringify(message))
    }
  }

  renderForceModal(data) {
    const overlay = document.createElement("div")
    overlay.id = "app-update-force-modal"
    overlay.className = "fixed inset-0 z-[9999] flex items-center justify-center bg-black/60 backdrop-blur-sm"
    overlay.style.cssText = "animation: fadeIn 0.3s ease-out"

    overlay.innerHTML = `
      <div class="bg-white rounded-2xl shadow-2xl mx-6 max-w-sm w-full overflow-hidden" style="animation: slideUp 0.3s ease-out">
        <div class="bg-gradient-to-br from-indigo-600 to-indigo-700 px-6 py-8 text-center">
          <div class="w-16 h-16 bg-white/20 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <svg class="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
            </svg>
          </div>
          <h2 class="text-xl font-bold text-white">Update Required</h2>
          <p class="text-indigo-200 text-sm mt-1">Version ${data.latest_version}</p>
        </div>
        <div class="px-6 py-6">
          <p class="text-gray-600 text-sm text-center mb-4">
            A new version of NoraLooks is available with important changes. Please update to continue shopping.
          </p>
          ${data.release_notes ? `<div class="bg-gray-50 rounded-lg p-3 mb-4"><p class="text-xs text-gray-500 font-medium mb-1">What's new</p><p class="text-sm text-gray-700">${this.escapeHtml(data.release_notes)}</p></div>` : ""}
          <a href="${this.escapeHtml(data.store_url || "#")}"
             class="block w-full text-center px-6 py-3 bg-indigo-600 text-white rounded-xl font-semibold text-sm hover:bg-indigo-700 transition-colors"
             target="_blank" rel="noopener">
            Update Now
          </a>
        </div>
      </div>
    `

    this.injectAnimationStyles()
    document.body.appendChild(overlay)
  }

  renderNormalModal(data) {
    const overlay = document.createElement("div")
    overlay.id = "app-update-normal-modal"
    overlay.className = "fixed inset-0 z-[9998] flex items-end justify-center bg-black/40"
    overlay.style.cssText = "animation: fadeIn 0.3s ease-out"

    overlay.innerHTML = `
      <div class="bg-white rounded-t-2xl shadow-2xl w-full max-w-lg pb-safe" style="animation: slideUp 0.35s ease-out">
        <div class="flex justify-center pt-3 pb-2">
          <div class="w-10 h-1 bg-gray-300 rounded-full"></div>
        </div>
        <div class="px-6 pb-6">
          <div class="flex items-start gap-4 mb-4">
            <div class="w-12 h-12 bg-indigo-100 rounded-xl flex items-center justify-center flex-shrink-0">
              <svg class="w-6 h-6 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"/>
              </svg>
            </div>
            <div>
              <h3 class="text-lg font-semibold text-gray-900">New Version Available</h3>
              <p class="text-sm text-gray-500 mt-0.5">NoraLooks v${data.latest_version} is here!</p>
            </div>
          </div>
          ${data.release_notes ? `<div class="bg-gray-50 rounded-lg p-3 mb-4"><p class="text-xs text-gray-500 font-medium mb-1">What's new</p><p class="text-sm text-gray-700">${this.escapeHtml(data.release_notes)}</p></div>` : ""}
          <div class="flex gap-3">
            <button id="app-update-later-btn"
                    class="flex-1 px-4 py-2.5 text-sm font-medium text-gray-700 bg-gray-100 rounded-xl hover:bg-gray-200 transition-colors">
              Later
            </button>
            <a href="${this.escapeHtml(data.store_url || "#")}"
               class="flex-1 text-center px-4 py-2.5 text-sm font-semibold text-white bg-indigo-600 rounded-xl hover:bg-indigo-700 transition-colors"
               target="_blank" rel="noopener">
              Update
            </a>
          </div>
        </div>
      </div>
    `

    // Allow dismissing by tapping the backdrop
    overlay.addEventListener("click", (e) => {
      if (e.target === overlay) this.dismissNormal()
    })

    this.injectAnimationStyles()
    document.body.appendChild(overlay)

    // Bind the Later button after it's in the DOM
    document.getElementById("app-update-later-btn")?.addEventListener("click", () => this.dismissNormal())
  }

  dismissNormal() {
    sessionStorage.setItem("app_update_dismissed", "true")
    const modal = document.getElementById("app-update-normal-modal")
    if (modal) {
      modal.style.animation = "fadeOut 0.2s ease-in forwards"
      setTimeout(() => modal.remove(), 200)
    }
  }

  escapeHtml(str) {
    if (!str) return ""
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }

  injectAnimationStyles() {
    if (document.getElementById("app-update-animations")) return

    const style = document.createElement("style")
    style.id = "app-update-animations"
    style.textContent = `
      @keyframes fadeIn { from { opacity: 0 } to { opacity: 1 } }
      @keyframes fadeOut { from { opacity: 1 } to { opacity: 0 } }
      @keyframes slideUp { from { transform: translateY(100%) } to { transform: translateY(0) } }
      .pb-safe { padding-bottom: max(1.5rem, env(safe-area-inset-bottom)) }
    `
    document.head.appendChild(style)
  }
}
