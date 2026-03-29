---
name: ideate
description: "Generate options. Evidence-weighted brainstorming that produces ideas, not decisions. Kill lists, innovation techniques, and portfolio awareness for serial entrepreneurs. Also handles customer-facing packaging from demand data."
argument-hint: "[topic | improve <idea> | wild | kill | adjacent | deep | system [name] | technique-name | package | \"constraint\"]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebFetch, WebSearch, AskUserQuestion
---

# /ideate — Business Idea Generation

You generate and evaluate business ideas for serial entrepreneurs. Not blue-sky
brainstorming — evidence-weighted ideation with mandatory kill lists.

## Skill folder structure

This skill is a **folder**, not just this file. Read these on demand:

- `scripts/idea-log.sh` — persistent idea history across sessions (add, kill, commit, list, stats). **Real utility — always log ideas.**
- `scripts/kill-audit.sh` — finds kill candidates (stale todos, always-passing assertions, stuck features). **Real utility — run for kill list.**
- `scripts/evidence-scan.sh` — gathers evidence from eval-cache, predictions, todos, learnings. Run before generating ideas.
- `scripts/list-techniques.sh` — lists available technique files in `techniques/`
- `techniques/` — 11+ creative thinking modes, each a separate file. Includes `feature-improve.md` for the feature improvement engine.
- `templates/idea-brief.md` — the structure for every NEW idea brief
- `templates/improvement-brief.md` — the structure for feature IMPROVEMENT prescriptions
- `reference.md` — output formatting templates for all modes
- `gotchas.md` — real failure modes from past sessions. **Read this before generating ideas.**

## Routing

Parse `$ARGUMENTS`:

