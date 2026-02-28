import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["firstName", "lastName", "email", "phone", "phoneError", "password", "passwordConfirmation", "form"]
  
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
    const errors = []

    // Validate required fields (only if targets exist)
    if (this.hasFirstNameTarget && this.firstNameTarget.value.trim() === '') {
      errors.push('First name is required')
    }

    if (this.hasLastNameTarget && this.lastNameTarget.value.trim() === '') {
      errors.push('Last name is required')
    }

    if (this.hasEmailTarget && this.emailTarget.value.trim() === '') {
      errors.push('Email is required')
    }

    // Password validation: different for signup vs signin
    if (this.hasPasswordTarget) {
      if (this.hasPasswordConfirmationTarget) {
        // Signup form - require minimum 8 characters
        if (this.passwordTarget.value.length < 8) {
          errors.push('Password must be at least 8 characters')
        }
      } else {
        // Signin form - just require non-empty
        if (this.passwordTarget.value.trim() === '') {
          errors.push('Password is required')
        }
      }
    }

    if (this.hasPasswordConfirmationTarget && this.hasPasswordTarget && 
        this.passwordConfirmationTarget.value !== this.passwordTarget.value) {
      errors.push('Password confirmation does not match')
    }

    // Validate phone number
    if (!this.validatePhone()) {
      if (this.hasPhoneTarget) {
        this.phoneTarget.focus()
      }
      return false
    }

    if (errors.length > 0) {
      alert(errors.join('\n'))
      return false
    }

    return true
  }

  // Form Submission
  submit(event) {
    if (!this.validateForm()) {
      event.preventDefault()
      return
    }

    // Format phone number with country code
    if (this.hasPhoneTarget && this.phoneTarget.value.trim() && this.phoneInputInstance) {
      const fullNumber = this.phoneInputInstance.getNumber()
      this.phoneTarget.value = fullNumber
    }
  }

  // Password Toggle
  togglePassword(event) {
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
