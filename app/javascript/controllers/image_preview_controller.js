import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "placeholder", "input"]

  connect() {
    this.syncVisibility()
  }

  change() {
    const file = this.inputTarget.files && this.inputTarget.files[0]
    if (!file) {
      this.syncVisibility()
      return
    }

    if (!file.type || !file.type.startsWith("image/")) {
      this.inputTarget.value = ""
      this.previewTarget.removeAttribute("src")
      this.syncVisibility(false)
      window.alert("Please select an image file.")
      return
    }

    if (file.size > 2 * 1024 * 1024) {
      this.inputTarget.value = ""
      this.previewTarget.removeAttribute("src")
      this.syncVisibility(false)
      window.alert("Image must be smaller than 2 MB.")
      return
    }

    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.src = e.target.result
      this.syncVisibility(true)
    }
    reader.readAsDataURL(file)
  }

  syncVisibility(forcePreview = false) {
    const hasPreview = forcePreview || (this.previewTarget.getAttribute("src") || "").length > 0

    if (hasPreview) {
      this.previewTarget.classList.remove("hidden")
      this.placeholderTarget.classList.add("hidden")
    } else {
      this.previewTarget.classList.add("hidden")
      this.placeholderTarget.classList.remove("hidden")
    }
  }
}
