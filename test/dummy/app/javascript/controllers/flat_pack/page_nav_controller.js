import { Controller } from "@hotwired/stimulus"

// Overrides FlatPack's default page nav back behavior in the dummy app.
// If browser history can't go back, fall back to the anchor action URL,
// then to the app root.
export default class extends Controller {
  back(event) {
    event.preventDefault()

    if (window.history.length > 1) {
      window.history.back()
      return
    }

    const fallbackLink = this.element.querySelector("a[aria-label='Back'], a[aria-label='Close']")
    if (fallbackLink?.href) {
      window.location.assign(fallbackLink.href)
      return
    }

    window.location.assign("/")
  }
}
