---
name: calibrate
description: "Use when the user wants to ground taste evals in reality — founder preferences, design system extraction, anti-slop profiling, or competitive visual landscape research"
argument-hint: "[profile|design-system|anti-slop|market|refresh|verify|drift]"
allowed-tools: Read, Write, Bash, Grep, Glob, AskUserQuestion, WebSearch, WebFetch, Agent, mcp__playwright__browser_navigate, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_snapshot, mcp__playwright__browser_wait_for, mcp__playwright__browser_click, mcp__playwright__browser_hover, mcp__playwright__browser_resize, mcp__playwright__browser_evaluate, mcp__playwright__browser_install
user-invocable: false
---

<!-- INTERNAL: This skill is infrastructure for other skills, not marketplace distribution. -->

!bash scripts/freshness-check.sh 2>/dev/null || true

# /calibrate — Subjective Lens

You are building the lens that taste sees through. Without calibration, taste is generic. With it, taste knows what the founder cares about, what slop looks like for this product category, and what the competitive landscape actually looks like right now.

Calibration produces artifacts. Taste reads them. The quality of taste evals is bounded by calibration quality.

## Skill folder structure

**Scripts:**
- `scripts/freshness-check.sh` — age of all calibration artifacts (zero context cost)
- `scripts/extract-design-system.sh` — mechanical token extraction from codebase

**References (read on demand):**
- `references/interview-protocol.md` — founder taste interview (specific questions, not generic)
- `references/slop-taxonomy.md` — slop categories with detection rules for 2026

## Routing

| Argument | Mode | What it does |
|----------|------|-------------|
| (none) | **Full calibration** — all modes in sequence | Profile + design system + anti-slop + market |
| `profile` | Founder interview | Produces `~/.claude/knowledge/founder-taste.md` |
| `design-system` | Extract tokens from code | Produces `.claude/design-system.md` |
| `anti-slop` | Build category-specific slop profile | Produces `.claude/cache/anti-slop.md` |
| `market` | Competitive visual landscape + trends | Produces `.claude/cache/taste-market.json` + `.claude/cache/market-snapshot.md` |
| `quick` | **Fast calibration** — 2 min, no interview | Design system + universal slop. Gets you to partial (cap 80). |
| `refresh` | Re-run stale artifacts only | Checks freshness, refreshes what's old |
| `verify` | Check calibration against founder | Compare scores to founder expectations |
| `drift` | Detect preference/market shift | Requires history |

## Protocol by mode

### Full calibration (no args)

Run all four in sequence: profile, design-system, anti-slop, market. After each, report what was produced. End with a freshness summary.

### Profile mode

Read `references/interview-protocol.md` first. Then:

1. If `~/.claude/knowledge/founder-taste.md` exists, show current profile and ask what changed
2. Run the interview via `AskUserQuestion` — specific questions, not "what do you like?"
3. Write `~/.claude/knowledge/founder-taste.md` with structured preferences:
   - **Loves**: specific products + what about them (with evidence)
   - **Hates**: specific anti-patterns + why
   - **Dimension weights**: which of the 11 dimensions matter most
   - **Category context**: what kind of product this is (affects expectations)
   - **Anti-slop triggers**: what makes a product feel generic to THIS founder

### Design-system mode

1. Run `bash scripts/extract-design-system.sh` to mechanically pull tokens
2. Read the output, supplement with manual code inspection if needed
3. Check for: tailwind.config, CSS variables, component library config, theme files
4. Write `.claude/design-system.md` with:
   - **Color tokens**: exact hex values, semantic names
   - **Spacing scale**: actual values used
   - **Typography**: font families, sizes, weights, line-heights
   - **Radius/shadow**: component border-radius, shadow definitions
   - **Component patterns**: actual components in use (with class names)
   - **Anti-slop rules**: what "default" looks like that should be avoided

### Anti-slop mode

Read `references/slop-taxonomy.md` first. Then:

