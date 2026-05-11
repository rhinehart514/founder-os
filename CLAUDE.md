# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Claude Code plugin providing multi-agent coordination primitives. Spawns multiple agents with the same prompt, aggregates their outputs (consensus, divergences, outliers) to get better answers than a single pass.

## Skills

| Skill | Purpose |
|-------|---------|
| `/stochastic` | Poll N agents (default 10), aggregate by consensus/divergences/outliers |
| `/model-chat` | 5 agents debate in a shared room, round-robin turns, synthesizer merges |
| `/fanout` | N Sonnet researchers in parallel, Opus synthesis |
| `/skillbuilder` | Build flawless Claude Code skills. Studies existing skills as reference, ensures correct format, pushes for genuine intelligence. |
| `/autoresearch` | Autonomous hill-climb optimization. Read code, generate mutations, measure, keep-or-revert, repeat. |

## Structure

```
skills/<name>/SKILL.md   # Skill definitions (frontmatter + instructions)
agents/*.md              # Agent definitions (parent, qa, researcher)
bin/install.sh           # Direct install to ~/.claude/
.claude-plugin/          # Plugin manifest for `claude plugin install`
```

## Install modes

Plugin (recommended): `claude plugin install rhinehart514/founder-os` → skills prefixed with `founder-os:`

Direct: `npm i -g @rhinehart514/founder-os` → skills at root level (`/stochastic`, etc.)

## Skill file format

```yaml
---
name: skill-name
description: "One-line description shown in skill list"
user-invocable: true
allowed-tools:
  - Read
  - Agent
  - Grep
effort: high
---

# Skill body with instructions
```

## Testing changes

After editing skills or agents, restart Claude Code to reload. No build step.
