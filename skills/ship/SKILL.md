---
name: ship
description: "Ship measured work — push to main or create a GitHub release. Also triggers on 'deploy', 'push', 'ship it'."
argument-hint: "[release [tag]]"
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion, WebFetch, Agent
---

# /ship

Two modes: push code to main, or create a GitHub release.

## Skill folder structure

- `scripts/pre-flight.sh` — pre-ship gate: score, assertions, secrets, eval freshness, deploy confidence
- `scripts/release-notes.sh` — generates release notes from git log + roadmap.yml + eval deltas
- `references/advanced-modes.md` — dry run, hotfix, PR, changelog, verify, rollback, history
- `references/ship-checklist.md` — full pre-ship checklist with explanations
- `references/release-types.md` — when to use each ship type
- `templates/release-notes.md` — release notes template (anti-slop rules included)
- `templates/pr-body.md` — PR description template
- `reference.md` — output formatting templates
- `gotchas.md` — real failure modes. **Read before shipping.**

## Routing

| Input | Mode |
|-------|------|
| (none) | **Ship**: pre-flight → commit → push → deploy → verify → log |
| `release [tag]` | **Release**: pre-flight → release notes → `gh release create` |
| anything else | Read `references/advanced-modes.md` for dry, hotfix, pr, changelog, verify, rollback, history |

## How to ship

Read `gotchas.md` first.

### 1. Pre-flight gate

Run `bash scripts/pre-flight.sh`. Parse the verdict line: SHIP / BLOCK / WARN.

- **BLOCK**: stop. Show blockers. Generate a task in /todo for each one (tagged `source: /ship`).
- **WARN**: show warnings. Ask founder whether to proceed.
- **SHIP**: continue.

### 2. Execute

**Ship (default):** stage → commit → push → deploy (auto-detect: Vercel, Netlify, or git-only) → verify → log.

**Release:** run `bash scripts/release-notes.sh [tag]` → compose release notes from git history + roadmap context → `gh release create`. Let Claude compose the notes naturally — the template in `templates/release-notes.md` is a reference, not a form to fill.

### 3. Log the ship

Append a JSONL entry to `${CLAUDE_PLUGIN_DATA}/ship-log.jsonl`:
```json
{"timestamp":"...","type":"deploy|release","version":"v9.x","commit":"abc1234","score":85,"features":"scoring,commands","target":"vercel","pr":"","tag":""}
```

## State to read

- `.claude/cache/eval-cache.json` — per-feature scores, freshness
- `.claude/cache/deploy-history.json` — last deploy, score delta
- `.claude/plans/roadmap.yml` — current version, thesis
- `config/founder.yml` — deploy target, features, mode

For release-type ships, also check (informational, non-blocking):
- `.claude/cache/market-context.json`, `.claude/cache/customer-intel.json` — GTM/customer signal
- `.claude/plans/todos.yml` — blocking todos tagged `source: /ship`

## Agent usage

- **founder-os:measurer** — run score checks (haiku, cheapest)

## System integration

Reads: eval-cache.json, deploy-history.json, roadmap.yml, todos.yml, founder.yml, ship-log.jsonl
Writes: ship-log.jsonl, deploy-history.json, todos.yml
Triggers: /retro (grade ship predictions)
Triggered by: /go (work complete), founder ("ship it", "deploy", "push")

## What you never do

- Push without running pre-flight (unless hotfix — see advanced-modes.md)
- Commit secrets (.env, credentials, API keys)
- Force push to main
- Ship past block-severity assertion failures
- Create releases with unproven claims

## Degraded modes

| Missing | Behavior |
|---------|----------|
| No deploy-history | Create empty, note "First tracked deployment" |
| No `gh` CLI | Skip release: "`brew install gh` to enable" |
| No roadmap.yml | Generate release notes from git log only |
| No eval-cache | Warn: "Run `/eval` for full pre-flight data" |

## If something breaks

- pre-flight.sh exits "no score": run `founder score .` first
- `gh release create` fails: check `gh auth status`
- Push rejected: check branch protection, `git pull --rebase`
- Rollback conflicts: see `references/advanced-modes.md`

$ARGUMENTS
