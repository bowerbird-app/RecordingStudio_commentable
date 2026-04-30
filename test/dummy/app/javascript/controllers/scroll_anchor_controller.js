import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["anchor"]
  static values = { hash: String, offset: Number, storageKey: String }

  connect() {
    this.boundScheduleScroll = this.scheduleScroll.bind(this)

    window.addEventListener("hashchange", this.boundScheduleScroll)
    window.addEventListener("pageshow", this.boundScheduleScroll)
    document.addEventListener("turbo:load", this.boundScheduleScroll)
    document.addEventListener("turbo:render", this.boundScheduleScroll)

    this.scheduleScroll()
  }

  disconnect() {
    window.removeEventListener("hashchange", this.boundScheduleScroll)
    window.removeEventListener("pageshow", this.boundScheduleScroll)
    document.removeEventListener("turbo:load", this.boundScheduleScroll)
    document.removeEventListener("turbo:render", this.boundScheduleScroll)
  }

  remember(event) {
    if (!(event.target instanceof HTMLFormElement)) return

    window.sessionStorage.setItem(this.storageKey(), this.hashValue)
  }

  scheduleScroll() {
    requestAnimationFrame(() => {
      requestAnimationFrame(() => this.scrollIfNeeded())
    })
  }

  scrollIfNeeded() {
    if (!this.hasAnchorTarget) return
    if (!this.shouldScroll()) return

    const scrollContainer = this.scrollContainer()
    const offset = this.hasOffsetValue ? this.offsetValue : 16

    if (scrollContainer === document.scrollingElement || scrollContainer === document.documentElement || scrollContainer === document.body) {
      const top = window.scrollY + this.anchorTarget.getBoundingClientRect().top - offset
      window.scrollTo({ top, behavior: "auto" })
    } else {
      const top = scrollContainer.scrollTop + this.anchorTarget.getBoundingClientRect().top - scrollContainer.getBoundingClientRect().top - offset
      scrollContainer.scrollTo({ top, behavior: "auto" })
    }

    window.sessionStorage.removeItem(this.storageKey())
  }

  shouldScroll() {
    return window.location.hash === `#${this.hashValue}` || window.sessionStorage.getItem(this.storageKey()) === this.hashValue
  }

  scrollContainer() {
    return this.anchorTarget.closest("main") || document.scrollingElement || document.documentElement
  }

  storageKey() {
    return this.hasStorageKeyValue ? this.storageKeyValue : "scroll-anchor"
  }
}