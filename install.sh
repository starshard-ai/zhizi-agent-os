#!/usr/bin/env bash
# Zhizi — one-command installer.
#
#   curl -fsSL https://raw.githubusercontent.com/starshard-ai/zhizi-agent-os/main/install.sh | bash          # default: Lite
#   curl -fsSL https://raw.githubusercontent.com/starshard-ai/zhizi-agent-os/main/install.sh | bash -s -- --pro   # + plugin/OS
#
# TWO MODES:
#   default (Lite) : drops a warm, non-technical personal-assistant ruleset
#                    into ~/zhizi/ (override with ZHIZI_HOME). No plugins,
#                    no daemons, no global settings touched.
#   --pro          : ALSO wires the Claude-native plugin marketplace
#                    (skills + hooks + subagents + MCP) and runs os-setup.sh
#                    (curated OS-level helpers/daemons). For technical users.
#
# DESIGN INVARIANTS (do not break):
#   - BYOK only. Never ships or asks for anyone else's API keys.
#   - Privacy-clean. Ships ONLY the files in this repo (templates/lite/,
#     plugin/, and the three scripts). No secrets, no people-registry, no
#     private memories, no owner-identity CLAUDE.md. payload/ stays empty
#     until its contents have been reviewed.
#   - Idempotent + reversible. Re-runnable; uninstall.sh undoes it.
set -euo pipefail

REPO_RAW="${ZHIZI_REPO_RAW:-https://raw.githubusercontent.com/starshard-ai/zhizi-agent-os/main}"
MARKETPLACE="${ZHIZI_MARKETPLACE:-starshard-ai/zhizi-agent-os}"
PLUGIN="zhizi-agent-os@starshard"
ZHIZI_HOME="${ZHIZI_HOME:-$HOME/zhizi}"

# Files the installer OWNS and refreshes on every run (the ruleset). Everything
# else in the template (USER/CONTEXT/TASKS/LOG/HANDOFF) is user data: created
# once, then never clobbered.
RULESET_FILES="CLAUDE.md AGENTS.md README.md FIRST_PROMPT.txt"
DATA_FILES="USER.md CONTEXT.md TASKS.md LOG.md HANDOFF.md ACCEPTANCE.md"

MODE="lite"
for arg in "$@"; do
  case "$arg" in
    --pro)  MODE="pro" ;;
    --lite) MODE="lite" ;;
    *) printf 'Unknown flag: %s (use --pro or --lite)\n' "$arg" >&2; exit 2 ;;
  esac
done

say() { printf '\033[1;36m▶ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m! %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

# 1) Preflight ---------------------------------------------------------------
say "Zhizi installer (${MODE} mode)"
if ! command -v claude >/dev/null 2>&1; then
  die "Claude Code (the 'claude' command) not found. Install it first:
      curl -fsSL https://claude.ai/install.sh | bash
    then open a NEW terminal window and re-run this installer.
    (Docs: https://code.claude.com/docs/en/setup — the desktop app alone does not put 'claude' on your PATH.)"
fi
say "Claude Code: $(claude --version 2>/dev/null || echo present)"

OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM=macos ;;
  Linux)  PLATFORM=linux ;;
  *) die "Unsupported OS: $OS (macOS / Linux only for now; on Windows run this inside WSL)." ;;
esac
say "Platform: $PLATFORM"

# 2) BYOK check (we never ship keys) ----------------------------------------
# Informational only: the install itself does not need a login. `claude auth
# status` is used instead of looking for ~/.claude/.credentials.json because on
# macOS Claude Code keeps credentials in the Keychain, not in that file.
if [ -z "${ANTHROPIC_API_KEY:-}" ] && ! claude auth status 2>/dev/null | grep -q '"loggedIn": *true'; then
  say "Not logged in to Claude Code yet. That's fine: you'll be asked to log in"
  say "with your own account the first time you run 'claude'. No need to re-run this installer."
fi

# 3) Lite template — ALWAYS installed (both modes) --------------------------
# Only treat this as a local checkout when the script is a real file on disk.
# Under `curl ... | bash` there is no script file ($0 is "bash"), and falling
# back to dirname "$0" would silently use whatever is in the current directory.
HERE=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
TEMPLATE_DIR=""
if [ -n "$HERE" ] && [ -d "$HERE/templates/lite" ]; then
  TEMPLATE_DIR="$HERE/templates/lite"
fi

say "Setting up your Zhizi workspace → $ZHIZI_HOME"
mkdir -p "$ZHIZI_HOME"

copy_one() {
  # copy_one <filename> <overwrite:yes|no>
  local f="$1" overwrite="$2" src dst
  dst="$ZHIZI_HOME/$f"
  if [ "$overwrite" = "no" ] && [ -e "$dst" ]; then
    return 0  # preserve user data
  fi
  if [ -n "$TEMPLATE_DIR" ] && [ -f "$TEMPLATE_DIR/$f" ]; then
    cp "$TEMPLATE_DIR/$f" "$dst"
  else
    curl -fsSL "$REPO_RAW/templates/lite/$f" -o "$dst" 2>/dev/null \
      || warn "could not fetch $f (skipped)"
  fi
}

# Ruleset files: refreshed every run (installer owns them).
for f in $RULESET_FILES; do copy_one "$f" yes; done
# Data files: created once, never clobbered (user's own content stays).
for f in $DATA_FILES; do copy_one "$f" no; done

if [ "$MODE" = "lite" ]; then
  say "Done 🌿  Your personal assistant is ready."
  printf '\n  Next step — just run:\n\n      cd %s && claude\n\n' "$ZHIZI_HOME"
  say "Want the technical (Pro) add-ons later? Re-run with: --pro"
  exit 0
fi

# 4) --pro ONLY — Part A: Claude-native payload via plugin marketplace -------
# Errors are shown, not hidden, and any failure changes the final message.
PRO_FAIL=0
say "Pro mode: wiring plugin marketplace (skills + hooks + subagents + MCP)…"
if claude plugin marketplace add "$MARKETPLACE"; then
  :
elif claude plugin marketplace update starshard; then
  say "marketplace 'starshard' was already added; refreshed it"
else
  warn "could not add the plugin marketplace ($MARKETPLACE) — see the error above"
  PRO_FAIL=1
fi
if [ "$PRO_FAIL" = 0 ]; then
  claude plugin install "$PLUGIN" || { warn "plugin install failed — see the error above"; PRO_FAIL=1; }
fi

# 5) --pro ONLY — Part C: OS-level helpers + daemons (curated allowlist) -----
say "Pro mode: installing OS-level helpers + daemons (curated subset)…"
if [ -n "$HERE" ] && [ -f "$HERE/os-setup.sh" ]; then
  bash "$HERE/os-setup.sh" "$PLATFORM"
else
  curl -fsSL "$REPO_RAW/os-setup.sh" | bash -s -- "$PLATFORM"
fi

if [ "$PRO_FAIL" = 0 ]; then
  say "Done. Pro plugin registered (v0.1 is a placeholder: it ships no skills or hooks yet)."
else
  warn "Pro add-ons NOT fully installed (see warnings above). Your Lite workspace is ready."
fi
printf '\n  Next step — just run:\n\n      cd %s && claude\n\n' "$ZHIZI_HOME"
say "Uninstall the Pro parts anytime: curl -fsSL $REPO_RAW/uninstall.sh | bash"
[ "$PRO_FAIL" = 0 ] || exit 1
