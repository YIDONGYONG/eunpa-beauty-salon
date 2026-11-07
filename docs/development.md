# 開発の進め方（自動検証・AI の活用・画像の出典）

## 開発ハーネス（Claude Code 用の作業環境）

このプロジェクトを Claude Code で修正するときに、ミスを減らすためのルールと自動チェックです。

| ファイル | 役割 |
| --- | --- |
| `CLAUDE.md` | プロジェクトのルール（構造、翻訳、アクセシビリティ、禁止事項、コマンド）。Claude が毎回読む（韓国語） |
| `.claude/settings.json` | 許可・禁止するコマンドと、フックの接続（`.env` の読み取り禁止、`docker compose down -v` の禁止など） |
| `.claude/hooks/protect_files.sh` | 秘密のファイル・`schema.rb`・既存のマイグレーションの変更をブロック |
| `.claude/hooks/after_edit.sh` | 編集の直後に RuboCop で自動修正し、ロケール・ビューを編集したときは翻訳の一貫性を検査 |
| `.claude/skills/verify` | 完了前の検証手順（`bin/verify`） |
| `.claude/skills/add-translated-content` | 多言語（ko/en/ja）の項目・文言を追加する手順 |
| `bin/verify` | RuboCop → Brakeman → テストを一度に実行 |
| `test/i18n_consistency_test.rb` | 翻訳キーの漏れ、変数の不一致、公開ビューへの韓国語の直書きを検出 |

フックは `jq` がインストールされた環境で動作します（macOS: `brew install jq`）。

## AI の利用と検証

### 使った部分
- 実装の大半（モデル・コントローラ・ビュー・CSS・マイグレーション・Dockerfile・CI・ドキュメント）を、Claude Code（Anthropic）と対話しながら作成した。
- 画像（ブログのカバー）はプログラム（Pillow）で生成した。ロゴは依頼者が用意した画像を最適化して使用している。

### 検証方法
- **自動**: Minitest（`bin/rails test`）、RuboCop、Brakeman、bundler-audit（CI で毎回）。翻訳キーの漏れと、公開ビューへの韓国語の直書きは、`test/i18n_consistency_test.rb` が検出する。
- **実機**: 本番イメージをビルドして起動し、`deploy/restore-test.sh`（バックアップ → ディスク消失 → 自動復元）と `deploy/measure-memory.sh`（メモリ）を実行した。Lighthouse（モバイル）を測定した。
- **人による確認**: 画面（モバイル 390px・PC）をブラウザで確認した。
- **未検証**: S3 の本番バケットでの復元、実際の VM でのデプロイ、英語・日本語の文言（草稿・要校閲）、NAVER 地図の実キーでの動作。
- **判断は自分で行う**: ADR に採用理由と代替案を書き、AI の提案を鵜呑みにしないようにした（例: Kamal を採用しない理由）。

## 使用した外部の画像・アイコンの出典

Flaticon の無料ライセンスでは、**作者のクレジット表示が必須**です。プライバシーポリシーのページ（`/ko/privacy` など）の「画像の出典」の項目に、Flaticon へのリンクを入れています。アイコンごとに作者名も併記する必要があるため、下の表を埋めたうえで、該当の項目を `Icon by 作者 from Flaticon` の形に補ってください。

| ファイル | 用途 | 作者 | Flaticon のページ URL | 入手日 | ライセンス |
|---|---|---|---|---|---|
| `db/seed_images/category-cut.png` | 料金表の「カット」のアイコン | 【TODO】 | 【TODO】 | 【TODO】 | Flaticon 無料（クレジット表示が必要） |
| `db/seed_images/category-perm.png` | 料金表の「パーマ」のアイコン | 【TODO】 | 【TODO】 | 【TODO】 | 同上 |
| `db/seed_images/category-makeup.png` | 料金表の「メイク」のアイコン | 【TODO】 | 【TODO】 | 【TODO】 | 同上 |
| `app/assets/images/cut.png` `perm.png` `hair.png` | 【TODO: 使用場所】 | 【TODO】 | 【TODO】 | 【TODO】 | 同上 |

- ダウンロードした zip の `license` ファイルは、リポジトリの外（個人の保管場所）に保管する。
- 有料（Premium）に切り替えると表示の義務が変わることがあるので、そのときにライセンスを再確認する。
