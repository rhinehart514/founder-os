---
name: build
description: "Build the right thing. Bottleneck diagnosis, wave-based parallel execution, quick ad-hoc tasks, and systematic quality pushing. Demand-aware — checks who wants this before building. Replaces: /plan, /go, /quick, /push. Also triggers on: 'build', 'plan', 'go', 'just build it', 'fix everything', 'what should I work on', 'quick', 'push scores up'."
argument-hint: "[go [feature] | quick [task] | push [feature] [target] | --safe | --interactive]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, AskUserQuestion, WebSearch, WebFetch, EnterPlanMode, ExitPlanMode, TaskCreate, TaskGet, TaskList, TaskUpdate
---

!command -v jq &>/dev/null && cat .claude/cache/eval-cache.json 2>/dev/null | jq 'to_entries | map({key, score: .value.score, d: .value.delivery_score, c: .value.craft_score, v: .value.viability_score, delta: .value.delta}) | from_entries' 2>/dev/null || echo "no eval cache"
!cat .claude/plans/plan.yml 2>/dev/null | head -20 || echo "no plan"
!tail -3 ~/.claude/knowledge/predictions.tsv 2>/dev/null || echo "no predictions"

# /build

One skill for all building. Diagnoses the bottleneck, creates wave-grouped plans, executes with parallel agents, handles ad-hoc tasks, and pushes scores systematically. Demand-aware: checks who wants this before writing code.

## Folder contents

- `scripts/` — `session-context.sh`, `bottleneck-report.sh`, `opportunity-scan.sh`, `startup-check.sh`, `plan-progress.sh`, `intelligence-query.sh`, `pre-build-scan.sh`, `assertion-gate.sh`, `plateau-check.sh`, `build-log.sh`, `extract-gaps.sh`
- `references/` — `structured-planning.md`, `prioritization-guide.md`, `tier-routing.md`, `startup-patterns-quick.md`, `keep-revert-matrix.md`, `build-patterns.md`, `wave-execution.md`, `xml-task-format.md`, `beta-features.md`, `push-protocol.md`, `five-rings.md`, `maturity-ladder.md`, `push-patterns.md`
- `templates/` — `move-format.md`, `build-session.md`, `prediction.md`, `plan-output.md`, `plan-template.yml`, `plan-template.xml`, `move-brief.md`
- `gotchas.md` — merged failure modes from all four predecessors. **Read before any mode.**

## Routing

| Input | Mode | What happens |
|-------|------|--------------|
| (none) | PLAN | World check, bottleneck diagnosis, tier-aware moves, XML task specs |
| `go [feature]` | GO | Autonomous wave-based parallel execution with measurement gates |
| `quick [task]` | QUICK | Snapshot, predict, lightweight plan (1-3 tasks), execute, measure, grade |
| `push [feature] [target]` | PUSH | Extract all gaps, diagnose, ideate across five rings, build, measure |
| `go --safe` | SAFE | Sequential single-agent execution, no parallelism |
| `go --interactive` | INTERACTIVE | User checkpoints between each task |

## Demand gate (soft)

Before building, check demand evidence: `config/portfolio.yml`, `.claude/cache/customer-intel.json`, eval-cache. If none exists, surface via AskUserQuestion: "No demand evidence for [feature]. What customer job does this serve?" Gate doesn't block — it forces the demand question into consciousness. Skip in `autonomy: autonomous` or `full-auto`.

## Key behaviors by mode

**PLAN:** EnterPlanMode. World check (WebSearch market, `mind/world.md`). Read state in parallel (`founder.yml`, `eval-cache.json`, `roadmap.yml`, `strategy.yml`, `predictions.tsv`, `plan.yml`). Diagnose bottleneck (lowest sub-score on highest-weight feature). **Name the hierarchy level of the bottleneck** (read `skills/shared/hierarchy-lens.md`): a feature-level fix for an outcome-level problem is wasted work; a system-level problem disguised as a feature bug will recur. Tier-aware recommendations via `references/tier-routing.md`. Surface opportunities via `scripts/opportunity-scan.sh`. Generate 1-2 moves with XML tasks grouped into dependency waves. Present via AskUserQuestion, write `plan.yml`, ExitPlanMode. Details: `references/structured-planning.md`, `references/prioritization-guide.md`.

