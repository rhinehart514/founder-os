# /research Reference — Multi-Source Protocol & Output Templates

Loaded on demand. Routing and core protocol are in SKILL.md.

---

## Multi-source investigation protocol

### 1. Source selection
Auto-determine which sources to use based on the topic:

- **docs** (context7): resolve-library-id → query-docs. Use when the topic involves a library, framework, or API. Real-time accurate docs vs web search hallucinations.
- **web** (WebSearch + WebFetch): blog posts, discussions, best practices. Use for patterns, approaches, industry knowledge.
- **site** (playwright): browser_navigate + browser_snapshot + browser_evaluate. Use when visual or structural analysis of a live product matters.
- **codebase** (Grep/Glob/Read): internal patterns, existing implementations. Always check.
- **knowledge** (experiment-learnings.md): avoid re-researching known patterns. Check what we already know.

### 2. Cross-referencing
Findings from one source feed queries to another:
- Web reveals a pattern → check codebase for existing usage → pull docs for the library
- Codebase uses a library → pull context7 docs → web search for advanced patterns
- Site analysis reveals a technique → web search for implementation → check docs

### 3. Actionable output
Every research session must end with one of:
- **Task proposal** — specific work for /plan to pick up
- **Assertion proposal** — testable belief for beliefs.yml
- **Model update** — pattern added to experiment-learnings.md
- **Specific next experiment** — what to try and what it would prove

## Research artifact format

Write `~/.claude/cache/last-research.yml` so /plan can read it:
```yaml
date: YYYY-MM-DD
topic: [what was researched]
mode: [docs|site|feature|free-form|claude-code|competitor|top-unknown]
product_completion: [current %]
targets_feature: [feature name this research is about]
targets_score: [what eval score improvement this enables, e.g., "40 → 60"]
findings:
  - finding: [one-line summary]
    source: [context7|web|playwright|codebase|knowledge]
    detail: [2-3 sentences]
suggested_tasks:
  - [task description for /plan to pick up]
suggested_assertions:
  - [testable belief for beliefs.yml]
suggested_score_updates:
  - feature: [name]
    current_score: [N]
    expected_score: [N]
    reason: [why this research justifies the update]
model_updates:
  - section: [Known|Uncertain|Unknown|Dead Ends]
    entry: [what was added/changed]
```

## Output format

### Feature research (with sub-scores)

```
◆ research — scoring

  product: **64%** · bottleneck: **learning** (building, w:4)
  scoring: 58/100 (d:62 c:50 v:60) — weakest: **craft_score 50**
  predict: error handling patterns will reveal 3+ unhandled paths
  because: Known Pattern — craft_score correlates with error path coverage
  targeting: scoring craft_score 50 → 65
  sources: codebase, context7, web

▾ findings
  · 4 unhandled subprocess calls in bin/score.sh — [codebase]
    Lines 120, 245, 380, 510 use 2>/dev/null without fallback.
    If jq or curl isn't installed, score.sh silently returns 0.

  · bash error handling best practice: trap + set -e + explicit checks — [web]
    Community consensus: 2>/dev/null is acceptable for optional features
    but not for core scoring logic. Trap-based cleanup is more robust.

  · rubric check (scoring): integrity axis says "all file I/O paths have error handling" for 80 — [codebase]
    Current state: 4 of 7 I/O paths handled. Rubric would score ~55 on integrity.

▾ what this changes
  · next build session: wrap the 4 subprocess calls in explicit error checks
  · pattern confirmed: craft_score tracks error path coverage (Known)
  · scoring: working → working (still needs UX work after quality fix)

▾ model update
  Known:     "craft_score tracks error path coverage" confirmed (3rd experiment)
  Uncertain: "trap-based cleanup improves robustness" (needs testing)
  Dead ends: none

  verdict: ✓ prediction correct — found 4 unhandled paths (predicted 3+)

▾ actionable
  · task: "wrap 4 subprocess calls in score.sh with error handling" → captured as todo
  · assert: "scoring: all subprocess calls have error handling"
  · next: test if fixing these 4 paths actually raises craft_score

▾ todos captured
  · [scoring] wrap subprocess calls in score.sh with error handling    /research  [new]
  · [scoring] add assertion: subprocess error handling                 /research  [new]

/plan scoring     turn findings into moves
/go scoring       build the fix
/eval deep scoring  verify after fix
```

### Top unknown research

```
◆ research — loop-compounds (top unknown)

  product: **64%** · bottleneck: **learning** (building, w:4)
  predict: prediction accuracy improves across sessions when experiment-learnings is cited
  because: Exploring — zero data on cross-session compounding
  targeting: learning craft_score 40 → unknown (exploratory)
  sources: knowledge, codebase, web

▾ findings
  ...

▾ todos captured
  · [learning] research: measure prediction accuracy by session       /research  [new]
  · research: does citing experiment-learnings improve predictions?   /research  [new]

/plan learning    apply learnings
/retro            grade this prediction
/go learning      build on findings
```

### Market research

```
◆ research market

  spawned: market-analyst agent
  product: **64%**
  predict: 2-3 competing approaches exist for product quality measurement
  sources: web, playwright (via agent)

▾ findings (from market-analyst agent)
  · [finding from agent]
  ...

▾ market context written to .claude/cache/market-context.json

▾ todos captured
  · research: investigate [competitor approach]                       /research  [new]

/eval vs [url]    compare against competitor
/ideate           brainstorm from market gaps
/product          revisit value proposition
```

**Formatting rules:**
- Header: `◆ research — [topic]`
- Feature research shows sub-scores with weakest dimension highlighted
- `targeting:` names the specific sub-score and goal
- Prediction block: predict/because/targeting/sources, indented
- Findings: bullet list with source attribution, each with detail
- Rubric checks shown when `.claude/cache/rubrics/<feature>.json` exists
- Model update: compact summary of what changed in experiment-learnings.md
- Verdict: ✓/✗/— with explanation
- Actionable: task proposals, assertion proposals, next experiments
- Todos captured: list of items written to todos.yml with source tag
- Bottom: 2-3 relevant next commands

## Tools to use

**Use context7** (resolve-library-id → query-docs) for any library or framework documentation. This is the biggest upgrade — real-time accurate docs vs web search hallucinations. Always prefer context7 for technical docs.

**Use playwright** (browser_navigate, browser_snapshot, browser_evaluate) for live site analysis. Visual and structural understanding of real products.

**Use WebSearch and WebFetch** for external research — blog posts, discussions, patterns, competitor analysis.

**Use Agent (Explore)** for deep codebase analysis — tracing dependencies, mapping architecture.

**Use Agent (general-purpose)** for parallel research threads — e.g., research competitors AND codebase simultaneously.
