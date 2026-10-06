# Zhizi — installer

One command. Two modes. Runs on **macOS or Linux** (on Windows: inside WSL).

## Prerequisite: Claude Code

The installer sets up Claude Code; it does not replace it. Install Claude Code
first (about 10–15 seconds), then **open a new terminal window** so `claude` is
on your PATH:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Claude Code needs a paid Claude plan (Pro, Max, Team, Enterprise) or Anthropic
Console API credits — the free claude.ai plan does not include it. Other install
methods: <https://code.claude.com/docs/en/setup>. You do **not** need to log in
before running the Zhizi installer; you'll log in the first time you run `claude`.

## Install

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
| A | skills + hooks + subagents + MCP | Claude Code plugin (`claude plugin install`) from this repo's marketplace (`.claude-plugin/marketplace.json`) |
| B | one-command orchestrator | `install.sh` (this repo) |
| C | OS-level helpers + daemons | `os-setup.sh` (installs only what is vendored in `payload/`) |

Claude Code's package manager is **plugins + marketplaces**. A plugin carries
skills/hooks/subagents/MCP wiring but cannot install shell helpers, background
daemons, or mutate global settings — so Pro mode adds the OS-level half too.

If any Pro step fails, the installer shows the real error, says that the Pro
add-ons were not fully installed, and exits non-zero. Your Lite workspace is
still set up.

## Principles

- **BYOK** — you bring your own Claude account or Anthropic key. We never ship or ask for anyone's keys.
- **Privacy-clean** — ships only the files in this repository: `templates/lite/`,
  `plugin/`, and the three scripts. No secrets, no personal data, no maintainer
  identity. The Lite template is fully genericized. `payload/` is kept out of
  the repo until its contents have been reviewed.
- **Reversible** — see Uninstall below.

## Uninstall

**Lite** only ever creates `~/zhizi/`. To remove it completely (this also
deletes your notes in it):

```bash
rm -rf ~/zhizi
```

**Pro** parts (plugin, plugin marketplace entry, `~/.local/bin` helpers,
daemons, and the empty `~/.agent-control-plane` scaffolding):

```bash
curl -fsSL https://raw.githubusercontent.com/starshard-ai/zhizi-agent-os/main/uninstall.sh | bash
```

`uninstall.sh` never touches your `~/zhizi/` folder. To remove Claude Code
itself, follow the "Uninstall" section of the Claude Code setup docs.

## Status

v0.1. Lite template is live and privacy-scrubbed. Pro: the plugin installs, but
it is a placeholder that ships no skills or hooks yet, and `payload/` (OS
helpers/daemons) is empty, so Pro currently adds nothing you can use beyond Lite.
