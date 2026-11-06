import { Controller } from "@hotwired/stimulus"

// 下部タブバー: ホームで「料金表」までスクロールした（または #prices を開いた）とき、
// 「ホーム」ではなく「料金表」タブをうすいピンクで強調する。
export default class extends Controller {
  static targets = [ "home", "prices" ]

  connect() {
    this.section = document.getElementById("prices")
    if (!this.hasHomeTarget || !this.hasPricesTarget || !this.section) return

    this.onScroll = () => this.update() // 計算は軽いので、間引かずその場で行う
    window.addEventListener("scroll", this.onScroll, { passive: true })
    window.addEventListener("hashchange", this.onScroll)
    this.update()
  }

  disconnect() {
    if (!this.onScroll) return
    window.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("hashchange", this.onScroll)
  }

  update() {
    const rect = this.section.getBoundingClientRect()
    const onPrices = rect.top < window.innerHeight * 0.5 && rect.bottom > window.innerHeight * 0.3
    this.pricesTarget.toggleAttribute("aria-current", onPrices)
    if (onPrices) this.pricesTarget.setAttribute("aria-current", "page")
    this.homeTarget.toggleAttribute("aria-current", !onPrices)
    if (!onPrices) this.homeTarget.setAttribute("aria-current", "page")
  }
}
