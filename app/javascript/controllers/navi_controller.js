import { Controller } from "@hotwired/stimulus"

// 「NAVER ナビで道案内」: まず NAVER 地図アプリ（URLスキーム）を開こうとし、
// アプリが開かなければ（画面が変わらなければ）NAVER 地図の Web へ移動します。
export default class extends Controller {
  static values = { appUrl: String, webUrl: String, trackUrl: String }

  go(event) {
    event.preventDefault()
    this.track()
    const isMobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent)

    if (!isMobile || !this.appUrlValue) {
      window.open(this.webUrlValue, "_blank", "noopener")
      return
    }

    let opened = false
    const markOpened = () => { opened = true }
    document.addEventListener("visibilitychange", markOpened, { once: true })
    window.addEventListener("pagehide", markOpened, { once: true })
    window.addEventListener("blur", markOpened, { once: true })

    window.location.href = this.appUrlValue

    setTimeout(() => {
      document.removeEventListener("visibilitychange", markOpened)
      window.removeEventListener("pagehide", markOpened)
      window.removeEventListener("blur", markOpened)
      if (!opened) window.location.href = this.webUrlValue
    }, 1800)
  }

  // 道案内ボタンのクリック数（件数だけ。個人を特定する情報は送らない）
  track() {
    if (!this.trackUrlValue || !navigator.sendBeacon) return
    const body = new FormData()
    body.append("kind", "directions")
    body.append("lang", document.documentElement.lang)
    body.append("page", "location")
    navigator.sendBeacon(this.trackUrlValue, body)
  }
}
