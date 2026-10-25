# Pin npm packages by running ./bin/importmap

pin "application"
# 管理画面専用のモジュールは preload しない（公開ページで 500KB 以上の無駄な読み込みを避ける）
pin "admin", preload: false
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "trix", preload: false
pin "@rails/actiontext", to: "actiontext.esm.js", preload: false
pin "@rails/activestorage", to: "activestorage.esm.js", preload: false
