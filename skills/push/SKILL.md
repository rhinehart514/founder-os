---
name: push
description: "Make everything better. Reads all measurement data, determines maturity, extracts gaps, ideates, and builds. Triggers on: 'make everything better', 'close all gaps', 'push scores up', 'quality sweep'."
argument-hint: "[feature] [extract] [target-score]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate
---

!bash scripts/extract-gaps.sh . 2>/dev/null | jq '{total_gaps, by_feature, by_dimension}' 2>/dev/null || echo "no gaps extracted"

# /push

Make everything better. Systematically.

/plan finds one bottleneck. /go builds one move. /push reads ALL measurement data, determines what level of work the product needs, and attacks it — mechanical fixes, deeper diagnosis, and creative ideation scaled to maturity.

## Skill folder structure

- `scripts/extract-gaps.sh` — pulls gaps from eval-cache, taste reports, flows reports. Prioritized JSON.
- `references/protocol.md` — full 7-step loop (extract → diagnose → ideate → display → build → measure)
- `references/five-rings.md` — ideation framework (code → feature → product → market → vision)
- `references/maturity-ladder.md` — what to work on at each score range
- `references/push-patterns.md` — three levels of work, batch strategy, anti-patterns
- `gotchas.md` — real failure modes

## Routing

| Argument | Mode |
|----------|------|
| (none) | Full loop: extract → ideate → build |
| `extract` | Show the attack surface — no building |
| `<feature>` | Scope to one feature |
| `<number>` | Push until all features hit this target (e.g., `/push 80`) |
| `all` | Include stale caches in extraction |

## Maturity ladder (compact)

The type of work changes as the score goes up. Read `references/maturity-ladder.md` for full detail.

| Score | Work unit | Focus |
|-------|-----------|-------|
| 0-30 | Whole features | Build what's missing, get happy path working |
| 30-50 | Systems | Wire features together, add error handling |
| 50-65 | Product coherence | Information architecture, output clarity, dead ends |
| 65-80 | Polish | Progressive disclosure, consistency, edge cases |
| 80-90 | Refinement | Performance, graceful degradation, accessibility |
| 90+ | Validation | External proof, instrumentation, documentation for strangers |

**Taste dimensions scale with maturity:** layout (30+) → spacing/typography (50+) → color/contrast (65+) → interaction feedback (80+) → delight/brand (90+). Don't fix micro-interactions when layout is broken.

## How it works

Full protocol in `references/protocol.md`. The loop:

1. **Determine maturity** from eval-cache weighted average
2. **Extract gaps** via `bash scripts/extract-gaps.sh .`
3. **Diagnose deeper** — read feature code, find what eval missed
4. **Ideate across five rings** — see `references/five-rings.md`
5. **Display attack surface** — grouped by feature with gap counts
6. **Build** — batch by feature, mechanical first, predict every fix
7. **Measure** — before/after, grade predictions, stop on plateau

## State to read

`config/founder.yml`, `.claude/cache/eval-cache.json`, `.claude/evals/reports/taste-*.json`, `.claude/evals/reports/flows-*.json`, `.claude/plans/todos.yml`, `.claude/cache/wrong-prediction-areas.txt`, `~/.claude/knowledge/experiment-learnings.md`

## Agent wiring

| Agent | When | Role |
|-------|------|------|
| **founder-os:builder** | Build phase, non-overlapping features | Parallel builds in worktrees |
| **founder-os:evaluator** | After build batch, if scores need refresh | Fresh eval for re-scoring |
| **founder-os:explorer** | Diagnose phase, complex features | Deep research on hard problems |

## Integration

- **Reads from**: /eval (gaps), /taste (visual + behavioral), /score (unified)
- **Writes to**: /todo (tasks), predictions.tsv (per build)
- **Triggers**: /eval (re-scoring after builds)
- **Triggered by**: "push scores up", "make everything better", "close all gaps", "improve everything", "quality sweep"

## What you never do

- Vague tasks — every task needs file:line or concrete idea
- Build without predicting — every fix gets a prediction
- Ignore assertion regressions — revert on drop
- Wrong-level work — respect the maturity ladder
- Trigger /taste directly — use cached data, flag if stale

## If something breaks

- No eval cache: run `/eval` first
- No features in founder.yml: run `/feature new [name]`
- extract-gaps.sh fails: check jq + eval-cache.json validity
- Too many gaps (50+): scope with `/push [feature]`
- Score stuck after 5+ fixes: eval cache stale, run `/eval`

$ARGUMENTS
