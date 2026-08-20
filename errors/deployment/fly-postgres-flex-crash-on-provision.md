---
title: "Fly.io postgres-flex: プロビジョニング後 Postgres プロセスがクラッシュ"
tags: [fly.io, postgres, deployment]
severity: high
date: "2026-08-20"
---

## 症状

```
tcp recv (idle): closed
DBConnection.ConnectionError: connection not available
```

`flyctl postgres create` 直後にアプリから接続できない。
HAProxy は port 5432 で LISTEN しているが全接続が即切断される。
`ps aux` で postgres プロセスが存在しない。

## 原因

Fly.io unmanaged postgres-flex の初回プロビジョニング後、
Postgres プロセス (PID 685 等) が何らかの理由でクラッシュしていた。
HAProxy は起動しているが backend の postgres が DOWN 扱いになり
`on-marked-down shutdown-sessions` ですべての接続を即切断する。

確認方法:
```bash
flyctl ssh console --app <pg-app> --command "ps aux | grep postgres | grep -v grep"
# postgres プロセスが存在しなければクラッシュ
```

ヘルスチェック確認:
```bash
flyctl ssh console --app <pg-app> --command "curl -s http://localhost:5500/flycheck/role"
# "failed to connect" が返ればHAProxy backend DOWN
```

## 解決策

postgres マシンを再起動する:

```bash
flyctl machine restart <machine-id> --app <pg-app>
```

再起動後 `ps aux | grep postgres` で postgres プロセスが存在することを確認してから
マイグレーションを実行する。

## 予防

- `flyctl postgres create` 後は必ず `/flycheck/role` ヘルスチェックを確認する
- postgres-flex は "unmanaged" のため自動復旧しない場合がある
- 可能なら Managed Postgres (fly mpg) の使用を検討する
