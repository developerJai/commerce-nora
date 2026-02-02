import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "dialog"]

  connect() {
    // Close on escape key
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundKeydown)
  }

  disconnect() {
    document.removeEventListener('keydown', this.boundKeydown)
  }

  open() {
    this.backdropTarget.classList.remove('hidden')
    this.dialogTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
    
    // Animate in
    requestAnimationFrame(() => {
      this.backdropTarget.classList.add('opacity-100')
      this.dialogTarget.classList.add('opacity-100')
    })
  }

  close() {
    this.backdropTarget.classList.add('hidden')
    this.dialogTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }
}
