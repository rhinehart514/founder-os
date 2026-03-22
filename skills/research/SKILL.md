---
name: research
description: "Gathers evidence for business decisions. Market intelligence, competitor teardowns, customer signals, technology landscape, live site analysis. Evidence, not opinions."
argument-hint: "[idea-name | market | competitor <name> | customer | docs <lib> | site <url> | gaps | feature <name> | history]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebFetch, WebSearch
---

# /research — Evidence Gathering

You gather evidence to inform go/kill/pivot decisions. You produce findings, not recommendations.

## Skill folder structure

This skill is a **folder**, not just this file. Read these on demand:

- `scripts/research-log.sh` — persistent research history (add, stats, repeats, topic search). Uses `${CLAUDE_PLUGIN_DATA}`.
- `scripts/source-quality.sh` — rates sources by reliability tier (T1-T5). **Real utility — run to rate evidence quality.**
- `scripts/market-scan.sh` — structured competitor/market data via WebSearch. **Real utility — run for market/competitor routes.**
- `references/research-methods.md` — when to use WebSearch vs context7 vs Playwright vs codebase. Signal vs noise.
- `references/evidence-hierarchy.md` — ranking evidence types (user behavior > statements > market > desk research > intuition)
- `templates/research-brief.md` — template for research output (findings, confidence, unknowns resolved)
- `templates/market-context.json` — schema for market-context.json so research outputs are structured
- `reference.md` — output formatting templates, multi-source protocol, research artifact format
- `gotchas.md` — real failure modes. **Read before every session.**

## Routing

Parse `$ARGUMENTS`:

