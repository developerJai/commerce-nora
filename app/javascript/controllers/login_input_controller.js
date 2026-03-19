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
    "button"
  ]

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

    // ONLY CODE SHOW
    this.buttonTarget.textContent = code

    // hidden input
    this.countryCodeTarget.value = code

    this.dropdownTarget.classList.add("hidden")
  }

  // ================= VALIDATION =================

  validate(){

    const value = this.inputTarget.value.trim()

    // EMPTY
    if(value === ""){
      this.countryWrapperTarget.classList.add("hidden")
      this.errorTarget.classList.add("hidden")
      this.submitTarget.disabled = true
      return
    }

    const isNumber = /^[0-9]+$/.test(value)

    if(isNumber){

      this.countryWrapperTarget.classList.remove("hidden")

      const countryCode = this.countryCodeTarget.value

      // INDIA
      if(countryCode === "+91"){
        if(value.length === 10 && /^[6-9]/.test(value)){
          this.enable()
        }else{
          this.disable("Enter valid mobile number")
        }
        return
      }

      // OTHER COUNTRIES
      if(value.length >= 6 && value.length <= 12){
        this.enable()
      }else{
        this.disable("Invalid phone number")
      }

      return
    }

    // EMAIL
    this.countryWrapperTarget.classList.add("hidden")
    this.dropdownTarget.classList.add("hidden") // close dropdown

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

    if(emailRegex.test(value)){
      this.enable()
    }else{
      this.disable("Enter valid email address")
    }

  }

  enable(){
    this.submitTarget.disabled = false
    this.errorTarget.classList.add("hidden")
  }

  disable(message){
    this.submitTarget.disabled = true
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

}