#!/usr/bin/env bash
set -euo pipefail

OPTIONS_FILE="/data/options.json"
if [ ! -f "$OPTIONS_FILE" ]; then
  echo "Missing $OPTIONS_FILE (add-on options)."
  exit 1
fi

TZNAME=$(jq -r '.timezone // "UTC"' "$OPTIONS_FILE")
ENABLE_TERMINAL=$(jq -r '.enable_terminal // true' "$OPTIONS_FILE")
TERMINAL_PORT_RAW=$(jq -r '.terminal_port // 7682' "$OPTIONS_FILE")
ASSISTANT_NAME=$(jq -r '.assistant_name // "Andy"' "$OPTIONS_FILE")
AI_CLI_PROVIDER=$(jq -r '.ai_cli_provider // "both"' "$OPTIONS_FILE")
BOOTSTRAP_REPOSITORY=$(jq -r '.bootstrap_repository // true' "$OPTIONS_FILE")
NANOCLAW_REPO_URL=$(jq -r '.nanoclaw_repo_url // "https://github.com/qwibitai/nanoclaw.git"' "$OPTIONS_FILE")
NANOCLAW_REPO_REF=$(jq -r '.nanoclaw_repo_ref // "main"' "$OPTIONS_FILE")
AUTO_START_NANOCLAW=$(jq -r '.auto_start_nanoclaw // true' "$OPTIONS_FILE")
MAX_CONCURRENT_CONTAINERS=$(jq -r '.max_concurrent_containers // 2' "$OPTIONS_FILE")
ONECLI_URL=$(jq -r '.onecli_url // empty' "$OPTIONS_FILE")
NANOCLAW_ENV_VARS_TYPE=$(jq -r 'if .nanoclaw_env_vars == null then "null" else (.nanoclaw_env_vars | type) end' "$OPTIONS_FILE")
NANOCLAW_ENV_VARS_JSON=$(jq -c '.nanoclaw_env_vars // []' "$OPTIONS_FILE")

if [[ "$TERMINAL_PORT_RAW" =~ ^[0-9]+$ ]] && [ "$TERMINAL_PORT_RAW" -ge 1024 ] && [ "$TERMINAL_PORT_RAW" -le 65535 ]; then
  TERMINAL_PORT="$TERMINAL_PORT_RAW"
else
  echo "WARN: Invalid terminal_port '$TERMINAL_PORT_RAW'. Falling back to 7682."
  TERMINAL_PORT="7682"
fi

export TZ="$TZNAME"
export HOME="/config"
export ASSISTANT_NAME
export MAX_CONCURRENT_CONTAINERS
export AI_CLI_PROVIDER
if [ -n "$ONECLI_URL" ]; then
  export ONECLI_URL
fi

NANOCLAW_ROOT="/config/nanoclaw"
APP_DIR="$NANOCLAW_ROOT/app"
LOG_DIR="$NANOCLAW_ROOT/logs"
LOG_FILE="$LOG_DIR/nanoclaw.log"
BOOTSTRAP_LOG="$LOG_DIR/bootstrap.log"
DOCKER_LOG="$LOG_DIR/dockerd.log"
DOCKER_DATA_ROOT="$NANOCLAW_ROOT/docker"
TTYD_PID=""
NGINX_PID=""
NANO_PID=""
DOCKER_PID=""

mkdir -p "$NANOCLAW_ROOT" "$LOG_DIR" "$DOCKER_DATA_ROOT" /config/.config /run/nginx

try_export_env_var() {
  local key="$1"
  local value="$2"

  if ! [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    echo "WARN: Invalid nanoclaw_env_vars key '$key', skipping"
    return 0
  fi

  case "$key" in
    HOME|PATH|PWD|OLDPWD|SHLVL|TZ)
      echo "WARN: Reserved env var '$key' cannot be overridden, skipping"
      return 0
      ;;
  esac

  export "$key=$value"
}

