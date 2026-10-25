# AI の利用と検証 / AI 사용과 검증

## 使った部分 / 사용한 부분
- 実装の大半（モデル・コントローラ・ビュー・CSS・マイグレーション・Dockerfile・CI・ドキュメント）を Claude Code（Anthropic）と対話しながら作成。
- 画像（ブログのカバー）はプログラム（Pillow）で生成。ロゴは依頼者が用意した画像を最適化して使用。

## 検証方法 / 검증 방법
- **自動**: Minitest（`bin/rails test`）、RuboCop、Brakeman、bundler-audit（CI で毎回）。翻訳キー漏れと公開ビューへの韓国語直書きは `test/i18n_consistency_test.rb` が検出。
- **実機**: 本番イメージをビルドして起動し、`deploy/restore-test.sh`（バックアップ → ディスク消失 → 自動復元）と `deploy/measure-memory.sh`（メモリ）を実行。Lighthouse（モバイル）を測定。
- **人による確認**: 画面（モバイル 390px・PC）をブラウザで確認。
- **未検証**: S3 本番バケットでの復元、実際の VM でのデプロイ、英語の文言（草稿・要校閲）、NAVER 地図の実キー動作。
- **判断は自分で**: ADR に採用理由と代替案を書き、AI の提案を鵜呑みにしないようにした（例: Kamal を採用しない理由）。
