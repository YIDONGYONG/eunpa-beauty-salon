import { Controller } from "@hotwired/stimulus"

// モバイルのハンバーガーメニュー。JS がオフならメニューはそのまま展開されて見えます。
export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    this.element.classList.add("nav-enhanced")
    this.close()
    this.onKeydown = (e) => { if (e.key === "Escape") this.close() }
    document.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
  }

  toggle() {
    this.element.classList.contains("nav-open") ? this.close() : this.open()
  }

  open() {
    this.element.classList.add("nav-open")
    this.update(true)
  }

  close() {
    this.element.classList.remove("nav-open")
    this.update(false)
  }

  update(expanded) {
    this.buttonTarget.setAttribute("aria-expanded", expanded)
    const label = this.buttonTarget.querySelector(".nav-toggle-label")
    if (label) label.textContent = expanded ? this.buttonTarget.dataset.closeLabel : this.buttonTarget.dataset.openLabel
  }
}
