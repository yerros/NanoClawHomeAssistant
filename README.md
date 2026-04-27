# NanoClaw Assistant – Home Assistant Add-on

This repository contains an experimental Home Assistant add-on that wraps **NanoClaw** for **Home Assistant OS (HAOS)**.

## Status

This repository is experimental.

It is intended for users who want to test NanoClaw inside Home Assistant with:
- a persistent NanoClaw checkout
- a browser terminal
- an internal Docker daemon for NanoClaw agent containers
- Claude Code installed inside the add-on

## Documentation

- **[Full documentation →](DOCS.md)** — installation, configuration, first boot, and troubleshooting
- **[Security Risks & Disclaimer →](SECURITY.md)** — important risks to understand before using this add-on

## Install

1. Home Assistant → **Settings → Add-ons → Add-on store**
2. **⋮ → Repositories**
3. Add this repo:
   - `https://github.com/techartdev/NanoClawHomeAssistant`
4. Install **NanoClaw Assistant**

## Included Add-on

- **NanoClaw Assistant** — terminal-first wrapper around upstream NanoClaw for Home Assistant
