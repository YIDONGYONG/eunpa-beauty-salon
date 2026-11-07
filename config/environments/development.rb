require "active_support/core_ext/integer/time"

Rails.application.configure do
  # 一時的な公開リンク（Cloudflare クイックトンネル）で見せるときに、そのホスト名を許可する。
  config.hosts << ".trycloudflare.com"

  # ここでの設定は config/application.rb の設定より優先されます。

  # サーバーを再起動しなくても、コードの変更がすぐ反映されます。
  config.enable_reloading = true

  # 起動時にコードを先読みしません。
  config.eager_load = false

  # 詳細なエラーレポートを表示します。
  config.consider_all_requests_local = true

  # サーバーのタイミング情報（Server-Timing）を有効にします。
  config.server_timing = true

  # Action Controller のキャッシュの有効・無効を切り替えます（既定は無効）。
  # rails dev:cache で切り替えられます。
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.public_file_server.headers = { "cache-control" => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false
  end

  # キャッシュを使いたくない場合は :null_store にします。
  config.cache_store = :memory_store

  # アップロードされたファイルをローカルのファイルシステムに保存します（選択肢は config/storage.yml を参照）。
  config.active_storage.service = :local

  # メールが送れなくても気にしません。
  config.action_mailer.raise_delivery_errors = false

  # テンプレートの変更がすぐ反映されます。
  config.action_mailer.perform_caching = false

  # メールのテンプレートで作られるリンクのホストを localhost にします。
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  # 非推奨の警告を Rails のログに出します。
  config.active_support.deprecation = :log

  # 未実行のマイグレーションがあれば、ページの表示時にエラーにします。
  config.active_record.migration_error = :page_load

  # データベースへの問い合わせを起こしたコードを、ログで強調表示します。
  config.active_record.verbose_query_logs = true

  # ログの SQL に、実行時の情報をコメントとして付けます。
  config.active_record.query_log_tags_enabled = true

  # バックグラウンドジョブを登録したコードを、ログで強調表示します。
  config.active_job.verbose_enqueue_logs = true

  # リダイレクトを起こしたコードを、ログで強調表示します。
  config.action_dispatch.verbose_redirect_logs = true

  # アセットへのリクエストのログは出しません。
  config.assets.quiet = true

  # 翻訳が見つからないときはエラーにします。
  # config.i18n.raise_on_missing_translations = true

  # 表示したビューにファイル名の注釈を付けます。
  config.action_view.annotate_rendered_view_with_filenames = true

  # どのオリジンからでも Action Cable に接続させたい場合は、コメントを外します。
  # config.action_cable.disable_request_forgery_protection = true

  # before_action の only/except に存在しないアクションを指定したら、エラーにします。
  config.action_controller.raise_on_missing_callback_actions = true

  # `bin/rails generate` で作られたファイルに、RuboCop の自動修正を適用します。
  # config.generators.apply_rubocop_autocorrect_after_generate!
end
