---
name: eval
description: "Does each feature deliver on the customer job it serves? Reads your code, judges whether each feature delivers what it promises, scores 0-100."
argument-hint: "[feature|beliefs|add-belief|health|blind|coverage|trend|slop]"
allowed-tools: Read, Write, Bash, Grep, Glob, AskUserQuestion, WebFetch, Agent, TaskCreate
---

!command -v jq &>/dev/null && cat .claude/cache/eval-cache.json 2>/dev/null | jq 'to_entries | map({key, d: .value.delivery_score, c: .value.craft_score, score: .value.score}) | from_entries' 2>/dev/null || echo "no eval cache (jq missing or cache empty)"
!cat ~/.claude/knowledge/experiment-learnings.md 2>/dev/null | head -60 || echo "no knowledge model"

# /eval

Does each feature deliver on the customer job it serves? Score 0-100 on delivery and craft. The number IS the verdict.

## Folder contents

Read on demand — not upfront:

- `scripts/quick-eval.sh [feature]` — mechanical assertion score, no LLM
- `scripts/variance-check.sh <feature> <proposed_score>` — catch score drift vs rubric
- `scripts/rubric-status.sh` — which features have rubrics, last scores, gaps
- `scripts/eval-history.sh [feature]` — score trends over time
- `references/scoring-guide.md` — dimensions, scale, honesty rules, anti-inflation
- `references/rubric-guide.md` — how rubrics work, how to write them
- `templates/rubric-template.json` — structure for feature rubrics
- `templates/eval-report.md` — output formatting for all modes
- `gotchas.md` — real failure modes. **Read before scoring.**

## Routing

| Argument | What happens |
|----------|-------------|
| (none) | Score all active features, parallel evaluators |
| `<feature>` | Deep eval of one feature |
| `beliefs` | Run mechanical assertion checks (beliefs.yml) |
| `add-belief <feature>: <text>` | Add a new assertion to beliefs.yml |
| `health` | Assertion coverage — type distribution, gaps per feature |
| `blind` | Cold-read code vs claims, score alignment |
| `coverage` | Assertion type distribution, signal quality |
| `trend` | Classify assertions: stable, flapping, changed |
| `slop` | Scan for LLM-generated code patterns |
| `execute` | Run commands, check runtime, then score with evidence |
| `adversarial` | Spawn agent to find gaps and propose new assertions |
| `mutation` | Test assertion strength — break code, check if assertions catch it |
| `taste` / `vs <url>` | Redirect to `/taste` |

## Scoring model

**Formula:** `delivery * 0.60 + craft * 0.40`

**Delivery (60%)** — Does this feature deliver real value? Read `delivers:` and `for:` from founder.yml, then read ALL code. Score what a user would experience.

**Craft (40%)** — Is this well-made? Error handling, architecture, product surface quality.

Detailed scoring anchors, caps, and hard rules are in `references/scoring-guide.md`.

Viability is NOT scored by /eval. That's `/score` via agent-backed research.

## What to read

- `config/founder.yml` — features, claims, code paths
- `.claude/cache/eval-cache.json` — previous scores for delta
- `.claude/cache/rubrics/<feature>.json` — anchoring rubrics
- `~/.claude/knowledge/experiment-learnings.md`
- `gotchas.md` — calibrate before scoring

## How to score

For each active feature:

1. Read ALL files in `code:` paths — no skimming
2. Check rubric — `.claude/cache/rubrics/<feature>.json`. Anchor to it.
3. Judge delivery and craft with file:line evidence
4. Run `bash scripts/variance-check.sh <feature> <score>` before publishing
5. Run `bash scripts/quick-eval.sh` for mechanical belief results alongside

**Parallel evaluators (3+ features):** Spawn one evaluator per feature:
```
Agent(subagent_type: "founder-os:evaluator", prompt: "Deep eval '[name]'. Read ALL code in [paths]. Score delivery/craft 0-100 with file:line evidence. Check rubric.", run_in_background: true)
```

