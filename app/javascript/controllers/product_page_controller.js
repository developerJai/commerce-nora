import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Only scroll to top when this is a fresh visit (advance), not a
    // restoration visit (back/forward). Turbo fires "turbo:before-render"
    // before Stimulus controllers connect, so we can't read the visit
    // action directly.  Instead, check whether this connect happened
    // during a Turbo restoration by inspecting the cached flag.
    if (document.documentElement.hasAttribute("data-turbo-preview")) {
      // This is a cached preview render — skip scrolling
      return
    }

    window.requestAnimationFrame(() => {
      window.scrollTo({ top: 0, left: 0, behavior: "auto" })
    })
  }
}
