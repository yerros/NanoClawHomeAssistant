<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>NanoClaw Assistant</title>
  <style>
    body{font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;margin:0;padding:16px;background:#0b1220;color:#e5e7eb}
    .card{max-width:980px;margin:0 auto;background:#111827;border:1px solid #1f2937;border-radius:12px;padding:18px}
    .row{display:flex;gap:12px;flex-wrap:wrap}
    .btn{display:inline-block;padding:10px 14px;border-radius:10px;background:#2563eb;color:#fff;text-decoration:none}
    .btn.secondary{background:#374151}
    .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:10px;margin:14px 0}
    .item{background:#0f172a;border:1px solid #1f2937;border-radius:10px;padding:12px}
    code,pre{background:#020617;border-radius:8px}
    code{padding:2px 6px}
    pre{padding:10px;overflow:auto}
    .note{background:#3f2a05;border:1px solid #92400e;color:#fde68a;padding:12px;border-radius:10px;margin:14px 0}
    .ok{color:#86efac}
    .warn{color:#fbbf24}
  </style>
</head>
<body>
  <div class="card">
    <h2 style="margin:0 0 4px 0">NanoClaw Assistant</h2>
    <p style="margin:0 0 12px 0;color:#9ca3af">Experimental Home Assistant wrapper for NanoClaw. This add-on focuses on terminal-first setup and runs an internal Docker daemon for NanoClaw containers.</p>

    <div class="row">
      <a class="btn" href="./terminal/" target="_self">Open Terminal</a>
      <a class="btn secondary" href="https://github.com/qwibitai/nanoclaw" target="_blank" rel="noopener noreferrer">NanoClaw Upstream</a>
    </div>

    <div class="grid">
      <div class="item"><b>Assistant name</b><br><span class="ok">__ASSISTANT_NAME__</span></div>
      <div class="item"><b>Repository</b><br>__REPO_STATUS__</div>
      <div class="item"><b>Docker access</b><br>__DOCKER_STATUS__</div>
      <div class="item"><b>Claude Code</b><br>__CLAUDE_STATUS__</div>
      <div class="item"><b>Runtime</b><br>__RUNTIME_STATUS__</div>
    </div>

    <div class="note">
      NanoClaw upstream expects Docker and Claude Code. In this add-on, first-time setup is still done from the terminal.
    </div>

    <h3>First boot</h3>
    <pre><code>cd __APP_DIR__
__SETUP_HINT__</code></pre>

    <h3>Autostart behavior</h3>
    <p>If the repository is bootstrapped, dependencies are installed, and <code>dist/index.js</code> exists, the add-on will try to start NanoClaw automatically. Logs are written to:</p>
    <pre><code>Runtime:   __LOG_FILE__
Bootstrap: __BOOTSTRAP_LOG__
Docker:    __DOCKER_LOG__</code></pre>

    <h3>Important limitations</h3>
    <ul>
      <li>This wrapper does not replace NanoClaw's upstream setup flow.</li>
      <li>This add-on runs an internal Docker daemon and therefore needs elevated add-on privileges.</li>
      <li>Pi 3 performance will be limited, especially during <code>pnpm install</code>, first build, and agent container startup.</li>
    </ul>
  </div>
</body>
</html>
