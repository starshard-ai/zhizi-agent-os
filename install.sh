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
#   - Privacy-clean. Ships ONLY what MANIFEST.md allowlists. No secrets, no
#     people-registry, no private memories, no owner-identity CLAUDE.md.
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
command -v claude >/dev/null 2>&1 || die "Claude Code not found. Install it first: https://claude.ai/download — then re-run."
say "Claude Code: $(claude --version 2>/dev/null || echo present)"

OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM=macos ;;
  Linux)  PLATFORM=linux ;;
  *) die "Unsupported OS: $OS (macOS / Linux only for now)." ;;
esac
say "Platform: $PLATFORM"

# 2) BYOK check (we never ship keys) ----------------------------------------
if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ ! -f "$HOME/.claude/.credentials.json" ]; then
  warn "No Anthropic credentials detected. Zhizi is BYOK — set ANTHROPIC_API_KEY"
  warn "or run 'claude' once to log in, then re-run this installer."
fi

# 3) Lite template — ALWAYS installed (both modes) --------------------------
HERE="$(cd "$(dirname "$0")" 2>/dev/null && pwd || echo "")"
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
say "Pro mode: wiring plugin marketplace (skills + hooks + subagents + MCP)…"
claude plugin marketplace add "$MARKETPLACE" 2>/dev/null || warn "marketplace add skipped (already added or repo not public yet)"
claude plugin install "$PLUGIN" 2>/dev/null || warn "plugin install skipped (run '/plugin install $PLUGIN' inside Claude Code)"

# 5) --pro ONLY — Part C: OS-level helpers + daemons (curated allowlist) -----
say "Pro mode: installing OS-level helpers + daemons (curated subset)…"
if [ -n "$HERE" ] && [ -f "$HERE/os-setup.sh" ]; then
  bash "$HERE/os-setup.sh" "$PLATFORM"
else
  curl -fsSL "$REPO_RAW/os-setup.sh" | bash -s -- "$PLATFORM"
fi

say "Done. Open Claude Code (cd $ZHIZI_HOME && claude) and run /help to see the Zhizi skills."
say "Uninstall anytime: curl -fsSL $REPO_RAW/uninstall.sh | bash"
