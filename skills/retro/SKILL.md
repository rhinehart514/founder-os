---
name: retro
description: "Grade predictions, audit whether features still matter, update the knowledge model, detect stale patterns. Closes the learning loop AND checks if the world changed while you were building."
argument-hint: "[grade | audit | consolidate | stale | accuracy | session | health | dimensions | auto]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebSearch, WebFetch
---

# /retro — Close the Learning Loop

The skill that makes serial entrepreneurs' judgment compound. Grade predictions,
update patterns, detect what's stale.

## Skill folder structure

This skill is a **folder**, not just this file. Read on demand:

- `scripts/retro-log.sh` — persistent retro session log (uses `${CLAUDE_PLUGIN_DATA}`)
- `scripts/prediction-stats.sh` — computes accuracy, calibration, domain breakdown from predictions.tsv
- `scripts/learning-velocity.sh` — model updates per week, prediction frequency, accuracy trend
- `scripts/stale-knowledge.sh` — scans experiment-learnings.md for stale entries
- `references/grading-guide.md` — how to grade predictions, partial credit, model update quality. **Read before grading.**
- `references/knowledge-maintenance.md` — promotion rules, pruning rules, staleness thresholds
- `templates/retro-report.md` — output template for retro sessions
- `reference.md` — full output templates for all routes
- `gotchas.md` — real failure modes. **Read before grading.**

## Routing

