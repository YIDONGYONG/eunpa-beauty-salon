# 運用手順書 / 운영 Runbook

対象: AWS Lightsail ソウル 1GB 1台（コンテナ2つ: Rails+Litestream / Caddy）+ DuckDNS の無料アドレス。まだサーバーを作っていないため、値は `deploy/env.production.example` のプレースホルダー。
대상: AWS Lightsail 서울 1GB 1대 + DuckDNS 무료 주소(eunpabeautysalon.duckdns.org). 실제 서버를 만들기 전이라 값은 플레이스홀더입니다.

## 1. 最初のセットアップ（1回だけ）/ 최초 설정 — AWS Lightsail ソウル 1GB + DuckDNS

> 用語: **VM/サーバー** = 24時間動くインターネット上のパソコン。**IP** = サーバーの住所の番号。**DNS** = 名前（eunpabeautysalon.duckdns.org）から IP を引く電話帳。**HTTPS** = 通信を暗号化する鍵マーク。**ファイアウォール** = 出入口の鍵（どのポートを開けるか）。

1. **料金の確認（作成前）**: Lightsail の料金ページでリージョンを「ソウル」にして 1GB プランの月額を確認（約 $5 の見込み。未確認）。AWS の請求 → 予算で **月 $8 のアラート**を作る（超過前にメール。自動停止ではない）。
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

## 2. 日々の運用 / 일상 운영

| やること | 方法 |
|---|---|
| デプロイ | `main` に push → GitHub Actions がテスト → イメージ作成 → VM で pull（自動） |
| ログ | `docker logs -f eunpa-web-1`（json-file 10MB×3 で自動ローテーション） |
| メモリ確認 | `docker stats --no-stream`（目安: 300MB 前後。700MB 上限の 70% 超えで調査） |
| 稼働監視 | UptimeRobot（無料）で `https://eunpabeautysalon.duckdns.org/up` を 5 分間隔。落ちたらメール |
| エラー通知 | `.env` に `ERROR_NOTIFY_EMAIL` と SMTP を設定（ADR 0009） |
| 画像のバックアップ | `/var/lib/eunpa/files` を日次で S3 へ: `aws s3 sync /var/lib/eunpa/files s3://BUCKET/eunpa/files`（cron。AWS CLI が必要）。**Litestream は画像を複製しない** |
| 予算 | 月 $3〜5 のアラート。想定は $0（無料枠内） |

### パッチ担当と周期 / 패치 담당·주기
- 担当: 開発者（このリポジトリの管理者）。院長は管理画面のみ。
- 週1回: Dependabot の PR を確認しマージ → 自動デプロイ。月1回: `bin/bundler-audit`、`bin/brakeman`（CI でも毎回実行）。Rails / Ruby のセキュリティ更新は **1週間以内**。
- Ruby のサポート期限を確認（`.ruby-version` と Dockerfile の `RUBY_VERSION`）。

## 3. 監視と請求 / 모니터링과 청구

- UptimeRobot（無料）で `https://eunpabeautysalon.duckdns.org/up` を 5 分間隔で監視。落ちたらメール。
- **DuckDNS 自体が止まる可能性**がある（無料の外部サービス）。名前が引けなくなると、サイトが動いていても開かない。長期運用なら独自ドメインへ。
- 請求: AWS の予算アラート（月 $8）。静的 IP の付け忘れ、不要なスナップショット、停止中のインスタンスにも課金される点に注意。
- アクセス数: 管理画面ダッシュボードの「최근 30일 버튼 클릭 수」（ADR 0007）。ページ閲覧数は必要になったら Cloudflare Web Analytics 等を検討（独自ドメインが必要）。

## 4. 障害対応 / 장애 대응

### 4-1. サイトが開かない
1. `curl -i https://eunpabeautysalon.duckdns.org/up`。名前が引けない場合は DuckDNS の管理画面で IP を確認。
2. VM に SSH: `docker ps` / `docker logs --tail 100 eunpa-web-1`。
3. 再起動: `cd /opt/eunpa && docker compose restart`。直らなければ直前のイメージに戻す: `.env` の `IMAGE` を `ghcr.io/OWNER/REPO:<前のコミットSHA>` にして `docker compose up -d`。
4. メモリ不足（`docker stats` が 700MB 近い）: スワップを確認 `swapon --show`。

