import { Controller } from "@hotwired/stimulus"

// 「電話」「道案内」などのクリック数を数える（件数だけ。個人を特定する情報は送らない）
export default class extends Controller {
  static values = { kind: String, url: String }

  send() {
    const body = new FormData()
    body.append("kind", this.kindValue)
    body.append("lang", document.documentElement.lang)
    body.append("page", location.pathname.split("/")[2] || "home")
    // sendBeacon はページ移動（tel: やアプリ起動）の直前でも送信が途切れない
    if (navigator.sendBeacon) navigator.sendBeacon(this.urlValue, body)
  }
}
