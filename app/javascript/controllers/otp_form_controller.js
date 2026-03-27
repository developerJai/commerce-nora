import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

	handleResponse(event) {
	  console.log("success:", event.detail.success)

	  if (!event.detail.success) {
	    this.inputTarget.value = ""
	  }
	}
}