### 4-2. DB が壊れた／ディスクが消えた（復元）
1. コンテナを止める: `docker compose stop`。
2. 壊れた DB を退避: `mv /var/lib/eunpa/production.sqlite3* /var/lib/eunpa/broken-$(date +%F)/`（ディレクトリを先に作る）。
3. `docker compose up -d` → `bin/docker-entrypoint` が **レプリカから自動復元**してから起動する（ログに `restoring` が出る）。
4. 画面と管理画面を確認。失った範囲は直近約10秒分まで。
5. 画像が消えた場合は `aws s3 sync s3://BUCKET/eunpa/files /var/lib/eunpa/files` で戻し、所有者を `chown -R 1000:1000 /var/lib/eunpa`。
- 特定の時点に戻す: `litestream restore -timestamp 2026-10-23T09:00:00Z ...`（保持 72 時間）。

### 4-3. 誤って削除した（ブログ・メニュー・イベント）
管理画面「휴지통」→「되돌리기」（ADR 0006）。バックアップ復元は不要。

## 5. 復元テストの記録 / 복원 테스트 기록

`deploy/restore-test.sh eunpa-prod` を本番イメージで実施（レプリカ先はローカルの `file://`。S3 / GCS と同じ設定・同じ手順で、URL だけが違う）。

| 日付 | 手順 | 結果 |
|---|---|---|
| 2026-10-23 | 初回起動 → 印のデータを保存 → 15秒待つ → データボリューム削除 → 再起動 | **成功**: 印と記事 6 件が自動復元された |

> 未実施: 実際の S3 バケットでのテスト（バケット・IAM ユーザーが未作成のため）。作成後に `LITESTREAM_REPLICA_URL=s3://...` で同じ手順を行い、この表に追記すること。

## 6. メモリ測定（1GB VM を想定）/ 메모리 측정

`deploy/measure-memory.sh eunpa-prod`（メモリ上限 700MB で起動）:

| 状態 | メモリ使用量 |
|---|---|
| 起動直後 | 約 214 MiB（30%） |
| 1,000 リクエスト後 | 約 266 MiB（38%） |

Litestream の複製プロセスは別途 +20〜40MB 程度の見込み（本番設定で再測定すること）。

## 7. NAVER 検索対策（「근처 미용실」「은파미용실」で見つけてもらう）/ 네이버 검색 대책

**最重要は NAVER プレイス（地図）です。** 「근처 미용실」のような地域検索の結果は、ほとんどがプレイス（地図）で決まります。ホームページは補助です。

1. **NAVER プレイスに登録・最新化**（無料。smartplace.naver.com）: 店名「은파미용실」、住所、電話、営業時間・休業日、**写真（外観・内観・メニュー）**、カテゴリ「미용실」、メニューと価格。情報が正確で写真が多いほど上位に出やすい。
2. プレイスの「홈페이지」欄に `https://eunpabeautysalon.duckdns.org` を入れる。サイトの「찾아오시는 길」から NAVER 地図へリンクする（相互リンク）。
3. **NAVER サーチアドバイザ**（searchadvisor.naver.com）にサイトを登録: 所有確認は HTML タグ方式。発行された値を `.env` の `NAVER_SITE_VERIFICATION` に入れて再起動すると、`<meta name="naver-site-verification">` が出る。→ 確認後、`/sitemap.xml` を送信し、「웹 페이지 수집」で主要ページを要청。
4. Google Search Console も同様（`GOOGLE_SITE_VERIFICATION`）。
5. サイト側で対応済み: タイトルに地域名（사이트 설정の「지역명」）と「커트·파마 전문 미용실」、JSON-LD `HairSalon`、sitemap、robots、hreflang、OG、モバイル最適化（Lighthouse SEO 100）。
6. 継続: ブログを月 1〜2 本（「상주 미용실」「파마 오래 유지」など地域＋悩みの言葉）、口コミ（プレイスの리뷰）を店で案内。

> ⚠️ `duckdns.org` は他人も使う共有ドメインのため、ドメインの評価は積み上がりにくく、**独自ドメインより不利**。地域検索はプレイスが主役なので当面は問題ないが、サイトを検索で育てたくなったら独自ドメイン（年 約 $10）を買う。検索順位は保証できない。
