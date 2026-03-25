---
name: product
description: "After commitment. Pressure-tests whether what you're building actually delivers on the demand hypothesis — assumptions, user journey, pitch clarity, product-market fit."
argument-hint: "[user|assumptions|why|pitch|focus|signals|delight|market|coherence|refine|pivot|\"I want to build...\"]"
allowed-tools: Read, Bash, Grep, Glob, AskUserQuestion, WebSearch, Agent
---

# /product

**Pressure-test assumptions, audit coherence, validate the value hypothesis. Make sure you're building something that matters.**

**2026 context:** Read `mind/world.md` before every product session. The frame shifted — sell the work not the tool, agents are colleagues not assistants, 40% of 2024 AI startups are dead, seed investors want $300-500K ARR. Your product thinking must reflect what's true NOW.

## Skill folder structure

This skill is a **folder**, not just this file. Read on demand:

- `references/product-thinking.md` — the 5 value questions, stage expectations, when to pivot, assumption stack.
- `references/pressure-tests.md` — specific pressure test questions per lens (user, market, technical, coherence, delight).
- `references/yc-readiness.md` — what YC looks for, mapped to founder-os metrics.
- `templates/product-brief.md` — output format for both new idea and existing product modes.
- `gotchas.md` — real failure modes. **Read before generating output.**

Scripts exist as verification: `scripts/product-scan.sh`, `scripts/assumption-audit.sh`, `scripts/coherence-check.sh` — run these to cross-check your analysis if needed.

## Routing

Parse `$ARGUMENTS`:

| Input | Mode |
|-------|------|
| (none) | Full product session — all stage-appropriate lenses |
| `"I want to build..."` or >10 words not matching a route | **New idea mode** |
| `user` / `journey` | User journey walkthrough |
| `assumptions` / `risks` | Assumption audit |
| `why` / `value` | Value chain trace |
| `pitch` | Pitch clarity test |
| `focus` / `cut` | Feature kill/focus exercise |
| `signals` | Signal instrumentation check |
| `delight` | Craft moment identification |
| `market` | Market reality check |
| `coherence` | Narrative coherence audit |
| `refine` | Pressure-test existing product-spec — is the spec still right? |
| `pivot` | Explore alternatives — what if the hypothesis is wrong? |
| `yc` | YC readiness check — read `references/yc-readiness.md` |
| `[feature name]` | Product thinking scoped to one feature |

## State to read

Read `gotchas.md` first. Then read state directly — you are the product thinker, not a script runner:

**Value hypothesis** — read `config/product-spec.yml` first (the canonical product definition), fall back to `config/founder.yml`:
- Extract: who is the person, what problem, what changes for them, how they find it
- If neither file exists: "no product definition — run /onboard or describe what you're building"

**Coherence check** — reason about contradictions yourself:
- README.md vs product-spec.yml/founder.yml: do claims match reality?
- Features vs beliefs.yml: do all features have assertions?
- Hypothesis vs features: does what you claim to build match what actually exists?
- narrative.yml vs roadmap: does narrative claim things evidence hasn't proven?

**Additional context** (read if they exist, skip if not):
- `.claude/cache/eval-cache.json` — feature scores as supporting evidence, not the primary input
- `.claude/knowledge/predictions.tsv` — wrong predictions reveal disproven assumptions
- `.claude/knowledge/experiment-learnings.md` — known vs unknown territory
- `.claude/cache/customer-intel.json` — external signal
- `.claude/plans/strategy.yml` (stage), `.claude/plans/roadmap.yml`, `README.md`, `git log --oneline -10`

## How to assess

**New idea mode** (no codebase or >10 word description): read `references/product-thinking.md` for the value questions and assumption stack. Use WebSearch for market reality. Produce a value hypothesis draft. Output per `templates/product-brief.md`.

**Existing product mode** — select lenses by stage:
- **Stage one** (0 users): who, assumptions, pitch, coherence
- **Stage some** (1-10): who, signals, assumptions, delight, coherence
- **Stage many/growth**: all lenses + market

For specific lens questions, read `references/pressure-tests.md` on demand.

**Hire/fire lens** (optional — any stage): Check if the product still matches the original hire trigger. Has the customer's reason for "hiring" this product changed? Would they "fire" it today? Reference `/blueprint switch` for structured analysis.

