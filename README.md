# Zhizi — installer

One command. Two modes.

```bash
# Default — Lite: a warm, non-technical personal AI assistant.
curl -fsSL https://raw.githubusercontent.com/starshard-ai/zhizi-agent-os/main/install.sh | bash

# Pro: everything in Lite, plus the technical agent-OS plugin + OS helpers.
curl -fsSL https://raw.githubusercontent.com/starshard-ai/zhizi-agent-os/main/install.sh | bash -s -- --pro
```

## Lite (default)

Drops a friendly personal-assistant ruleset into `~/zhizi/` (override with
`ZHIZI_HOME`). No plugins, no daemons, nothing global is touched. The folder
holds a `CLAUDE.md` ruleset plus a small "memory book" (USER / CONTEXT / TASKS /
LOG / HANDOFF) that the assistant fills in by chatting with you.

After install:

```bash
cd ~/zhizi && claude
```

Claude Code auto-reads `CLAUDE.md` and becomes your personal "智子" assistant —
no technical knowledge required. Safety red-lines are baked in (never asks for
passwords / 验证码 / bank cards; stops before logins, payments, or system
changes).

**Idempotent:** re-running refreshes only the ruleset files
(`CLAUDE.md AGENTS.md README.md FIRST_PROMPT.txt`) and never clobbers your own
notes (`USER / CONTEXT / TASKS / LOG / HANDOFF`).

## Pro (`--pro`)

For technical users. Runs everything Lite does, then also:

| Part | What | Mechanism |
|------|------|-----------|
| A | skills + hooks + subagents + MCP | Claude Code plugin (`/plugin install`) |
| B | one-command orchestrator | `install.sh` (this repo) |
| C | OS-level helpers + daemons | `os-setup.sh` (curated allowlist only) |

Claude Code's package manager is **plugins + marketplaces**. A plugin carries
skills/hooks/subagents/MCP wiring but cannot install shell helpers, background
daemons, or mutate global settings — so Pro mode adds the OS-level half too.

## Principles

- **BYOK** — you bring your own Anthropic key. We never ship or ask for anyone's keys.
- **Privacy-clean** — ships only what `MANIFEST.md` allowlists. No secrets, no
  personal data, no maintainer identity. The Lite template is fully genericized.
- **Reversible** — `uninstall.sh` undoes the Pro plugin/helpers/daemons and
  leaves your `~/zhizi/` notes untouched.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/starshard-ai/zhizi-agent-os/main/uninstall.sh | bash
```

Removes the plugin, `~/.local/bin` helpers, and any daemons. Your `~/zhizi/`
working folder and data are left in place.

## Status

v0.1. Lite template is live and privacy-scrubbed. Pro payload allowlist
(`MANIFEST.md`) pending ratification — in Pro mode the plugin/OS parts degrade
gracefully if the marketplace repo or `payload/` isn't populated yet.
