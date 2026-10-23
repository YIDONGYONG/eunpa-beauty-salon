# 저비용 서버(Google Cloud Compute Engine e2-micro) 운영 가이드

> 서버·도메인은 아직 미정이므로 **배포 파일은 만들지 않았습니다.** 이 문서는 요금 방어 체크리스트와
> 프로젝트에 이미 반영된 절약 설정을 정리한 것입니다. 정책/무료 한도는 바뀔 수 있으니 생성 시 공식 문서를 다시 확인하세요.

## 요금 방어 체크리스트

1. **서버 생성 시 세 가지를 확인합니다.**
   - 리전: 무료 한도 대상 미국 리전 중 하나 (예: `us-central1`)
   - 머신 타입: `e2-micro`
   - 디스크: 표준 영구 디스크(Standard persistent disk) 30GB 이하
2. **예산 알림 설정**: Google Cloud 콘솔 → 결제 → 예산 및 알림 → 월 $1~5 로 설정(초과 전 이메일).
3. **사용하지 않는 자원 삭제**: 쓰지 않는 고정 IP, 디스크, 스냅샷은 바로 삭제합니다(예약만 해 두어도 과금될 수 있습니다).
4. **이미지 자동 축소** — ✅ 프로젝트에 반영됨
   - 관리자가 올리는 대표 이미지·원장님 사진·매장 사진은 저장 전에 긴 변 1600px 이하, 품질 82로 줄입니다.
   - 값 변경: 환경변수 `IMAGE_MAX_EDGE`, `IMAGE_QUALITY`. (코드: `app/models/concerns/image_optimization.rb`)
   - 화면에 보여 줄 때도 크기에 맞는 변형본(variant)을 만들어 사용합니다(libvips 필요, Dockerfile에 포함).
   - 블로그 본문 에디터에 직접 넣는 사진은 대상이 아닙니다. 되도록 대표 이미지 기능을 쓰거나 작은 사진을 올려 주세요.
5. **메모리 1GB 대응**
   - 프로젝트 기본값: Puma 워커 0(단일 프로세스, 스레드 3), YJIT 끔, 운영 로그 레벨 `warn`, 캐시 `memory_store`.
   - 서버에 설정할 환경변수 권장값:
     ```
     RAILS_MAX_THREADS=2
     WEB_CONCURRENCY=0
     RAILS_YJIT=false
     MALLOC_ARENA_MAX=2
     ```
   - **스왑(2GB) 설정** (서버에서 한 번만):
     ```bash
     sudo fallocate -l 2G /swapfile
     sudo chmod 600 /swapfile
     sudo mkswap /swapfile
     sudo swapon /swapfile
     echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
     echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swap.conf
     ```
   - PostgreSQL을 같은 서버에 둘 경우 `shared_buffers = 128MB`, `max_connections = 20` 정도로 낮추는 것을 권장합니다.

## 참고
- 외부로 나가는 네트워크 트래픽(egress)에도 무료 한도가 있습니다. 사진을 줄여 두면 트래픽도 함께 줄어듭니다.
- Docker로 운영할 경우에도 메모리가 부족하면 빌드 중 서버가 멈출 수 있으니, 이미지는 로컬/CI에서 빌드해 올리는 방식을 권장합니다.
