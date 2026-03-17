import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = [
    "input",
    "countryCode",
    "submit",
    "error",
    "countdown",
    "timerText",
    "resendButton"
  ]

  connect(){

    // OTP TIMER
    if(this.hasCountdownTarget){

      this.timeLeft = 30

      this.timer = setInterval(() => {

        this.timeLeft--

        this.countdownTarget.textContent = this.timeLeft

        if(this.timeLeft <= 0){

          clearInterval(this.timer)

          if(this.hasTimerTextTarget){
            this.timerTextTarget.classList.add("hidden")
          }

          if(this.hasResendButtonTarget){
            this.resendButtonTarget.classList.remove("hidden")
          }

        }

      },1000)

    }

  }


  validate(){

    const value = this.inputTarget.value.trim()

    // EMPTY FIELD
    if(value === ""){
      this.countryCodeTarget.classList.add("hidden")
      this.errorTarget.classList.add("hidden")
      this.submitTarget.disabled = true
      return
    }

    const isNumber = /^[0-9]+$/.test(value)

    if(isNumber){

      this.countryCodeTarget.classList.remove("hidden")
      const countryCode = this.countryCodeTarget.value

      // INDIA VALIDATION
      if(countryCode === "+91"){

        if(value.length === 10 && /^[6-9]/.test(value)){
          this.enable()
        }else{
          this.disable("Enter valid Indian mobile number")
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

    // EMAIL VALIDATION
    this.countryCodeTarget.classList.add("hidden")

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