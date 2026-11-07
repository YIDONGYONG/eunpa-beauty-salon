source "https://rubygems.org"

# 最新の開発版 Rails を使う場合: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# Rails の新しいアセットパイプライン [https://github.com/rails/propshaft]
gem "propshaft"
# Active Record のデータベースに PostgreSQL を使う場合
gem "sqlite3", ">= 2.1"

# Rails 8 標準の Solid 3 種（Redis 不要）。キャッシュ / ジョブ / WebSocket を SQLite で動かす
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
# Puma Web サーバーを使います [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# ESM の import map で JavaScript を使います [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire の SPA のようなページ高速化 [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire の控えめな JavaScript フレームワーク [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# 本番で Action Cable を動かすのに Redis アダプターを使う場合
# gem "redis", ">= 4.0.1"

# Active Model の has_secure_password を使います [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows には zoneinfo ファイルがないため、tzinfo-data gem を同梱します。
gem "tzinfo-data", platforms: %i[ windows jruby ]

# キャッシュで起動時間を短縮します（config/boot.rb で必要）。
gem "bootsnap", require: false

# Active Storage のバリアント（画像変換）を使います [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# 管理者パスワードのハッシュ化（has_secure_password）
gem "bcrypt", "~> 3.1"

# 韓国語・英語の日付・数値・検証メッセージの翻訳
gem "rails-i18n", "~> 8.0"

group :development, :test do
  # .env ファイルの読み込み（Docker の外で実行するとき）
  gem "dotenv-rails"
  # デバッグの方法: https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # gem の既知の脆弱性を検査します（除外するものは config/bundler-audit.yml に書きます）。
  gem "bundler-audit", require: false

  # セキュリティ上の問題を静的解析で検出します [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Rails 標準（Omakase）の Ruby スタイル [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # 例外ページ上でコンソールを使います [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # システムテストを使います [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