if [ "$NANOCLAW_ENV_VARS_TYPE" = "array" ] && [ "$NANOCLAW_ENV_VARS_JSON" != "[]" ]; then
  while IFS= read -r -d '' key && IFS= read -r -d '' value; do
    try_export_env_var "$key" "$value"
  done < <(printf '%s' "$NANOCLAW_ENV_VARS_JSON" | jq -j '.[] | select((type == "object") and ((.name | type) == "string") and (has("value"))) | .name, "\u0000", (.value | tostring), "\u0000"')
fi

shutdown() {
  if [ -n "$DOCKER_PID" ] && kill -0 "$DOCKER_PID" >/dev/null 2>&1; then
    kill -TERM "$DOCKER_PID" >/dev/null 2>&1 || true
    wait "$DOCKER_PID" 2>/dev/null || true
  fi

  if [ -n "$NGINX_PID" ] && kill -0 "$NGINX_PID" >/dev/null 2>&1; then
    kill -TERM "$NGINX_PID" >/dev/null 2>&1 || true
    wait "$NGINX_PID" 2>/dev/null || true
  fi

  if [ -n "$TTYD_PID" ] && kill -0 "$TTYD_PID" >/dev/null 2>&1; then
    kill -TERM "$TTYD_PID" >/dev/null 2>&1 || true
    wait "$TTYD_PID" 2>/dev/null || true
  fi

  if [ -n "$NANO_PID" ] && kill -0 "$NANO_PID" >/dev/null 2>&1; then
    kill -TERM "$NANO_PID" >/dev/null 2>&1 || true
    wait "$NANO_PID" 2>/dev/null || true
  fi
}

trap shutdown INT TERM

start_internal_docker() {
  if ! command -v dockerd >/dev/null 2>&1; then
    echo "WARN: dockerd not installed in image"
    return 1
  fi

  if [ -S /var/run/docker.sock ]; then
    rm -f /var/run/docker.sock || true
  fi

  echo "INFO: Starting internal Docker daemon for NanoClaw ..."
  dockerd \
    --host=unix:///var/run/docker.sock \
    --data-root "$DOCKER_DATA_ROOT" \
    --exec-root /tmp/nanoclaw-docker-exec \
    --pidfile /tmp/nanoclaw-dockerd.pid \
    --storage-driver=vfs \
    >>"$DOCKER_LOG" 2>&1 &
  DOCKER_PID=$!

  for _i in $(seq 1 30); do
    if docker version >/dev/null 2>&1; then
      echo "INFO: Internal Docker daemon is ready"
      return 0
    fi
    sleep 1
  done

  echo "WARN: Internal Docker daemon did not become ready; see $DOCKER_LOG"
  return 1
}

REPO_STATUS="not bootstrapped"
SETUP_HINT="bash nanoclaw.sh"
BUILD_READY="false"

case "$AI_CLI_PROVIDER" in
  claude|codex|both) ;;
  *)
    echo "WARN: Invalid ai_cli_provider '$AI_CLI_PROVIDER'. Falling back to 'both'."
    AI_CLI_PROVIDER="both"
    export AI_CLI_PROVIDER
    ;;
esac

if [ ! -d "$APP_DIR/.git" ]; then
  if [ "$BOOTSTRAP_REPOSITORY" = "true" ] || [ "$BOOTSTRAP_REPOSITORY" = "1" ]; then
    echo "INFO: Cloning NanoClaw repository into $APP_DIR ..."
    rm -rf "$APP_DIR"
    if git clone --branch "$NANOCLAW_REPO_REF" --single-branch "$NANOCLAW_REPO_URL" "$APP_DIR" >>"$BOOTSTRAP_LOG" 2>&1; then
      REPO_STATUS="cloned from $NANOCLAW_REPO_REF"
    else
      REPO_STATUS="clone failed, see bootstrap.log"
      SETUP_HINT="git clone $NANOCLAW_REPO_URL $APP_DIR"
    fi
  else
    REPO_STATUS="bootstrap disabled"
  fi
else
  REPO_STATUS="existing checkout detected"
fi

if [ -d "$APP_DIR" ]; then
  git config --global --add safe.directory "$APP_DIR" >/dev/null 2>&1 || true