- **No args** → `FULL` mode (grade + consolidate + stale check + audit)
- **`grade`** → `GRADE` mode (grade ungraded predictions only)
- **`audit`** → `AUDIT` mode (does each feature still matter? has the market shifted?)
- **`consolidate`** → `CONSOLIDATE` mode (maintain knowledge model only)
- **`stale`** → `STALE` mode (find outdated patterns)
- **`accuracy`** → `ACCURACY` mode (just the number — accuracy + calibration)
- **`session`** → `SESSION` mode (grade only current session's predictions)
- **`health`** → `HEALTH` mode (dashboard — prediction frequency, grading latency, model freshness)
- **`dimensions`** → `DIMENSIONS` mode (by-topic accuracy, blind spots)
- **`auto`** → `AUTO` mode (mechanical grading from score-cache + eval-cache + git)

---

## FULL Mode (default)

### Step 1: Grade Ungraded Predictions

Read `~/.claude/knowledge/predictions.tsv`.
Find rows where `correct` column is empty.

For each ungraded prediction:
1. Read the prediction and evidence
2. Check current state: did the predicted outcome happen?
   - Check portfolio.yml for idea outcomes
   - Check research findings
   - Check decision records
3. Grade: yes / no / partial
4. If wrong or partial: what was the actual outcome? Why was the prediction wrong?
5. Write model_update: what this changes about our understanding

Update predictions.tsv with grades.

### Step 2: Consolidate Knowledge Model

Read `~/.claude/knowledge/experiment-learnings.md`.
Process all newly graded predictions:

- **Correct prediction with known pattern**: increment the experiment count
- **Correct prediction with uncertain pattern**: if now 3+ confirmations, promote to Known
- **Wrong prediction**:
  - Update the pattern with the correction
  - If a Known pattern was wrong, add a boundary condition
  - If this is a new mechanism, add to Uncertain or Unknown
- **New territory discovered**: add to Unknown Territory or Uncertain

Optionally spawn consolidator agent for large updates:
```
Agent(subagent_type: "founder-os:consolidator", prompt: "Consolidate experiment-learnings.md. [N] predictions graded. Merge duplicates, promote uncertain→known where 3+ confirm, flag stale, revive zombie dead ends.")
```

### Step 3: Feature Purpose Audit

**The world changes while you build.** Read `mind/world.md` for context, then for each active feature in `config/founder.yml`:

1. **WebSearch** "[feature category] 2026" — has someone shipped this for free? Has AI made it trivial?
2. **Check timing**: does the `why_now` from the original idea still hold? Timing windows close.
3. **Check competition**: any new entrants since the feature was defined?
4. **Check pricing model**: is per-seat still right, or should it be outcome-based?
5. **Check platform risk**: has any API or dependency this feature relies on changed terms/pricing?

For each feature, output one of:
- **Still matters** — evidence still supports it, keep building
- **Needs pivot** — the need exists but the approach is outdated, suggest change
- **Audit failed** — this feature may no longer matter, recommend kill or deprioritize

Generate tasks for any feature that needs pivot or failed audit. Tag `source: /retro audit`.

### Step 4: Stale Check

Review Known Patterns:
- Any pattern that hasn't been referenced in 30+ days → flag as potentially stale
- Any pattern with evidence from only one market/domain → flag as potentially narrow
- Any Dead End older than 6 months → flag for re-evaluation (markets change)

Run `bash scripts/stale-knowledge.sh` for mechanical staleness scan.

### Step 4: Task Generation

For every learning gap found, generate tasks:
- **Wrong prediction tasks**: investigate why the model was wrong
- **Stale knowledge tasks**: retest or prune entries >30d without confirmation
- **Prediction coverage tasks**: features with 0 predictions, blind spot dimensions
- **Model health tasks**: duplicates, empty Unknown Territory, no recent updates

Write tasks to `/todo`. Tag with `source: /retro`.

### Step 5: Output

```
  /retro
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  graded       [N] predictions  ·  [X] correct  ·  [Y] wrong  ·  [Z] partial
  accuracy     [X]%  (lifetime)  ·  [Y]%  (last 10)
  model        [N] patterns updated  ·  [M] promotions  ·  [P] corrections

  WRONG PREDICTIONS (highest learning value)
  - predicted: [X]  ·  actual: [Y]  ·  update: [what we learned]

  PROMOTIONS (uncertain → known)
  - [pattern] — now confirmed across [N] ventures

  STALE PATTERNS
  - [pattern] — last referenced [date], may need re-evaluation

  → [next action — usually /ideate or /research based on what we learned]
```

Log via `bash scripts/retro-log.sh`. Write `~/.claude/cache/last-retro.yml`.

---

## AUDIT Mode — "/retro audit"

Does each feature still matter? Has the market shifted while you were building?

For each active feature in `config/founder.yml`:

1. **WebSearch** the feature's domain — new competitors? new free alternatives? AI made it trivial?
2. Check the idea's `why_now` in portfolio.yml — is the timing window still open?
3. Check platform dependencies — API pricing changes? Terms of service shifts?
4. Check pricing model — still aligned with 2026 market expectations? (outcome-based > per-seat)
5. Read `mind/world.md` for externalities that apply

Output per feature:
```
  feature audit
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  auth           ✓ still matters    no new free alternatives, enterprise need growing
  ai-chat        ⚠ needs pivot      3 competitors launched free tiers since Feb
  pdf-export     ✗ audit failed     browser-native PDF improved, demand signal gone
  pricing        ⚠ needs pivot      per-seat → consider outcome-based

  → 2 tasks generated (tag: /retro audit)
```

Generate tasks for pivots and failures. This is the skill that prevents building features nobody needs anymore.

---

## GRADE Mode — "/retro grade"

Grade ungraded predictions only. No consolidation or staleness check.
Read `references/grading-guide.md` first.

---

## CONSOLIDATE Mode — "/retro consolidate"

Maintain knowledge model only. No grading.
- Merge duplicates in experiment-learnings.md
- Promote uncertain patterns with 3+ confirmations to Known
- Flag stale entries per `references/knowledge-maintenance.md`

---

## STALE Mode — "/retro stale"

Find outdated patterns:
- Run `bash scripts/stale-knowledge.sh`
- Flag Known Patterns with no recent prediction confirmation
- Flag Uncertain Patterns >14d old — candidates for promotion or pruning
- Flag zombie Dead Ends that appear in recent predictions

---

## ACCURACY Mode — "/retro accuracy"

One-line output. Compute from predictions.tsv directly:
- `(correct + partial * 0.5) / graded * 100`
- Report: accuracy %, total graded, ungraded backlog count
- Calibration verdict: 50-70% = well-calibrated, >70% = too safe, <50% = model needs work

---

## SESSION Mode — "/retro session"

Grade only the current session's predictions (filter by today's date):
- Grade each, write model_update for wrong ones
- Report session accuracy vs overall accuracy
- Flag if session had 0 predictions (learning loop starving)

