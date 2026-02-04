import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["notice"];

  connect() {
    setTimeout(() => {
      this.hide();
    }, 5000);
  }

  hide() {
    this.noticeTarget.classList.remove("show");
  }
}
