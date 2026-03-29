import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "editButton", "actions"]

  edit() {
    this.fieldTargets.forEach(el => el.disabled = false)
    this.editButtonTarget.classList.add("hidden")
    this.actionsTarget.classList.remove("hidden")
  }

  cancel() {
    this.element.reset()
    this.lock()
  }

  lock() {
    this.fieldTargets.forEach(el => el.disabled = true)
    this.editButtonTarget.classList.remove("hidden")
    this.actionsTarget.classList.add("hidden")
  }
}
