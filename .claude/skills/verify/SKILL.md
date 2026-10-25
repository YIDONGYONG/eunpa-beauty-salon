---
name: verify
description: 은파미용실 프로젝트의 변경 사항을 검증합니다(rubocop, brakeman, 테스트, 번역 누락 검사). 코드를 고친 뒤 "완료"라고 말하기 전에 사용하세요.
---

1. `bin/verify` 를 실행합니다. (로컬에 Ruby 3.4 가 없으면 `docker compose run --rm --no-deps -e RAILS_ENV=test web bin/rails test` 와 `... web bundle exec rubocop`)
2. 실패하면 원인을 고치고 다시 실행합니다. 테스트를 지우거나 약하게 바꿔서 통과시키지 않습니다.
3. 화면이 바뀐 작업이면 `docker compose up` 또는 `bin/rails server` 로 직접 열어 모바일(360px)과 데스크톱을 확인하고,
   영어(`/en`) 페이지도 가로 스크롤이 없는지 봅니다.
4. 결과를 "무엇을 바꿨고, 어떻게 확인했고, 확인하지 못한 것"으로 짧게 보고합니다.
