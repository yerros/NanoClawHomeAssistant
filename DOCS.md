# NanoClaw Assistant — Experimental Home Assistant Add-on

This repository ships the `nanoclaw_assistant` add-on for Home Assistant OS.

## Status

`nanoclaw_assistant` is experimental. It is not a polished NanoClaw port yet.

What it does today:
- packages NanoClaw as a Home Assistant add-on shell
- provides Ingress UI and a browser terminal
- clones a persistent NanoClaw checkout into `/config/nanoclaw/app`
- installs `pnpm` and `Claude Code`
- starts an internal Docker daemon inside the add-on
- attempts `pnpm install`, `pnpm build`, and `pnpm start` automatically

What it does not do:
- replace the upstream NanoClaw onboarding flow
- hide Docker or Claude Code requirements
- guarantee good performance on Raspberry Pi 3

## Why it is different from OpenClaw Assistant

OpenClaw can be wrapped as a more self-contained runtime.

NanoClaw upstream is different:
- it expects a persistent git checkout
- it expects `Claude Code`
- it expects Docker so it can spawn its own agent containers

Upstream references:
- NanoClaw repo: https://github.com/qwibitai/nanoclaw
- Claude Code setup docs: https://docs.anthropic.com/en/docs/claude-code/getting-started

## Installation

1. In Home Assistant, open **Settings → Add-ons → Add-on store**
2. Add this repository:
   - `https://github.com/techartdev/NanoClawHomeAssistant`
3. Install **NanoClaw Assistant**
4. Open the **Configuration** tab before first start

## Recommended configuration

For a first boot:

- `bootstrap_repository: true`
- `nanoclaw_repo_url: https://github.com/qwibitai/nanoclaw.git`
- `nanoclaw_repo_ref: main`
- `auto_start_nanoclaw: true`
- `enable_terminal: true`
- `assistant_name: Andy`
- `max_concurrent_containers: 1` on Raspberry Pi 3

## First boot flow

When the add-on starts, it will try to:

1. clone NanoClaw into `/config/nanoclaw/app`
2. run `pnpm install`
3. run `pnpm build`
4. start `pnpm start`

If one of those steps fails, the add-on should still keep the Ingress page and terminal alive so you can finish setup manually.

Important files:

- checkout: `/config/nanoclaw/app`
- runtime log: `/config/nanoclaw/logs/nanoclaw.log`
- bootstrap/install log: `/config/nanoclaw/logs/bootstrap.log`
- docker daemon log: `/config/nanoclaw/logs/dockerd.log`

## Manual setup

Open the add-on terminal and run:

```sh
cd /config/nanoclaw/app
bash nanoclaw.sh
```

If the checkout already exists but the upstream script is not the right path for your branch, try:

```sh
cd /config/nanoclaw/app
pnpm install
pnpm build
pnpm setup
pnpm start
```

## Claude Code authentication

NanoClaw depends on Claude Code for its normal workflows. The add-on installs the `claude` CLI, but you still need to authenticate it interactively from the terminal.

Typical flow:

```sh
claude
```

## Docker requirement

NanoClaw upstream runs agent workloads in containers. Home Assistant's `docker_api` capability is documented as read-only, so it is not sufficient for NanoClaw because NanoClaw needs to create containers.

Because of that, this add-on uses:

- `full_access: true`
- `apparmor: false`
- an internal `dockerd`

This is the main security tradeoff of this wrapper.

Relevant runtime log:

```sh
tail -n 200 /config/nanoclaw/logs/dockerd.log
```

## Raspberry Pi 3 guidance

NanoClaw is lighter than OpenClaw, but Raspberry Pi 3 is still constrained.

Use these settings:

- `max_concurrent_containers: 1`
- avoid multiple channels
- keep terminal enabled only when needed
- expect `pnpm install` and first build to be slow

## Troubleshooting

### The add-on page opens, but NanoClaw is not running

Check:

```sh
tail -n 200 /config/nanoclaw/logs/bootstrap.log
tail -n 200 /config/nanoclaw/logs/nanoclaw.log
```

Then try:

```sh
cd /config/nanoclaw/app
pnpm install
pnpm build
pnpm start
```

### Docker-related errors

If NanoClaw reports it cannot start containers:

1. confirm the add-on was installed with the current elevated privilege settings
2. review `/config/nanoclaw/logs/dockerd.log`
3. review NanoClaw logs for upstream container runtime errors
