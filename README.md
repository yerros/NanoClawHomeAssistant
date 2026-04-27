# NanoClaw Assistant

Experimental Home Assistant add-on for running **NanoClaw** on **Home Assistant OS (HAOS)**.

## Status

This repository is experimental and terminal-first.

It is meant for users who want to test NanoClaw inside Home Assistant with:
- a persistent NanoClaw checkout under `/config/nanoclaw/app`
- an embedded browser terminal
- both `Claude Code` and `Codex` installed in the add-on
- an internal Docker daemon for NanoClaw agent containers

It is not yet a polished one-click NanoClaw port.

## What is in this repository

- `nanoclaw_assistant/` — the Home Assistant add-on
- `repository.yaml` — add-on repository metadata for Home Assistant
- `DOCS.md` — install, configuration, first boot, and troubleshooting guide
- `SECURITY.md` — security model, tradeoffs, and operational risks

## Documentation

- **[Full documentation →](DOCS.md)** — installation, configuration, first boot, and troubleshooting
- **[Security Risks & Disclaimer →](SECURITY.md)** — important risks to understand before using this add-on

## Install

1. In Home Assistant, go to **Settings → Add-ons → Add-on store**
2. Open **⋮ → Repositories**
3. Add this repository:
   - `https://github.com/yerros/NanoClawHomeAssistant`
4. Install **NanoClaw Assistant**
5. Open the add-on **Configuration** tab before first boot

## Upstream references

- NanoClaw: `https://github.com/qwibitai/nanoclaw`
- Claude Code docs: `https://docs.anthropic.com/en/docs/claude-code/getting-started`
- Codex CLI docs: `https://help.openai.com/en/articles/11096431-openai-codex-ci-getting-started`
