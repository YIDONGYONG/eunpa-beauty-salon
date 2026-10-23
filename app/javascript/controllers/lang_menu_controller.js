import { Controller } from "@hotwired/stimulus"

// 言語選択リスト: 外側をクリックするか Esc で閉じます（JS がなくても <details> で動作）
export default class extends Controller {
  close() {
    this.element.removeAttribute("open")
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }
}
