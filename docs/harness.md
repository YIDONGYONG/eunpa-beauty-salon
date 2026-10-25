# 개발 하네스 (Claude Code용 작업 환경)

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
