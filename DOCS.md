# NanoClaw Assistant Documentation

This repository ships one Home Assistant add-on: `nanoclaw_assistant`.

It wraps upstream NanoClaw in a Home Assistant friendly package, but the workflow is still terminal-first and experimental.

## Overview

What the add-on does:
- bundles NanoClaw source into the image for automatic first-boot checkout
- prepares NanoClaw in persistent storage at `/config/nanoclaw/app`
- installs `pnpm`, `Claude Code`, and `Codex`
- starts an internal Docker daemon for NanoClaw agent containers
- exposes an Ingress page with a browser terminal
- attempts `pnpm install`, `pnpm build`, and `pnpm start` automatically

What the add-on does not do:
- replace upstream NanoClaw onboarding with a polished Home Assistant wizard
- remove the need for Docker or a supported coding CLI
- avoid interactive CLI login
- make Raspberry Pi 3 fast

## Upstream references

- NanoClaw: `https://github.com/qwibitai/nanoclaw`
- Claude Code docs: `https://docs.anthropic.com/en/docs/claude-code/getting-started`
- Codex CLI docs: `https://help.openai.com/en/articles/11096431-openai-codex-ci-getting-started`
- Codex ChatGPT sign-in docs: `https://help.openai.com/en/articles/11381614`

## Installation

1. In Home Assistant, open **Settings → Add-ons → Add-on store**
2. Open **⋮ → Repositories**
3. Add this repository:
   - `https://github.com/yerros/NanoClawHomeAssistant`
4. Install **NanoClaw Assistant**
5. Open the add-on **Configuration** tab before first start

## Recommended first-boot configuration

- `bootstrap_repository: true`
- `nanoclaw_repo_url: https://github.com/qwibitai/nanoclaw.git`
- `nanoclaw_repo_ref: main`
- `auto_start_nanoclaw: true`
- `enable_terminal: true`
- `assistant_name: Andy`
- `ai_cli_provider: both`
- `max_concurrent_containers: 1` on Raspberry Pi 3

## First boot flow

On startup, the add-on tries to:

1. clone NanoClaw into `/config/nanoclaw/app`
2. install dependencies with `pnpm install`
3. build with `pnpm build`
4. start NanoClaw with `pnpm start`

If any of those steps fail, the add-on should still keep the Ingress page and terminal available so you can finish setup manually.

When the configured repository URL and ref match the bundled upstream snapshot, the add-on copies source from the image into `/config/nanoclaw/app` instead of relying on a live `git clone` during first boot.

Useful paths:
- checkout: `/config/nanoclaw/app`
- runtime log: `/config/nanoclaw/logs/nanoclaw.log`
- bootstrap/install log: `/config/nanoclaw/logs/bootstrap.log`
- Docker daemon log: `/config/nanoclaw/logs/dockerd.log`

## Manual setup

Open the add-on terminal and run:

```sh
cd /config/nanoclaw/app
bash nanoclaw.sh
```

If your upstream branch does not provide `nanoclaw.sh`, use:

```sh
cd /config/nanoclaw/app
pnpm install
pnpm build
pnpm setup
pnpm start
```

## CLI authentication

The add-on installs both supported coding CLIs:
- `claude`
- `codex`

Choose the one you want to authenticate and use.

Claude Code:

```sh
claude
```

Codex:

```sh
codex --login
```

Then complete the login flow shown in the terminal.

Important:
- source checkout, dependency install, and build are automated by the add-on
- CLI authentication is still interactive
- if upstream NanoClaw expects a skill like `/setup` inside the CLI, you still need to run that manually after login

## Configuration reference

`timezone`
- Exported as `TZ` inside the add-on runtime.

`enable_terminal`
- Enables the embedded `ttyd` terminal in the Ingress page.

`terminal_port`
- Internal port used by `ttyd`.

`assistant_name`
- Exported as `ASSISTANT_NAME`.

`ai_cli_provider`
- Exported as `AI_CLI_PROVIDER`.
- Allowed values: `claude`, `codex`, `both`.
- Controls the preferred CLI shown in the UI and the runtime environment.

`bootstrap_repository`
- Automatically prepares NanoClaw in persistent storage if no checkout exists yet.
- Uses the bundled source from the image when the configured repo URL and ref match the bundled upstream snapshot.
- Falls back to live `git clone` when a custom repo URL or ref is configured.

`nanoclaw_repo_url`
- Git URL used for the persistent checkout.

`nanoclaw_repo_ref`
- Git branch or tag used for the first clone.

`auto_start_nanoclaw`
- Starts `pnpm start` automatically when `dist/index.js` exists.

`max_concurrent_containers`
- Exported as `MAX_CONCURRENT_CONTAINERS`.

`onecli_url`
- Optional `ONECLI_URL` override.

`nanoclaw_env_vars`
- Additional environment variables passed to the NanoClaw host process.

## Security model

NanoClaw needs to create containers for agent workloads. Home Assistant documents `docker_api` as read-only, so this add-on cannot rely on that capability.

Instead, the add-on uses:
- `full_access: true`
- `apparmor: false`
- an internal `dockerd`

This is the largest operational and security tradeoff in the project. Read [SECURITY.md](SECURITY.md) before deploying it on a trusted Home Assistant instance.

## CLI compatibility note

This repository now supports both `Claude Code` and `Codex` at the add-on level, meaning both CLIs are installed and available in the terminal/runtime.

That does **not** guarantee that upstream NanoClaw already treats both CLIs as interchangeable in every workflow. If upstream NanoClaw still hardcodes one CLI in its scripts or prompts, you may need to patch the checkout under `/config/nanoclaw/app` or maintain a fork.

## Raspberry Pi 3 guidance

NanoClaw is lighter than OpenClaw, but Raspberry Pi 3 is still resource-constrained.

Recommended settings:
- `max_concurrent_containers: 1`
- keep the number of active channels low
- avoid repeated rebuilds
- expect slow `pnpm install`, `pnpm build`, and container startup

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

If NanoClaw cannot start agent containers:

1. confirm the add-on is running with the current elevated privilege settings
2. inspect `/config/nanoclaw/logs/dockerd.log`
3. inspect NanoClaw runtime logs for upstream container runtime failures

### Claude Code setup does not complete

Authenticate Claude Code first:

```sh
claude
```

### Codex setup does not complete

Authenticate Codex first:

```sh
codex --login
```
