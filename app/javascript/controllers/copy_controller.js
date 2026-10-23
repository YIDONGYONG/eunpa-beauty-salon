import { Controller } from "@hotwired/stimulus"

// 住所コピーボタン
export default class extends Controller {
  static targets = ["status"]
  static values = { text: String, done: String, fail: String }

  async copy() {
    try {
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(this.textValue)
      } else {
        this.legacyCopy()
      }
      this.statusTarget.textContent = this.doneValue
    } catch (_error) {
      this.statusTarget.textContent = this.failValue
    }
  }

  legacyCopy() {
    const area = document.createElement("textarea")
    area.value = this.textValue
    area.setAttribute("readonly", "")
    area.style.position = "fixed"
    area.style.opacity = "0"
    document.body.appendChild(area)
    area.select()
    const ok = document.execCommand("copy")
    area.remove()
    if (!ok) throw new Error("copy failed")
  }
}
