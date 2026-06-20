#!/usr/bin/env bash
# Zhizi — uninstaller. Undoes what install.sh --pro / os-setup.sh put in place.
#
# IMPORTANT: this NEVER deletes your ~/zhizi/ working folder or your notes.
# Your USER/CONTEXT/TASKS/LOG/HANDOFF content is yours and is left untouched.
set -euo pipefail

PLUGIN="zhizi-agent-os@starshard"
ZHIZI_HOME="${ZHIZI_HOME:-$HOME/zhizi}"

say() { printf '\033[1;36m▶ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m! %s\033[0m\n' "$*"; }

say "Zhizi uninstaller"

# 1) Remove the Claude Code plugin (best-effort) ----------------------------
if command -v claude >/dev/null 2>&1; then
  say "Removing Claude Code plugin…"
  claude plugin uninstall "$PLUGIN" 2>/dev/null || warn "plugin uninstall skipped (not installed, or remove via '/plugin' inside Claude Code)"
else
  warn "claude not on PATH — skipping plugin removal."
fi

# 2) Remove ~/.local/bin helpers that os-setup.sh installed -----------------
HERE="$(cd "$(dirname "$0")" 2>/dev/null && pwd || echo "")"
PAYLOAD="$HERE/payload"
if [ -d "$PAYLOAD/bin" ] && [ -n "$(ls -A "$PAYLOAD/bin" 2>/dev/null)" ]; then
  say "Removing helper scripts from ~/.local/bin…"
  for f in "$PAYLOAD/bin"/*; do
    target="$HOME/.local/bin/$(basename "$f")"
    [ -e "$target" ] && rm -f "$target" && say "  removed $(basename "$f")"
  done
else
  warn "No payload/bin helpers to remove."
fi

# 3) Unload + remove daemons (launchd / systemd) from payload ---------------
if [ -d "$PAYLOAD/launchd" ] && [ -n "$(ls -A "$PAYLOAD/launchd" 2>/dev/null)" ]; then
  say "Unloading launchd agents…"
  for p in "$PAYLOAD/launchd"/*.plist; do
    name="$(basename "$p")"
    target="$HOME/Library/LaunchAgents/$name"
    if [ -e "$target" ]; then
      launchctl unload -w "$target" 2>/dev/null || true
      rm -f "$target" && say "  removed $name"
    fi
  done
fi
if [ -d "$PAYLOAD/systemd" ] && [ -n "$(ls -A "$PAYLOAD/systemd" 2>/dev/null)" ]; then
  say "Removing systemd --user units…"
  for u in "$PAYLOAD/systemd"/*; do
    name="$(basename "$u")"
    target="$HOME/.config/systemd/user/$name"
    if [ -e "$target" ]; then
      systemctl --user stop "$name" 2>/dev/null || true
      systemctl --user disable "$name" 2>/dev/null || true
      rm -f "$target" && say "  removed $name"
    fi
  done
  systemctl --user daemon-reload 2>/dev/null || true
fi

say "Uninstall complete."
printf '\n  Your working folder is UNTOUCHED: %s\n' "$ZHIZI_HOME"
printf '  Your notes and data are still there. Delete it yourself only if you want to.\n\n'
