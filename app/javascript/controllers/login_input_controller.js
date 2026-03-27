import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = [
    "input",
    "countryCode",
    "countryWrapper",
    "submit",
    "error",
    "dropdown",
    "search",
    "list",
    "dropdown",
    "button"
  ]

  connect() {
    this.loadUtils()
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }


    disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  toggle() {
    this.dropdownTarget.classList.toggle("hidden")
  }

  // ✅ CLICK OUTSIDE LOGIC
  handleClickOutside(event) {
    // agar click dropdown ya button ke andar nahi hai
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden")
    }
  }

  // 🔥 LOAD GOOGLE LIBPHONENUMBER (via intl utils)
  loadUtils() {
    if (window.intlTelInputUtils) return

    const script = document.createElement("script")
    script.src = "https://cdnjs.cloudflare.com/ajax/libs/intl-tel-input/17.0.19/js/utils.min.js"
    document.head.appendChild(script)
  }

  // ================= DROPDOWN =================

  toggle() {
    this.dropdownTarget.classList.toggle("hidden")

    if (!this.dropdownTarget.classList.contains("hidden")) {
      this.searchTarget.focus()
    }
  }

  filter() {
    const value = this.searchTarget.value.toLowerCase()

    this.listTarget.querySelectorAll("li").forEach(item => {
      const text = item.textContent.toLowerCase()
      item.classList.toggle("hidden", !text.includes(value))
    })
  }

  select(event) {
    const item = event.currentTarget
    const code = item.dataset.code

    this.buttonTarget.textContent = code
    this.countryCodeTarget.value = code

    this.dropdownTarget.classList.add("hidden")

    // 🔥 revalidate after change
    this.validate()
  }

  // ================= VALIDATION =================

  validate() {
    const value = this.inputTarget.value.trim()

    // EMPTY
    if (value === "") {
      this.countryWrapperTarget.classList.add("hidden")
      this.disable("")
      return
    }

    // EMAIL CHECK
    if (this.isEmail(value)) {
      this.countryWrapperTarget.classList.add("hidden")
      this.dropdownTarget.classList.add("hidden")
      this.enable()
      return
    }

    // NUMBER CHECK
    if (/^[0-9]+$/.test(value)) {

      this.countryWrapperTarget.classList.remove("hidden")

      const countryCode = this.countryCodeTarget.value.replace("+", "")
      const fullNumber = "+" + countryCode + value

      // 🔥 DYNAMIC VALIDATION (ALL COUNTRIES)
      if (window.intlTelInputUtils) {

        const isValid = window.intlTelInputUtils.isValidNumber(
          fullNumber,
          countryCode
        )

        if (isValid) {
          this.enable()
        } else {
          this.disable("Enter valid phone number")
        }

      } else {
        // fallback (rare)
        if (value.length >= 6) {
          this.enable()
        } else {
          this.disable("Invalid phone number")
        }
      }

      return
    }

    // INVALID INPUT
    this.disable("Enter valid email or phone number")
  }

  isEmail(value) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
  }

  enable() {
    this.submitTarget.disabled = false
    this.errorTarget.classList.add("hidden")
    this.inputTarget.classList.remove("border-red-500")
  }

  disable(message) {
    this.submitTarget.disabled = true

    if (message) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
      this.inputTarget.classList.add("border-red-500")
    }
  }
}