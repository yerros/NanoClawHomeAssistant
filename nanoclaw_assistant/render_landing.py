#!/usr/bin/env python3
import os
from pathlib import Path


def main():
    tpl = Path("/etc/nginx/nginx.conf.tpl").read_text()
    landing_tpl = Path("/etc/nginx/landing.html.tpl").read_text()

    terminal_port = os.environ.get("TERMINAL_PORT", "7682")
    values = {
        "__TERMINAL_PORT__": terminal_port,
        "__ASSISTANT_NAME__": os.environ.get("ASSISTANT_NAME", "Andy"),
        "__REPO_STATUS__": os.environ.get("REPO_STATUS", "unknown"),
        "__DOCKER_STATUS__": os.environ.get("DOCKER_STATUS", "unknown"),
        "__CLAUDE_STATUS__": os.environ.get("CLAUDE_STATUS", "unknown"),
        "__CODEX_STATUS__": os.environ.get("CODEX_STATUS", "unknown"),
        "__CLI_STATUS_DETAIL__": os.environ.get("CLI_STATUS_DETAIL", "provider=both"),
        "__RUNTIME_STATUS__": os.environ.get("RUNTIME_STATUS", "manual setup required"),
        "__SETUP_HINT__": os.environ.get("SETUP_HINT", "Open the terminal and run bash nanoclaw.sh"),
        "__APP_DIR__": os.environ.get("APP_DIR", "/config/nanoclaw/app"),
        "__LOG_FILE__": os.environ.get("LOG_FILE", "/config/nanoclaw/logs/nanoclaw.log"),
        "__BOOTSTRAP_LOG__": os.environ.get("BOOTSTRAP_LOG", "/config/nanoclaw/logs/bootstrap.log"),
        "__DOCKER_LOG__": os.environ.get("DOCKER_LOG", "/config/nanoclaw/logs/dockerd.log"),
    }

    conf = tpl.replace("__TERMINAL_PORT__", terminal_port)
    Path("/etc/nginx/nginx.conf").write_text(conf)

    landing = landing_tpl
    for key, value in values.items():
      landing = landing.replace(key, value)

    out_dir = Path("/etc/nginx/html")
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "index.html"
    out_file.write_text(landing)

    try:
        out_dir.chmod(0o755)
        out_file.chmod(0o644)
    except Exception:
        pass


if __name__ == "__main__":
    main()
