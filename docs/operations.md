# 運用（障害対応・セットアップ・費用）

対象: AWS Lightsail ソウル 1GB を1台（Rails+Litestream と Caddy の2コンテナ）+ DuckDNS。**まだサーバーを作っていない**ため、以下の復元・メモリの数値は、ローカルの Docker で測定した値です。セットアップ・日々の運用・検索対策・費用は、下の付録を参照してください。

## 障害対応（3つ）

**1. サイトが開かないとき**
1. `curl -i https://eunpabeautysalon.duckdns.org/up` を実行。名前が引けない場合は、DuckDNS の管理画面で IP を確認する。
2. VM で `docker ps`、`docker logs --tail 100 eunpa-web-1` を実行。
3. `cd /opt/eunpa && docker compose restart`。直らなければ、`.env` の `IMAGE` を前のコミットの SHA に変えて `docker compose up -d`（ロールバック）。

**2. DB が壊れた・ディスクが消えたとき（復元）**
1. `docker compose stop` し、壊れた `/var/lib/eunpa/production.sqlite3*` を別のフォルダへ移す。
2. `docker compose up -d` を実行すると、`bin/docker-entrypoint` が **S3 のレプリカから自動で復元**してから起動する（損失は最大で約10秒分）。
3. 画像は Litestream の対象外なので、`aws s3 sync s3://BUCKET/eunpa/files /var/lib/eunpa/files` で戻す（日次同期の cron は**未設定**）。
4. 特定の時点に戻す場合: `litestream restore -timestamp ...`（保持期間は 72 時間）。

**3. 誤って削除したとき（ブログ・メニュー・イベント）**
管理画面の「ゴミ箱」（韓国語表示は「휴지통」）→「元に戻す」。論理削除なので、バックアップからの復元は不要です（ADR 0006）。

## 復元テストの記録

`deploy/restore-test.sh`: 本番イメージで実行。複製先はローカルの `file://`（S3 と設定・手順は同じで、URL だけが違う）。

| 日付 | 手順 | 結果 |
|---|---|---|
| 2026-10-23 | 初回起動 → 目印のデータを保存 → 15秒待つ → データボリュームを削除 → 再起動 | **成功**: 目印のデータと記事6件が自動で復元された |

> **未実施:** 実際の S3 バケットでのテスト（バケット・IAM ユーザーが未作成）。作成後に `LITESTREAM_REPLICA_URL=s3://...` で同じ手順を行い、この表に追記する。

## メモリ測定（1GB の VM を想定）

`deploy/measure-memory.sh` — コンテナのメモリ上限を 700MB にして実行。

| 状態 | メモリ使用量 |
|---|---|
| 起動直後 | 約 214 MiB（30%） |
| 1,000 リクエスト後 | 約 266 MiB（38%） |

Litestream のプロセスは別に +20〜40MB 程度と見積もっている（本番の設定で再測定が必要）。

---

# 付録 A. セットアップと日々の運用

対象: AWS Lightsail ソウル 1GB を1台（コンテナ2つ: Rails+Litestream / Caddy）+ DuckDNS の無料アドレス。まだサーバーを作っていないため、値は `deploy/env.production.example` のプレースホルダーです。

## 1. 最初のセットアップ（1回だけ）— AWS Lightsail ソウル 1GB + DuckDNS

> 用語: **VM/サーバー** = 24時間動くインターネット上のパソコン。**IP** = サーバーの住所の番号。**DNS** = 名前（eunpabeautysalon.duckdns.org）から IP を引く電話帳。**HTTPS** = 通信を暗号化する鍵マーク。**ファイアウォール** = 出入口の鍵（どのポートを開けるか）。

