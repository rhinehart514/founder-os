---
name: ship
description: "Get it out. Deploy, release, roadmap management, version theses, product copy, pitch decks. Copy modes read demand-cache.json packages — use customer names, not internal feature names. Replaces: /ship, /roadmap, /copy. Also triggers on: 'ship', 'deploy', 'push', 'release', 'roadmap', 'what's next', 'copy', 'pitch', 'landing page'."
argument-hint: "[deploy | release [tag] | roadmap [next|bump|ideate|narrative|changelog] | version [X.Y] | copy [landing|pitch|outreach|release|onboard|empty-states] ]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, WebSearch, WebFetch, Agent
---

# /ship

Three jobs. One command. Deploy code, manage the roadmap, write product copy.

## Routing

| Input | Mode | What |
|-------|------|------|
| (none) | DEPLOY | Pre-flight → commit → push → deploy → verify |
| `release [tag]` | RELEASE | Release notes → `gh release create` |
| `roadmap` | ROADMAP | Reflection + version list |
| `roadmap next` | NEXT | Diagnose what's most provable |
| `roadmap bump` | BUMP | Increment version, auto-synthesize, transfer thesis → Known Pattern |
| `roadmap ideate` | THESIS | Brainstorm future theses from evidence patterns |
| `roadmap narrative` | NARRATIVE | Generate external story from proven evidence |
| `roadmap changelog` | CHANGELOG | Version-by-version external changelog |
| `version [X.Y]` | VERSION | Version archaeology — thesis, proof, influence |
| `copy [type]` | COPY | Product copy: landing, pitch, outreach, release, onboard, empty-states |

## Skill folder structure

**Scripts:** `pre-flight.sh`, `release-notes.sh`, `ship-log.sh`, `version-history.sh`, `version-progress.sh`, `evidence-tracker.sh`, `slop-check.sh`, `copy-log.sh`, `copy-diff.sh`
**References:** `advanced-modes.md`, `ship-checklist.md`, `release-types.md`, `version-guide.md`, `version-lifecycle.md`, `changelog-guide.md`, `customer-language.md`, `positioning-frameworks.md`, `voice-guide.md`, `slop-words.md`, `copy-patterns.md`
**Templates:** `pr-body.md`, `release-notes.md`, `roadmap-template.yml`, `changelog-template.md`, `landing-page.md`, `release-announcement.md`, `pitch-narrative.md`, `cold-outreach.md`, `copy-release-notes.md`

## State to read

All modes: `.claude/plans/roadmap.yml`, `config/founder.yml`, `.claude/cache/eval-cache.json`
Deploy/release: `.claude/cache/deploy-history.json`, ship-log.jsonl
Roadmap: `.claude/knowledge/predictions.tsv`, `.claude/knowledge/experiment-learnings.md`, `git log --oneline -20`
Copy: `.claude/cache/demand-cache.json` (packages), `.claude/cache/market-context.json`, `.claude/cache/customer-intel.json`, `.claude/cache/narrative.yml`

## DEPLOY mode (default)

Read `gotchas.md` first. Run `bash scripts/pre-flight.sh`. Parse verdict: SHIP / BLOCK / WARN.
- **BLOCK**: stop. Show blockers.
- **WARN**: show warnings. Ask founder.
- **SHIP**: stage → commit → push → deploy → verify → log to ship-log.jsonl.

## RELEASE mode

Run `bash scripts/release-notes.sh [tag]`. Compose notes from git history + roadmap context. `gh release create`. Evidence-traced claims only.

## ROADMAP mode

Versions are theses, not releases. Each asks a question — proven, disproven, or abandoned.

**Reflection first**: 2-3 sentences from velocity (git log), learning (prediction accuracy), honesty (evidence vs actual), shape (cross-version patterns). Run `scripts/version-progress.sh` + `scripts/version-history.sh`. **Tag each thesis by hierarchy level** (read `skills/shared/hierarchy-lens.md`). An outcome-level thesis ("does this product improve retention?") requires different evidence than a system-level thesis ("does the auth system work reliably?").

