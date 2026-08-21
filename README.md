# dev-pulse-live

Real-time GitHub activity dashboard built with Phoenix LiveView + Elixir.

Displays push commits, pull requests, and issues as they happen — updated live via GitHub Webhooks and a REST API poller.

## Features

- Real-time event stream via Phoenix PubSub / LiveView
- GitHub Webhook receiver with HMAC-SHA256 signature verification
- REST API poller as a fallback (configurable interval)
- Event type filter tabs (All / Commits / PRs / Issues)
- Daily stats bar (commits, PRs, issues)
- Deployed on Fly.io (`dev-pulse-live.fly.dev`)

## Requirements

- Elixir 1.17+ / Erlang/OTP 27+
- PostgreSQL 14+
- A GitHub Personal Access Token (scopes: `read:user`, `repo`)
- [ngrok](https://ngrok.com/) or similar for local Webhook testing

## Local development

### 1. Clone and install dependencies

```bash
git clone https://github.com/flipslidersand/dev-pulse-live.git
cd dev-pulse-live
mix setup          # deps.get + ecto.setup + assets
```

### 2. Configure environment variables

Copy `.env.example` and fill in the values:

```bash
cp .env.example .env
```

| Variable | Description | Example |
|---|---|---|
| `SECRET_KEY_BASE` | Phoenix secret (`mix phx.gen.secret`) | `AbCd...` |
| `DATABASE_URL` | Ecto connection string | `ecto://postgres:postgres@localhost:5432/dev_pulse_live_dev` |
| `GITHUB_TOKEN` | Personal Access Token (scopes: `read:user`, `repo`) | `ghp_xxx` |
| `GITHUB_WEBHOOK_SECRET` | Shared secret for Webhook HMAC verification | any random string |
| `GITHUB_ACTOR` | GitHub username whose events the poller fetches | `flipslidersand` |
| `POLLER_INTERVAL_MS` | REST poll interval in ms (default: 300000 = 5 min) | `60000` |
| `PHX_HOST` | Public hostname (leave `localhost` for local dev) | `localhost` |

Load the variables before starting the server:

```bash
export $(grep -v '^#' .env | xargs)
```

### 3. Start the server

```bash
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000). The dashboard shows events polled from the GitHub REST API every `POLLER_INTERVAL_MS` milliseconds.

### 4. Run tests

```bash
mix test              # run all tests
mix test --cover      # with coverage report (threshold: 70%)
mix precommit         # compile + format check + test (run before committing)
```

## GitHub Webhook setup

Webhooks deliver events in real time — no waiting for the poller interval. The app receives them at `POST /webhooks/github`.

### Local tunneling with ngrok

```bash
ngrok http 4000
# → Forwarding: https://xxxx.ngrok-free.app → http://localhost:4000
```

### Register the Webhook on GitHub

1. Open **GitHub → Settings → Webhooks → Add webhook** (or the target repository's settings)
2. Fill in:
   - **Payload URL**: `https://xxxx.ngrok-free.app/webhooks/github`
   - **Content type**: `application/json`
   - **Secret**: the value of `GITHUB_WEBHOOK_SECRET` in your `.env`
   - **Events**: select **Push**, **Pull requests**, **Issues** (or "Send me everything")
3. Click **Add webhook**

GitHub will send a ping event immediately. The app responds `200 ok` or `200 ignored` for unsupported events, and `401` for invalid signatures.

### Verify signature locally

The app validates every webhook using HMAC-SHA256:

```
x-hub-signature-256: sha256=<HMAC(body, GITHUB_WEBHOOK_SECRET)>
```

If the signature does not match, the request is rejected with `401 invalid signature`.

## Deployment (Fly.io)

The app is deployed on [Fly.io](https://fly.io). To deploy your own instance:

### 1. Create the app and database

```bash
fly launch --name my-dev-pulse --region nrt   # follow prompts, skip deploy
fly postgres create --name my-dev-pulse-db
fly postgres attach my-dev-pulse-db
```

### 2. Set secrets

```bash
fly secrets set \
  SECRET_KEY_BASE=$(mix phx.gen.secret) \
  GITHUB_TOKEN=ghp_your_token \
  GITHUB_WEBHOOK_SECRET=your_webhook_secret \
  GITHUB_ACTOR=your_github_username
```

### 3. Deploy

```bash
fly deploy
```

Migrations run automatically via `fly.toml`'s `release_command` before the app starts.

### 4. Register the Webhook on GitHub

Use your Fly.io app URL as the Payload URL:

```
https://my-dev-pulse.fly.dev/webhooks/github
```

## Architecture

```
GitHub REST API ──(poll every N min)──▶ Poller (GenServer)
                                              │
GitHub Webhooks ──(POST /webhooks/github)──▶ WebhookController
                                              │
                                        EventParser
                                              │
                                         Repo (Postgres)
                                              │
                                        Broadcaster (PubSub)
                                              │
                                       DashboardLive (LiveView)
                                              │
                                          Browser
```

## Project structure

```
lib/
  dev_pulse_live/
    activity_feed/
      broadcaster.ex      # Phoenix.PubSub wrapper
      poller.ex           # GenServer — polls GitHub REST API
    events/
      events.ex           # Ecto context
      github_event.ex     # schema
    github/
      client.ex           # Req HTTP client for GitHub API
      event_parser.ex     # webhook payload → internal attrs
      webhook_verifier.ex # HMAC-SHA256 signature check
  dev_pulse_live_web/
    live/
      dashboard_live.ex   # main LiveView
    controllers/
      webhook_controller.ex
    plugs/
      cache_body_reader.ex         # caches raw body for signature check
      verify_github_signature.ex   # HMAC plug
    components/
      activity_components.ex       # event card, stats bar
      core_components.ex           # buttons, inputs, table, etc.
```
