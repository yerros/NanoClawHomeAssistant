# NanoClaw Assistant

`nanoclaw_assistant` is an experimental Home Assistant add-on that wraps upstream NanoClaw in a terminal-first workflow.

## What it does

- clones NanoClaw into `/config/nanoclaw/app`
- installs `pnpm` and `Claude Code`
- starts an internal Docker daemon for NanoClaw agent containers
- exposes a browser terminal in the add-on page
- attempts to install dependencies, build, and start NanoClaw automatically

## First steps

1. Install the add-on
2. Open the add-on page
3. Open the embedded terminal
4. Run:

```sh
cd /config/nanoclaw/app
bash nanoclaw.sh
```

If your upstream branch does not ship `nanoclaw.sh`, use:

```sh
cd /config/nanoclaw/app
pnpm install
pnpm build
pnpm setup
pnpm start
```

## Logs

- Runtime: `/config/nanoclaw/logs/nanoclaw.log`
- Bootstrap: `/config/nanoclaw/logs/bootstrap.log`
- Docker: `/config/nanoclaw/logs/dockerd.log`

## Important note

This add-on requires elevated privileges because NanoClaw needs write access to a Docker daemon in order to create agent containers. Home Assistant's documented `docker_api` capability is read-only, so this add-on runs its own internal Docker daemon instead.

Read [../SECURITY.md](../SECURITY.md) before deploying it on a trusted Home Assistant instance.

For the full repository-level documentation, see [../DOCS.md](../DOCS.md).