- **`[idea-name]`** → `IDEA` mode (research the top unknown for this idea)
- **`market [space]`** → `MARKET` mode (market sizing, trends, timing)
- **`competitor [name]`** → `COMPETITOR` mode (deep teardown of one competitor)
- **`customer [idea]`** → `CUSTOMER` mode (find customer signal)
- **`docs [library]`** → `DOCS` mode (pull real-time library/API docs for building)
- **`site [url]`** → `SITE` mode (analyze a live product)
- **`gaps`** → `GAPS` mode (what don't we know across the portfolio?)
- **`feature [name]`** → `FEATURE` mode (deep-dive a specific feature from code + external sources)
- **`history`** → `HISTORY` mode (review past research sessions)
- **`compete`** → `COMPETE` mode (analyze specific competitors — positioning, pricing, features, weaknesses)
- **No args** → `TOP-UNKNOWN` mode (find and research the highest-value unknown)

**Ambiguous input:** exact keyword match wins -> idea name match -> free-form topic. Never ask "did you mean?" — just act.

## When to use

Use `/research` when you need evidence before making a decision — filling knowledge gaps, investigating unknowns, or gathering competitive intel. Use `/ideate` instead when you already have enough evidence and need ideas for what to build. Use `/product` when the question is "should this exist?" rather than "how should it work?" Use `/strategy` when the question is about positioning, not information gathering.

---

## TOP-UNKNOWN Mode (default)

1. Read `config/portfolio.yml` — find ideas in active stages (researching, validating)
2. Read `~/.claude/knowledge/experiment-learnings.md` — check Unknown Territory section
3. For each active idea, identify the hypothesis with status: `untested` that would be most decisive
4. Pick the ONE unknown with highest information value (usually: the kill condition)
5. Research it using explorer + market-analyst agents
6. Update the hypothesis status with evidence

---

## IDEA Mode — "/research [idea-name]"

1. Read the idea from `config/portfolio.yml`
2. Identify the weakest-evidenced dimension (market/model/moat)
3. Spawn appropriate agent:
   - Market weak → market-analyst
   - Model weak → gtm agent
   - Customer unclear → customer agent
4. Update idea with findings
5. Log prediction before researching

---

## MARKET Mode — "/research market [space]"

Spawn in parallel:
```
Agent(subagent_type: "founder-os:explorer", prompt: "Market research: [space].
TAM/SAM sizing (bottom-up preferred), growth trends, timing catalysts,
adjacent markets, regulatory environment.", run_in_background: true)

Agent(subagent_type: "founder-os:market-analyst", prompt: "Competitive landscape: [space].
Top 10 players, pricing, positioning, recent funding/M&A, gaps.",
run_in_background: true)
```

Also run `scripts/market-scan.sh` for structured competitor/market data.

Synthesize into market brief. Store in `.claude/cache/last-research.yml`.

---

## COMPETITOR Mode — "/research competitor [name]"

Spawn explorer to deep-dive one competitor:
- Product (features, UX, what they do well)
- Pricing (tiers, model, value metric)
- Positioning (who they target, messaging)
- Weaknesses (user complaints, G2/Capterra reviews, Reddit threads)
- Technology (stack, APIs, integrations)
- Trajectory (recent changes, hiring, funding)

---

## COMPETE Mode — "/research compete"

Analyze specific competitors — positioning, pricing, features, weaknesses. Uses WebSearch + Playwright + `scripts/market-scan.sh`. Deeper than competitor mode — focuses on strategic response.

---

## CUSTOMER Mode — "/research customer [idea]"

Spawn customer agent:
- Pain signals from forums, reviews, social media
- Current solutions and their costs
- Willingness-to-pay indicators
- Buyer profile (decision maker vs. user vs. blocker)
- Switching triggers

---

## DOCS Mode — "/research docs [library]"

For when you're about to BUILD. Pull real-time documentation for a library or API.
Use context7 MCP if available (resolve-library-id -> query-docs), otherwise WebFetch official docs.
Output a concise reference focused on what you need for implementation.

---

## SITE Mode — "/research site [url]"

Analyze a live product/competitor site:
- What it does (product, not marketing)
- Who it's for (evidence from copy, pricing, features)
- Pricing and packaging
- UX quality (first impression, clarity, friction)
- Technology (visible stack, integrations)
- Weaknesses (what's missing, what's confusing)

Use Playwright MCP if available for live analysis.

---

## FEATURE Mode — "/research feature [name]"

Deep-dive a specific feature from code + external sources:
1. Read eval-cache for feature scores and gaps
2. Grep/Glob the codebase for feature implementation
3. Use context7 for relevant library docs
4. WebSearch for competitive implementations
5. Synthesize: what works, what's missing, what the market expects

---

## HISTORY Mode — "/research history"

Review past research sessions via `scripts/research-log.sh`. Shows:
- Recent topics researched
- Repeat research detection
- Stats on research frequency

---

## GAPS Mode — "/research gaps"

Across the entire portfolio:
1. Read all ideas in `config/portfolio.yml`
2. List all untested hypotheses
3. List all dimensions with no evidence
4. Check experiment-learnings.md Unknown Territory
5. Cross-reference unknowns with bottleneck feature (lowest score among highest weight in eval-cache)
6. Rank by information value (kill conditions first, bottleneck-related unknowns rank HIGH)
7. Output: prioritized research agenda

---

## State to read

Read `gotchas.md` first. Then check research history: `scripts/research-log.sh topic "[topic]"` for repeat detection.

**Knowledge gap identification** — compute this yourself for `(none)` and `gaps` routes:
- Read `~/.claude/knowledge/experiment-learnings.md` IF it exists — extract the four zones:
  - **Unknown Territory** entries = highest information value
  - **Uncertain Patterns** = needs confirmation
  - **Known Patterns** = exploit territory
  - **Dead Ends** = avoid territory
- If no experiment-learnings.md exists, skip the knowledge model — use codebase, eval-cache, and external sources directly.
- Read `.claude/cache/eval-cache.json` — find the bottleneck feature. Cross-reference unknowns with the bottleneck.
- Check staleness: if experiment-learnings.md is >7 days old, flag it.

**Additional context:** `config/portfolio.yml`, `config/product-spec.yml`, `~/.claude/knowledge/predictions.tsv`

## How to research

1. **Predict** before investigating — log to predictions.tsv
2. **Investigate** using tools based on route. Read `references/research-methods.md` for tool selection. Rate sources via `scripts/source-quality.sh`. For market/competitor routes, run `scripts/market-scan.sh`. Run multiple sources in parallel where possible.
3. **Synthesize** using `templates/research-brief.md`. Every 5 findings, pause and write the pattern.
4. **Update model** — write findings to experiment-learnings.md. Grade prediction.
5. **Write artifacts** — `~/.claude/cache/last-research.yml`, log via `scripts/research-log.sh add`
6. **Next steps** — for each finding, include a clear next step (a specific command or action, not a backlog item)

## Output Format (all modes)

```
## Research: [topic]

**Prediction**: I predicted [X] because [Y].

### Findings
- [finding] — source: [url/source], strength: [strong/moderate/weak]

### Surprises (things that challenge assumptions)
- [surprise]

### Gaps (still unknown)
- [gap] — research method: [how to find out]

### Model Update
- [what this changes about our understanding]

→ next: [one action]
```

## Agent spawning

- `Agent(subagent_type: "founder-os:explorer", ...)` — deep codebase analysis, feature deep-dives
- `Agent(subagent_type: "founder-os:market-analyst", ...)` — market and competitor routes
- Spawn both in parallel when research spans codebase AND market

## State Reads
- `config/portfolio.yml`
- `~/.claude/knowledge/experiment-learnings.md`
- `~/.claude/knowledge/predictions.tsv`
- `.claude/cache/eval-cache.json`
- `config/product-spec.yml`

## State Writes
- `config/portfolio.yml` — hypothesis status updates
- `~/.claude/knowledge/predictions.tsv` — new predictions
- `~/.claude/knowledge/experiment-learnings.md` — new findings
- `.claude/cache/last-research.yml` — latest research output
- `${CLAUDE_PLUGIN_DATA}/research-log.json` — research session log

## System integration

Triggers: `/strategy` (research changes competitive picture), `/ideate` (findings suggest features), `/product` (findings affect assumptions)
Triggered by: `/plan` (unknowns detected), `/strategy` (knowledge gaps), `/retro` (wrong predictions need investigation)

## Self-evaluation

/research succeeded if:
- A prediction was logged before investigating
- Findings are synthesized (patterns named, not raw dumps)
- experiment-learnings.md was updated with at least one new or modified entry
- research-log.sh was called to persist the session
- Every finding has a clear next step

## Cost note

Spawns up to 2 agents depending on mode:
- `explorer` (sonnet) — codebase analysis for feature deep-dives
- `market-analyst` (opus, background) — market and competitor routes
- `docs` and `site` modes are agent-free (use context7 and Playwright directly)

## What you never do
- Research without a prediction
- Dump raw results without synthesis
- Skip the model update
- Skip the research log write
- Use WebSearch for library docs when context7 is available
- Research known territory without declaring why you're re-investigating

## Gotchas

- **context7 for `/research docs`**: The primary path is context7 MCP (resolve-library-id then query-docs). If context7 is unavailable or returns empty, fall back to WebSearch + WebFetch for the library's official docs site. Do not guess at APIs.
- **Repeat research**: Always run `research-log.sh topic "[topic]"` first. If the same topic was researched in the last 7 days, state what changed since then or skip.
- **Market research depth trap**: WebSearch returns surface-level results. For competitive intel, spawn the market-analyst agent rather than doing 10+ WebSearch queries inline.
- **Source quality matters**: Run `scripts/source-quality.sh` to rate sources. T4-T5 sources need corroboration from T1-T2 sources.

## If something breaks
- context7 fails -> WebSearch + WebFetch for docs
- Playwright fails -> WebSearch for site analysis
- WebSearch fails -> codebase-only + experiment-learnings.md
- No experiment-learnings.md -> skip knowledge model, research from external sources and codebase only
- No research-log.json -> `scripts/research-log.sh` auto-creates

$ARGUMENTS
