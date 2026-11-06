# 은파미용실 홈페이지

**경력 40년 넘는 원장님이 직접 해 주는 동네 미용실. 손님은 방문 전에 가격과 위치를 확인하고, 원장님은 코딩 없이 직접 고칩니다.**

| 모바일 홈 | 데스크톱 홈 |
|---|---|
| ![모바일 홈](docs/images/home-mobile.png) | ![데스크톱 홈](docs/images/home-desktop.png) |

로컬 실행: http://localhost:3001/ko (아직 서버에 배포하지 않았습니다)

## 무엇을 해결하는가

경북 상주 중앙시장 근처 미용실은 검색하면 **주소밖에 나오지 않아** 처음 온 손님이 판단할 수 없었습니다.

- **손님(40~70대 여성):** 가격표·경력·길 안내를 확인하고 전화한다. 큰 글씨(18px+), 큰 버튼(48px+), 명도 대비 4.5:1, 한국어·영어·일본어.
- **원장님(비개발자):** 한국어 관리자 화면에서 한 화면 인라인 편집으로 가격·블로그·영업시간을 직접 고친다.
- **의도적으로 만들지 않은 것:** 자체 예약·후기·쿠폰. 개인정보 부담을 피하고 네이버 예약·플레이스를 연결합니다.

## 기술 선택

Ruby 3.4 · Rails 8.1 (Hotwire) · 순수 CSS · SQLite + Litestream · Docker · GitHub Actions

| 선택 | 이유 |
|---|---|
| Rails + Hotwire (SPA 아님) | 페이지가 적고 SEO가 중요, 관리자 인라인 편집에 Turbo Stream이 적합 |
| SQLite (PostgreSQL 아님) | 쓰는 사람이 원장님 1명, 1GB 서버에서 운영이 단순. Redis도 없이 Solid Queue/Cache/Cable |
| Litestream → S3 | DB를 연속 복제(손실 최대 약 10초). 복원은 컨테이너 시작 때 자동 |

나머지 선택(삭제 방식, 이미지, 언어 수 등)과 대안은 [docs/decisions.md](docs/decisions.md)에 있습니다.

## 현재 상태 (솔직하게)

- **한 것:** 공개 페이지, 관리자 화면, 3개 언어, 테스트 95건 · RuboCop · Brakeman · bundler-audit (CI), 로컬 Docker에서 복원 테스트 성공, 메모리 측정(1GB 서버 기준 약 214~266MiB)
- **아직 못 한 것:** 실제 서버 배포, 실제 S3 버킷에서의 복원 테스트, 배포 후 방문·전화 수 측정
- **주의:** 영어·일본어 번역은 **초안**이라 공개 전 전문 검수가 필요합니다. Litestream은 DB만 백업하고 업로드 이미지는 별도 동기화가 필요합니다(미설정).

## 실행

Docker Desktop만 있으면 됩니다.

```bash
cp .env.example .env          # 관리자 계정 등을 직접 설정 (.env는 저장소에 올리지 않음)
docker compose up -d --build  # DB 생성·마이그레이션·시드 자동 실행
```

손님 화면 http://localhost:3001/ko · 관리자 http://localhost:3001/admin · 전체 검사 `bin/verify`

## 문서

| 문서 | 내용 |
|---|---|
| [docs/planning.md](docs/planning.md) | 기획 기록: 과제, 사용자, 경쟁·가격 조사, 사업 관점(가설 → 시책 → 계측 → 개선) |
| [docs/decisions.md](docs/decisions.md) | 기술 선택 기록 (ADR 11건) |
| [docs/operations.md](docs/operations.md) | 장애 대응 · 복원 테스트 · 메모리 측정 · 설정 절차 · 서버 비용 |
| [docs/development.md](docs/development.md) · [CLAUDE.md](CLAUDE.md) | 자동 검증 · AI 활용 기록 · 작업 규칙 |

日本語版: [README.ja.md](README.ja.md)
