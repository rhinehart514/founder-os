---
name: go
description: "Use when the user says 'just build it', 'go', 'fix everything', or wants autonomous building. Builds, measures, learns in a loop. '/go auth' scopes to a feature, '/go --safe' disables beta features."
argument-hint: "[feature...] [--safe] [--speculate N]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, AskUserQuestion, WebSearch, WebFetch, TaskCreate, TaskGet, TaskList, TaskUpdate
---

!command -v jq &>/dev/null && cat .claude/cache/eval-cache.json 2>/dev/null | jq 'to_entries | map({key, score: .value.score, delta: .value.delta}) | from_entries' 2>/dev/null || echo "no eval cache (jq missing or cache empty)"
!command -v jq &>/dev/null && cat .claude/cache/product-value.json 2>/dev/null | jq '{loop: .value_loop[:5], type: .product_type}' 2>/dev/null || echo "no product-value cache (jq missing or cache empty)"
!tail -3 ~/.claude/knowledge/predictions.tsv 2>/dev/null || echo "no predictions"

# /go

Autonomous creation loop. Plan, predict, build, measure, learn — no human in the loop until you hit a wall or plateau.

## Skill folder

- `scripts/assertion-gate.sh` — checks assertion pass/fail. Run after every build.
- `scripts/pre-build-scan.sh` — state snapshot. Use to VERIFY your reading.
- `scripts/plateau-check.sh` — detects N consecutive flat moves. Use to VERIFY plateau judgment.
- `scripts/build-log.sh` — persistent session log across conversations.
- `references/keep-revert-matrix.md` — when to keep vs revert. Read before first decision.
- `references/build-patterns.md` — patterns that work and anti-patterns.
- `references/beta-features.md` — speculative branching + adversarial review (opt-in).
- `templates/move-format.md` — output formatting reference.
- `templates/build-session.md` — session log structure.
- `templates/prediction.md` — prediction format and quality checks.
- `gotchas.md` — real failure modes. **Read before entering the loop.**

## Modes

| Argument | Behavior |
|----------|----------|
| `/go` | Full loop with beta features (speculative branching, adversarial review) |
| `/go --safe` | Proven sequential loop only |
| `/go --speculate N` | Force N parallel approaches (default: 2) |
| `/go [feature]` | Scope to a single feature. Multiple = work sequentially. None = target bottleneck. |

## The build loop

### 1. Understand the situation

Read in parallel: `eval-cache.json`, `founder.yml`, `plan.yml`, `predictions.tsv`, `todos.yml`, `product-spec.yml`, `preferences.yml`. Also read `gotchas.md` and `references/build-patterns.md`. Verify with `bash scripts/pre-build-scan.sh`. Capture baseline assertion count and scores.

**Soft discovery gate:** If target feature has no eval data AND no customer-intel.json, present via AskUserQuestion. Skip if autonomy is autonomous/full-auto.

### 2. Pick the move — completeness-driven

**The goal is "finish the feature," not "do one thing."** Read the situation:

1. **Failing assertions** — fix regressions first. Verify with `bash scripts/assertion-gate.sh [feature]`.
2. **Tasks from /eval or /taste** — specific gaps already identified.
3. **Missing assertion coverage** — <5 assertions for a feature? Add more before building more code.
4. **Weakest sub-score dimension** — from eval-cache, target the lowest of delivery/craft.
5. **Promoted todos** — founder intent from todos.yml.
6. **New work** — only when all above are clear.

**Cleanup:** If the task is cleanup/refactor, spawn `founder-os:refactorer` in worktree. Hard constraint: no behavior changes, assertions must hold.

### 3. Predict

Before every build, log to `~/.claude/knowledge/predictions.tsv`. See `templates/prediction.md` for format. Specific numbers, cited evidence, falsification condition.

### 4. Approval gate

