import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "main", "placeholder", "thumbs", "error"]
  static values = { maxFiles: { type: Number, default: 15 } }

  connect() {
    this.createdObjectUrls = []
    this.syncVisibility()
  }

  disconnect() {
    // Clean up object URLs to prevent memory leaks
    this.revokeAllObjectUrls()
  }

  change() {
    const files = (this.inputTarget.files && Array.from(this.inputTarget.files)) || []

    if (files.length === 0) {
      this.syncVisibility()
      return
    }

    // Validate file count
    if (files.length > this.maxFilesValue) {
      this.showError(`Please select no more than ${this.maxFilesValue} images.`)
      this.inputTarget.value = ""
      return
    }

    // Validate file types
    const invalidType = files.find((f) => !f.type || !f.type.startsWith("image/"))
    if (invalidType) {
      this.showError("Please select only image files (JPEG, PNG, GIF, etc.).")
      this.inputTarget.value = ""
      return
    }

    // Validate file sizes
    const oversize = files.find((f) => f.size > 2 * 1024 * 1024)
    if (oversize) {
      this.showError("Each image must be smaller than 2 MB.")
      this.inputTarget.value = ""
      return
    }

    // Clear previous error and object URLs
    this.clearError()
    this.revokeAllObjectUrls()

    // Create new object URLs and store them for cleanup
    const urls = files.map((f) => {
      const url = URL.createObjectURL(f)
      this.createdObjectUrls.push(url)
      return url
    })

    this.mainTarget.src = urls[0]

    if (this.hasThumbsTarget) {
      this.thumbsTarget.innerHTML = ""
      urls.forEach((url, idx) => {
        const btn = document.createElement("button")
        btn.type = "button"
        btn.className = "aspect-square bg-stone-50 rounded-lg overflow-hidden border border-stone-200 hover:border-rose-300 transition"
        btn.addEventListener("click", () => {
          this.mainTarget.src = url
          this.syncVisibility(true)
        })

        const img = document.createElement("img")
        img.src = url
        img.alt = ""
        img.className = "w-full h-full object-cover"

        btn.appendChild(img)
        this.thumbsTarget.appendChild(btn)
      })
    }

    this.syncVisibility(true)
  }

  select(event) {
    const url = event.currentTarget.dataset.url
    if (!url) return

    this.mainTarget.src = url
    this.syncVisibility(true)
  }

  syncVisibility(forcePreview = false) {
    const hasPreview = forcePreview || (this.mainTarget.getAttribute("src") || "").length > 0

    if (hasPreview) {
      this.mainTarget.classList.remove("hidden")
      if (this.hasPlaceholderTarget) this.placeholderTarget.classList.add("hidden")
    } else {
      this.mainTarget.classList.add("hidden")
      if (this.hasPlaceholderTarget) this.placeholderTarget.classList.remove("hidden")
    }
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    } else {
      // Fallback to alert if no error target exists
      window.alert(message)
    }
  }

  clearError() {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = ""
      this.errorTarget.classList.add("hidden")
    }
  }

  revokeAllObjectUrls() {
    this.createdObjectUrls.forEach(url => {
      URL.revokeObjectURL(url)
    })
    this.createdObjectUrls = []
  }
}
