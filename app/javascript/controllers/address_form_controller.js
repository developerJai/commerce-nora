import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["phone", "phoneError", "country", "state", "countryCodeField"]
  static values = { statesByCountry: Object }

  connect() {
    this.phoneInputInstance = null
    this.initializePhoneInput()
  }

  disconnect() {
    if (this.phoneInputInstance) {
      this.phoneInputInstance.destroy()
    }
  }

  // --- Phone Input (intl-tel-input) ---

  async initializePhoneInput() {
    try {
      if (typeof window.intlTelInput === 'undefined') {
        await this.loadIntlTelInput()
      }

      if (this.hasPhoneTarget) {
        if (this.phoneInputInstance) {
          this.phoneInputInstance.destroy()
        }

        const initialCountry = this.phoneTarget.dataset.initialCountry || 'in'

        this.phoneInputInstance = window.intlTelInput(this.phoneTarget, {
          initialCountry: initialCountry,
          separateDialCode: true,
          utilsScript: 'https://cdnjs.cloudflare.com/ajax/libs/intl-tel-input/17.0.19/js/utils.min.js',
          preferredCountries: ['in', 'us', 'gb', 'ca', 'au'],
          customPlaceholder: () => 'Enter phone number'
        })
      }
    } catch (error) {
      console.error('[AddressForm] Phone input init error:', error)
    }
  }

  loadIntlTelInput() {
    return new Promise((resolve, reject) => {
      if (typeof window.intlTelInput !== 'undefined') {
        resolve()
        return
      }

      if (document.querySelector('script[src*="intlTelInput"]')) {
        const checkLoaded = setInterval(() => {
          if (typeof window.intlTelInput !== 'undefined') {
            clearInterval(checkLoaded)
            resolve()
          }
        }, 50)
        return
      }

      const css = document.createElement('link')
      css.rel = 'stylesheet'
      css.href = 'https://cdnjs.cloudflare.com/ajax/libs/intl-tel-input/17.0.19/css/intlTelInput.css'
      document.head.appendChild(css)

      const script = document.createElement('script')
      script.src = 'https://cdnjs.cloudflare.com/ajax/libs/intl-tel-input/17.0.19/js/intlTelInput.min.js'
      script.onload = () => setTimeout(resolve, 100)
      script.onerror = () => reject(new Error('Failed to load intl-tel-input'))
      document.head.appendChild(script)
    })
  }

  // --- Country / State (plain native selects) ---

  countryChanged() {
    if (!this.hasCountryTarget || !this.hasStateTarget) return

    const country = this.countryTarget.value
    if (!country) return

    const statesByCountry = this.statesByCountryValue || {}
    const states = statesByCountry[country] || []

    // Rebuild state <option> list
    const stateSelect = this.stateTarget
    stateSelect.innerHTML = ''

    // Placeholder
    const placeholder = document.createElement('option')
    placeholder.value = ''
    placeholder.textContent = 'Select state'
    placeholder.disabled = true
    placeholder.selected = true
    stateSelect.appendChild(placeholder)

    states.forEach(state => {
      const opt = document.createElement('option')
      opt.value = state
      opt.textContent = state
      stateSelect.appendChild(opt)
    })
  }

  // --- Validation ---

  validatePhone() {
    if (!this.hasPhoneTarget) return true

    const phoneValue = this.phoneTarget.value.trim()

    if (!phoneValue) {
      this.showPhoneError('Phone number is required')
      return false
    }

    // Use intl-tel-input validation if utils is loaded
    if (this.phoneInputInstance && typeof intlTelInputUtils !== 'undefined') {
      if (!this.phoneInputInstance.isValidNumber()) {
        const errorCode = this.phoneInputInstance.getValidationError()
        const countryData = this.phoneInputInstance.getSelectedCountryData()
        let msg = 'Invalid phone number'

        switch (errorCode) {
          case 1: msg = `Phone number too short for ${countryData.name}`; break
          case 2: msg = `Phone number too long for ${countryData.name}`; break
          case 3: msg = `Invalid phone number format for ${countryData.name}`; break
          default: msg = `Invalid phone number for ${countryData.name}`
        }

        this.showPhoneError(msg)
        return false
      }
    } else {
      // Fallback: basic digit-length check
      const digits = phoneValue.replace(/\D/g, '')
      if (digits.length < 7 || digits.length > 15) {
        this.showPhoneError('Please enter a valid phone number')
        return false
      }
    }

    this.clearPhoneError()
    return true
  }

  showPhoneError(msg) {
    if (this.hasPhoneErrorTarget) {
      this.phoneErrorTarget.textContent = msg
      this.phoneErrorTarget.classList.remove('hidden')
    }
    this.phoneTarget.classList.add('border-red-500')
  }

  clearPhoneError() {
    if (this.hasPhoneErrorTarget) {
      this.phoneErrorTarget.classList.add('hidden')
    }
    this.phoneTarget.classList.remove('border-red-500')
  }

  // --- Form Submit ---

  submit(event) {
    let isValid = true

    // 1. Validate phone
    if (!this.validatePhone()) {
      isValid = false
    } else if (this.phoneInputInstance) {
      // Save country code to hidden field
      const countryData = this.phoneInputInstance.getSelectedCountryData()
      if (this.hasCountryCodeFieldTarget) {
        this.countryCodeFieldTarget.value = '+' + countryData.dialCode
      }
      // Store only digits in the phone field
      this.phoneTarget.value = this.phoneTarget.value.replace(/\D/g, '')
    }

    // 2. Validate state
    if (this.hasStateTarget) {
      const stateValue = this.stateTarget.value
      if (!stateValue) {
        isValid = false
        this.stateTarget.classList.add('border-red-500')
      } else {
        this.stateTarget.classList.remove('border-red-500')
      }
    }

    // 3. Validate country
    if (this.hasCountryTarget) {
      const countryValue = this.countryTarget.value
      if (!countryValue) {
        isValid = false
        this.countryTarget.classList.add('border-red-500')
      } else {
        this.countryTarget.classList.remove('border-red-500')
      }
    }

    if (!isValid) {
      event.preventDefault()
      return false
    }
  }
}
