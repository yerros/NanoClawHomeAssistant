# NanoClaw Assistant

Experimental Home Assistant add-on wrapper for NanoClaw.

This add-on provides:
- a persistent NanoClaw checkout under `/config/nanoclaw/app`
- a browser terminal via `ttyd`
- automatic `pnpm install` and `pnpm build` attempts
- an internal Docker daemon for NanoClaw's container runtime

See [DOCS.md](DOCS.md) for installation and usage notes.