fi

DOCKER_STATUS="internal docker unavailable"
if start_internal_docker; then
  DOCKER_STATUS="internal dockerd running"
fi

CLAUDE_STATUS="not installed"
if command -v claude >/dev/null 2>&1; then
  CLAUDE_STATUS="installed"
fi

CODEX_STATUS="not installed"
if command -v codex >/dev/null 2>&1; then
  CODEX_STATUS="installed"
fi

CLI_STATUS_DETAIL="provider=${AI_CLI_PROVIDER}"
case "$AI_CLI_PROVIDER" in
  claude)
    CLI_STATUS_DETAIL="${CLI_STATUS_DETAIL}; login with: claude"
    ;;
  codex)
    CLI_STATUS_DETAIL="${CLI_STATUS_DETAIL}; login with: codex --login"
    ;;
  both)
    CLI_STATUS_DETAIL="${CLI_STATUS_DETAIL}; login with: claude or codex --login"
    ;;
esac

RUNTIME_STATUS="manual setup required"
if [ -d "$APP_DIR" ] && [ -f "$APP_DIR/package.json" ]; then
  if [ ! -d "$APP_DIR/node_modules" ]; then
    echo "INFO: Installing NanoClaw dependencies ..."
    if ! (cd "$APP_DIR" && pnpm install --frozen-lockfile >>"$BOOTSTRAP_LOG" 2>&1); then
      if ! (cd "$APP_DIR" && pnpm install >>"$BOOTSTRAP_LOG" 2>&1); then
        RUNTIME_STATUS="dependency install failed, open terminal"
      fi
    fi
  fi

  if [ -d "$APP_DIR/node_modules" ] && [ ! -f "$APP_DIR/dist/index.js" ]; then
    echo "INFO: Building NanoClaw ..."
    if ! (cd "$APP_DIR" && pnpm build >>"$BOOTSTRAP_LOG" 2>&1); then
      RUNTIME_STATUS="build failed, open terminal"
    fi
  fi

  if [ -f "$APP_DIR/nanoclaw.sh" ]; then
    SETUP_HINT="bash nanoclaw.sh"
  elif [ -f "$APP_DIR/package.json" ]; then
    SETUP_HINT="pnpm setup"
  fi

  if [ -f "$APP_DIR/dist/index.js" ]; then
    BUILD_READY="true"
  fi

  if [ "$AUTO_START_NANOCLAW" = "true" ] || [ "$AUTO_START_NANOCLAW" = "1" ]; then
    if [ "$BUILD_READY" = "true" ]; then
      echo "INFO: Starting NanoClaw runtime ..."
      (
        cd "$APP_DIR"
        exec pnpm start >>"$LOG_FILE" 2>&1
      ) &
      NANO_PID=$!
      RUNTIME_STATUS="running (PID $NANO_PID)"
    else
      RUNTIME_STATUS="build incomplete, open terminal and run setup"
    fi
  else
    RUNTIME_STATUS="autostart disabled"
  fi
fi

export TERMINAL_PORT
export REPO_STATUS
export DOCKER_STATUS
export CLAUDE_STATUS
export CODEX_STATUS
export CLI_STATUS_DETAIL
export RUNTIME_STATUS
export SETUP_HINT
export APP_DIR
export LOG_FILE
export BOOTSTRAP_LOG
export DOCKER_LOG

python3 /render_landing.py

if [ "$ENABLE_TERMINAL" = "true" ] || [ "$ENABLE_TERMINAL" = "1" ]; then
  echo "INFO: Starting ttyd on 127.0.0.1:${TERMINAL_PORT}"
  ttyd -W -i 127.0.0.1 -p "${TERMINAL_PORT}" -b /terminal bash &
  TTYD_PID=$!
fi

echo "INFO: Starting nginx ingress UI"
nginx -g 'daemon off;' &
NGINX_PID=$!

wait -n "$NGINX_PID" ${TTYD_PID:+$TTYD_PID} ${NANO_PID:+$NANO_PID}
