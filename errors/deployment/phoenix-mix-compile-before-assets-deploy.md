---
title: "Phoenix 1.8: mix assets.deploy が colocated.css を解決できない"
tags: [phoenix, elixir, docker, tailwind]
severity: medium
date: "2026-08-20"
---

## 症状

```
Error: Can't resolve 'phoenix-colocated/dev_pulse_live/colocated.css' in '/app/assets/css'
** (Mix) `mix tailwind dev_pulse_live --minify` exited with 1
```

Dockerfile でのビルドが `mix assets.deploy` ステップで失敗する。

## 原因

Phoenix 1.8 の colocated CSS 機能は `mix compile` によって
`_build/prod/phoenix-colocated/` 配下にファイルを生成する。
Dockerfile でデフォルト順（`mix assets.deploy` → `mix compile`）だと
`colocated.css` がまだ存在しない状態で Tailwind が import しようとして失敗する。

## 解決策

Dockerfile の順序を入れ替える:

```dockerfile
# 誤
RUN mix assets.deploy
RUN mix compile

# 正
RUN mix compile
RUN mix assets.deploy
```

## 予防

Phoenix 1.8 以降の scaffold 生成 Dockerfile はこの順序になっているが、
手動で Dockerfile を書く場合や古いテンプレートを流用した場合は要注意。
