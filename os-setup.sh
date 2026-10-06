#!/usr/bin/env bash
# Zhizi Agent OS — Part C: OS-level setup (helpers + daemons).
# Runs OUTSIDE Claude Code. Installs ONLY what is vendored in payload/ (reviewed
# before each release; empty today).
#
# HARD RULE: this script copies from a vendored, privacy-scrubbed `payload/`
# directory that lives IN THIS REPO — never from the maintainer's live ~/bin or
# ~/.agent-control-plane. If payload/ is empty, nothing OS-level is installed
# yet (the allowlist has not been ratified). That is the correct safe default.
set -euo pipefail
PLATFORM="${1:-$(uname -s | tr '[:upper:]' '[:lower:]')}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD="$HERE/payload"

say() { printf '\033[1;36m  ▸ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }

mkdir -p "$HOME/.local/bin"

# 1) Helper scripts (allowlist) ---------------------------------------------
if [ -d "$PAYLOAD/bin" ] && [ -n "$(ls -A "$PAYLOAD/bin" 2>/dev/null)" ]; then
  say "Installing helper scripts → ~/.local/bin"
  for f in "$PAYLOAD/bin"/*; do
    install -m 0755 "$f" "$HOME/.local/bin/$(basename "$f")"
  done
else
  warn "payload/bin is empty — OS helper allowlist not ratified yet, skipping."
fi

# 2) Background daemons (per-platform) --------------------------------------
case "$PLATFORM" in
  macos)
    if [ -d "$PAYLOAD/launchd" ] && [ -n "$(ls -A "$PAYLOAD/launchd" 2>/dev/null)" ]; then
      say "Registering launchd agents"
      mkdir -p "$HOME/Library/LaunchAgents"
      for p in "$PAYLOAD/launchd"/*.plist; do
        cp "$p" "$HOME/Library/LaunchAgents/"
        launchctl load -w "$HOME/Library/LaunchAgents/$(basename "$p")" 2>/dev/null || true
      done
    else
      warn "payload/launchd empty — no daemons to register."
    fi
    ;;
  linux)
    if [ -d "$PAYLOAD/systemd" ] && [ -n "$(ls -A "$PAYLOAD/systemd" 2>/dev/null)" ]; then
      say "Installing systemd --user units"
      mkdir -p "$HOME/.config/systemd/user"
      for u in "$PAYLOAD/systemd"/*; do
        cp "$u" "$HOME/.config/systemd/user/"
      done
      systemctl --user daemon-reload 2>/dev/null || true
    else
      warn "payload/systemd empty — no daemons to register."
    fi
    ;;
esac

# 3) Control-plane scaffolding (empty dirs only, no content) ----------------
say "Scaffolding ~/.agent-control-plane (empty dirs)"
mkdir -p "$HOME/.agent-control-plane"/{task-ledger,capability-registry,onboarding}

say "OS-level setup complete."
