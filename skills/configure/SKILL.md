---
name: configure
description: "Use when the user wants to tune founder-os behavior — agent models, output verbosity, /go gates, or view current configuration"
argument-hint: "[show|agents|output|go|reset]"
allowed-tools: Read, Write, Bash, Grep, Glob, AskUserQuestion
context: fork
user-invocable: false
---

<!-- INTERNAL: This skill is for founder-os self-management, not marketplace distribution. -->

# /configure

One place to tune founder-os behavior. Reads project config (founder.yml) and user preferences (~/.claude/preferences.yml). Changes write to preferences.yml — founder.yml stays as the project-level source of truth.

## Skill folder structure

This skill is a **folder**, not just this file. Read on demand:

- `scripts/config-diff.sh` — shows configured vs default values, highlights overrides
- `references/config-reference.md` — all configurable values with defaults and explanations
- `reference.md` — output templates
- `gotchas.md` — real failure modes. **Read before changing config.**

## Routing

Parse `$ARGUMENTS`:

| Input | Mode |
|-------|------|
| (none) or `show` | Run `scripts/config-diff.sh`, display current settings with explanations |
| `agents` | Interview: cost tier and autonomy level |
| `output` | Interview: output verbosity |
| `go` | Interview: hard gate and plateau threshold |
| `reset` | Delete preferences.yml, confirm |

## Route: show (default)

Run `bash scripts/config-diff.sh` for a quick overview. Then read `references/config-reference.md` for full context on any non-default values.

Display all current settings with behavioral explanations. Show which values come from preferences vs founder.yml defaults.

## Route: agents

Interview via AskUserQuestion. Two questions:
1. **Cost tier** — economy/balanced/premium. Model mapping:
   - **economy**: haiku/sonnet for all agents (cheapest)
   - **balanced** (default): opus for builder/evaluator/market-analyst, sonnet for explorer/grader/debugger/refactorer, haiku for measurer/reviewer
   - **premium**: opus/sonnet for all agents (most capable)
2. **Autonomy** — supervised/autonomous/full-auto.

Write to `~/.claude/preferences.yml`. Merge, don't overwrite. Show resolved agent models.

## Route: output

Interview via AskUserQuestion. One question: quiet/normal/verbose. Write to preferences.yml.

## Route: go

Interview via AskUserQuestion. Two questions:
1. **Hard gate** — yes/no (approval before each /go move)
2. **Plateau threshold** — number 1-10 (flat moves before stopping)

Write to preferences.yml.

## Route: reset

Confirm via AskUserQuestion. Delete preferences.yml. Show defaults.

## Self-evaluation

The skill worked if:
- **Show**: all settings displayed with source (preferences vs founder.yml default) and behavioral explanation
- **Agents/output/go**: preference was written to `~/.claude/preferences.yml` via merge (not overwrite)
- **Reset**: confirmation was obtained AND preferences.yml was deleted
- **All modes**: resolved values match what the config-reference.md documents for that tier

## Gotchas

- **preferences.yml merge, not overwrite**: writing a single key must preserve all other keys. Read the file first, merge, then write.
- **Config not taking effect**: preferences.yml keys must match the exact nesting documented in `references/config-reference.md`. A typo silently falls back to defaults.
- **Fork constraint**: this skill uses `context: fork` so it runs as a subagent. It cannot spawn additional agents. All work must be done inline.

## System integration

Reads: `config/founder.yml` (project defaults), `~/.claude/preferences.yml` (user overrides), `references/config-reference.md`
Writes: `~/.claude/preferences.yml`
Triggers: none (configuration is terminal)
Triggered by: manual, `/onboard` (initial setup suggestion)

## What you never do

- Modify founder.yml — it's the project-level source of truth
- Set preferences without the interview — always confirm with the user
- Skip confirmation on reset
- Recommend config changes to fix scores — the product needs work, not the config

## If something breaks

- preferences.yml parse error: delete `~/.claude/preferences.yml` and re-run `/configure reset`
- config-diff.sh shows no output: `config/founder.yml` may be missing — run `/onboard` first
- Agent model override not taking effect: preferences.yml must use exact keys from `references/config-reference.md` — check spelling and nesting

$ARGUMENTS
