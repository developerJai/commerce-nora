import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option"]

  selectVariant(event) {
    const button = event.currentTarget
    const variantSlug = button.dataset.variantSlug

    const currentUrl = new URL(window.location.href)
    currentUrl.searchParams.set('variant', variantSlug)
    Turbo.visit(currentUrl.toString(), { frame: "_top" })
  }
}