**Standalone check**: No eval-cache? Completion = proven/total evidence items. No founder.yml? Evidence-only mode.

### NEXT — diagnose provability
Run `scripts/evidence-tracker.sh`. Map evidence to features, score provability (ready/close/blocked/unknown). **Consider hierarchy level of each evidence item**: outcome-level evidence is hardest to prove but most valuable; system-level evidence is provable through architecture review; feature-level evidence is provable through eval scores. Recommend first experiment.

### BUMP — graduate thesis
Read `references/version-guide.md`. Auto-detect tier: MAJOR (new question), MINOR (new evidence), PATCH (fixes). Synthesize from evidence + predictions + git log. Present via AskUserQuestion. Transfer thesis → Known Pattern in experiment-learnings.md. **After bumping: run `bash bin/sync-version.sh <new-version>` to update marketplace.json and plugin.json.**

### THESIS (ideate) — brainstorm future
Check: proven patterns, dead ends, unknown territory, gap between proven and aspirational. Generate 3-4 candidate theses. **Ensure at least 1 candidate at each of the top 3 hierarchy levels** (outcome, opportunity, system) — read `skills/shared/hierarchy-lens.md`. A roadmap with only feature-level theses is a todo list, not a strategy. Present via AskUserQuestion.

### NARRATIVE — external story
Derive from proven evidence. Generate: one-liner, paragraph, positioning. Every claim traces to evidence. Write to `.claude/cache/narrative.yml`.

### CHANGELOG — external changelog
Read `references/changelog-guide.md` + `templates/changelog-template.md`. Translate internal → external. Write to `.claude/cache/changelog.md`.

### VERSION — archaeology
Run `scripts/version-history.sh v[X.Y]`. Show thesis, proof, lessons, influence on later versions.

## COPY mode

Read `gotchas.md` and `references/slop-words.md` first. **Read demand-cache.json packages** — use `customer_name` and `one_liner`, not internal feature names. If no packages exist, suggest `/ideate package` first.

**Types:** `landing` (hero+problem+solution+proof+CTA), `pitch` (elevator/tweet/paragraph), `outreach` (cold email/DM), `release` (user-facing notes), `onboard` (first-screen copy), `empty-states` (all empty states).

**Quality gate (mandatory):** Names a person? States what changes? Differentiates? Slop-free (`slop-check.sh`)? 2026-native (sell the work, not the tool)? **Addresses outcome level** (what changes for the customer), not just feature level (what the product does)? Read `skills/shared/hierarchy-lens.md` — the outcome questions ("what metric moves?") translate directly to copy headlines.

For landing/pitch/outreach: also read `references/positioning-frameworks.md`, `references/customer-language.md`.
Log via `bash scripts/copy-log.sh add "[type]" "[headline]" "[preview]"`.

## Thesis health monitor (runs on every roadmap invocation)

- **Contradiction**: >50% thesis predictions wrong → surface warning
- **Stall**: no evidence movement in >14 days → diagnose
- **Disproven**: check `if_disproven:` field, write Dead End to experiment-learnings.md

## What you never do

- Push without pre-flight (unless hotfix via `references/advanced-modes.md`)
- Commit secrets, force push to main, ship past block-severity failures
- Create releases or copy with unproven claims
- Auto-bump without asking — graduating a thesis is a founder decision
- Use slop words — the ban list is absolute
- Frame as tool/assistant when it could be framed as delivering work
- Skip the copy quality gate

## If something breaks

- No score: run `/eval` first. No `gh`: `brew install gh`. Push rejected: `git pull --rebase`.
- No roadmap.yml: create from git log. No eval-cache: standalone completion formula.
- No demand-cache.json for copy: suggest `/ideate package` first.
- No market-context.json: degrade to un-positioned copy, flag it.

$ARGUMENTS