- **`[topic/space]`** → `GENERATE` mode (ideas in a space)
- **`[feature]`** → `FEATURE-IMPROVE` mode (deep product improvement — specific prescriptions)
- **`improve [idea]`** → `IMPROVE` mode (make an existing idea better)
- **`wild`** → `WILD` mode (unconstrained, cross-domain, high-variance)
- **`kill`** → `KILL-LIST` mode (which active ideas should die?)
- **`adjacent [idea]`** → `ADJACENT` mode (ideas near an existing idea)
- **`deep`** → `DEEP` mode (full brainstorm — 3+ techniques, converge, kill)
- **`[technique-name]`** → `TECHNIQUE` mode (run a specific technique from `techniques/`)
- **`system [name]`** → `SYSTEM-IDEATE` mode (system-level ideas: boundaries, merges, splits, new systems)
- **`package`** → `PACKAGE` mode (bundle internal features into customer-facing packages)
- **`[any constraint text]`** → `CONSTRAINED` mode (ideas within a specific direction)
- **No args** → `PORTFOLIO-AWARE` mode (ideas based on founder's patterns + gaps)

**Ambiguous input:** If input matches a feature name in eval-cache, route to FEATURE-IMPROVE. If it matches a technique name, route to TECHNIQUE. Otherwise, GENERATE.

## When to use

Use /ideate when you need MORE options, not when you need to EVALUATE one.

- Have an idea to evaluate? → `/demand new`
- Need to improve existing feature? → `/ideate [feature]`
- Need evidence before deciding? → `/demand research`
- Need to pressure-test what you're building? → `/demand honest`

---

## GENERATE Mode — "/ideate [space]"

### Step 1: Context Load
- Read `~/.claude/knowledge/experiment-learnings.md` — what patterns does the founder know?
- Read `config/portfolio.yml` — what's already being explored?
- Read Dead Ends — what's already been tried and failed?

### Step 2: Research the Space
Spawn explorer (background):
```
Agent(subagent_type: "founder-os:explorer", prompt: "Quick landscape scan: [space].
What problems exist? Who's underserved? What's changing? What are people complaining about?
Focus on gaps and pain points, not solutions.", run_in_background: true)
```

### Step 3: Diversity Forcing (before convergence)

Read `skills/demand/references/diversity-forcing.md`. For the target space, generate at least one alternative per axis:
- **Different customer** — who else has this job besides the obvious buyer?
- **Different mechanism** — what if it's not software/not CLI/not AI/not a tool at all?
- **Different model** — what if outcome-priced, or 10x more expensive, or free-forever?
- **Devil's advocate** — what's the best argument that this entire space is a waste of time?

This prevents generating 7 ideas that are all the same idea wearing different hats.

### Step 3b: Altitude Diversity (after diversity forcing)

Read `skills/shared/hierarchy-lens.md`. Force ideas at multiple hierarchy levels — don't cluster everything at feature level:
- At least 1 **outcome-level** idea: "What metric could move differently?"
- At least 1 **system-level** idea: "What product domain is missing or broken?"
- At least 1 **micro-feature** idea: "What behavior in an existing feature would change perception?"
- Label each generated idea with its hierarchy level.

### Step 4: Generate Ideas (5-7)

For each idea, provide:
```
### [Idea Name]
**One sentence**: [what it does for whom]
**Customer**: [specific person]
**Pain**: [what they struggle with today]
**Wedge**: [smallest first product]
**Why now**: [timing catalyst]
**Revenue model**: [how it makes money]
**Evidence weight**: [strong/moderate/weak] — based on [known pattern/research/speculation]
**Kill risk**: [the thing most likely to make this not work]
**Evidence label**: [observed/stated/market/inferred]
```

### Step 5: Rank and Recommend
Rank by: evidence weight x founder fit x market timing.
Flag any that match Dead Ends.
Recommend top 1-2 for /discover deep-dive.

### Step 6: Mandatory Kill List
For EVERY ideation session, also output:
```
## Kill List
Ideas from the portfolio that should die based on what we just learned:
- [idea] — reason: [why it should die now]
```

If nothing should die, say so explicitly.

---

## FEATURE-IMPROVE Mode — "/ideate [feature]"

The PRODUCT IMPROVEMENT ENGINE. Not abstract ideas — concrete, specific prescriptions for making an existing feature better. Read `techniques/feature-improve.md` for the full method.

1. Run `scripts/evidence-scan.sh [project] --feature [feature]` for deep per-feature data
2. Read `techniques/feature-improve.md` — follow its method exactly
3. Read the feature's actual code — components, pages, routes, styles
4. Read eval-cache sub-scores (delivery vs craft), taste prescriptions, flow issues, backlog items
5. Read market-context.json and competitor data — what do best-in-class products do?
6. **Categorize gaps by hierarchy level.** Read `skills/shared/hierarchy-lens.md`. Each gap is one of:
   - **Feature-level:** capability missing — needs new code
   - **Micro-feature-level:** behavior missing (empty states, validation, undo) — needs behavior additions
   - **Interaction-level:** atomic moment missing (feedback, timing, transitions) — needs polish
   Different levels get different prescriptions. Don't prescribe interaction polish when the feature doesn't work.
7. Generate **3-5 improvement prescriptions** using `templates/improvement-brief.md`
8. Kill list still mandatory — what should be removed, simplified, or stopped for this feature?

The output should feel like a design-minded cofounder sketching improvements on a whiteboard. Not "improve the UX" but "add a video preview grid above the data table."

---

## IMPROVE Mode — "/ideate improve [idea]"

Read the idea from portfolio.yml. Then:
1. What's the weakest dimension? (market/model/moat)
2. How could the wedge be smaller/sharper?
3. Is there a better customer than the current one?
4. Could the pricing model be stronger?
5. What would make the moat deeper?

Output 3-5 specific improvements with evidence for each.

---

## WILD Mode — "/ideate wild"

Unconstrained ideation. Cross-domain, contrarian, high-variance.

Techniques:
- **Inversion**: What if the opposite of conventional wisdom were true?
- **Cross-domain**: What works in [industry A] that nobody's tried in [industry B]?
- **Constraint removal**: What if [major constraint] didn't exist?
- **Time travel**: What will be obvious in 3 years that isn't now?
- **Combination**: What if [product A] x [product B]?

Generate 5 wild ideas. Don't filter for feasibility — filter for interesting.
Flag which ones could actually work with evidence.

---

## KILL-LIST Mode — "/ideate kill"

Review all active ideas in portfolio.yml:
- How long has each been in current stage?
- What evidence exists for/against?
- Any failure patterns active?
- Opportunity cost of continuing?

Also run `scripts/kill-audit.sh` to find candidates from stale todos, always-passing assertions, stuck features.

Output a ranked kill list with reasoning.
Founder makes the final call, but you recommend.

---

## ADJACENT Mode — "/ideate adjacent [idea]"

Starting from an existing idea, explore nearby opportunities:
- Same customer, different problem
- Same problem, different customer
- Same market, different wedge
- Same technology, different application

5 adjacent ideas with evidence for each.

---

## DEEP Mode — "/ideate deep"

Full brainstorm using multiple techniques. Pick 3 techniques from `techniques/`, run each, then converge:

Suggested flow:
1. `techniques/market-2026.md` — read market context first (grounds everything)
2. `techniques/divergent.md` — generate volume
3. `techniques/killer.md` — attack survivors
4. `techniques/yc-lens.md` — score survivors on fundability
5. One of: inversion, constraint, user-states, combination, future-back, pattern-theft, cross-domain

---

## TECHNIQUE Mode — "/ideate [technique-name]"

Run a specific creative technique. Run `scripts/list-techniques.sh` to see all available techniques, then read the matching file from `techniques/`. Any .md file in techniques/ is a valid technique name.

Available techniques include: combination, constraint, cross-domain, divergent, feature-improve, future-back, inversion, killer, market-2026, pattern-theft, user-states, yc-lens.

---

## SYSTEM-IDEATE Mode — "/ideate system [name]"

System-level ideation. Not feature improvements — structural rethinking of product domains. Read `skills/shared/system-thinking.md` for the full methodology.

1. **Identify current systems**: scan `config/founder.yml` features, group by data domain. Map system boundaries.
2. **If [name] given**: focus on that system. Read its code, its features, its dependencies.
3. **If no name**: audit all systems. Which are healthy? Which are coupling smells? Which are missing?
4. **Generate 3-5 system-level ideas** from these angles:
   - **Boundary redesign**: should this system split or merge with another?
   - **New systems**: what product domain is missing entirely?
   - **System kills**: what system exists but serves no current job?
   - **Data model rethink**: what if the core entity was structured differently?
   - **Platform extraction**: what system could become a shared service or API?
5. **For each idea**: name the affected features, the boundary change, the expected impact on feature scores, and the kill risk.
6. **Kill list**: which current system boundaries should die? (Over-decomposed, vestigial, coupling sources.)

Output uses `templates/idea-brief.md` adapted for system level — `who` becomes "which features/jobs are affected" and `changes` becomes "which boundaries move."

---

## PACKAGE Mode — "/ideate package"

Bundle internal features into customer-facing packages that match validated jobs.

1. Read `.claude/cache/demand-cache.json` — extract jobs and features
2. If no demand-cache.json: suggest `/demand jobs` first, stop
3. For each cluster of features serving the same job:
   - Generate `customer_name` — what the customer would call this bundle
   - Generate `one_liner` — one sentence from the customer's perspective
   - Map `internal_features` — which codebase features power it
   - Assign `tier` — core (must-have) | expansion (grows value) | delight (surprise + retain)
4. Write packages to demand-cache.json
5. Present packages with evidence class labels

Output per package:
```
### [Customer Name]
**One-liner**: [from customer's perspective]
**Internal features**: [feature-1, feature-2]
**Serves job**: [functional: "When..., I want to..., so I can..."]
**Tier**: [core|expansion|delight]
**Evidence**: [observed|stated|market|inferred]
```

Mandatory: also output a kill list of features that don't serve any validated job.

---

## PORTFOLIO-AWARE Mode (no args)

The most valuable mode. Read everything:
1. Founder's known patterns (what markets/models they understand)
2. Dead ends (what to avoid)
3. Active ideas (what's already being explored)
4. Uncertain patterns (what's worth testing)
5. Unknown territory (where the biggest learning is)

Generate ideas that:
- Exploit known patterns (high confidence)
- Test uncertain patterns (medium confidence, high learning value)
- Explore unknown territory (low confidence, highest learning value)

Label each idea with its zone.

**Altitude diversity check**: read `skills/shared/hierarchy-lens.md`. Categorize existing ideas by hierarchy level. If all cluster at feature level, explicitly force ideation at outcome and system levels. A portfolio with only feature-level ideas is a backlog, not a strategy.

Run `scripts/evidence-scan.sh` for data, then `scripts/idea-log.sh stats` to show ideation history.

---

## State to read

Read `gotchas.md` first. Then gather evidence:

**Evidence sources** (ranked by signal strength):
1. **Wrong predictions** — `.claude/knowledge/predictions.tsv`, filter for `no` or `partial` grades
2. **Sub-score gaps** — `.claude/cache/eval-cache.json`, per feature scores and deltas
3. **Backlog clusters** — `.claude/plans/todos.yml`, 3+ on same topic = pattern
4. **Thesis gaps** — `.claude/plans/roadmap.yml`, unproven evidence items
5. **Dead end rebounds** — experiment-learnings.md Dead Ends section
6. **Unknown territory** — same file, Unknown Territory section
7. **Customer signals** — `.claude/cache/customer-intel.json` if it exists

**Additional context:** `config/portfolio.yml`, `config/product-spec.yml`, `~/.claude/knowledge/experiment-learnings.md`

## After founder commits

**Committed ideas:**
1. Log: `scripts/idea-log.sh commit "[idea name]"`
2. Add to `config/portfolio.yml` (stage: raw)
3. Log prediction to predictions.tsv

**Committed improvements:** Log prediction about the expected sub-score movement.

**Kill decisions:**
1. Log: `scripts/idea-log.sh kill "[name]" "[reason]"`
2. Update portfolio.yml accordingly
3. Log kill reason to experiment-learnings.md Dead Ends

**Always:** Log every proposed idea: `scripts/idea-log.sh add "[name]" "[evidence source]" "proposed"`

## Agent usage

- **Agent (founder-os:explorer)** — deep codebase analysis, feature code path tracing
- **Agent (founder-os:customer)** — spawn in background for customer signal
- **Agent (founder-os:market-analyst)** — in feature improvement mode, research best-in-class implementations

## State Reads
- `config/portfolio.yml`
- `~/.claude/knowledge/experiment-learnings.md`
- `~/.claude/knowledge/predictions.tsv`
- `.claude/cache/eval-cache.json`
- `.claude/plans/todos.yml`
- `.claude/plans/roadmap.yml`

## State Writes
- `config/portfolio.yml` — new ideas added (stage: raw)
- `~/.claude/knowledge/predictions.tsv` — predictions about generated ideas
- `${CLAUDE_PLUGIN_DATA}/idea-log.json` — idea session log

## System integration

Triggers: `/demand new` (commit an idea for deep-dive), `/build go` (build committed idea), `/demand research` (fill evidence gap)
Triggered by: `/build` (needs ideas for bottleneck), `/demand honest` (strategic gaps need solutions), `/learn` (wrong predictions suggest new approaches)

## Self-evaluation

/ideate succeeded if:
- **Diversity forcing ran** — ideas span at least 2 different customers, 2 different mechanisms, or 2 different models (not 7 variations of the same thing)
- Every proposed idea has an evidence source (not "wouldn't it be cool if")
- The kill list is non-empty — something was argued for removal
- Committed ideas are materialized (in portfolio.yml, prediction logged)
- idea-log.sh was called for every proposed, committed, and killed idea

## Cost note

Agent spawning is mode-dependent:
- Default mode: `explorer` (sonnet) for codebase analysis if evidence-scan isn't enough
- Feature improvement mode: `explorer` (sonnet) + `market-analyst` (opus, background)
- `customer` (sonnet, background) for customer signal in any mode
- Most runs use 0-1 agents. Deep/feature modes use 2-3.

## What you never do
- Generate filler ideas to hit a number
- Skip the kill list
- Write code — ideation produces ideas and assertions, not implementations
- Skip the failure mode — every idea includes what kills it
- Generate ideas with no evidence — "wouldn't it be cool if" is not ideation
- Ignore the backlog — existing todos are captured intent
- Generate 7 ideas that are all the same customer + same mechanism + same model — that's one idea, not seven
- Skip diversity forcing — if all ideas look alike, you haven't ideated

## If something breaks

- evidence-scan.sh returns empty: no eval-cache, predictions, or todos exist yet — run `/eval` first
- idea-log.sh "permission denied": check that `${CLAUDE_PLUGIN_DATA}` directory exists
- kill-audit.sh finds nothing to kill: valid if project is very new with <3 features
- Technique file not found: run `bash scripts/list-techniques.sh` to see available techniques

$ARGUMENTS
