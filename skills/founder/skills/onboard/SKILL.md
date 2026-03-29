# /onboard — Cold-Start Protocol

Bootstrap any project from zero to working founder-os in under 2 minutes. Generates all config, demand stub, assertions, learning loop, and portfolio entry from codebase analysis.

## Time target

Under 2 minutes from invocation to full output.

## Scripts (run mechanically, not LLM)

| Script | What it does |
|--------|-------------|
| `scripts/detect-project.sh` | Language, framework, styling, testing, source structure, git state |
| `scripts/onboard-checklist.sh` | Existing artifact status, completion score (N/8) |
| `scripts/demand-from-readme.sh` | README → stub demand-cache.json with [inferred] evidence |
| `scripts/first-score.sh` | Runs score + explains what numbers mean for new users |

## Protocol

### Step 1: Detect + Check (parallel)

Run both in parallel:
```
bash scripts/detect-project.sh
bash scripts/onboard-checklist.sh
```

Capture: language, framework, source structure, git state, existing artifacts, completion score.

**Gate**: If checklist ≥ 6/8, project is already initialized. Suggest `--force` to regenerate, otherwise show current state and exit.

### Step 2: Demand-cache from README (NEW — cold-start)

Run mechanically:
```
bash scripts/demand-from-readme.sh . > .claude/cache/demand-cache.json
```

This generates a stub with [inferred] evidence labels. Then enrich it:
- Read README.md directly — extract who, what, why, how
- Read detect-project.sh output — what type of project is this?
- Update the stub's job statements to be specific to this project
- Keep all evidence labeled [inferred] — honest about cold-start state
- Set `demand_tier: "stub"` — distinguishes from real /demand output

The demand-cache gives every subsequent command (score, eval, build, plan) something to work with from minute one.

### Step 3: Understand the product

Read the actual code (key files from detect-project output). Form specific opinions:

- **What is this?** One sentence. Not "a web app" — "a campus platform that generates conflict-free course schedules."
- **Who uses it?** A person. "A first-year CS student avoiding 8am classes" not "students."
- **What value?** What changes. "Conflict-free schedule in 30 seconds instead of 2 hours."
- **Current state?** Working / broken / half-built / polished. Be honest.

### Step 4: Write config/founder.yml

Zero placeholders. Every field filled from code analysis:

```yaml
project:
  name: [from detection]
  stage: [mvp|early|growth|mature — from evidence]
  mode: build
  type: [web|cli|api|library — from detection]

value:
  hypothesis: "[user] can [action] without [pain]"
  user: "[named person from step 3]"
  signals: [2-3 measurable value signals]

features:
  [feature-name]:
    delivers: "[what user value]"
    for: "[who]"
    code: [file paths]
    status: active
    weight: [1-5]
```

Reference: `templates/founder-yml-template.yml` for full structure.

### Step 5: Generate features

Detection heuristic:
- Route directories (`app/dashboard/`) → feature
- Major source modules (`src/auth/`) → feature
- CLI commands (`bin/score.sh`) → feature
- Package scripts (`"test"`) → feature
- NOT utilities, configs, or infrastructure

Each feature needs: delivers (from code, not guess), for (who benefits), code (real file paths), weight (1-5), maturity.

### Step 6: Generate assertions (beliefs.yml)

2-3 per feature, mechanical types first:
- `file_check` — does core file exist? Contains expected content?
- `command_check` — does something run and return expected output?
- `content_check` — forbidden words in source dirs?
- `llm_judge` — LAST RESORT only

Every assertion needs: id, belief (plain English), type, feature, quality (correctness|craft|completeness), layer (infrastructure|logic|ux), severity (block|warn).

**Hard rule**: `llm_judge` assertions have ±15pt variance. Use mechanical types when possible.

### Step 7: Start learning loop + seed predictions (NEW — cold-start)

Create or verify:
- `.claude/knowledge/predictions.tsv` — with header row
- `.claude/knowledge/experiment-learnings.md` — Known/Uncertain/Unknown/Dead Ends template
- `.claude/plans/strategy.yml` — stage + bottleneck from eval
- `.claude/plans/roadmap.yml` — version thesis from value hypothesis

**Seed 3 predictions** (NEW):
1. Feature-specific: "I predict [highest-weight feature] will score above 50 after first /eval because [evidence from code]. I'd be wrong if [condition]."
2. System-level: "I predict assertions will achieve 60%+ pass rate within one /build session because [N] features have clear file_check targets."
3. Bottleneck: "I predict [weakest feature from detection] is the bottleneck because [evidence]. I'd be wrong if [condition]."

All predictions labeled `evidence=[inferred] cold-start seed`. These start the learning loop spinning immediately — a new user gets grading and accuracy tracking from session 2.

### Step 8: Portfolio entry (NEW — cold-start)

Read `~/.founder-os/portfolio.yml`. If this project is not already listed:
- Add entry with: name, stage, created (today), outcome (from hypothesis)
- Set `demand_tier: "hypothesized"` (stub exists, not validated)
- Link to demand-cache.json jobs
- Do NOT overwrite existing entries

### Step 9: First score + present

Run `scripts/first-score.sh` (calls `founder score .` with explanation).

Present output:

```
◆ onboard — [project name]

  [project name] — [one sentence description]
  for: [who]
  hypothesis: "[testable sentence]"
  stage: [stage] · mode: build

  ✓ config/founder.yml — value hypothesis + [N] features
  ✓ beliefs.yml — [N] assertions across [N] features
  ✓ demand-cache.json — [N] jobs (stub, [inferred])
  ✓ portfolio entry — added to ~/.founder-os/portfolio.yml
  ✓ predictions seeded — 3 initial predictions logged
  ✓ learning loop — predictions.tsv, experiment-learnings.md

▾ features detected
  ▸ [name]     w:[N]  [maturity]  [score]/100
    "[delivers]"

  score: [N]/100 · assertions: [pass]/[total]
  bottleneck: **[worst feature]** — [why]

▾ demand stub (run /demand new for real validation)
  job: "[functional job statement]" [inferred]
  next: /demand new

▾ what's next
  /plan              find the bottleneck and plan a fix
  /go [feature]      autonomous build on the worst feature
  /demand new        replace stub with real JTBD validation
```

## State

**Reads**: README.md, package.json (or equivalent), source files, ~/.founder-os/portfolio.yml
**Writes**: config/founder.yml, beliefs.yml (or lens/product/eval/beliefs.yml), .claude/cache/demand-cache.json, .claude/plans/strategy.yml, .claude/plans/roadmap.yml, ~/.founder-os/portfolio.yml, ~/.claude/knowledge/predictions.tsv

## Self-evaluation

Onboard succeeded if:
- [ ] founder.yml has zero empty/placeholder fields
- [ ] beliefs.yml has ≥ 2 assertions per feature, mechanical types preferred
- [ ] demand-cache.json exists with ≥ 1 job, all labeled [inferred]
- [ ] portfolio.yml has entry for this project
- [ ] predictions.tsv has ≥ 3 seed predictions
- [ ] Checklist score improved from step 1 baseline
- [ ] Total time < 2 minutes
- [ ] Output shows features, score, bottleneck, and next commands

## What you never do

- Generate placeholder text ("TODO", "describe your product here")
- Skip demand-cache generation — even a stub beats nothing
- Create demand-cache jobs without [inferred] labels
- Overwrite existing portfolio entries for other projects
- Skip mechanical assertion types for llm_judge
- Spend more than 30 seconds on any single step
- Claim demand is "validated" from code reading alone — it's [inferred] until real users confirm
