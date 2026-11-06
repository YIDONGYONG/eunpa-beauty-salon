# 운영 Runbook (면접용 요약)

대상: AWS Lightsail 서울 1GB 1대(Rails+Litestream / Caddy 컨테이너 2개) + DuckDNS. **아직 서버를 만들지 않아** 아래 복원·메모리 수치는 로컬 Docker에서 측정한 값입니다. 설정·일상 운영·검색 대책 상세: [ops-setup.md](ops-setup.md)

## 장애 대응 3가지

**1. 사이트가 열리지 않을 때**
1. `curl -i https://eunpabeautysalon.duckdns.org/up` → 이름이 안 풀리면 DuckDNS에서 IP 확인
2. VM에서 `docker ps`, `docker logs --tail 100 eunpa-web-1`
3. `cd /opt/eunpa && docker compose restart`. 안 되면 `.env`의 `IMAGE`를 이전 커밋 SHA로 바꿔 `docker compose up -d` (롤백)

**2. DB가 깨졌거나 디스크가 사라졌을 때 (복원)**
1. `docker compose stop` → 깨진 `/var/lib/eunpa/production.sqlite3*`를 다른 폴더로 옮김
2. `docker compose up -d` → `bin/docker-entrypoint`가 **S3 복제본에서 자동 복원** 후 기동 (손실은 최대 약 10초분)
3. 이미지는 Litestream 대상이 아니므로 `aws s3 sync s3://BUCKET/eunpa/files /var/lib/eunpa/files`로 복구 (일일 동기화 cron은 **미설정**)
4. 특정 시점으로: `litestream restore -timestamp ...` (보관 72시간)

**3. 실수로 지웠을 때 (블로그·메뉴·이벤트)**
관리자 화면 「휴지통」→「되돌리기」. 논리 삭제라 백업 복원이 필요 없습니다 (ADR 0006).

## 복원 테스트 기록

`deploy/restore-test.sh`: 운영 이미지로 실행, 복제 대상은 로컬 `file://` (S3와 설정·절차 동일, URL만 다름).

| 날짜 | 절차 | 결과 |
|---|---|---|
| 2026-10-23 | 첫 기동 → 표시 데이터 저장 → 15초 대기 → 데이터 볼륨 삭제 → 재기동 | **성공**: 표시 데이터와 글 6건 자동 복원 |

> **미실시:** 실제 S3 버킷 테스트(버킷·IAM 사용자 미생성). 만든 뒤 `LITESTREAM_REPLICA_URL=s3://...`로 같은 절차를 실행하고 이 표에 추가합니다.

## 메모리 측정 (1GB VM 가정)

`deploy/measure-memory.sh` — 컨테이너 메모리 상한 700MB로 실행.

| 상태 | 메모리 사용량 |
|---|---|
| 기동 직후 | 약 214 MiB (30%) |
| 1,000 요청 후 | 약 266 MiB (38%) |

Litestream 프로세스는 별도로 +20~40MB 정도로 추정합니다 (운영 설정에서 재측정 필요).
