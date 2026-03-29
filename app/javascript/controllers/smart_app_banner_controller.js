import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner", "storeName", "ctaButton", "fab", "fabIconIos", "fabIconAndroid", "fabIconFallback", "bannerIconDefault", "bannerIconIos", "bannerIconAndroid"]
  static values = {
    iosUrl: String,
    androidUrl: String,
    dismissed: { type: Boolean, default: false }
  }

  connect() {
    if (this.isDesktop() || this.isHotwireNative()) return

    if (this.wasDismissed()) {
      this.showFab()
    } else {
      this.showBanner()
    }
  }

  showBanner() {
    const platform = this.detectPlatform()
    if (!platform) return

    const url = platform === "ios" ? this.iosUrlValue : this.androidUrlValue
    if (!url) return

    this.ctaButtonTarget.href = url
    this.storeNameTarget.textContent = platform === "ios" ? "App Store" : "Google Play"

    // Show platform icon in banner
    if (platform === "ios" && this.hasBannerIconIosTarget) {
      this.bannerIconIosTarget.classList.remove("hidden")
      if (this.hasBannerIconDefaultTarget) this.bannerIconDefaultTarget.classList.add("hidden")
    } else if (platform === "android" && this.hasBannerIconAndroidTarget) {
      this.bannerIconAndroidTarget.classList.remove("hidden")
      if (this.hasBannerIconDefaultTarget) this.bannerIconDefaultTarget.classList.add("hidden")
    }

    this.bannerTarget.classList.remove("hidden")

    // Animate in
    requestAnimationFrame(() => {
      this.bannerTarget.classList.remove("translate-y-full", "opacity-0")
      this.bannerTarget.classList.add("translate-y-0", "opacity-100")
    })
  }

  dismiss() {
    this.bannerTarget.classList.add("translate-y-full", "opacity-0")
    this.bannerTarget.classList.remove("translate-y-0", "opacity-100")

    setTimeout(() => {
      this.bannerTarget.classList.add("hidden")
      this.showFab()
    }, 300)

    try {
      localStorage.setItem("smart_app_banner_dismissed", Date.now().toString())
    } catch (e) {
      // localStorage not available
    }
  }

  showFab() {
    if (!this.hasFabTarget) return

    // Show the correct platform icon
    const platform = this.detectPlatform()
    if (platform === "ios" && this.hasFabIconIosTarget) {
      this.fabIconIosTarget.classList.remove("hidden")
      if (this.hasFabIconFallbackTarget) this.fabIconFallbackTarget.classList.add("hidden")
    } else if (platform === "android" && this.hasFabIconAndroidTarget) {
      this.fabIconAndroidTarget.classList.remove("hidden")
      if (this.hasFabIconFallbackTarget) this.fabIconFallbackTarget.classList.add("hidden")
    }

    this.fabTarget.classList.remove("hidden")
    requestAnimationFrame(() => {
      this.fabTarget.classList.remove("scale-0", "opacity-0")
      this.fabTarget.classList.add("scale-100", "opacity-100")
    })
  }

  hideFab() {
    if (!this.hasFabTarget) return
    this.fabTarget.classList.add("scale-0", "opacity-0")
    setTimeout(() => {
      this.fabTarget.classList.add("hidden")
    }, 200)
  }

  openFromFab() {
    this.hideFab()

    try {
      localStorage.removeItem("smart_app_banner_dismissed")
    } catch (e) {
      // localStorage not available
    }

    this.showBanner()
  }

  detectPlatform() {
    const ua = navigator.userAgent || ""

    // iOS detection
    if (/iPhone|iPad|iPod/.test(ua) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)) {
      return this.iosUrlValue ? "ios" : null
    }

    // Android detection
    if (/Android/.test(ua)) {
      return this.androidUrlValue ? "android" : null
    }

    return null
  }

  isDesktop() {
    return !/Mobi|Android|iPhone|iPad|iPod/i.test(navigator.userAgent)
  }

  isHotwireNative() {
    return (navigator.userAgent || "").includes("NoraLooks/")
  }

  wasDismissed() {
    try {
      const dismissed = localStorage.getItem("smart_app_banner_dismissed")
      if (!dismissed) return false

      const elapsed = Date.now() - parseInt(dismissed, 10)
      const ONE_HOUR = 60 * 60 * 1000

      if (elapsed >= ONE_HOUR) {
        localStorage.removeItem("smart_app_banner_dismissed")
        return false
      }
      return true
    } catch (e) {
      return false
    }
  }
}
