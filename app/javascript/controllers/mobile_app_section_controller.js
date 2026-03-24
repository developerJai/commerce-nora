import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["section", "fab"]
  static values = {
    iosUrl: String,
    androidUrl: String
  }

  connect() {
    if (this.isDismissed()) {
      this.sectionTarget.classList.add("hidden")
      this.fabTarget.classList.remove("hidden")
    }
  }

  dismiss() {
    // Slide out the section
    this.sectionTarget.style.transition = "opacity 0.3s ease, max-height 0.4s ease"
    this.sectionTarget.style.opacity = "0"
    this.sectionTarget.style.maxHeight = this.sectionTarget.scrollHeight + "px"

    requestAnimationFrame(() => {
      this.sectionTarget.style.maxHeight = "0"
      this.sectionTarget.style.overflow = "hidden"
    })

    setTimeout(() => {
      this.sectionTarget.classList.add("hidden")
      this.showFab()
    }, 400)

    try {
      localStorage.setItem("mobile_app_section_dismissed", Date.now().toString())
    } catch (e) {
      // localStorage not available
    }
  }

  showFab() {
    this.fabTarget.classList.remove("hidden")
    requestAnimationFrame(() => {
      this.fabTarget.classList.remove("scale-0", "opacity-0")
      this.fabTarget.classList.add("scale-100", "opacity-100")
    })
  }

  openFromFab() {
    // Restore the section
    this.sectionTarget.classList.remove("hidden")
    this.sectionTarget.style.transition = "opacity 0.3s ease"
    this.sectionTarget.style.opacity = "0"
    this.sectionTarget.style.maxHeight = ""
    this.sectionTarget.style.overflow = ""

    requestAnimationFrame(() => {
      this.sectionTarget.style.opacity = "1"
    })

    // Hide FAB
    this.fabTarget.classList.add("scale-0", "opacity-0")
    setTimeout(() => {
      this.fabTarget.classList.add("hidden")
    }, 200)

    // Scroll to section
    this.sectionTarget.scrollIntoView({ behavior: "smooth", block: "center" })

    try {
      localStorage.removeItem("mobile_app_section_dismissed")
    } catch (e) {
      // localStorage not available
    }
  }

  getAppUrl() {
    const ua = navigator.userAgent || ""
    if (/iPhone|iPad|iPod/.test(ua)) return this.iosUrlValue
    if (/Android/.test(ua)) return this.androidUrlValue
    return this.iosUrlValue || this.androidUrlValue
  }

  isDismissed() {
    try {
      const dismissed = localStorage.getItem("mobile_app_section_dismissed")
      if (!dismissed) return false

      const elapsed = Date.now() - parseInt(dismissed, 10)
      const ONE_HOUR = 60 * 60 * 1000

      if (elapsed >= ONE_HOUR) {
        localStorage.removeItem("mobile_app_section_dismissed")
        return false
      }
      return true
    } catch (e) {
      return false
    }
  }
}
