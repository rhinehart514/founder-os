---
name: feature
description: "Use when the user wants to define, view, detect, or improve features — including maturity tracking, sub-scores, and feature-specific ideation"
argument-hint: "[name|new|detect] [name]"
allowed-tools: Read, Bash, Grep, Glob, Edit, Write, AskUserQuestion, WebSearch, Agent
user-invocable: false
---

<!-- INTERNAL: This skill is for founder-os self-management, not marketplace distribution. -->

!cat .claude/cache/eval-cache.json 2>/dev/null | jq 'to_entries | map({key, score: .value.score, delivery: .value.delivery_score, craft: .value.craft_score, viability: .value.viability_score, delta: .value.delta}) | from_entries' 2>/dev/null || echo "no eval cache"

# /feature

Features are named parts of your product. Each has assertions, pass rates, sub-scores (delivery/craft/viability), weights, and dependencies.

## Skill folder structure

This skill is a **folder**, not just this file. Read on demand:

- `references/feature-lifecycle.md` — maturity stages and what moves each transition
- `references/feature-design.md` — how to define a good feature, common mistakes
- `references/improvement-protocol.md` — full method for feature improvement ideation (read for `[name] ideate`)
- `templates/feature-template.yml` — copy-paste template for founder.yml
- `reference.md` — output formatting templates
- `gotchas.md` — real failure modes. **Read before creating, killing, or improving features.**

Scripts (`feature-map.sh`, `feature-health.sh`, `feature-ideate.sh`, `dependency-graph.sh`) exist as verification — run to cross-check your synthesis, not as the primary path.

## State

Read these directly — synthesize, don't delegate:

| File | What it tells you |
|------|-------------------|
| `config/founder.yml` | Feature definitions: name, delivers, for, code paths, weight, depends_on, status |
| `config/product-spec.yml` | What the product claims — features should map to spec sections |
| `.claude/cache/eval-cache.json` | Per-feature scores, delivery/craft/viability sub-scores, deltas, timestamps |
| `.claude/cache/rubrics/<feature>.json` | Per-feature rubric (for detail views) |
| `.claude/knowledge/predictions.tsv` | Relevant predictions about features (fall back to `~/.claude/knowledge/`) |
| `.claude/plans/roadmap.yml` | Thesis evidence — which features connect to the current version thesis |
| `lens/product/eval/beliefs.yml` | Assertions per feature — pass rates, coverage |
| `.claude/plans/todos.yml` | Open backlog items per feature |

**Maturity labels** (derived from eval score, not stored): 0-29=planned, 30-49=building, 50-69=working, 70-89=polished, 90+=proven.

## Routing

Parse `$ARGUMENTS`:

| Argument | Action |
|----------|--------|
| (none) | Read founder.yml features + eval-cache → list all active features with sub-scores, weights, maturity, dependencies → name the bottleneck |
| `[name]` | Read feature entry + eval-cache + rubric + beliefs + todos → detail view with sub-score breakdown, assertion pass rate, dep status, verdict |
| `[name] [name]...` | Detail for each, identify weakest |
| `new [name]` | AskUserQuestion for delivers/for/code/weight/depends_on → write to founder.yml → baseline eval |
| `detect` | Glob/Grep scan → cross-ref founder.yml → AskUserQuestion to confirm → write |
| `[name] status [value]` | Lifecycle transition: active/proven/killed/archived |
| `[name] ideate` | Context-aware improvement engine — reads ALL state for this feature → specific prescriptions |
| `[name] research` | WebSearch + codebase scan → findings + recommendations |

**Ambiguity rule:** exact keyword > feature name match > free-form lookup. Never ask "did you mean?" — just act.

**Status filter:** only show `active` and `proven` features. Skip `killed`/`archived` unless explicitly requested.

## Ideate mode — the feature improvement engine

When `[name] ideate` is triggered, this is a context-aware improvement engine, not a brainstorm. Read `references/improvement-protocol.md` for the full method.

For deep feature improvement with creative techniques (divergent thinking, market analysis, cross-domain patterns), use `/ideate [feature]` instead. `/feature [name] ideate` focuses on score-driven diagnosis and buildable prescriptions from existing state; `/ideate [feature]` brings the full creative toolkit.

**What to read:** The feature's eval-cache sub-scores, its code files (from founder.yml `code:` field), its assertions and pass rates, its todos, accumulated intelligence via `skills/plan/scripts/intelligence-query.sh [project] [feature]`, and any taste/flows reports that mention it.

