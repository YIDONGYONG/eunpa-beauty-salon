# 恩波美容室ホームページ — 作業ルール

街の美容室（40〜70代の女性のお客様）のホームページ。Rails 8.1 · Hotwire · SQLite（Solid Cache/Queue/Cable）· Litestream · Active Storage · Action Text · 純粋な CSS。
ユーザー（院長）はコードが分からないため、**管理画面は「韓国語・大きなボタン・1画面でのインライン編集」**が原則です。

## よく使うコマンド
- 起動: `docker compose up` → http://localhost:3001（3000番は別のプロジェクトが使うため使わない）。DB は SQLite のファイルなので、DB 用のコンテナはない
- 検証: `bin/verify`（rubocop + brakeman + テスト + 翻訳の漏れの検査）。作業の完了前に必ず実行する
- テストのみ: `bin/rails test` / 単一: `bin/rails test test/integration/admin_menu_flow_test.rb`
- シード: `bin/rails db:seed`（何回実行しても安全）

## 構造のルール
- 言語は `ko`（既定）`en` `ja` の3つ（ADR 0003、2026-11 に日本語を追加）。公開の URL は `/:locale/...`、管理画面は `/admin`（韓国語固定、locale なし）
- 公開画面の文言は `config/locales/*.yml` のみを使う（ビューに韓国語を直接書かない。3つのファイルでキーと `%{変数}` を同じにする）
- DB の翻訳する項目は `_ko/_en/_ja` の列と `Translatable` モジュール。空なら韓国語で代替する
- 並べ替えは `Positionable`、アップロードは `ImageValidation`（形式・サイズの制限）+ `ImageOptimization`（自動縮小）
- 住所・電話・座標・営業時間は `SiteSetting`（管理画面で変更）。コードに直書きしない
- 価格は整数（ウォン）で保存し、画面では `format_price`（`30,000원`）で表示する
- アップロード画像は**中身（マジックバイト）**で検証する（`ImageOptimization.real_image?`）。管理画面のフォームを再表示するときの添付のプレビューは `saved_attachment?` のみを使う（検証に失敗したときの 500 を防ぐ）
- 院長の写真は、`owner_profiles.show_photo_on_home` がオンのときだけ公開画面に表示する（既定はオフ）
- 管理画面のインライン編集は Turbo Stream（`Admin::MenuItemsController` を参照）。失敗したときは 422
- コード内の注釈は日本語で書く

## アクセシビリティ（高齢の方向け）のルール — CSS/ビューを直すときに守ること
- 本文は 18px 以上、見出しは 24px 以上、行間 1.8、ボタンの高さ 48px 以上
- 文字と背景のコントラストは WCAG AA（4.5:1）以上。色は `application.css` の先頭の `:root` の変数だけを使う
- 自動スライドや複雑なアニメーションは禁止。モバイル下部の固定バー（電話・道案内）は維持する
- モバイル（360px）で横スクロールが出ないことを確認する（韓国語のみ `word-break: keep-all`）

## やってはいけないこと
- `.env`、`config/master.key` の読み取り・変更・コミット（例は `.env.example`）
- すでに作ったマイグレーションの変更（新しいマイグレーションを追加する）
- サーバー・ドメインの値をコードに入れる（デプロイ用のファイルは `deploy/`・`Dockerfile`・`.github/workflows/deploy.yml` にあり、値は環境変数のプレースホルダーとして分ける）
- 削除機能を `destroy` で実装する（論理削除の `discard!` を使い、ゴミ箱から復元できるようにする — ADR 0006）
- すでに使っている Litestream の対象（primary DB）以外のファイルを「バックアップされる」と言う（画像は別途 rsync）
- 英語・日本語の翻訳を「最終版」と言う — 常に「草稿、専門的な校閲が必要」と報告する
- テストを削除したり弱めたりして通す

## ガードレール（自動）
- `.claude/hooks/protect_files.sh`: 秘密のファイル・schema.rb・既存のマイグレーションの変更をブロックする
- `.claude/hooks/after_edit.sh`: 編集した Ruby ファイルを rubocop で自動修正し、locale・ビューを編集したときは翻訳の一貫性のテストを実行する
- `test/i18n_consistency_test.rb`: 翻訳キーの漏れ、`%{変数}` の不一致、公開ビューへの韓国語の直書きを検出する
- スキル: `/verify`、`/add-translated-content`