1. Read `config/founder.yml` for product category
2. Use `WebSearch` to research what generic/template products look like in this category in 2026
3. Build a category-specific anti-slop profile
4. Write `.claude/cache/anti-slop.md` with:
   - **Category**: what kind of product this is
   - **Generic signals**: what a template/AI-generated version of this category looks like
   - **Copy slop**: headline patterns that scream "AI wrote this" ("Build faster", "Supercharge your", etc.)
   - **Visual slop**: gradient heroes, 3-column feature grids, stock illustrations, default shadcn cards
   - **Interaction slop**: no custom interactions, hover-only states, no motion beyond fade
   - **Crafted signals**: what intentionality looks like in this category
   - **Detection rules**: mechanical checks (package.json deps, class patterns, copy patterns)

### Market mode

1. Read `config/founder.yml` for product category and competitors
2. Use `WebSearch` to find top 5 products in this category + current design trend articles
3. Use Playwright to screenshot 2-3 competitor/reference sites (navigate + screenshot)
4. Write `.claude/cache/taste-market.json`:
   ```json
   {
     "category": "...",
     "date": "YYYY-MM-DD",
     "competitors": [
       { "name": "...", "url": "...", "strengths": [], "weaknesses": [], "notable": "..." }
     ],
     "trends_2026": ["..."],
     "bar": { "dimension": "what 80+ looks like in this category" }
   }
   ```
5. Write `.claude/cache/market-snapshot.md` — human-readable summary of current design trends from research, what's moving, what's dying, what's peaking

### Quick mode (2 minutes, no interview)

The fast path for first-time users who want to run `/taste` without a full calibration session. Gets partial calibration (cap 80) with zero founder input.

**Why cap 80:** The `/taste` skill enforces calibration-based score caps: 0 artifacts = cap 70, 1-2 artifacts (partial) = cap 80, 3+ artifacts (full) = no cap. Quick mode produces exactly 2 artifacts (design-system + anti-slop), so it reaches the partial tier. The cap prevents inflated scores from evals that lack founder preference data and competitive context.

1. Run `bash scripts/extract-design-system.sh` — mechanical token extraction
2. Read `references/slop-taxonomy.md` — use universal taxonomy (no WebSearch needed)
3. Detect product category from `config/founder.yml` or directory structure
4. Write `.claude/cache/anti-slop.md` using universal taxonomy + detected category (no research, faster)
5. Write `.claude/design-system.md` from extracted tokens
6. Skip: founder interview, market research, competitor screenshots
7. Report: "Quick calibration complete. Partial (2/5 artifacts). Taste cap: 80. Run `/calibrate` for full calibration."

This produces design-system + anti-slop = 2 artifacts = partial calibration. Taste caps at 80 instead of 70.

### Refresh mode

1. Run `bash scripts/freshness-check.sh`
2. For each stale artifact (>30d profile, >14d anti-slop, >14d market, >7d design-system after code changes):
   - Re-run that mode
3. Skip fresh artifacts

### Verify mode