1. **料金の確認（作成前）**: Lightsail の料金ページでリージョンを「ソウル」にして **IPv4 付きの 1GB プラン（$7）**を選ぶ（IPv6 専用の $5 は不可。公式の料金ページで確認済み。ソウルの最終料金と消費税は契約画面で確認）。AWS の請求 → 予算で **月 $10 のアラート**を作る（超過前にメール。自動停止ではない）。
2. **Lightsail でインスタンスを作成**: リージョンは `ap-northeast-2`（ソウル）。アカウントの都合でソウルを選べない間は、暫定的に `ap-southeast-2`（シドニー）を使い、後でソウルへ移す（その場合、S3 バケットと `AWS_REGION` もサーバーと同じリージョンにそろえる）。OS は Ubuntu 24.04 LTS、プランは IPv4 付きの 1GB。作成画面の「起動スクリプト（Launch script）」に `deploy/lightsail-launch-script.sh` の内容を貼り付けると、手順 6 の初期設定が作成直後に自動で終わる（ログ: `/var/log/eunpa-setup.log`）。
3. **静的 IP を作ってインスタンスにアタッチ**（IP が再起動で変わらないようにする。**アタッチしたままにする**。未使用の静的 IP は課金される）。
4. **ファイアウォール（Lightsail の「ネットワーキング」タブ）**: 開けるのは **22（SSH。可能なら自分の IP のみ）/ 80 / 443** だけ。それ以外は閉じる。
5. **DuckDNS**: https://www.duckdns.org でログイン → サブドメイン `eunpabeautysalon` を作り、IP 欄に**手順3の静的 IP** を入れる（静的 IP なので更新作業は不要）。
6. サーバーの初期設定: 手順 2 の起動スクリプトを使った場合は自動で済んでいる。使わなかった場合は、サーバーに SSH して `sudo deploy/vm-setup.sh` を実行する（スワップ 2GB、Docker、OS の自動更新、`/var/lib/eunpa`）。
7. **バックアップ用の S3 バケット（ソウル）**（AWS の CloudShell で `deploy/cloudshell-s3-setup.sh` を実行すると、バケット・IAM ユーザー・アクセスキーを一度に作れる）を作り、**そのバケットだけ**に権限を絞った IAM ユーザーのアクセスキーを発行する（AWS ルートのキーは使わない）。
8. （手順 8・9 は、サーバーで `deploy/bootstrap.sh` を実行すると、質問に答えるだけで自動的に済む。以下は手動で行う場合の内容）`/opt/eunpa/` に `deploy/compose.production.yml`（**`compose.yaml` という名前で**置く。GitHub Actions の配備が、ファイル名を指定せずに `docker compose` を実行するため）、`deploy/Caddyfile`、`.env`（`deploy/env.production.example` をコピーして値を入れる）を置く。`SECRET_KEY_BASE` は `bin/rails secret` で作る。`IMAGE` は GHCR のイメージ名で、**小文字**で書く（例: `ghcr.io/yidongyong/eunpa-beauty-salon`）。
9. `docker compose up -d`（`/opt/eunpa` で実行）→ Caddy が自動で HTTPS 証明書（Let's Encrypt）を取得する。`https://eunpabeautysalon.duckdns.org/up` が 200 なら成功。管理者を作成したら `.env` を `RUN_SEED=false` にする。
10. GitHub の Variables に `DEPLOY_ENABLED=true`、Secrets に `VM_HOST`・`VM_USER`・`VM_SSH_KEY`（配備専用の SSH 鍵）を設定する。

> ⚠️ **DuckDNS は自分のドメインではないため、Cloudflare（CDN・DDoS 緩和）を前に置けません。** 代わりに、ファイアウォールで 80/443 以外を閉じる、Caddy が HTTPS を担当する、コンテナのメモリ上限（700MB）を設ける、請求アラートを設定する、といった対策をとります。大きな攻撃は防げないので、サイトが止まっても **NAVER プレイス（地図）の情報は影響を受けない**ようにしておきます。将来、独自ドメイン（年 約 $10）を買えば Cloudflare を前に置けます。

## 2. 日々の運用

| やること | 方法 |
|---|---|
| デプロイ | `main` に push → GitHub Actions がテスト → イメージ作成 → VM で pull（自動） |
| ログ | `docker logs -f eunpa-web-1`（json-file 10MB×3 で自動ローテーション） |
| メモリ確認 | `docker stats --no-stream`（目安: 300MB 前後。700MB 上限の 70% を超えたら調査） |
| 稼働監視 | UptimeRobot（無料）で `https://eunpabeautysalon.duckdns.org/up` を 5 分間隔で確認。落ちたらメール |
| エラー通知 | `.env` に `ERROR_NOTIFY_EMAIL` と SMTP を設定（ADR 0009） |
| 画像のバックアップ | `/var/lib/eunpa/files` を日次で S3 へ: `aws s3 sync /var/lib/eunpa/files s3://BUCKET/eunpa/files`（cron。AWS CLI が必要）。**Litestream は画像を複製しない** |
| 予算 | 月 $10 のアラート。想定は月 $7（＋消費税） |

### パッチの担当と周期
- 担当: 開発者（このリポジトリの管理者）。院長は管理画面のみを使う。
- 週1回: Dependabot の PR を確認してマージ → 自動デプロイ。月1回: `bin/bundler-audit`、`bin/brakeman`（CI でも毎回実行）。Rails / Ruby のセキュリティ更新は **1週間以内**に反映する。
- Ruby のサポート期限を確認する（`.ruby-version` と Dockerfile の `RUBY_VERSION`）。

## 3. 監視と請求

