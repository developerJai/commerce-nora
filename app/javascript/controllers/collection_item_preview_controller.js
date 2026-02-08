import { Controller } from "@hotwired/stimulus"

// Provides live preview for homepage collection item forms:
// - Shows uploaded image in a card preview matching the storefront layout
// - Validates file size (2 MB max) and type (JPG/PNG/WebP)
// - Displays image dimensions and file size info
// - Overlays title, subtitle, and badge text in real-time

export default class extends Controller {
  static targets = [
    "input",             // file input
    "previewImage",      // <img> in the preview card
    "previewPlaceholder",// placeholder div when no image
    "previewTitle",      // title overlay text
    "previewSubtitle",   // subtitle overlay text
    "previewBadge",      // badge overlay text
    "previewOverlay",    // the overlay container
    "fileMeta",          // file size + dimensions display
    "titleInput",        // title text field
    "subtitleInput",     // subtitle text field
    "badgeInput",        // badge text field
    "errorMessage"       // validation error display
  ]

  static values = {
    maxSize: { type: Number, default: 2097152 }, // 2 MB
    recommendedWidth: Number,
    recommendedHeight: Number
  }

  connect() {
    this.syncPreview()
    this.syncOverlayText()
  }

  // Called when file input changes
  selectFile() {
    this.clearError()
    const file = this.inputTarget.files && this.inputTarget.files[0]

    if (!file) {
      this.hideImage()
      return
    }

    // Validate type
    if (!["image/jpeg", "image/png", "image/webp"].includes(file.type)) {
      this.showError("Please select a JPG, PNG, or WebP image.")
      this.inputTarget.value = ""
      this.hideImage()
      return
    }

    // Validate size
    if (file.size > this.maxSizeValue) {
      const sizeMB = (file.size / (1024 * 1024)).toFixed(1)
      this.showError(`Image must be less than 2 MB. Selected file is ${sizeMB} MB.`)
      this.inputTarget.value = ""
      this.hideImage()
      return
    }

    // Read and preview
    const reader = new FileReader()
    reader.onload = (e) => {
      this.showImage(e.target.result)
      this.loadImageMeta(e.target.result, file.size)
    }
    reader.readAsDataURL(file)
  }

  // Called when title/subtitle/badge text fields change
  updateOverlay() {
    this.syncOverlayText()
  }

  // ── Private helpers ──

  showImage(src) {
    if (this.hasPreviewImageTarget) {
      this.previewImageTarget.src = src
      this.previewImageTarget.classList.remove("hidden")
    }
    if (this.hasPreviewPlaceholderTarget) {
      this.previewPlaceholderTarget.classList.add("hidden")
    }
  }

  hideImage() {
    if (this.hasPreviewImageTarget) {
      this.previewImageTarget.classList.add("hidden")
      this.previewImageTarget.removeAttribute("src")
    }
    if (this.hasPreviewPlaceholderTarget) {
      this.previewPlaceholderTarget.classList.remove("hidden")
    }
    if (this.hasFileMetaTarget) {
      this.fileMetaTarget.innerHTML = ""
    }
  }

  syncPreview() {
    // If there's already an image src (existing record), show it
    if (this.hasPreviewImageTarget) {
      const src = this.previewImageTarget.getAttribute("src")
      if (src && src.length > 0) {
        this.previewImageTarget.classList.remove("hidden")
        if (this.hasPreviewPlaceholderTarget) {
          this.previewPlaceholderTarget.classList.add("hidden")
        }
      } else {
        this.hideImage()
      }
    }
  }

  syncOverlayText() {
    if (this.hasPreviewTitleTarget && this.hasTitleInputTarget) {
      const val = this.titleInputTarget.value.trim()
      this.previewTitleTarget.textContent = val
      this.previewTitleTarget.classList.toggle("hidden", !val)
    }
    if (this.hasPreviewSubtitleTarget && this.hasSubtitleInputTarget) {
      const val = this.subtitleInputTarget.value.trim()
      this.previewSubtitleTarget.textContent = val
      this.previewSubtitleTarget.classList.toggle("hidden", !val)
    }
    if (this.hasPreviewBadgeTarget && this.hasBadgeInputTarget) {
      const val = this.badgeInputTarget.value.trim()
      this.previewBadgeTarget.textContent = val
      this.previewBadgeTarget.classList.toggle("hidden", !val)
    }
    // Show/hide overlay based on whether any text present
    if (this.hasPreviewOverlayTarget) {
      const hasAny = (this.hasTitleInputTarget && this.titleInputTarget.value.trim()) ||
                     (this.hasSubtitleInputTarget && this.subtitleInputTarget.value.trim()) ||
                     (this.hasBadgeInputTarget && this.badgeInputTarget.value.trim())
      this.previewOverlayTarget.classList.toggle("hidden", !hasAny)
    }
  }

  loadImageMeta(src, fileSize) {
    if (!this.hasFileMetaTarget) return

    const img = new Image()
    img.onload = () => {
      const w = img.naturalWidth
      const h = img.naturalHeight
      const sizeMB = (fileSize / (1024 * 1024)).toFixed(2)
      const recW = this.hasRecommendedWidthValue ? this.recommendedWidthValue : null
      const recH = this.hasRecommendedHeightValue ? this.recommendedHeightValue : null

      let dimClass = "text-green-600"
      let dimNote = "Dimensions look good"
      if (recW && recH) {
        if (w < recW * 0.7 || h < recH * 0.7) {
          dimClass = "text-red-600"
          dimNote = `Too small — recommended ${recW} × ${recH}px`
        } else if (w < recW || h < recH) {
          dimClass = "text-amber-600"
          dimNote = `Slightly small — recommended ${recW} × ${recH}px`
        } else {
          dimNote = `Meets recommended ${recW} × ${recH}px`
        }
      }

      this.fileMetaTarget.innerHTML = `
        <div class="flex items-center gap-4 text-xs mt-2">
          <span class="text-gray-500">${w} × ${h}px</span>
          <span class="text-gray-500">${sizeMB} MB</span>
          <span class="${dimClass} font-medium">${dimNote}</span>
        </div>
      `
    }
    img.src = src
  }

  showError(message) {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message
      this.errorMessageTarget.classList.remove("hidden")
    }
  }

  clearError() {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = ""
      this.errorMessageTarget.classList.add("hidden")
    }
  }
}
