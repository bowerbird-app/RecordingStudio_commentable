import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    rootMargin: { type: String, default: "200px 0px" }
  }

  connect() {
    if (!this.hasUrlValue) return

    this.hasLoaded = false
    this.observer = new IntersectionObserver(
      (entries) => this.handleIntersect(entries),
      { rootMargin: this.rootMarginValue }
    )

    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }

  handleIntersect(entries) {
    if (this.hasLoaded) return

    const entry = entries.find((current) => current.isIntersecting)
    if (!entry) return

    this.hasLoaded = true
    this.element.src = this.urlValue
    this.observer?.disconnect()
  }
}