# NanoClaw Assistant

Experimental Home Assistant add-on wrapper for NanoClaw.

What it provides:
- a persistent NanoClaw checkout under `/config/nanoclaw/app`
- a browser terminal via `ttyd`
- automatic `pnpm install` and `pnpm build` attempts
- both `claude` and `codex` CLIs installed in the image
- an internal Docker daemon for NanoClaw agent containers

Use this add-on if you want a terminal-first NanoClaw environment inside Home Assistant.

See [DOCS.md](DOCS.md) for setup and [../SECURITY.md](../SECURITY.md) for the security model.
