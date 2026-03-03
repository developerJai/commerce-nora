import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["firstName", "lastName", "email", "emailError", "phone", "phoneError", "password", "passwordConfirmation", "form", "submitButton"]
  
  connect() {
    this.phoneInputInstance = null
    this.initializePhoneInput()
    this.setupSpacePrevention()
  }

  disconnect() {
    // Clean up phone input instance
    if (this.phoneInputInstance) {
      this.phoneInputInstance.destroy()
    }
  }

  // Phone Input Methods
  async initializePhoneInput() {
    // Wait for DOM to be ready
    await new Promise(resolve => {
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', resolve)
      } else {
        resolve()
      }
    })

    // Load intl-tel-input if not available
    if (typeof window.intlTelInput === 'undefined') {
      await this.loadIntlTelInput()
    }

    if (this.hasPhoneTarget) {
      // Destroy existing instance if it exists
      if (this.phoneInputInstance) {
        this.phoneInputInstance.destroy()
      }

      // Initialize intl-tel-input
      this.phoneInputInstance = window.intlTelInput(this.phoneTarget, {
        initialCountry: 'us',
        separateDialCode: true,
        utilsScript: 'https://cdnjs.cloudflare.com/ajax/libs/intl-tel-input/17.0.19/js/utils.min.js',
        preferredCountries: ['us', 'gb', 'in', 'ca', 'au'],
        customPlaceholder: () => 'Enter phone number',
        formatOnInit: true
      })
    }
  }

  async loadIntlTelInput() {
    return new Promise((resolve) => {
      if (typeof window.intlTelInput !== 'undefined') {
        resolve()
        return
      }

      // Load CSS
      const css = document.createElement('link')
      css.rel = 'stylesheet'
      css.href = 'https://cdnjs.cloudflare.com/ajax/libs/intl-tel-input/17.0.19/css/intlTelInput.css'
      document.head.appendChild(css)

      // Load utils script first
      const utilsScript = document.createElement('script')
      utilsScript.src = 'https://cdnjs.cloudflare.com/ajax/libs/intl-tel-input/17.0.19/js/utils.min.js'
      
      // Load main script
      const script = document.createElement('script')
      script.src = 'https://cdnjs.cloudflare.com/ajax/libs/intl-tel-input/17.0.19/js/intlTelInput.min.js'
      
      script.onload = () => {
        // Wait a bit more to ensure everything is loaded
        setTimeout(resolve, 100)
      }
      
      document.head.appendChild(utilsScript)
      document.head.appendChild(script)
    })
  }

  validatePhone() {
    if (!this.hasPhoneTarget || !this.phoneInputInstance) return true

    if (this.phoneTarget.value.trim()) {
      if (!this.phoneInputInstance.isValidNumber()) {
        const errorCode = this.phoneInputInstance.getValidationError()
        let errorMessage = 'Invalid phone number'

        switch(errorCode) {
          case 0:
            errorMessage = 'Invalid country code'
            break
          case 1:
            errorMessage = 'Phone number too short'
            break
          case 2:
            errorMessage = 'Phone number too long'
            break
          case 3:
            errorMessage = 'Invalid phone number format'
            break
        }

        // Special validation for India (10 digits)
        const countryData = this.phoneInputInstance.getSelectedCountryData()
        if (countryData.iso2 === 'in') {
          const phoneNumber = this.phoneTarget.value.replace(/\D/g, '')
          if (phoneNumber.length !== 10) {
            errorMessage = 'Indian phone numbers must be exactly 10 digits'
          }
        }

        this.phoneErrorTarget.textContent = errorMessage
        this.phoneErrorTarget.classList.remove('hidden')
        this.phoneTarget.classList.add('border-red-500')
        return false
      } else {
        this.phoneErrorTarget.classList.add('hidden')
        this.phoneTarget.classList.remove('border-red-500')
        return true
      }
    } else {
      this.phoneErrorTarget.classList.add('hidden')
      this.phoneTarget.classList.remove('border-red-500')
      return true // Phone is optional
    }
  }

  // Email Validation Helper
  isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailRegex.test(email)
  }

  validateEmail() {
    if (!this.hasEmailTarget) return true

    const email = this.emailTarget.value.trim()
    
    if (email === '') {
      if (this.hasEmailErrorTarget) {
        this.emailErrorTarget.textContent = 'Email is required'
        this.emailErrorTarget.classList.remove('hidden')
      }
      this.emailTarget.classList.add('border-red-500')
      return false
    } else if (!this.isValidEmail(email)) {
      if (this.hasEmailErrorTarget) {
        this.emailErrorTarget.textContent = 'Please enter a valid email address'
        this.emailErrorTarget.classList.remove('hidden')
      }
      this.emailTarget.classList.add('border-red-500')
      return false
    } else {
      if (this.hasEmailErrorTarget) {
        this.emailErrorTarget.classList.add('hidden')
      }
      this.emailTarget.classList.remove('border-red-500')
      return true
    }
  }

  // Space Prevention Methods

  setupSpacePrevention() {
    const spacePreventedFields = [
      this.hasFirstNameTarget ? this.firstNameTarget : null,
      this.hasLastNameTarget ? this.lastNameTarget : null,
      this.hasPasswordTarget ? this.passwordTarget : null,
      this.hasPasswordConfirmationTarget ? this.passwordConfirmationTarget : null
    ].filter(Boolean)

    spacePreventedFields.forEach(field => {
      field.addEventListener('input', this.removeSpaces.bind(this))
      field.addEventListener('keydown', this.preventSpaceKey.bind(this))
    })

    if (this.hasEmailTarget) {
      this.emailTarget.addEventListener('input', this.removeSpaces.bind(this))
      this.emailTarget.addEventListener('keydown', this.preventSpaceKey.bind(this))
    }
} 

  removeSpaces(event) {
    event.target.value = event.target.value.replace(/\s/g, '')
  }

  preventSpaceKey(event) {
    if (event.key === ' ') {
      event.preventDefault()
    }
  }

  // Form Validation
  validateForm() {
    let isValid = true

    // Validate required fields (only if targets exist)
    if (this.hasFirstNameTarget && this.firstNameTarget.value.trim() === '') {
      this.firstNameTarget.classList.add('border-red-500')
      isValid = false
    } else if (this.hasFirstNameTarget) {
      this.firstNameTarget.classList.remove('border-red-500')
    }

    if (this.hasLastNameTarget && this.lastNameTarget.value.trim() === '') {
      this.lastNameTarget.classList.add('border-red-500')
      isValid = false
    } else if (this.hasLastNameTarget) {
      this.lastNameTarget.classList.remove('border-red-500')
    }

    // Validate email
    if (!this.validateEmail()) {
      isValid = false
    }

    // Password validation: different for signup vs signin
    if (this.hasPasswordTarget) {
      if (this.hasPasswordConfirmationTarget) {
        // Signup form - require minimum 8 characters
        if (this.passwordTarget.value.length < 8) {
          this.passwordTarget.classList.add('border-red-500')
          isValid = false
        } else {
          this.passwordTarget.classList.remove('border-red-500')
        }
      }
    }

    if (this.hasPasswordConfirmationTarget && this.hasPasswordTarget && 
        this.passwordConfirmationTarget.value !== this.passwordTarget.value) {
      this.passwordConfirmationTarget.classList.add('border-red-500')
      isValid = false
    } else if (this.hasPasswordConfirmationTarget) {
      this.passwordConfirmationTarget.classList.remove('border-red-500')
    }

    // Validate phone number
    if (!this.validatePhone()) {
      isValid = false
    }

    return isValid
  }

  // Form Submission
  submit(event) {
    if (!this.validateForm()) {
      event.preventDefault()
      return
    }

    // Show loading state
    this.showLoading()

    // Format phone number with country code
    if (this.hasPhoneTarget && this.phoneTarget.value.trim() && this.phoneInputInstance) {
      const fullNumber = this.phoneInputInstance.getNumber()
      this.phoneTarget.value = fullNumber
    }

    // Form will submit normally - don't prevent default
  }

  showLoading() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.dataset.originalText = this.submitButtonTarget.value
      this.submitButtonTarget.value = 'Loading...'
      this.submitButtonTarget.classList.add('opacity-75', 'cursor-not-allowed')
    }
  }

  hideLoading() {
    if (this.hasSubmitButtonTarget && this.submitButtonTarget.dataset.originalText) {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.value = this.submitButtonTarget.dataset.originalText
      this.submitButtonTarget.classList.remove('opacity-75', 'cursor-not-allowed')
    }
  }

  // Password Toggle - Fixed for mobile touch
  togglePassword(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const button = event.currentTarget
    const fieldId = button.dataset.fieldId
    const field = document.getElementById(fieldId)
    
    if (!field) return

    const isPassword = field.type === 'password'
    field.type = isPassword ? 'text' : 'password'

    // Toggle eye icon
    if (isPassword) {
      button.innerHTML = `
        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"/>
        </svg>
      `
    } else {
      button.innerHTML = `
        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
        </svg>
      `
    }
  }
}