| Mode | Behavior |
|------|----------|
| `mode: build` (default) | Present plan inline, proceed. Founder can interrupt. |
| `mode: ship` or `autonomy: supervised` | Wait for founder acknowledgment via AskUserQuestion. |
| `autonomy: autonomous`/`full-auto` | Skip. |

### 5. Build

**Safe mode:** Build directly. Atomic commits. One intent per commit.

**Beta mode:** See `references/beta-features.md` for speculative branching and adversarial review.

### 6. Measure

After each commit: `bash scripts/assertion-gate.sh [feature]` for pass/fail, then `founder eval . --feature [name] --fresh` for sub-scores. Check: did the TARGETED sub-score improve?

### 7. Keep or revert

Read `references/keep-revert-matrix.md`. Assertion regressed -> revert always. Assertion improved -> keep always. Assertion stable + reviewer REVERT -> revert. On regression: spawn `founder-os:debugger` in background.

### 8. Grade prediction

**Mandatory before next move.** Spawn `founder-os:grader` for predictions.tsv. Spawn `founder-os:consolidator` in background for experiment-learnings.md.

### 9. Plateau detection

Every 3 moves: targeted sub-score delta < 2 per move = plateau. Verify with `bash scripts/plateau-check.sh`. On plateau: stop, research or report.

### 10. Loop or stop

Tasks remain and no plateau -> loop to step 2. All tasks done -> fresh eval for NEW gaps.

### Session end

Run `bash scripts/assertion-gate.sh --diff`, compare to baseline. Log with `bash scripts/build-log.sh add`. Write `.claude/sessions/YYYY-MM-DD-HH.yml` (see `templates/build-session.md`).

Report: tasks completed, remaining, assertion delta, sub-score changes, new tasks generated, estimated sessions to completion. See `templates/move-format.md` for formatting.

## Tier-aware behavior

| Tier | Behavior |
|------|----------|
| **fix** (<50) | Pure build. Fix assertions, improve health. No eval between cycles. |
| **deepen** (50-70) | Build + eval after every 3 commits. |
| **strengthen** (70-85) | Build + eval after every commit. Research inline for unknowns. |
| **expand** (85+, eval<70) | Check if bottleneck is "missing capability" vs "incomplete." Missing -> suggest /ideate or /research. |
| **mature** (85+, eval 70+) | Shorter sessions. Every 2 cycles: is another build higher leverage than /ideate or /research? Stop when features are good. |

## Agent routing

| Step | Agent | Notes |
|------|-------|-------|
| Build (safe) | direct | Single-agent, main worktree |
| Build (cleanup) | founder-os:refactorer | No behavior changes |
| Measure | founder-os:measurer or Bash | Mechanical, cheap |
| Grade | founder-os:grader | Has memory, learns grading |
| Debug regression | founder-os:debugger (bg) | Async during revert |

See `references/beta-features.md` for beta-specific agent routing.

## What you never do

- Skip the prediction or prediction grading
- Continue past plateau without researching
- Modify score.sh, eval.sh, taste.mjs, or skills/taste/SKILL.md (immutable eval harness)
- Speculate on trivial moves
- Let the reviewer block a keep when assertions improved
- Skip presenting the move plan (soft-gate still shows it)

## System integration

Reads: eval-cache.json, founder.yml, plan.yml, predictions.tsv, todos.yml, beliefs.yml, product-spec.yml, preferences.yml, experiment-learnings.md
Writes: code (commits), predictions.tsv, experiment-learnings.md, session YAML, build-log
Triggers: /eval (measurement), /research (plateau), /retro (prediction grading)
Triggered by: /plan (after diagnosis), founder saying "go" / "build it" / "fix everything"

## If something breaks

- `founder eval .` fails: check config/founder.yml features section
- Worktree fails: fall back to `--safe`, log failure
- No plan exists: run /plan logic inline first
- Dirty git state: `git stash` before starting
- Missing files: create experiment-learnings.md or predictions.tsv with standard templates

$ARGUMENTS
