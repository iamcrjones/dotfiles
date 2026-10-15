#!/usr/bin/env bash
# Installs the PR review watcher as a launchd job that checks every 5 minutes.
# Safe to re-run: it rewrites the plist and restarts the job.
#
#   install.sh               install (or reinstall) and start
#   install.sh --uninstall   stop, disable and remove the job (keeps reports)
#
# PR_WATCHER_INTERVAL=<seconds> overrides the 300s interval.
set -euo pipefail

LABEL="au.com.trilogycare.pr-review-watcher"
INTERVAL="${PR_WATCHER_INTERVAL:-300}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DATA="$HOME/.claude/pr-review-watcher"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"

die() { echo "error: $*" >&2; exit 1; }

if [[ "${1:-}" == "--uninstall" ]]; then
  launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
  launchctl disable "$DOMAIN/$LABEL"
  rm -f "$PLIST"
  echo "Uninstalled $LABEL. Reports are still in $DATA/reports."
  exit 0
fi

[[ "$(uname)" == "Darwin" ]] || die "macOS only (uses launchd and osascript)"
for cmd in claude gh git jq osascript; do
  command -v "$cmd" >/dev/null || die "'$cmd' not found on PATH"
done
gh auth status >/dev/null 2>&1 || die "gh isn't logged in; run: gh auth login"
[[ -f "$HOME/.claude/commands/review.md" ]] || die "~/.claude/commands/review.md (the four-pass /review command) is missing"

chmod +x "$SCRIPT_DIR/run.sh" "$SCRIPT_DIR/read.sh"
mkdir -p "$DATA/reports/read" "$DATA/repos" "$HOME/Library/LaunchAgents"
touch "$DATA/reviewed.txt"

# launchd starts jobs with a bare PATH, so bake in where the tools live on this machine
launch_path=""
for cmd in claude gh git jq node; do
  dir="$(dirname "$(command -v "$cmd" 2>/dev/null || echo /usr/bin/true)")"
  [[ ":$launch_path:" == *":$dir:"* ]] || launch_path="${launch_path:+$launch_path:}$dir"
done
launch_path="$launch_path:/usr/bin:/bin:/usr/sbin:/sbin"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array><string>/bin/zsh</string><string>$SCRIPT_DIR/run.sh</string></array>
  <key>EnvironmentVariables</key>
  <dict><key>PATH</key><string>$launch_path</string></dict>
  <key>StartInterval</key><integer>$INTERVAL</integer>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>$DATA/watcher.log</string>
  <key>StandardErrorPath</key><string>$DATA/watcher.log</string>
</dict>
</plist>
EOF
plutil -lint "$PLIST" >/dev/null || die "generated plist is invalid: $PLIST"

launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
launchctl enable "$DOMAIN/$LABEL"
# bootout finishes asynchronously, so retry bootstrap briefly
for _ in 1 2 3 4 5; do
  launchctl bootstrap "$DOMAIN" "$PLIST" 2>/dev/null && break
  sleep 1
done
launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1 || die "launchd didn't load the job; try: launchctl bootstrap $DOMAIN $PLIST"

echo "Installed $LABEL: checks every $((INTERVAL / 60)) min, first check now."
echo "  script:  $SCRIPT_DIR/run.sh"
echo "  reports: $DATA/reports"
echo "  log:     $DATA/watcher.log"
echo "Tip: set Script Editor notifications to Persistent in System Settings → Notifications so they stay on screen."
