# 개발 방식 (자동 검증 · AI 활용 · 이미지 출처)

## 개발 하네스 (Claude Code용 작업 환경)

이 프로젝트를 Claude Code로 수정할 때 실수를 줄이기 위한 규칙과 자동 점검입니다.

| 파일 | 역할 |
| --- | --- |
| `CLAUDE.md` | 프로젝트 규칙(구조, 번역, 접근성, 금지 사항, 명령). Claude가 매번 읽습니다 |
| `.claude/settings.json` | 허용/금지 명령, 훅 연결 (`.env` 읽기 금지, `docker compose down -v` 금지 등) |
| `.claude/hooks/protect_files.sh` | 비밀 파일·`schema.rb`·기존 마이그레이션 수정 차단 |
| `.claude/hooks/after_edit.sh` | 수정 직후 rubocop 자동 교정, locale/뷰 수정 시 번역 일관성 검사 |
| `.claude/skills/verify` | 완료 전 검증 절차(`bin/verify`) |
| `.claude/skills/add-translated-content` | 2개 언어(ko/en) 필드/문구 추가 절차 |
| `bin/verify` | rubocop → brakeman → 테스트 한 번에 실행 |
| `test/i18n_consistency_test.rb` | 번역 키 누락 · 변수 불일치 · 공개 뷰 한글 하드코딩 검출 |

훅은 `jq` 가 설치된 환경에서 동작합니다(macOS: `brew install jq`).

## AI の利用と検証 / AI 사용과 검증

### 使った部分 / 사용한 부분
- 実装の大半（モデル・コントローラ・ビュー・CSS・マイグレーション・Dockerfile・CI・ドキュメント）を Claude Code（Anthropic）と対話しながら作成。
- 画像（ブログのカバー）はプログラム（Pillow）で生成。ロゴは依頼者が用意した画像を最適化して使用。

### 検証方法 / 검증 방법
- **自動**: Minitest（`bin/rails test`）、RuboCop、Brakeman、bundler-audit（CI で毎回）。翻訳キー漏れと公開ビューへの韓国語直書きは `test/i18n_consistency_test.rb` が検出。
- **実機**: 本番イメージをビルドして起動し、`deploy/restore-test.sh`（バックアップ → ディスク消失 → 自動復元）と `deploy/measure-memory.sh`（メモリ）を実行。Lighthouse（モバイル）を測定。
- **人による確認**: 画面（モバイル 390px・PC）をブラウザで確認。
- **未検証**: S3 本番バケットでの復元、実際の VM でのデプロイ、英語の文言（草稿・要校閲）、NAVER 地図の実キー動作。
- **判断は自分で**: ADR に採用理由と代替案を書き、AI の提案を鵜呑みにしないようにした（例: Kamal を採用しない理由）。

## 사용한 외부 이미지·아이콘의 출처

Flaticon 무료 라이선스는 **저작자 표시가 필수**입니다. 개인정보 처리방침 페이지(`/ko/privacy`)의 "이미지 출처" 항목에 Flaticon 링크를 넣었습니다. 아이콘마다 저작자 이름을 함께 적어야 하므로 아래 표를 채우고, 해당 항목을 `Icon by 저작자 from Flaticon` 형태로 보완하세요.

| 파일 | 용도 | 저작자 | Flaticon 페이지 URL | 받은 날 | 라이선스 |
|---|---|---|---|---|---|
| `db/seed_images/category-cut.png` | 가격표 커트 아이콘 | 【TODO】 | 【TODO】 | 【TODO】 | Flaticon 무료(저작자 표시) |
| `db/seed_images/category-perm.png` | 가격표 파마 아이콘 | 【TODO】 | 【TODO】 | 【TODO】 | 〃 |
| `db/seed_images/category-makeup.png` | 가격표 화장 아이콘 | 【TODO】 | 【TODO】 | 【TODO】 | 〃 |
| `app/assets/images/cut.png` `perm.png` `hair.png` | 【TODO: 사용처】 | 【TODO】 | 【TODO】 | 【TODO】 | 〃 |

- 다운로드한 zip의 `license` 파일은 저장소 밖(개인 보관함)에 보관합니다.
- 유료(Premium)로 바꾸면 표시 의무가 달라질 수 있으니 그때 라이선스를 다시 확인합니다.
