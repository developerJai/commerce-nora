import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "thumbnail"]

  selectImage(event) {
    const index = event.params.index

    // Update slides with opacity transition
    this.slideTargets.forEach((slide, i) => {
      if (i === index) {
        slide.classList.remove("opacity-0")
        slide.classList.add("opacity-100")
      } else {
        slide.classList.remove("opacity-100")
        slide.classList.add("opacity-0")
      }
    })

    // Update thumbnails
    this.thumbnailTargets.forEach((thumb, i) => {
      if (i === index) {
        thumb.classList.add("border-rose-500")
        thumb.classList.remove("border-stone-200", "border-transparent", "hover:border-rose-300")
      } else {
        thumb.classList.remove("border-rose-500")
        thumb.classList.add("border-stone-200", "hover:border-rose-300")
      }
    })
  }
}
