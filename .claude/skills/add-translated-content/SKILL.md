---
name: add-translated-content
description: 4개 언어(ko/en/vi/ja)로 입력하는 새 DB 필드나 고정 문구를 추가할 때의 절차입니다.
---

## 고정 문구 (버튼, 안내 문구)
1. `config/locales/ko.yml` 에 키 추가 → `en.yml`, `vi.yml`, `ja.yml` 에 **같은 키와 같은 `%{변수}`** 로 추가
2. 뷰에서는 `t("...")` 만 사용합니다(한글을 직접 쓰지 않습니다 — 테스트가 잡아냅니다).
3. 번역은 "초안"입니다. 최종 검수가 필요하다는 점을 보고에 남깁니다.

## DB 필드 (관리자에서 입력하는 내용)
1. 마이그레이션: `필드_ko`(필수 아님/있음), `필드_en`, `필드_vi`, `필드_ja` 4개 컬럼
2. 모델: `include Translatable` + `translates :필드` (현재 언어 값, 비면 한국어로 대체)
3. 관리자 폼: `render "admin/shared/translated_field", f: f, attr: :필드, label: "…"`
4. 컨트롤러 strong parameters에 4개 컬럼 모두 허용
5. 공개 화면: `record.필드` 사용. 한국어로 대체되는 경우 `translation_fallback_notice` 로 안내
6. 시드(`db/seeds.rb`)에 4개 언어 예시 추가, 테스트(`test/models/translatable_test.rb` 참고) 추가
