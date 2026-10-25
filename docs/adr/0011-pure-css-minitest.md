# ADR 0011: CSS は純粋な CSS、テストは Minitest / CSS는 순수 CSS, 테스트는 Minitest

状態 / 상태: 採用 / 채택 (2026-10)

## 決定 / 결정
- **CSS**: フレームワーク無し（`app/assets/stylesheets/application.css`、色は `:root` の変数のみ）。ページ数が4つで、アクセシビリティ（文字 18px 以上・コントラスト・ボタン 48px 以上）を数値で一元管理したい。Tailwind はビルド工程と依存が増える。
- **テスト**: Minitest（Rails 標準、追加 gem なし）。統合テスト中心（管理画面の操作・公開ページ・翻訳の一貫性）。RSpec は DSL の学習コストと依存が増える一方、この規模では利点が小さい。

## 守るルール
`test/i18n_consistency_test.rb`: 翻訳キー漏れ、`%{変数}` の不一致、公開ビューへの韓国語の直書きを検出する。
