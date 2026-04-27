# Security Risks & Disclaimer

This document outlines the main security risks of running the `NanoClaw Assistant` Home Assistant add-on.

**By installing and using this add-on, you acknowledge and accept the risks described below.**

## Disclaimer

This add-on is provided **"AS IS"**, without warranty of any kind, under the [MIT License](LICENSE).

The authors and contributors are **not responsible** for damage, data loss, security breach, unauthorized access, financial loss, or other harm caused by installing, configuring, or using this add-on.

You use this add-on entirely at your own risk.

## Main risks

### 1. Elevated add-on privileges

This add-on runs with:
- `full_access: true`
- `apparmor: false`

That is a high-privilege runtime profile for a Home Assistant add-on.

Risk:
- if NanoClaw or code it launches is compromised, the blast radius is larger than a normal restricted add-on
- container isolation provided by Home Assistant add-on restrictions is deliberately reduced

Mitigation:
- treat this add-on as experimental infrastructure, not a low-risk household utility
- do not install it on a Home Assistant instance you cannot afford to rebuild

### 2. Internal Docker daemon

NanoClaw needs to create containers for agent workloads. Because Home Assistant documents `docker_api` as read-only, this add-on starts its own internal `dockerd`.

Risk:
- agent workloads can create and run containers from inside the add-on
- misconfiguration or malicious prompts may lead to unexpected container activity
- resource consumption can spike quickly on low-power hardware

Mitigation:
- monitor `/config/nanoclaw/logs/dockerd.log`
- keep `max_concurrent_containers` low, especially on Raspberry Pi 3
- do not treat this add-on as isolated from the rest of your trusted environment

### 3. Coding CLI authentication and credentials

The add-on installs both `Claude Code` and `Codex`, and you authenticate the CLI you want to use from the terminal.

Risk:
- credentials or session data stored in the add-on runtime could be exposed if the add-on is compromised
- any code path that can act as your authenticated NanoClaw/CLI session should be treated as sensitive

Mitigation:
- only authenticate in an environment you trust
- review what gets persisted under `/config/nanoclaw`
- rotate or revoke credentials if you suspect compromise

### 4. Third-party code and supply chain

This add-on pulls and runs upstream NanoClaw plus its dependencies.

Risk:
- upstream code changes can alter runtime behavior
- npm dependencies or install scripts can introduce unwanted behavior
- any manual packages or scripts you run in the terminal add more risk

Mitigation:
- pin to a branch or tag you trust
- inspect changes before switching `nanoclaw_repo_ref`
- monitor the bootstrap and runtime logs after updates

### 5. Prompt injection and agent behavior

NanoClaw is an agentic system. If it processes untrusted content, it may be manipulated by prompt injection or hostile instructions embedded in external data.

Risk:
- the agent may take actions you did not intend
- the agent may create containers, run commands, or expose data through its workflows

Mitigation:
- avoid giving the agent broad access to untrusted inputs until you understand its behavior
- review logs and test with narrow scopes first

### 6. Persistent writable state

The add-on stores its checkout, logs, and Docker data under `/config/nanoclaw`.

Risk:
- malicious or broken state can survive add-on restarts
- failed installs or broken images may leave behind large amounts of data

Mitigation:
- back up Home Assistant before experimenting
- know how to remove `/config/nanoclaw` if you want a clean reset
- watch disk usage on low-storage systems

## Recommended operational posture

- use this add-on only for testing and controlled experimentation
- prefer a dedicated Home Assistant environment if possible
- keep backups before upgrades or large changes
- keep concurrency low on Raspberry Pi 3
- review logs after every install or update

## Reporting security issues

If you discover a security issue in this repository, report it responsibly through GitHub rather than posting exploit details in a public issue first.
