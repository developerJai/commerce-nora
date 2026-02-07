import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "main", "placeholder", "thumbs"]

  connect() {
    this.syncVisibility()
  }

  change() {
    const files = (this.inputTarget.files && Array.from(this.inputTarget.files)) || []

    if (files.length === 0) {
      this.syncVisibility()
      return
    }

    const invalidType = files.find((f) => !f.type || !f.type.startsWith("image/"))
    if (invalidType) {
      this.inputTarget.value = ""
      window.alert("Please select only image files.")
      return
    }

    const oversize = files.find((f) => f.size > 2 * 1024 * 1024)
    if (oversize) {
      this.inputTarget.value = ""
      window.alert("Each image must be smaller than 2 MB.")
      return
    }

    const urls = files.map((f) => URL.createObjectURL(f))
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
}
