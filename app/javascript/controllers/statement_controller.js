import { Controller } from "@hotwired/stimulus";
import { validStartAndEndDate, validAccountNumber } from "services/field-validation_services";

export default class extends Controller {
  static targets = [
    "accountNumber",
    "accountNumberError",
    "fromDate",
    "toDate",
    "toDateError",
    "tooltip",
    "submitButton"
  ];

  isAccountValid = false;
  isDateValid = false;

  connect() {
    this.toDateErrorTarget.classList.add("hidden");
  }

  validateFromAndToDate() {
    const isValid = validStartAndEndDate(
      this.fromDateTarget.value,
      this.toDateTarget.value
    );

    this.toDateErrorTarget.classList.toggle("hidden", isValid);
    this.isDateValid = isValid;
    this.submitable();
  }

  validateAccountNumber() {
    const isValid = validAccountNumber(this.accountNumberTarget.value);
    const message = isValid ? "" : "Invalid Account Number";

    this.accountNumberErrorTarget.textContent = message;
    this.isAccountValid = isValid;
    this.submitable();
  }

  submitable() {
    this.submitButtonTarget.disabled = !(this.isAccountValid && this.isDateValid);
  }

  showTooltip() {
    this.tooltipTarget.classList.remove("hidden");
  }

  hideTooltip() {
    this.tooltipTarget.classList.add("hidden");
  }
}
