# 은파미용실 홈페이지 — 작업 규칙

동네 미용실(40~70대 여성 고객) 홈페이지. Rails 8.1 · Hotwire · SQLite(Solid Cache/Queue/Cable) · Litestream · Active Storage · Action Text · 순수 CSS.
사용자(원장님)가 코딩을 모르므로 **관리자 화면은 한국어·큰 버튼·한 화면 인라인 편집**이 원칙입니다.

## 자주 쓰는 명령
- 실행: `docker compose up` → http://localhost:3001 (3000번은 다른 프로젝트가 사용하므로 쓰지 않음). DB는 SQLite 파일이라 별도 DB 컨테이너가 없음
- 검증: `bin/verify` (rubocop + brakeman + 테스트 + 번역 누락 검사). 작업 완료 전에 반드시 실행
- 테스트만: `bin/rails test` / 단일: `bin/rails test test/integration/admin_menu_flow_test.rb`
- 시드: `bin/rails db:seed` (여러 번 실행해도 안전)

## 구조 규칙
- 언어는 `ko`(기본) `en` 두 개뿐 (ADR 0003). 공개 주소는 `/:locale/...`, 관리자는 `/admin`(한국어 고정, locale 없음)
- 공개 화면 문구는 `config/locales/*.yml` 만 사용 (뷰에 한글 직접 입력 금지, 2개 파일 키·`%{변수}` 동일)
- DB 번역 필드는 `_ko/_en` 컬럼 + `Translatable` 모듈. 비어 있으면 한국어로 대체
- 순서 변경은 `Positionable`, 업로드는 `ImageValidation`(형식·크기 제한) + `ImageOptimization`(자동 축소)
- 주소·전화·좌표·영업시간은 `SiteSetting`(관리자 수정). 코드에 하드코딩 금지
- 가격은 정수(원) 저장, 화면은 `format_price` (`30,000원`)
- 업로드 이미지는 **내용(매직 바이트)** 으로 검증(`ImageOptimization.real_image?`). 관리자 폼 재표시에서 첨부 미리보기는 `saved_attachment?` 로만 (검증 실패 시 500 방지)
- 원장님 사진은 `owner_profiles.show_photo_on_home` 가 켜졌을 때만 공개 화면에 표시(기본 꺼짐)
- 관리자 인라인 편집은 Turbo Stream (`Admin::MenuItemsController` 참고). 실패 시 422

## 접근성(시니어) 규칙 — CSS/뷰를 고칠 때 지킬 것
- 본문 18px 이상, 제목 24px 이상, 줄 간격 1.8, 버튼 높이 48px 이상
- 글씨/배경 대비 WCAG AA(4.5:1) 이상. 색은 `application.css` 상단 `:root` 변수만 사용
- 자동 슬라이드·복잡한 애니메이션 금지. 모바일 하단 고정 바(전화/길 찾기) 유지
- 모바일(360px)에서 가로 스크롤이 생기지 않는지 확인 (한국어만 `word-break: keep-all`)

## 하지 말 것
- `.env`, `config/master.key` 읽기/수정/커밋 (예시는 `.env.example`)
- 이미 만든 마이그레이션 수정 (새 마이그레이션 추가)
- 서버·도메인 값을 코드에 넣기 (배포 파일은 `deploy/`·`Dockerfile`·`.github/workflows/deploy.yml`에 있고, 값은 환경변수 플레이스홀더로만 분리)
- 삭제 기능을 `destroy` 로 구현 (논리 삭제 `discard!` 사용, 휴지통에서 복구 — ADR 0006)
- 이미 쓰고 있는 Litestream 대상(primary DB) 외 파일을 "백업된다"고 말하기 (이미지는 별도 rsync)
- 영어 번역을 "최종"이라고 말하기 — 항상 "초안, 전문 검수 필요"로 보고
- 테스트를 삭제하거나 약화해서 통과시키기

## 가드레일(자동)
- `.claude/hooks/protect_files.sh`: 비밀 파일/schema.rb/기존 마이그레이션 수정 차단
- `.claude/hooks/after_edit.sh`: 수정한 Ruby 파일 rubocop 자동 교정, locale/뷰 수정 시 번역 일관성 테스트
- `test/i18n_consistency_test.rb`: 번역 키 누락, `%{변수}` 불일치, 공개 뷰의 한글 하드코딩 검출
- 스킬: `/verify`, `/add-translated-content`
