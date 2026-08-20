---
title: "Fly.io: flyctl ssh での Release.migrate() が GenServer timeout で失敗"
tags: [fly.io, elixir, ecto, deployment]
severity: medium
date: "2026-08-20"
---

## 症状

```
** (exit) exited in: GenServer.stop(DevPulseLive.Repo, :normal, 5000)
    ** (EXIT) time out
```

起動済みのアプリマシンに SSH して `Release.migrate()` を eval すると
マイグレーションは実行されないまま GenServer stop がタイムアウトする。

## 原因

`Ecto.Migrator.with_repo/3` は Repo を起動 → マイグレーション → stop する。
しかしアプリが既に動いており Repo も起動済みの場合、
with_repo が stop しようとしても既存プロセスが存在して競合する。

## 解決策

`fly.toml` に `release_command` を追加して、アプリ起動前のマシンで実行する:

```toml
[deploy]
  release_command = "/app/bin/dev_pulse_live eval 'DevPulseLive.Release.migrate()'"
```

release_command はアプリプロセスが起動する前の専用マシンで実行されるため競合しない。

## 予防

Fly.io での Ecto マイグレーションは `release_command` 経由が正式な方法。
既存アプリマシンへの SSH eval は避ける。
