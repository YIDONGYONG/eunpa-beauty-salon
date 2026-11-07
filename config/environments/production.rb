require "active_support/core_ext/integer/time"

Rails.application.configure do
  # ここでの設定は config/application.rb の設定より優先されます。

  # リクエストごとのコード再読み込みは行いません。
  config.enable_reloading = false

  # 起動時にコードを先読みして、性能とメモリ効率を上げます（Rake タスクでは無視されます）。
  config.eager_load = true

  # 詳細なエラーレポートは無効にします。
  config.consider_all_requests_local = false

  # ビューのフラグメントキャッシュを有効にします。
  config.action_controller.perform_caching = true

  # アセットはすべてダイジェスト付きなので、有効期限を遠い将来にしてキャッシュします。
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # 画像・CSS・JavaScript をアセット用サーバーから配信する場合の設定です。
  # config.asset_host = "http://assets.example.com"

  # アップロードされたファイルをローカルのファイルシステムに保存します（選択肢は config/storage.yml を参照）。
  config.active_storage.service = :local

  # アプリへのアクセスはすべて、SSL を終端するリバースプロキシ（Caddy）経由であるものとします。
  config.assume_ssl = ENV.fetch("FORCE_SSL", "true") == "true"

  # アクセスをすべて SSL にし、Strict-Transport-Security と secure Cookie を使います。
  config.force_ssl = ENV.fetch("FORCE_SSL", "true") == "true"

  # 標準のヘルスチェック（/up）は、http から https へのリダイレクトの対象外にします。
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # リクエスト ID をログのタグにして、標準出力へログを出します。
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # "debug" にすると全てを記録します（個人を特定できる情報を含む可能性があるので注意）。
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "warn")

  # ヘルスチェックのログでログが埋まらないようにします。
  config.silence_healthcheck_path = "/up"

  # 非推奨の警告はログに出しません。
  config.active_support.report_deprecations = false

  # 既定のプロセス内メモリキャッシュを、永続的な方式（Solid Cache）に置き換えます。
  config.cache_store = :solid_cache_store

  # Active Job の既定の（永続しない）キューを、永続的な方式（Solid Queue）に置き換えます。
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # 不正なメールアドレスは無視し、メール送信のエラーは発生させません。
  # 送信エラーを発生させたい場合は true にして、メールサーバーの設定を行います。
  # config.action_mailer.raise_delivery_errors = false

  # メールのテンプレートで作られるリンクのホスト名を設定します。
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "example.com") }

  # 送信用の SMTP サーバーを指定します。認証情報は bin/rails credentials:edit で smtp/* に追加してください。
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password: Rails.application.credentials.dig(:smtp, :password),
  #   address: "smtp.example.com",
  #   port: 587,
  #   authentication: :plain
  # }

  # I18n のロケール代替を有効にします（翻訳が見つからないときは
  # I18n.default_locale の翻訳で代替します）。
  config.i18n.fallbacks = true

  # マイグレーションの後に schema を書き出しません。
  config.active_record.dump_schema_after_migration = false

  # 本番では inspect の出力に :id だけを使います。
  config.active_record.attributes_for_inspect = [ :id ]

  # 追加のセキュリティヘッダ（HSTS は force_ssl が付けます）
  config.action_dispatch.default_headers.merge!(
    "Referrer-Policy" => "strict-origin-when-cross-origin",
    "Permissions-Policy" => "camera=(), microphone=(), geolocation=()",
    "X-Content-Type-Options" => "nosniff"
  )

  # DNS リバインディングなど、Host ヘッダーを使った攻撃への保護を有効にします。
  # APP_HOST（例: "example.com,www.example.com"）が設定されていれば、そのホスト名だけを許可します。
  # ドメインが決まる前は未設定のまま（すべて許可）で動きます。
  if ENV["APP_HOST"].present?
    config.hosts = ENV["APP_HOST"].split(",").map(&:strip)
  end
  # ヘルスチェック（/up）はホスト名に関係なく許可します（監視サービス・Docker 用）。
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # ---- メール（例外通知用。SMTP_ADDRESS が設定されたときだけ有効）----
  if ENV["SMTP_ADDRESS"].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV["SMTP_ADDRESS"], port: ENV.fetch("SMTP_PORT", 587).to_i,
      user_name: ENV["SMTP_USER"], password: ENV["SMTP_PASSWORD"],
      authentication: :plain, enable_starttls_auto: true
    }
  else
    config.action_mailer.delivery_method = :test
  end
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "localhost").split(",").first }
end
