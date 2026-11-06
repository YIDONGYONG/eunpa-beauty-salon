import { Controller } from "@hotwired/stimulus"

// 画像の読み込みに失敗したとき（言語切り替えのページ遷移で通信が中断された場合など）、1回だけ読み直す
export default class extends Controller {
  retry() {
    if (this.element.dataset.retried) return
    this.element.dataset.retried = "1"
    const src = this.element.currentSrc || this.element.src
    this.element.removeAttribute("src")
    setTimeout(() => { this.element.src = src }, 300)
  }

  connect() {
    // 描画前にすでに失敗していた画像（Turbo のキャッシュ表示など）も救う
    if (this.element.complete && this.element.naturalWidth === 0 && this.element.src) this.retry()
  }
}
