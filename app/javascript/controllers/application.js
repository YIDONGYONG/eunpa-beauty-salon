import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Stimulus の開発時の設定
application.debug = false
window.Stimulus   = application

export { application }
