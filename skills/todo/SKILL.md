---
name: todo
description: "Use when the user wants to manage backlog items — capture, tag, prioritize, promote, decay, or review backlog health"
argument-hint: "[add \"title\"|done <id>|promote <id>|active|health|decay]"
allowed-tools: Read, Bash, Edit, Grep, Glob, AskUserQuestion
---

!cat .claude/plans/todos.yml 2>/dev/null | grep -c 'status: backlog' 2>/dev/null || echo "0"
!cat .claude/plans/todos.yml 2>/dev/null | grep -c 'status: active' 2>/dev/null || echo "0"

# /todo

A living backlog. Decays stale items, graduates recurring todos to assertions, surfaces the right item based on what the product needs.

Storage: `.claude/plans/todos.yml`

## Standalone check

If `config/founder.yml` exists, load feature names for auto-tagging and eval-cache for smart promote. Otherwise, operate in standalone mode — tags are manual (or omitted), smart promote suggests by age/priority instead of bottleneck feature, and graduation works without feature weights.

## Skill folder structure

This skill is a **folder**, not just this file. Read on demand:

- `references/todo-lifecycle.md` — captured→tagged→prioritized→promoted/killed, decay rules, graduation criteria
- `references/todo-sources.md` — where todos come from: /ideate, /eval, /go, manual, agents
- `templates/todo-template.yml` — valid fields for a todo item
- `reference.md` — output formatting templates
- `gotchas.md` — real failure modes. **Read before any batch operation.**

Scripts (`todo-stats.sh`, `todo-decay.sh`, `todo-promote.sh`) exist as verification — run to cross-check your analysis, not as the primary path.

## State

Read these directly — synthesize, don't delegate:

| File | What it tells you |
|------|-------------------|
| `.claude/plans/todos.yml` | The backlog: id, title, status, feature, source, created_at, done_count |
| `config/founder.yml` | Feature names for auto-tagging (optional — standalone works without it) |
| `.claude/cache/eval-cache.json` | Sub-scores for smart promote (optional — falls back to age-based) |
| `lens/product/eval/beliefs.yml` | Existing assertions — for graduation dedup |

**You can read todos.yml directly.** Count items by status. Compute ages from created_at timestamps. Find clusters by feature. Identify stale items (>7d, >14d, >30d). Check for orphans (no feature tag). This is YOUR analysis work — scripts verify it.

## Routing

Parse `$ARGUMENTS`:

| Input | Action |
|-------|--------|
| (no args) or `show` | Read todos.yml → list items by status → check for stale items → smart promote if 0 active |
| `add "title"` | Capture to backlog. Auto-tag if feature detected in title (when founder.yml exists). |
| `done <id>` | Mark complete. Check if recurring (done 3+ times) → suggest graduation to assertion. |
| `promote <id>` | Activate for session |
| `active` | Show active only |
| `tag <id> <tag>` | Tag to feature or version. Validated against founder.yml when available, freeform otherwise. |
| `feature [name]` | Filter by feature |
| `version [tag]` | Filter by version |
| `health` | Full backlog diagnostic: counts, ages, clusters, orphans, type distribution. Verify with `todo-stats.sh`. |
| `decay` | Surface all items >7d. Force decisions: promote, kill, or refresh. Verify with `todo-decay.sh`. |
| `all` | Show all including done |
| (plain text) | Quick capture: treat as `add "$ARGUMENTS"` |

## Core behaviors

**Decay** — universal thresholds, checked on every show:
- **>7 days**: stale warning — surface in decay section
- **>14 days**: stale — prompt for decision (promote, kill, or refresh)
- **>30 days**: archive candidate — strongly suggest kill or escalate
Never auto-delete. Founder decides.

**Graduation**: On `done`, check if this todo has recurred 3+ times (done_count field). If so, suggest converting to assertion in beliefs.yml. Works without feature weights — the pattern alone justifies graduation. Needs founder confirmation via AskUserQuestion.

**Smart promote**: When 0 active items and eval-cache exists, find the bottleneck feature and suggest the highest-leverage todo for it. Without eval-cache, suggest the oldest un-promoted item or the one with the most related todos (cluster signal).

**Auto-tag**: On `add`, when founder.yml exists, scan title for feature names and version refs. When standalone, accept any tag the user provides.

**Cross-skill capture**: Skills and agents write todos via `todo:` prefixed SendMessage. See `references/todo-sources.md`.

For lifecycle details: `references/todo-lifecycle.md`
For output templates: `reference.md`

## Self-evaluation

The skill worked if:
- **Add**: item was written to todos.yml with no duplicate ids
- **Done**: graduation check ran if done_count >= 3
- **Show/health**: decay check ran, stale items surfaced, smart promote fired when 0 active items

## System integration

**Reads:** todos.yml, founder.yml (optional), eval-cache.json (optional), beliefs.yml
**Writes:** `.claude/plans/todos.yml` (add/done/promote/tag/decay)
**Triggers:** /assert graduate (recurring patterns), /plan (0 active items), /go (active work items)
**Triggered by:** "backlog", "todo", "capture this", /ideate outputs, /eval gap tasks, /go builder reports, agent `todo:` messages

## What you never do

- Auto-delete stale items — decay surfaces, founder decides
- Auto-promote items — suggest, don't act
- Show done items unless `all` or `version` specified
- Graduate to assertion without founder confirmation

## If something breaks

- No todos.yml → create it on first `add`
- No founder.yml → standalone mode (manual tags, age-based promote)
- Invalid subcommand → show routing table
- No eval-cache for smart promote → fall back to age-based suggestion
- No beliefs.yml for graduation → create it with the graduated assertion

$ARGUMENTS
