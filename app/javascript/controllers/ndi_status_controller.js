import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { token: String };
  static targets = ["loader"];

  connect() {
    this.maxAttempts = 20;
    this.attempts = 0;

    // Start polling every 10 seconds
    this.interval = setInterval(() => this.checkWebhookProcessed(), 10000);

    // Show loader after 20 seconds
    this.loaderTimeout = setTimeout(() => this.showLoader(), 20000);
  }

  checkWebhookProcessed() {
    if (this.attempts >= this.maxAttempts) {
      this.redirectWithMessage("/", "Maximum attempts reached.");
      return;
    }

    this.attempts += 1;

    fetch(`/fetch_status?token=${this.tokenValue}`)
      .then(async (response) => {
        const data = await response.json();

        switch (response.status) {
          case 200:
            this.stopPolling();
            if (data.shared) {
              const redirectUrl = `/statement/new?token=${this.tokenValue}`
              window.location.href = redirectUrl;
              break;
            } else {
              this.redirectWithMessage("/", "Please share all data to process!");
              break;
            }

          case 400:
            this.redirectWithMessage("/", "Bad Request: Token is missing or empty.");
            break;

          case 401:
            this.redirectWithMessage("/", "Unauthorized: Invalid or expired token.");
            break;

          case 404:
            // Keep polling, VC not ready yet
            break;

          default:
            this.redirectWithMessage("/", `Unexpected error ${response.status}`);
        }
      })
      .catch((error) => {
        console.error("Unexpected fetch error:", error);
        this.redirectWithMessage("/", "Something went wrong. Please check your network or try again.");
      });
  }

  showLoader() {
    if (this.hasLoaderTarget) {
      this.loaderTarget.classList.remove("hidden");
      this.loaderTarget.classList.add("flex");
    }
  }

  stopPolling() {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = null;
    }
  }

  disconnect() {
    this.stopPolling();
  }

  redirectWithMessage(path, message) {
    alert(message);
    this.stopPolling();
    window.location.href = path;
  }
}
