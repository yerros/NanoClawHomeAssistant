# Changelog

All notable changes to the NanoClaw Assistant Home Assistant add-on will be documented in this file.

## [0.1.1] - 2026-04-27

### Added
- Initial experimental NanoClaw Home Assistant add-on scaffold.
- Ingress landing page and optional web terminal via ttyd.
- Persistent checkout under `/config/nanoclaw/app`.
- Internal Docker daemon bootstrap for NanoClaw's container-based runtime.
- Automatic dependency install and build attempt on first boot.
- Dual CLI support in the add-on image: `Claude Code` and `Codex`.
- New add-on option `ai_cli_provider` to declare the preferred coding CLI in the runtime and UI.

### Notes
- This add-on is experimental and terminal-first.
- Upstream NanoClaw setup still needs to be completed from the terminal.