**Agent enrichment** (optional — existing product only):
- Do NOT auto-spawn agents. If the assessment reveals gaps that need deeper signal, ask first via AskUserQuestion: "Want deeper signal from customer research?" or "Want failure mode detection from the founder-coach?"
- `founder-os:customer` — customer signal research. Useful when assumptions about the user are untested.
- `founder-os:founder-coach` — failure mode detection against startup-patterns.md. Useful when patterns look concerning.

**Refine mode** (`/product refine`): Pressure-test the existing product-spec.yml. Is the named person still right? Has the problem changed? Are the assumptions holding? This absorbed the spec pressure-test that was in /discover.

**Pivot mode** (`/product pivot`): The hypothesis might be wrong. Explore: what if the person is different? What if the problem is adjacent? What if the mechanism needs to change? Uses the assumption stack from `references/product-thinking.md` to identify which layer to pivot on.

Synthesize using `templates/product-brief.md`. End with exactly 3 next commands.

## Tools

- **WebSearch**: market reality (new idea), assumption validation (existing). 30 seconds max per query. For deep research, suggest `/research market`.
- **AskUserQuestion**: naming the person, editing the value hypothesis, verdict discussion.
- **Read**: state files, references on demand.
- **Bash**: `scripts/*.sh`, `founder score .`, `founder feature`, `git log`.
- **Agent**: customer signal (founder-os:customer), founder coaching (founder-os:founder-coach).

## Output

/product produces a verdict — the honest assessment of whether you're building the right thing. It names gaps between "what you claim" and "what's true."

Label every claim: [observed], [stated], [market], or [inferred].

For each gap found, state the gap, the evidence, and the next step (a specific command). Do NOT generate task lists. /product diagnoses; /plan and the founder decide what to act on.

Example output for a gap:
- "Value hypothesis names 'developers' — not a person. Next: `/product user` to name a specific human."
- "README claims real-time sync but code is polling. Next: fix the code or fix the claim."

## System integration

Reads: `config/product-spec.yml`, `config/founder.yml`, `.claude/plans/strategy.yml`, `.claude/plans/roadmap.yml`, `.claude/cache/customer-intel.json`, `.claude/cache/narrative.yml`, `config/beliefs.yml`, `README.md`, `.claude/knowledge/predictions.tsv`, `.claude/knowledge/experiment-learnings.md`, `.claude/cache/eval-cache.json` (optional supporting evidence)
Writes: `.claude/knowledge/predictions.tsv`
Triggers: `/ideate` (gaps need solutions), `/research` (assumptions need evidence), `/product refine` (spec pressure-test), `/copy pitch` (pitch fails clarity test)
Triggered by: `/plan` (product-market fit questions), `/strategy` (is the product working?)

## What you never do

- Generate feature ideas — flag gaps, redirect to /ideate
- Be sycophantic — "promising" and "solid foundation" are banned
- Do deep research inline — surface validation, flag deep dives for /research
- Run all lenses regardless of stage
- Produce generic insights — "improve UX" is garbage
- Skip the coherence check on existing products
- Tell a founder their idea is good without naming the person

## Self-evaluation

/product succeeded if:
- Every untested assumption is named with evidence (or lack thereof)
- Coherence check ran and disconnects are surfaced
- The founder knows the biggest gap between "what we claim" and "what's true"
- At least one pressure test question made the founder uncomfortable

## Cost note

Agent spawning is optional and user-prompted:
- `customer` (sonnet, background) — only when founder confirms deeper customer signal is needed
- `founder-coach` (opus) — only when founder confirms failure mode detection is needed
- Most runs are agent-free. New idea mode never spawns agents.

## When to use

Use /product AFTER you've committed to building. For products that exist, not ideas you're still evaluating.

- Still evaluating? → `/discover`
- Need positioning? → `/strategy`
- Need evidence? → `/research`
- Need options? → `/ideate`

## If something breaks

- product-scan.sh returns empty: `config/founder.yml` may not exist — run `/onboard` first
- assumption-audit.sh finds zero assumptions: the value hypothesis in founder.yml is too vague — flesh out the `value:` section with specific claims
- coherence-check.sh reports false mismatches: README may describe aspirational features — update README to match current state or mark features as `planned`
- founder-coach agent times out: the startup-patterns check is running against a large repo — this is informational only, skip and proceed with other lenses

$ARGUMENTS
