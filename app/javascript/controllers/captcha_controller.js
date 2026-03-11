import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "submit", "hiddenField"]
  static values = {
    verified: { type: Boolean, default: false }
  }

  connect() {
    this.generateChallenge()
    this.disableSubmit()
  }

  generateChallenge() {
    const challenges = [
      this.createEmojiChallenge,
      this.createColorChallenge,
      this.createShapeChallenge,
      this.createPatternChallenge
    ]
    
    const randomChallenge = challenges[Math.floor(Math.random() * challenges.length)]
    randomChallenge.call(this)
  }

  createEmojiChallenge() {
    const emojis = ['🌟', '🎨', '🚀', '🌈', '⚡', '🎯', '💎', '🔥']
    const correctEmoji = emojis[Math.floor(Math.random() * emojis.length)]
    const shuffled = this.shuffleArray([...emojis])
    
    this.containerTarget.innerHTML = `
      <div class="mb-4">
        <p class="text-sm font-medium text-gray-700 mb-3">Verify you're human: Click the <span class="text-lg">${correctEmoji}</span></p>
        <div class="grid grid-cols-4 gap-2">
          ${shuffled.map(emoji => `
            <button type="button" 
                    data-action="click->captcha#verifyEmoji"
                    data-emoji="${emoji}"
                    data-correct="${emoji === correctEmoji}"
                    class="p-3 text-2xl bg-gray-50 hover:bg-gray-100 rounded-lg transition-colors border border-gray-200 focus:outline-none focus:ring-2 focus:ring-indigo-500">
              ${emoji}
            </button>
          `).join('')}
        </div>
      </div>
    `
  }

  createColorChallenge() {
    const colors = [
      { name: 'Red', class: 'bg-red-500', value: 'red' },
      { name: 'Blue', class: 'bg-blue-500', value: 'blue' },
      { name: 'Green', class: 'bg-green-500', value: 'green' },
      { name: 'Yellow', class: 'bg-yellow-500', value: 'yellow' },
      { name: 'Purple', class: 'bg-purple-500', value: 'purple' },
      { name: 'Orange', class: 'bg-orange-500', value: 'orange' }
    ]
    
    const correctColor = colors[Math.floor(Math.random() * colors.length)]
    const shuffled = this.shuffleArray([...colors])
    
    this.containerTarget.innerHTML = `
      <div class="mb-4">
        <p class="text-sm font-medium text-gray-700 mb-3">Verify you're human: Select <span class="font-bold">${correctColor.name}</span></p>
        <div class="grid grid-cols-3 gap-2">
          ${shuffled.map(color => `
            <button type="button"
                    data-action="click->captcha#verifyColor"
                    data-color="${color.value}"
                    data-correct="${color.value === correctColor.value}"
                    class="${color.class} h-12 rounded-lg hover:opacity-80 transition-opacity border-2 border-gray-300 focus:outline-none focus:ring-2 focus:ring-indigo-500">
            </button>
          `).join('')}
        </div>
      </div>
    `
  }

  createShapeChallenge() {
    const shapes = [
      { name: 'Circle', svg: '<circle cx="20" cy="20" r="15" fill="currentColor"/>', value: 'circle' },
      { name: 'Square', svg: '<rect x="5" y="5" width="30" height="30" fill="currentColor"/>', value: 'square' },
      { name: 'Triangle', svg: '<polygon points="20,5 35,35 5,35" fill="currentColor"/>', value: 'triangle' },
      { name: 'Star', svg: '<polygon points="20,2 25,15 38,15 28,23 32,36 20,28 8,36 12,23 2,15 15,15" fill="currentColor"/>', value: 'star' }
    ]
    
    const correctShape = shapes[Math.floor(Math.random() * shapes.length)]
    const shuffled = this.shuffleArray([...shapes])
    
    this.containerTarget.innerHTML = `
      <div class="mb-4">
        <p class="text-sm font-medium text-gray-700 mb-3">Verify you're human: Click the <span class="font-bold">${correctShape.name}</span></p>
        <div class="grid grid-cols-4 gap-2">
          ${shuffled.map(shape => `
            <button type="button"
                    data-action="click->captcha#verifyShape"
                    data-shape="${shape.value}"
                    data-correct="${shape.value === correctShape.value}"
                    class="p-3 bg-gray-50 hover:bg-gray-100 rounded-lg transition-colors border border-gray-200 focus:outline-none focus:ring-2 focus:ring-indigo-500">
              <svg viewBox="0 0 40 40" class="w-10 h-10 text-gray-700 mx-auto">
                ${shape.svg}
              </svg>
            </button>
          `).join('')}
        </div>
      </div>
    `
  }

  createPatternChallenge() {
    const patterns = [
      { name: 'Horizontal Lines', pattern: 'repeating-linear-gradient(0deg, #4B5563 0px, #4B5563 2px, transparent 2px, transparent 6px)', value: 'horizontal' },
      { name: 'Vertical Lines', pattern: 'repeating-linear-gradient(90deg, #4B5563 0px, #4B5563 2px, transparent 2px, transparent 6px)', value: 'vertical' },
      { name: 'Diagonal Lines', pattern: 'repeating-linear-gradient(45deg, #4B5563 0px, #4B5563 2px, transparent 2px, transparent 6px)', value: 'diagonal' },
      { name: 'Dots', pattern: 'radial-gradient(circle, #4B5563 1px, transparent 1px)', value: 'dots' }
    ]
    
    const correctPattern = patterns[Math.floor(Math.random() * patterns.length)]
    const shuffled = this.shuffleArray([...patterns])
    
    this.containerTarget.innerHTML = `
      <div class="mb-4">
        <p class="text-sm font-medium text-gray-700 mb-3">Verify you're human: Select <span class="font-bold">${correctPattern.name}</span></p>
        <div class="grid grid-cols-2 gap-2">
          ${shuffled.map(pattern => `
            <button type="button"
                    data-action="click->captcha#verifyPattern"
                    data-pattern="${pattern.value}"
                    data-correct="${pattern.value === correctPattern.value}"
                    style="background-image: ${pattern.pattern}; background-size: ${pattern.value === 'dots' ? '8px 8px' : 'auto'};"
                    class="h-16 rounded-lg hover:opacity-80 transition-opacity border-2 border-gray-300 focus:outline-none focus:ring-2 focus:ring-indigo-500">
            </button>
          `).join('')}
        </div>
      </div>
    `
  }

  togglePassword(event) {
    const button = event.currentTarget
    const fieldId = button.dataset.fieldId
    const input = document.getElementById(fieldId)

    const slash = button.querySelector(".eye-slash")

    if (input.type === "password") {
      input.type = "text"
      slash.classList.remove("hidden")
    } else {
      input.type = "password"
      slash.classList.add("hidden")
    }
  }

  verifyEmoji(event) {
    this.handleVerification(event)
  }

  verifyColor(event) {
    this.handleVerification(event)
  }

  verifyShape(event) {
    this.handleVerification(event)
  }

  verifyPattern(event) {
    this.handleVerification(event)
  }

  handleVerification(event) {
    const button = event.currentTarget
    const isCorrect = button.dataset.correct === 'true'
    
    if (isCorrect) {
      this.verifiedValue = true
      this.hiddenFieldTarget.value = this.generateToken()
      
      button.classList.remove('bg-gray-50', 'hover:bg-gray-100')
      button.classList.add('bg-green-100', 'border-green-500')
      
      this.containerTarget.innerHTML = `
        <div class="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg">
          <p class="text-sm font-medium text-green-800 flex items-center">
            <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
            </svg>
            Verification successful! You can now sign in.
          </p>
        </div>
      `
      
      this.enableSubmit()
    } else {
      button.classList.add('bg-red-100', 'border-red-500')
      setTimeout(() => {
        this.containerTarget.innerHTML = `
          <div class="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p class="text-sm font-medium text-red-800">Incorrect selection. Generating new challenge...</p>
          </div>
        `
        setTimeout(() => {
          this.generateChallenge()
        }, 1000)
      }, 500)
    }
  }

  generateToken() {
    const timestamp = Date.now()
    const random = Math.random().toString(36).substring(2, 15)
    return `${timestamp}-${random}`
  }

  disableSubmit() {
    this.submitTarget.disabled = true
    this.submitTarget.classList.add('opacity-50', 'cursor-not-allowed')
    this.submitTarget.classList.remove('hover:bg-indigo-700')
  }

  enableSubmit() {
    this.submitTarget.disabled = false
    this.submitTarget.classList.remove('opacity-50', 'cursor-not-allowed')
    this.submitTarget.classList.add('hover:bg-indigo-700')
  }

  shuffleArray(array) {
    const shuffled = [...array]
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]]
    }
    return shuffled
  }
}