**GO:** Pre-build measurement + baseline capture. Load or create XML task specs. Group into dependency waves (independent = parallel, dependent = sequential). Predict before executing. **Hierarchy-aware demand gate**: if building toward an outcome-level goal, verify the outcome metric is named. If system-level work (refactor, boundary cleanup), read `skills/shared/system-thinking.md` for system health checklist. Spawn agents per wave, gate between waves with `scripts/assertion-gate.sh`. Post-build: verify all acceptance criteria, keep/revert per `references/keep-revert-matrix.md`, grade prediction. Plateau detection every 3 cycles. Details: `references/wave-execution.md`, `references/build-patterns.md`.

**QUICK:** Get task, snapshot baseline, predict, optional --discuss (gray areas) or --research (explorer agent). Plan 1-3 tasks. Execute inline (<3 files) or spawn builder. Measure after, grade prediction. If 4+ tasks or 3+ features, route to GO instead. Details: `gotchas.md` section on scope creep.

**PUSH:** Determine maturity from eval-cache weighted average. Extract gaps via `scripts/extract-gaps.sh`. Diagnose deeper by reading feature code. Ideate across five rings (`references/five-rings.md`). Display attack surface. Build in batches, predict every fix. Measure, grade, stop on plateau. Details: `references/push-protocol.md`, `references/maturity-ladder.md`.

## Agent routing

| Task complexity | Agent |
|----------------|-------|
| Simple (config, rename, single-file) | gsd-executor |
| Standard (feature work, 1-3 files) | gsd-executor |
| Complex (multi-file, architectural) | founder-os:builder |
| Cleanup/refactor | founder-os:refactorer |

Supporting agents: founder-os:grader (grade predictions), founder-os:consolidator (update learnings), founder-os:debugger (regression), founder-os:explorer (research), founder-os:evaluator (re-scoring).

## State

**Reads:** founder.yml, eval-cache.json, roadmap.yml, strategy.yml, predictions.tsv, plan.yml, todos.yml, beliefs.yml, product-spec.yml, preferences.yml, experiment-learnings.md, product-value.json, customer-intel.json, market-context.json, .planning/*-PLAN.md
**Writes:** plan.yml, code (commits), predictions.tsv, experiment-learnings.md, session YAML, build-log, tasks (TaskCreate)
**Triggers:** /eval (measurement), /research (unknowns/plateau)
**Triggered by:** session start, "what should I work on", "go", "build it", "fix everything", "quick fix", "push scores up"

## Self-evaluation

Succeeded if: prediction logged before work, baseline captured, each task committed atomically, assertions didn't regress (or reverted), prediction graded, output shows before/after delta.

## What you never do

- Skip prediction or grading — even "I predict 1 commit" counts
- Continue past plateau without researching
- Modify eval harness (score.sh, eval.sh, taste.mjs, skills/taste/SKILL.md)
- Execute wave N+1 when wave N regressed assertions
- Spawn agents without fresh context
- Use `git add .` or `git add -A`
- Plan 5+ tasks when 1-2 moves cover it
- Build without checking demand evidence
- Propose the same stalled approach with different words
- Write vague task actions or subjective acceptance criteria

## If something breaks

- No eval cache: run `/eval` first
- No features in founder.yml: run `/onboard`
- Agent spawn fails: fall back to `--safe`
- Dirty git state: `git stash` before starting
- Script fails: check `jq` dependency, do the check manually, never skip the step
- Too many gaps (50+): scope with `/build push [feature]`

$ARGUMENTS
