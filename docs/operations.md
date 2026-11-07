# 운영 (장애 대응 · 설정 · 비용)

대상: AWS Lightsail 서울 1GB 1대(Rails+Litestream / Caddy 컨테이너 2개) + DuckDNS. **아직 서버를 만들지 않아** 아래 복원·메모리 수치는 로컬 Docker에서 측정한 값입니다. 설정·일상 운영·검색 대책·비용은 아래 부록.

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

---

# 부록 A. 설정과 일상 운영


対象: AWS Lightsail ソウル 1GB 1台（コンテナ2つ: Rails+Litestream / Caddy）+ DuckDNS の無料アドレス。まだサーバーを作っていないため、値は `deploy/env.production.example` のプレースホルダー。

### 1. 最初のセットアップ（1回だけ）/ 최초 설정 — AWS Lightsail ソウル 1GB + DuckDNS

> 用語: **VM/サーバー** = 24時間動くインターネット上のパソコン。**IP** = サーバーの住所の番号。**DNS** = 名前（eunpabeautysalon.duckdns.org）から IP を引く電話帳。**HTTPS** = 通信を暗号化する鍵マーク。**ファイアウォール** = 出入口の鍵（どのポートを開けるか）。

1. **料金の確認（作成前）**: Lightsail の料金ページでリージョンを「ソウル」にして **IPv4 付きの 1GB プラン（$7）**を選ぶ（IPv6 専用の $5 は不可。公式料金ページで確認済み、ソウルの最終料金と消費税は契約画面で確認）。AWS の請求 → 予算で **月 $10 のアラート**を作る（超過前にメール。自動停止ではない）。
2. **Lightsail でインスタンスを作成**: リージョン `ap-northeast-2`（ソウル）、OS は Ubuntu 24.04 LTS、プランは 1GB（メモリ 1GB）。
3. **静的 IP を作ってインスタンスにアタッチ**（IP が再起動で変わらないようにする。**アタッチしたままにする**。未使用の静的 IP は課金される）。
4. **ファイアウォール（Lightsail の「ネットワーキング」タブ）**: 開けるのは **22（SSH。可能なら自分の IP のみ）/ 80 / 443** だけ。それ以外は閉じる。
5. **DuckDNS**: https://www.duckdns.org でログイン → サブドメイン `eunpabeautysalon` を作り、IP 欄に **手順3の静的 IP** を入れる（静的 IP なので更新作業は不要）。
6. サーバーに SSH → `sudo deploy/vm-setup.sh`（スワップ 2GB、Docker、`/var/lib/eunpa`）。
7. **バックアップ用 S3 バケット（ソウル）**を作り、**そのバケットだけ**に権限を絞った IAM ユーザーのアクセスキーを発行（AWS ルートのキーは使わない）。
8. `/opt/eunpa/` に `deploy/compose.production.yml` `deploy/Caddyfile` と `.env`（`deploy/env.production.example` をコピーして値を入れる）を置く。`SECRET_KEY_BASE` は `bin/rails secret`。
9. `docker compose -f compose.production.yml up -d` → Caddy が自動で HTTPS 証明書（Let's Encrypt）を取得。`https://eunpabeautysalon.duckdns.org/up` が 200 なら成功。管理者作成後は `.env` を `RUN_SEED=false` に。
10. GitHub の Variables に `DEPLOY_ENABLED=true`、Secrets に `VM_HOST` `VM_USER` `VM_SSH_KEY`（配備専用の SSH 鍵）。

> ⚠️ **DuckDNS は自分のドメインではないため、Cloudflare（CDN・DDoS 緩和）を前に置けません。** 代わりに: ファイアウォールで 80/443 以外を閉じる、Caddy が HTTPS を担当、コンテナのメモリ上限（700MB）、請求アラート。大きな攻撃は防げないので、サイトが止まっても **NAVER プレイス（地図）の情報は影響を受けない**ようにしておく。将来、独自ドメイン（年 約 $10）を買えば Cloudflare を前に置ける。

### 2. 日々の運用 / 일상 운영

| やること | 方法 |
|---|---|
| デプロイ | `main` に push → GitHub Actions がテスト → イメージ作成 → VM で pull（自動） |
| ログ | `docker logs -f eunpa-web-1`（json-file 10MB×3 で自動ローテーション） |
| メモリ確認 | `docker stats --no-stream`（目安: 300MB 前後。700MB 上限の 70% 超えで調査） |
| 稼働監視 | UptimeRobot（無料）で `https://eunpabeautysalon.duckdns.org/up` を 5 分間隔。落ちたらメール |
| エラー通知 | `.env` に `ERROR_NOTIFY_EMAIL` と SMTP を設定（ADR 0009） |
| 画像のバックアップ | `/var/lib/eunpa/files` を日次で S3 へ: `aws s3 sync /var/lib/eunpa/files s3://BUCKET/eunpa/files`（cron。AWS CLI が必要）。**Litestream は画像を複製しない** |
| 予算 | 月 $10 のアラート。想定は月 $7（＋消費税） |

#### パッチ担当と周期 / 패치 담당·주기
- 担当: 開発者（このリポジトリの管理者）。院長は管理画面のみ。
- 週1回: Dependabot の PR を確認しマージ → 自動デプロイ。月1回: `bin/bundler-audit`、`bin/brakeman`（CI でも毎回実行）。Rails / Ruby のセキュリティ更新は **1週間以内**。
- Ruby のサポート期限を確認（`.ruby-version` と Dockerfile の `RUBY_VERSION`）。

