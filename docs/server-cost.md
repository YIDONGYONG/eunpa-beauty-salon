# 저비용 서버 가이드 (AWS Lightsail 서울 1GB)

> 절차 전체는 [runbook.md](runbook.md), 설계 이유는 [adr/](adr/). 요금·조건은 바뀔 수 있으므로 **가입 전에 AWS 요금 페이지(리전: 서울)에서 다시 확인**하세요.

## 요금 방어 체크리스트
1. 인스턴스: 서울(`ap-northeast-2`), 메모리 1GB 플랜. 월 정액이라 트래픽이 늘어도 서버가 자동으로 커지지 않습니다.
2. **데이터 전송량**: 플랜 포함량을 넘으면 서버에서 나가는 트래픽에만 GB당 요금이 붙습니다(들어오는 것은 무료). 서울 단가는 미확인.
3. **AWS 예산 알림** 월 $8 (알림만 보냅니다. 자동 차단은 아님).
4. 쓰지 않는 **고정 IP·스냅샷·서버**는 삭제(중지한 서버도 과금됩니다). 고정 IP는 서버에 연결해 둡니다.
5. 이미지는 업로드 때 WebP·긴 변 1600px로 줄어 전송량이 작습니다(ADR 0008).

## 메모리 1GB 대응 (프로젝트에 반영됨)
- Rails+Litestream 컨테이너(상한 700MB) + Caddy(상한 100MB), Puma 워커 0·스레드 3, Solid Queue는 Puma 안, YJIT 끔, jemalloc, 로그 레벨 `warn`
- 스왑 2GB·swappiness 10(`deploy/vm-setup.sh`)
- **VM에서 `docker build`를 하지 않습니다**(GitHub Actions에서 빌드, ADR 0004)
- 측정: `deploy/measure-memory.sh` (Rails 컨테이너 시작 직후 약 214MiB, 1,000요청 후 약 266MiB. Caddy는 별도)

## 방어 구조
- 방화벽: 22(가능하면 내 IP만)/80/443만 엽니다.
- DuckDNS 주소는 Cloudflare 뒤에 둘 수 없어 CDN·디도스 완화가 없습니다. 독자 도메인(연 약 $10)을 사면 Cloudflare를 앞에 둘 수 있습니다.
