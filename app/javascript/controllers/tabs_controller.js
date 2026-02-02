import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    const selectedTab = event.currentTarget.dataset.tab

    // Update tabs
    this.tabTargets.forEach(tab => {
      if (tab.dataset.tab === selectedTab) {
        tab.classList.add("border-rose-700", "text-rose-800")
        tab.classList.remove("border-transparent", "text-stone-500", "hover:text-stone-700")
      } else {
        tab.classList.remove("border-rose-700", "text-rose-800")
        tab.classList.add("border-transparent", "text-stone-500", "hover:text-stone-700")
      }
    })

    // Update panels
    this.panelTargets.forEach(panel => {
      if (panel.dataset.tab === selectedTab) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}