### 3. 監視と請求 / 모니터링과 청구

- UptimeRobot（無料）で `https://eunpabeautysalon.duckdns.org/up` を 5 分間隔で監視。落ちたらメール。
- **DuckDNS 自体が止まる可能性**がある（無料の外部サービス）。名前が引けなくなると、サイトが動いていても開かない。長期運用なら独自ドメインへ。
- 請求: AWS の予算アラート（月 $10）。静的 IP の付け忘れ、不要なスナップショット、停止中のインスタンスにも課金される点に注意。
- アクセス数: 管理画面ダッシュボードの「최근 30일 버튼 클릭 수」（ADR 0007）。ページ閲覧数は必要になったら Cloudflare Web Analytics 等を検討（独自ドメインが必要）。

### 4. NAVER 検索対策（「근처 미용실」「은파미용실」で見つけてもらう）/ 네이버 검색 대책

**最重要は NAVER プレイス（地図）です。** 「근처 미용실」のような地域検索の結果は、ほとんどがプレイス（地図）で決まります。ホームページは補助です。

1. **NAVER プレイスに登録・最新化**（無料。smartplace.naver.com）: 店名「은파미용실」、住所、電話、営業時間・休業日、**写真（外観・内観・メニュー）**、カテゴリ「미용실」、メニューと価格。情報が正確で写真が多いほど上位に出やすい。
2. プレイスの「홈페이지」欄に `https://eunpabeautysalon.duckdns.org` を入れる。サイトの「찾아오시는 길」から NAVER 地図へリンクする（相互リンク）。
3. **NAVER サーチアドバイザ**（searchadvisor.naver.com）にサイトを登録: 所有確認は HTML タグ方式。発行された値を `.env` の `NAVER_SITE_VERIFICATION` に入れて再起動すると、`<meta name="naver-site-verification">` が出る。→ 確認後、`/sitemap.xml` を送信し、「웹 페이지 수집」で主要ページを要청。
4. Google Search Console も同様（`GOOGLE_SITE_VERIFICATION`）。
5. サイト側で対応済み: タイトルに地域名（사이트 설정の「지역명」）と「커트·파마 전문 미용실」、JSON-LD `HairSalon`、sitemap、robots、hreflang、OG、モバイル最適化（Lighthouse SEO 100）。
6. 継続: ブログを月 1〜2 本（「상주 미용실」「파마 오래 유지」など地域＋悩みの言葉）、口コミ（プレイスの리뷰）を店で案内。

> ⚠️ `duckdns.org` は他人も使う共有ドメインのため、ドメインの評価は積み上がりにくく、**独自ドメインより不利**。地域検索はプレイスが主役なので当面は問題ないが、サイトを検索で育てたくなったら独自ドメイン（年 約 $10）を買う。検索順位は保証できない。

---

# 부록 B. 저비용 서버 가이드 (AWS Lightsail 서울 1GB)

> 요금·조건은 바뀔 수 있으므로 **가입 전에 AWS 요금 페이지(리전: 서울)에서 다시 확인**하세요.


### 요금 방어 체크리스트
1. 인스턴스: 서울(`ap-northeast-2`), **IPv4 포함 메모리 1GB 플랜($7, 저장공간 40GB, 전송 2TB 포함)**. IPv6 전용 $5 플랜과 0.5GB 플랜은 쓰지 않습니다. 월 정액이라 트래픽이 늘어도 서버가 자동으로 커지지 않습니다.
2. **데이터 전송량**: 플랜 포함량을 넘으면 서버에서 나가는 트래픽에만 GB당 요금이 붙습니다(들어오는 것은 무료). 서울 단가는 미확인.
3. **AWS 예산 알림** 월 $10 (알림만 보냅니다. 자동 차단은 아님).
4. 쓰지 않는 **고정 IP·스냅샷·서버**는 삭제(중지한 서버도 과금됩니다). 고정 IP는 서버에 연결해 둡니다.
5. 이미지는 업로드 때 WebP·긴 변 1600px로 줄어 전송량이 작습니다(ADR 0008).

### 메모리 1GB 대응 (프로젝트에 반영됨)
- Rails+Litestream 컨테이너(상한 700MB) + Caddy(상한 100MB), Puma 워커 0·스레드 3, Solid Queue는 Puma 안, YJIT 끔, jemalloc, 로그 레벨 `warn`
- 스왑 2GB·swappiness 10(`deploy/vm-setup.sh`)
- **VM에서 `docker build`를 하지 않습니다**(GitHub Actions에서 빌드, ADR 0004)
- 측정: `deploy/measure-memory.sh` (Rails 컨테이너 시작 직후 약 214MiB, 1,000요청 후 약 266MiB. Caddy는 별도)

### 방어 구조
- 방화벽: 22(가능하면 내 IP만)/80/443만 엽니다.
- DuckDNS 주소는 Cloudflare 뒤에 둘 수 없어 CDN·디도스 완화가 없습니다. 독자 도메인(연 약 $10)을 사면 Cloudflare를 앞에 둘 수 있습니다.
