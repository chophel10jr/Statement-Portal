import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["otpInput", "otpField", "submitButton"]

  connect() {
    if (this.otpInputTargets.length > 0) {
      this.otpInputTargets[0].focus()
    }
  }

  handleOTPInput(event) {
    const input = event.target
    const value = input.value

    // Only allow numbers
    if (!/^\d$/.test(value)) {
      input.value = ""
      this.updateOTPField()
      this.validateOTP()
      return
    }

    // Move to next input if current input is filled
    const index = parseInt(input.dataset.index)
    if (value && index < this.otpInputTargets.length - 1) {
      this.otpInputTargets[index + 1].focus()
    }

    // Update hidden field and validate
    this.updateOTPField()
    this.validateOTP()
  }

  handleKeydown(event) {
    const input = event.target
    const index = parseInt(input.dataset.index)

    // Handle backspace
    if (event.key === "Backspace") {
      // Clear current input first
      input.value = ""
      
      // Update and validate immediately
      this.updateOTPField()
      this.validateOTP()
      
      // Move to previous input if current was already empty
      if (index > 0) {
        this.otpInputTargets[index - 1].focus()
      }
      
      event.preventDefault()
    }

    // Handle delete key
    if (event.key === "Delete") {
      input.value = ""
      this.updateOTPField()
      this.validateOTP()
      event.preventDefault()
    }

    // Handle arrow keys
    if (event.key === "ArrowLeft" && index > 0) {
      this.otpInputTargets[index - 1].focus()
    }
    if (event.key === "ArrowRight" && index < this.otpInputTargets.length - 1) {
      this.otpInputTargets[index + 1].focus()
    }
  }

  handlePaste(event) {
    event.preventDefault()
    const pastedData = event.clipboardData.getData("text").trim()

    // Only allow numeric paste
    if (!/^\d+$/.test(pastedData)) {
      return
    }

    // Fill inputs with pasted data
    const digits = pastedData.split("").slice(0, 4)
    digits.forEach((digit, index) => {
      if (this.otpInputTargets[index]) {
        this.otpInputTargets[index].value = digit
      }
    })

    // Focus on last filled input or next empty input
    const lastIndex = Math.min(digits.length, this.otpInputTargets.length - 1)
    this.otpInputTargets[lastIndex].focus()

    // Update hidden field and validate
    this.updateOTPField()
    this.validateOTP()
  }

  updateOTPField() {
    const otp = this.otpInputTargets.map(input => input.value).join("")
    this.otpFieldTarget.value = otp
  }

  validateOTP() {
    const otp = this.otpFieldTarget.value

    if (otp.length === 4) {
      this.submitButtonTarget.disabled = false
    } else {
      this.submitButtonTarget.disabled = true
    }
  }
}