---

## HEALTH Mode — "/retro health"

Dashboard view. No grading, no model changes. Read-only analysis:
- Prediction frequency (per week, last 4 weeks) via `bash scripts/learning-velocity.sh`
- Grading latency (how many ungraded, oldest ungraded date)
- Model freshness (file age of experiment-learnings.md)
- Section balance (Known vs Uncertain vs Unknown vs Dead Ends counts)
- Accuracy trend (rolling 5-prediction window, improving/declining/flat)

---

## DIMENSIONS Mode — "/retro dimensions"

By-topic accuracy breakdown:
- Classify predictions by keyword (score/craft/delivery/market/customer/pricing)
- Compute accuracy per domain
- Flag domains with 3+ graded and <40% accuracy as overconfident
- Flag domains with 0 predictions as blind spots

---

## AUTO Mode — "/retro auto"

Hands-off audit for programmatic invocation. Full pipeline without asking questions:
1. Mechanical grade from score-cache + eval-cache + git
2. Agent grade for remaining ungraded:
   ```
   Agent(subagent_type: "founder-os:grader", prompt: "Batch grade all ungraded predictions. Check git log, eval-cache, experiment-learnings for evidence.")
   ```
3. Wrong prediction analysis — identify mechanisms, write model_updates
4. Consolidate via consolidator agent
5. Generate ALL tasks — write to todos.yml tagged `source: /retro auto`
6. Log to `~/.claude/cache/last-retro.yml`

---

## Quality Gates

- Model updates MUST include mechanism words ("because", "discovered that", "the reason is")
- Reject updates that are tautologies ("X works because X is good")
- Wrong predictions MUST explain WHY, not just note the disagreement
- Promotions require 3+ independent data points (not 3 observations of the same thing)

---

## State Reads
- `~/.claude/knowledge/predictions.tsv`
- `~/.claude/knowledge/experiment-learnings.md`
- `config/portfolio.yml`
- `.claude/cache/eval-cache.json`
- `.claude/cache/score-cache.json`

## State Writes
- `~/.claude/knowledge/predictions.tsv` — grades added
- `~/.claude/knowledge/experiment-learnings.md` — pattern updates
- `~/.claude/cache/last-retro.yml` — retro summary
- `.claude/plans/todos.yml` — learning gap tasks

## System integration

Triggers: `/plan` (act on learning gaps), `/research` (rebuild broken model domains), `/eval` (re-evaluate after wrong predictions)
Triggered by: `/go` (post-session review), `/plan` (learning health check)

## Self-evaluation

/retro succeeded if:
- All previously ungraded predictions now have a grade
- Every wrong prediction has a model_update entry explaining WHY
- experiment-learnings.md was updated (not just read)
- Retro session was logged
- Every learning gap found has a corresponding task

## Cost note

Spawns up to 2 agents:
- `grader` (sonnet) — batch grades ungraded predictions
- `consolidator` (sonnet) — merges duplicates, promotes patterns, flags stale entries

## What you never do

- Skip grading because "not enough evidence" — make your best call
- Grade `yes` when outcome differs from prediction text
- Delete predictions — they're training signal
- Add predictions (that's /plan's job)
- Skip anti-rationalization checks
- Grade everything as "partial" to avoid committing
- Write model updates without citing a graded prediction

## If something breaks

- predictions.tsv has no ungraded entries: run `/retro health` or `/retro dimensions` instead
- consolidator produces empty output: experiment-learnings.md may be missing — create with four-zone template
- Staleness scan reports everything as stale: dates may use non-standard format — use YYYY-MM-DD
- No predictions.tsv: "No predictions to grade. Start predicting — every move needs one."

$ARGUMENTS
