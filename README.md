# dev-pulse-live

Real-time GitHub activity dashboard built with Phoenix LiveView + Elixir.
Displays push commits, pull requests, and issues as they happen — updated live via GitHub Webhooks and a REST API poller.

Phoenix LiveView + Elixir で構築したリアルタイム GitHub アクティビティダッシュボード。
GitHub Webhooks と REST API ポーラーにより、push コミット・PR・Issue をリアルタイムで表示します。

## Features / 機能

- Real-time event stream via Phoenix PubSub / LiveView / Phoenix PubSub / LiveView によるリアルタイムイベントストリーム
- GitHub Webhook receiver with HMAC-SHA256 signature verification / HMAC-SHA256 署名検証付き Webhook レシーバー
- REST API poller as fallback (configurable interval) / フォールバック用 REST API ポーラー（ポーリング間隔設定可能）
- Event type filter tabs (All / Commits / PRs / Issues) / イベント種別フィルタータブ
- Daily stats bar (commits, PRs, issues) / 日次統計バー
- Deployed on Fly.io (`dev-pulse-live.fly.dev`) / Fly.io にデプロイ済み

## Requirements / 必要環境

- Elixir 1.17+ / Erlang/OTP 27+
- PostgreSQL 14+
- GitHub Personal Access Token (scopes: `read:user`, `repo`)
- [ngrok](https://ngrok.com/) for local Webhook testing / ローカル Webhook テスト用

## Local Development / ローカル開発

```bash
git clone https://github.com/flipslidersand/dev-pulse-live.git
cd dev-pulse-live
mix setup
```

### Environment Variables / 環境変数

| Variable | Description / 説明 | Example |
|---|---|---|
| `SECRET_KEY_BASE` | Phoenix secret | `AbCd...` |
| `DATABASE_URL` | Ecto connection string / Ecto 接続文字列 | `ecto://postgres:...` |
| `GITHUB_TOKEN` | PAT (scopes: `read:user`, `repo`) | `ghp_xxx` |
| `GITHUB_WEBHOOK_SECRET` | Shared secret for HMAC / HMAC 用共有シークレット | any random string |
| `GITHUB_ACTOR` | GitHub username to poll / ポーリング対象ユーザー | `flipslidersand` |
| `POLLER_INTERVAL_MS` | Poll interval in ms (default: 300000) / ポーリング間隔 | `60000` |

```bash
mix phx.server
mix test              # run tests / テスト実行
mix test --cover      # coverage (threshold: 70%)
mix precommit         # compile + format + test
```

## GitHub Webhook Setup / Webhook 設定

Register at `POST /webhooks/github`. Every request is validated using HMAC-SHA256.
`POST /webhooks/github` に登録。すべてのリクエストを HMAC-SHA256 で検証します。

## Deployment (Fly.io) / デプロイ

```bash
fly launch --name my-dev-pulse --region nrt
fly postgres create --name my-dev-pulse-db && fly postgres attach my-dev-pulse-db
fly secrets set SECRET_KEY_BASE=... GITHUB_TOKEN=... GITHUB_WEBHOOK_SECRET=...
fly deploy
```

## Architecture / アーキテクチャ

```
GitHub REST API ──(poll)──▶ Poller (GenServer)
GitHub Webhooks ──────────▶ WebhookController
                                  │
                            EventParser → Repo (Postgres)
                                  │
                            Broadcaster (PubSub)
                                  │
                           DashboardLive (LiveView) → Browser
```