**Multi-sample median:** For contested scores, run 3 evaluations and take the median. This kills the +/-15pt LLM variance problem.

## What to write

- Merge into `.claude/cache/eval-cache.json` — preserve unscored features
- Write/update rubrics per feature
- Output: scores, gaps, file:line evidence, delta vs previous

## Belief sub-commands

/eval absorbs assertion management from the former /assert skill.

**`eval beliefs`** — Run mechanical assertion checks via `bash scripts/quick-eval.sh`. Shows pass/fail counts per feature.

**`eval add-belief <feature>: <text>`** — Append to `lens/product/eval/beliefs.yml`. Auto-detect type: file path → `file_check`, "contains"/"has" → `content_check`, "command"/"runs" → `command_check`, else → `llm_judge` (flag it — mechanical preferred). Default severity: `warn`.

**`eval health`** — Read beliefs.yml directly. Show: assertion count per feature, type distribution, mechanical-vs-llm ratio, coverage gaps. Cross-reference features in founder.yml to find features with zero assertions.

## Other modes

- **Blind**: Cold-read code vs `delivers:` claims. Categories: ALIGNED, INFLATED, DEFLATED, DISCONNECTED.
- **Coverage**: Assertion type distribution per feature. Ideal: 30% mechanical, 50% content/command, 20% llm_judge.
- **Trend**: Read `.claude/evals/assertion-history.tsv`. Classify: stable, flapping, recently changed.
- **Slop**: Comments restating code, over-engineered abstractions, generic names, empty catches. Cite file:line. Report human-quality %.

## Adversarial mode

Spawns an evaluator agent in a worktree to find product gaps that current assertions don't cover.

The agent:
1. Reads all active features from founder.yml
2. Reads current beliefs.yml to know what's already tested
3. Explores the codebase looking for: missing error handling, dead ends, uncovered edge cases, untested flows
4. For each gap found, proposes a new assertion in beliefs.yml format
5. Returns proposed assertions for founder review — never auto-adds

Use AskUserQuestion to confirm each proposed assertion before adding.

## Mutation mode

Tests whether assertions actually protect against regressions.

For each high-value assertion:
1. Identify the code path it tests
2. Spawn an agent in worktree isolation
3. Agent makes a minimal breaking change (remove error handler, delete redirect, break validation)
4. Run quick-eval.sh to check if the assertion catches the break
5. Revert (worktree is disposable)

Report: "N/M assertions caught their mutation. K assertions passed despite broken code — these are decorative."

Cost note: spawns 1 agent per assertion tested. Use `mutation [feature]` to limit scope.

## First-run guidance

No features in founder.yml:
- "No features yet. `/feature new [name]` or `/onboard` to auto-detect."

## What you never do

- Score without reading code — read every file before scoring
- Give a score without file:line evidence
- Present beliefs as the primary result — 0-100 scores are the eval
- Grade predictions or write to predictions.tsv — that's /retro
- Edit code — eval is measurement only

## System integration

Reads: founder.yml, eval-cache.json, rubrics/*.json, experiment-learnings.md, beliefs.yml
Writes: eval-cache.json, rubrics/<feature>.json, beliefs.yml (add-belief/health modes)
Triggers: /score (unified quality), /taste (visual quality for web), /go (build from gaps)
Triggered by: /go (measurement), /plan (stale data), /score (code tier)
Agents: **founder-os:evaluator** (parallel per feature), **founder-os:measurer** (cheap mechanical)

## If something breaks

- No features in founder.yml: "No features defined. `/feature new [name]`"
- Code paths empty: score 0, note "no code files found"
- Cache missing: no delta, establish baseline
- Rubric missing: score from scratch, write rubric after
- Beliefs fail: run `bash scripts/quick-eval.sh` to diagnose
- Scripts fail on missing `jq`: tell user `brew install jq`, continue manually

$ARGUMENTS