1. Read current calibration artifacts
2. If taste-history.tsv exists, show recent scores
3. Use `AskUserQuestion` to ask: "Looking at these scores, which feel wrong? Which dimensions are too high or too low?"
4. Compare founder feedback against calibration data
5. Identify miscalibrated dimensions (founder says "too high" but calibration doesn't penalize)
6. Update calibration artifacts to fix mismatches

### Drift mode

Requires both `~/.claude/knowledge/founder-taste.md` and `.claude/evals/taste-history.tsv`.

1. Compare founder's stated preferences against score trends
2. If a dimension the founder cares about is stuck/regressing, flag it
3. Use `WebSearch` to check if market trends have shifted since last market calibration
4. Report: what's drifted, what needs updating, whether preferences or market moved

## Artifacts produced

| Artifact | Path | Freshness |
|----------|------|-----------|
| Founder profile | `~/.claude/knowledge/founder-taste.md` | 30 days |
| Design system | `.claude/design-system.md` | Until code changes |
| Anti-slop profile | `.claude/cache/anti-slop.md` | 14 days |
| Market landscape | `.claude/cache/taste-market.json` | 14 days |
| Market snapshot | `.claude/cache/market-snapshot.md` | 14 days |
| Calibration history | `.claude/cache/calibration-history.json` | Append-only |

After any calibration run, append to `.claude/cache/calibration-history.json`:
```json
{ "calibrations": [{ "date": "YYYY-MM-DD", "modes": ["profile","design-system"], "artifacts": [...] }] }
```

## After calibration — feed ideation

Calibration discovers gaps. Those gaps are ideation fuel.

**After market mode:**
- If competitive screenshots reveal capabilities the product lacks → log as ideas:
  `idea-log.sh add "[capability] (seen in [competitor])" "calibrate:market" "proposed"`
- If trends_2026 reveals a pattern the product could adopt → log it
- Suggest: `/ideate market` to generate evidence-weighted ideas from the new competitive data

**After anti-slop mode:**
- If the slop profile reveals the product currently matches 2+ generic patterns → suggest `/taste <url>` to measure the gap, then `/ideate` to explore distinctive alternatives
- The anti-slop profile itself is evidence: "our product looks like category slop in [these ways]" is a problem statement for ideation

**After profile mode:**
- If the founder names a dimension as "critical" but the latest taste score for that dimension is < 55 → flag the mismatch and suggest `/ideate [dimension]` to brainstorm improvements

**After full calibration:**
- Always suggest: "Run `/taste <url>` to see how the product scores with calibrated eyes. Then `/ideate` to act on what you find."

## Self-evaluation

The skill worked if:
- **Profile**: `founder-taste.md` contains specific product references (not generic preferences)
- **Design-system**: `.claude/design-system.md` contains actual hex values and spacing scales from the codebase
- **Anti-slop**: `.claude/cache/anti-slop.md` has category-specific detection rules (not just the universal list)
- **Market**: `taste-market.json` has 3+ competitors with specific strengths/weaknesses
- **Quick**: exactly 2 artifacts produced, taste cap reported as 80
- **All modes**: `calibration-history.json` was appended to

## Gotchas

- **Design system extraction from CSS-in-JS**: `extract-design-system.sh` works best with tailwind.config or CSS variables. Styled-components or emotion tokens require manual code inspection in step 2.
- **Market mode without Playwright**: falls back to WebSearch-only, which produces text descriptions instead of visual comparisons. The competitive landscape analysis is weaker without screenshots.
- **Stale calibration is worse than no calibration**: a 60-day-old market snapshot actively misleads taste scores. Refresh mode exists for this reason -- use it.
- **Profile mode interview quality**: vague founder answers ("I like clean design") produce useless calibration. The interview protocol pushes for specifics, but the output quality is bounded by input specificity.

## System integration

Reads: `config/founder.yml` (product category, competitors), `~/.claude/knowledge/founder-taste.md`, `.claude/design-system.md`, `.claude/cache/anti-slop.md`, `.claude/cache/taste-market.json`, `.claude/cache/calibration-history.json`, `.claude/evals/taste-history.tsv`
Writes: `~/.claude/knowledge/founder-taste.md`, `.claude/design-system.md`, `.claude/cache/anti-slop.md`, `.claude/cache/taste-market.json`, `.claude/cache/market-snapshot.md`, `.claude/cache/calibration-history.json`
Triggers: `/taste <url>` (score with calibrated eyes), `/ideate` (act on gaps found), `/ideate market` (from competitive data)
Triggered by: `/taste` (when calibration artifacts missing/stale), first-time setup, manual

## What you never do

- Calibrate to inflate scores — calibration makes taste honest, not generous
- Skip the founder interview — mechanical extraction without founder input is incomplete
- Use generic trend articles without checking dates — "2024 design trends" is not 2026
- Overwrite artifacts without showing what changed

## If something breaks

- Playwright can't connect: fall back to WebSearch-only for market mode, skip screenshots
- No founder.yml: ask founder for product category via AskUserQuestion
- No package.json: skip dependency-based slop checks in anti-slop mode
- Founder gives vague answers: push for specifics per interview-protocol.md

$ARGUMENTS
