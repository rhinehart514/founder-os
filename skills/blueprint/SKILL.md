---
name: blueprint
description: "Produces research-backed product blueprints using Jobs-to-Be-Done, value proposition design, and feature architecture. Use when asked to analyze what to build, structure customer jobs, generate opportunity maps, define value propositions, prioritize features, frame a product for customers, or decide build sequence. Also triggers on: 'blueprint', 'JTBD', 'value prop', 'what features', 'how should we frame this', 'what should we build'."
argument-hint: "[full | jobs | valueprop | framing | features | tiers | reframe | interview | forces | switch]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebFetch, WebSearch, AskUserQuestion
---

# /blueprint

Product architecture from JTBD. Researches customer jobs, scores opportunities, generates value props, frames the product, maps features, sequences tiers.

## Folder (read on demand)

- `references/jtbd-method.md` — Ulwick outcome statements, ODI scoring, Moesta four forces, job map stages
- `references/four-lens.md` — 4-lens feature grid (job-backward, journey, displacement, value chain)
- `references/framing-angles.md` — 7 framing archetypes with peer test
- `references/interview-guide.md` — switch interview questions, timeline technique
- `patterns/` — bad/good examples for job statements, value props, hire/fire triggers
- `templates/blueprint-output.md` — output structure
- `gotchas.md` — failure modes. **Read first.**

## Routing

| Input | Mode |
|-------|------|
| (none) or `full` | Full pipeline: research → jobs → value props → framing → features → tiers |
| `jobs` | JTBD identification with parallel research |
| `valueprop` / `vp` | Value props per job + pressure test |
| `framing` | 7 framing angles with peer test |
| `features` | 4-lens grid + kill list |
| `tiers` | Feature sequencing + moat |
| `reframe` | New positioning from customer language research |
| `interview` | Generate switch interview guide for customer discovery |
| `forces` | Four forces analysis — push/pull/anxiety/inertia for a switching decision |
| `switch` | Hire/fire switch analysis — triggers, real competitor, switch destination |

## Before starting

1. Read `gotchas.md`
2. Read `patterns/` relevant to the mode
3. If customer/product unclear, ask (don't guess):
   - Who is the customer? (role + situation, not a segment)
   - What do they struggle with / spend money on today?
   - What's the product idea?

Use conversation context if these are already answered.

## FULL Mode

**Step 1: Research** — spawn 3 agents in parallel (customer pains, competitors, JTBD forces). Wait for all.

**Step 2: Jobs** — read `references/jtbd-method.md`. Identify 4-8 jobs. For each: Ulwick-format statement (verb + object), outcome statements ("minimize the [time/likelihood] of [negative] when [context]"), four forces (push/pull/anxiety/habit), opportunity score (importance + max(importance - satisfaction, 0)). Rank by score. Read `patterns/job-statements.md` for format.

**Step 3: Value props** — for each top job, one sentence the customer would say. Pressure test per `patterns/value-props.md`. Three checks: repeatable, outcome-first, peer-worthy.

**Step 4: Framing** — read `references/framing-angles.md`. Generate 3-5 options. Peer test each. Recommend acquisition + retention frames.

**Step 5: Features** — read `references/four-lens.md`. Build master grid. Generate 3 candidate solutions per top opportunity (Torres rule — prevents premature convergence). Name riskiest assumption per solution.

**Step 6: Kill list** — mandatory. Read `patterns/kill-reasons.md`.

**Step 7: Tiers** — 3 build tiers. Each: features, displacement math, price point.

**Step 8: Moat** — how switching cost grows over time (month 1, 3, 6).

**Step 9: Persist** — write `blueprint-[project]-[date].md` to current directory. Append to `data/sessions.jsonl`.

## Individual Modes

- **JOBS**: Steps 1-2. Research + job identification. Identify functional, emotional, and social dimensions for each job.
- **VALUEPROP**: Step 3. Requires jobs from context.
- **FRAMING**: Step 4. Generate 5-7 options across all archetypes.
- **FEATURES**: Steps 5-6. Grid + kill list.
- **TIERS**: Steps 7-8. Sequencing + moat.
- **REFRAME**: Research customer language (forums, reviews), generate new frames.
- **INTERVIEW**: Read `references/interview-guide.md`. Generate switch interview script for the specific customer.
- **FORCES**: Read `references/jtbd-method.md` Four Forces section. Run four forces analysis for the target product/idea. For each force (push, pull, anxiety, habit/inertia): name specific events, not abstractions. Output: force diagram, net switching energy assessment, product design implications (amplify push, increase pull, reduce anxiety, break habits).
- **SWITCH**: Read `patterns/hire-fire-triggers.md`. Identify: hire trigger (specific event that starts the search), fire trigger (specific event that ends usage), real competitor (often inertia or a spreadsheet, not a SaaS product), switch destination (where they go after firing). Use Moesta timeline format. Output: hire/fire trigger pair, four forces summary, switch destination map.

## Agents

3 parallel for FULL/JOBS. 0-1 for other modes.

## Output

Use `templates/blueprint-output.md`. Dense, scannable. End with 3 next steps.

$ARGUMENTS