**What to synthesize:** Diagnose the gap — delivery (doesn't work), craft (works but rough), or viability (works but who cares?). Cite sub-scores. Generate 3-5 specific, buildable prescriptions with predicted score impact. Include a kill list: complexity that serves no user.

**Present + materialize:** AskUserQuestion for founder selection → write todos, log predictions.

**Agents (optional, for complex features):**
- **founder-os:explorer** — trace code paths when the code list is large
- **founder-os:market-analyst** — background research on how best-in-class products handle this feature type. Write to `.claude/cache/feature-research-[name].json`. Skip if market context is fresh (<7d).

## System integration

**Reads:** founder.yml, product-spec.yml, eval-cache.json, rubrics/, predictions.tsv, roadmap.yml, beliefs.yml, todos.yml, market-context.json, customer-intel.json, taste/flows reports
**Writes:** `config/founder.yml` (new/detect/status), `.claude/cache/feature-research-[name].json` (ideate)
**Triggers:** /eval (baseline after new), /plan (bottleneck identified), /assert suggest (coverage gaps), /ideate (improvement prescriptions), /go (build tasks), /research (viability gaps)
**Triggered by:** "what features?", "list features", "how's [feature]?", post-eval review, /plan bottleneck drill-down

## Task generation — the path to feature completion

See `../shared/task-generation.md` for the task generation protocol. /feature generates tasks for:

**For EVERY feature analyzed, generate the complete task list:**

### Blocked feature tasks
- Each feature blocked by a dependency scoring <50 → task: "Feature [X] blocked by [Y] scoring [Z] — fix [Y] first"
- Each feature with status `active` but no code paths → task: "Feature [X] defined but has no code — implement or kill"
- Each feature with broken dependency chain → task: "Feature [X] depends on [Y] which depends on [Z] — unblock from bottom"

### Maturity gap tasks
- Each feature scoring <30 (planned) with weight >2 → task: "High-weight feature [X] at [score] — needs implementation"
- Each feature scoring 30-49 (building) → tasks for specific delivery gaps from eval-cache sub-scores
- Each feature scoring 50-69 (working) → tasks for craft improvements from eval-cache
- Each feature at 70+ but with viability dragging → task: "Feature [X] works but viability is [V] — run /research to validate"

### Assertion coverage tasks
- Each feature with 0 assertions → task: "Feature [X] has no assertions — run /assert suggest [X]"
- Each feature where all assertions pass but score is <50 → task: "Feature [X] passes all assertions but scores [N] — assertions are too weak"
- Each feature with no eval data → task: "Feature [X] never evaluated — run /eval [X]"

### Weight/priority tasks
- Feature weights don't match thesis priorities → task: "Feature [X] weight [W] doesn't match thesis — re-weight"
- High-weight features with lowest scores → task: "Bottleneck: feature [X] (w:[W]) scoring [S] — highest leverage fix"
- Features with no weight assigned → task: "Feature [X] has no weight — assign based on thesis"

### Lifecycle tasks
- Features stuck at same maturity for >14d → task: "Feature [X] stuck at [maturity] for [N]d — diagnose via /eval [X]"
- Features with declining scores → task: "Feature [X] regressed from [old] to [new] — investigate"
- Features that should be killed (no progress, low weight, no thesis connection) → task: "Consider killing feature [X] — run /ideate kill"

Tag with `source: /feature`, feature name, and gap type (blocked/maturity/coverage/weight/lifecycle). Priority: highest-weight features with lowest scores first.

## Self-evaluation

The skill worked if:
- **List view**: every active feature shows sub-scores and a maturity label consistent with eval-cache
- **Detail view**: the feature's delivery/craft/viability breakdown is shown with actionable verdict
- **Ideate**: produced 3-5 buildable prescriptions (not generic advice) with predicted score impact
- **New/detect**: feature was written to founder.yml AND baseline eval was triggered
- **All modes**: tasks were generated for every gap found and written to /todo

## Agent cost note

`/feature [name] ideate` may spawn two agents: **explorer** (sonnet, traces code paths) and **market-analyst** (opus, background, researches competitors). The market-analyst is the expensive one -- skip it if the feature is internal-only or the market context is already fresh (<7d).

## What you never do

- Output raw CLI output without formatting — use `reference.md` templates
- Create features without asking what they deliver
- Skip baseline eval after creating a new feature
- Show scores without sub-score breakdown when eval-cache has them
- Let maturity labels diverge from eval scores (read `references/feature-lifecycle.md`)

## If something breaks

- No founder.yml → suggest `/onboard` to initialize the project
- No eval-cache.json → show features from founder.yml with "unscored" label, suggest `/eval`
- No features defined → suggest `/feature new [name]` or `/feature detect`
- Feature name doesn't match founder.yml → fuzzy match on delivers/code fields, or suggest closest

$ARGUMENTS