- UptimeRobot（無料）で `https://eunpabeautysalon.duckdns.org/up` を 5 分間隔で監視する。落ちたらメールが届く。
- **DuckDNS 自体が止まる可能性**がある（無料の外部サービス）。名前が引けなくなると、サイトが動いていても開けない。長期運用なら独自ドメインへ移す。
- 請求: AWS の予算アラート（月 $10）。静的 IP の付け忘れ、不要なスナップショット、停止中のインスタンスにも課金される点に注意する。
- アクセス数: 管理画面ダッシュボードの「最近30日のボタンのクリック数」（ADR 0007）。ページの閲覧数は、必要になったら Cloudflare Web Analytics 等を検討する（独自ドメインが必要）。

## 4. NAVER 検索対策（「근처 미용실」「은파미용실」で見つけてもらう）

**最重要は NAVER プレイス（地図）です。** 「근처 미용실」（近くの美容室）のような地域検索の結果は、ほとんどがプレイス（地図）で決まります。ホームページは補助的な位置づけです。

1. **NAVER プレイスに登録・最新化**（無料。smartplace.naver.com）: 店名「은파미용실」、住所、電話、営業時間・休業日、**写真（外観・内観・メニュー）**、カテゴリ「미용실」、メニューと価格。情報が正確で、写真が多いほど上位に出やすい。
2. プレイスの「ホームページ」欄に `https://eunpabeautysalon.duckdns.org` を入れる。サイトの「アクセス」ページから NAVER 地図へリンクする（相互リンク）。
3. **NAVER サーチアドバイザ**（searchadvisor.naver.com）にサイトを登録する: 所有確認は HTML タグ方式。発行された値を `.env` の `NAVER_SITE_VERIFICATION` に入れて再起動すると、`<meta name="naver-site-verification">` が出力される。確認後、`/sitemap.xml` を送信し、「ウェブページ収集」で主要ページを依頼する。
4. Google Search Console も同様に行う（`GOOGLE_SITE_VERIFICATION`）。
5. サイト側で対応済みの項目: タイトルに地域名（管理画面のサイト設定の「地域名」）と「カット・パーマ専門の美容室」、JSON-LD `HairSalon`、sitemap、robots、hreflang、OG、モバイル最適化（Lighthouse SEO 100）。
6. 継続すること: ブログを月 1〜2 本（「상주 미용실」「파마 오래 유지」のように、地域＋悩みの言葉を含める）。口コミ（プレイスのレビュー）を店頭で案内する。

> ⚠️ `duckdns.org` は他人も使う共有ドメインのため、ドメインの評価が積み上がりにくく、**独自ドメインより不利**です。地域検索はプレイスが主役なので当面は問題ありませんが、サイトを検索で育てたくなったら独自ドメイン（年 約 $10）を買います。検索順位は保証できません。

---

# 付録 B. 低コストなサーバーのガイド（AWS Lightsail ソウル 1GB）

> 料金や条件は変わることがあるため、**契約の前に AWS の料金ページ（リージョン: ソウル）で再確認**してください。

## 料金を守るチェックリスト
1. インスタンス: ソウル（`ap-northeast-2`）、**IPv4 付きのメモリ 1GB プラン（$7、SSD 40GB、転送 2TB を含む）**。IPv6 専用の $5 プランと 0.5GB プランは使わない。月額固定なので、アクセスが増えてもサーバーが自動で大きくなることはない。
2. **データ転送量**: プランの含まれる量を超えた場合のみ、サーバーから出る通信に GB あたりの料金がかかる（入ってくる通信は無料）。ソウルの単価は未確認。
3. **AWS の予算アラート**は月 $10（通知のみ。自動で止まるわけではない）。
4. 使わない**静的 IP・スナップショット・サーバー**は削除する（停止しただけのサーバーも課金される）。静的 IP はサーバーにアタッチしておく。
5. 画像はアップロード時に WebP・長辺 1600px へ縮小するため、転送量が小さい（ADR 0008）。

## メモリ 1GB への対応（プロジェクトに反映済み）
- Rails+Litestream のコンテナ（上限 700MB）+ Caddy（上限 100MB）。Puma はワーカーなし・スレッド3。Solid Queue は Puma の中で動かす。YJIT はオフ、jemalloc を使用、ログレベルは `warn`。
- スワップ 2GB・swappiness 10（`deploy/vm-setup.sh`）。
- **VM では `docker build` を行わない**（GitHub Actions でビルド。ADR 0004）。
- 測定: `deploy/measure-memory.sh`（Rails コンテナの起動直後は約 214MiB、1,000 リクエスト後は約 266MiB。Caddy は別）。

## 防御の構造
- ファイアウォール: 22（可能なら自分の IP のみ）/ 80 / 443 だけを開ける。
- DuckDNS のアドレスは Cloudflare の背後に置けないため、CDN・DDoS 緩和がない。独自ドメイン（年 約 $10）を買えば、Cloudflare を前に置ける。
