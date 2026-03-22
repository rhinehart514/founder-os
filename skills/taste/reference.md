# /taste Reference — Architecture & Memory

Loaded on demand. Output templates are in `templates/taste-report.md`. Dimensions are in `references/dimensions.md`.

---

## Architecture

The `/taste` skill uses Claude Code natively — Playwright MCP for screenshots, Claude Vision for evaluation. No subprocess, no `claude -p`. Claude IS the runtime AND the evaluator.

## Key Files

| File | Purpose |
|------|---------|
| `skills/taste/SKILL.md` | Skill definition, routing, protocol |
| `skills/taste/scripts/dimension-summary.sh` | Latest scores, weakest/strongest, pending prescriptions |
| `skills/taste/scripts/taste-history.sh` | Score trends per dimension, trajectory classification |
| `skills/taste/scripts/calibration-check.sh` | Calibration state: profile, design system, dimension knowledge |
| `skills/taste/scripts/slop-check.sh` | Mechanical slop detection — runs before every visual eval |
| `skills/taste/scripts/append-history.sh` | Append eval results to taste-history.tsv after every eval |
| `skills/taste/references/dimensions.md` | All 11 dimensions with scoring anchors |
| `skills/taste/references/evaluation-voice.md` | How to see and talk during eval — read before scoring |
| `skills/taste/references/calibration-guide.md` | Calibration protocol and traps |
| `skills/taste/templates/taste-report.md` | Output templates for all modes |
| `skills/taste/gotchas.md` | Real failure modes — read before every eval |

## Data Files (per-project)

| File | Purpose |
|------|---------|
| `.claude/evals/reports/taste-*.json` | Full evaluation reports |
| `.claude/evals/taste-history.tsv` | Score history (append-only) |
| `.claude/evals/taste-learnings.md` | Accumulated intelligence (max 5 entries) |
| `.claude/evals/taste-market.json` | Cached market research |
| `~/.claude/knowledge/founder-taste.md` | Founder preferences (from calibrate) |
| `.claude/design-system.md` | Project visual rules |
| `.claude/cache/calibration-history.json` | Calibration tracking |
| `lens/product/eval/knowledge/*.md` | Per-dimension research rubrics |

## Flows Mode Architecture

`/taste <url> flows` is a behavioral delivery audit, not a visual eval. Different protocol, different output.

**Measurement stack position:** Flows sits between Health (score.sh) and Craft (taste visual). It answers "does the frontend work?" — the question neither health checks nor visual eval can answer.

```
Health (score.sh)     → Does the code compile and pass lint?
Flows (taste flows)   → Does the frontend actually work as a product?
Craft (taste visual)  → Is the frontend well-designed?
Value (eval)          → Does the product deliver on its claims?
```

**The right order:** Fix health → pass flows → polish craft → prove value.

**Key files:**
| File | Purpose |
|------|---------|
| `references/flow-checklist.md` | 6-layer behavioral checklist |
| `templates/taste-report.md` | Output templates (flows section) |
| `.claude/evals/reports/flows-*.json` | Flow audit reports |

**Existing infrastructure (not yet wired in):**
| File | What it does | How flows uses it |
|------|-------------|------------------|
| `lens/product/eval/dom-eval.mjs` | Mechanical DOM checks via Playwright | Flows Layer 1+5 checks do the same via MCP `browser_evaluate` |
| `lens/product/eval/blind-eval.mjs` | Blind agent task completion | Flows Layer 3 does this via MCP click/fill/snapshot |
| `lens/product/eval/copy-eval.mjs` | Headline clarity, value prop | Flows Layer 2 checks value prop visibility |

## Score Mapping

- 0-100 natively (no conversion from 1-5 scale)
- `overall` = mean(all 11 dimensions)
- Gate dimensions (layout_coherence, information_architecture) cap overall at 30 when either < 30
- `overall` and `score_100` fields are identical (backward compat with score.sh)

## Memory Architecture

```
taste-learnings.md    — knowledge model (updated after each eval, max 5 entries)
taste-history.tsv     — score timeline (append-only)
taste-*.json          — full reports (one per eval date)
taste-market.json     — what "great" looks like (refreshed on calibrate)
```

The learnings file compounds: which prescriptions worked, which dimensions respond to CSS tweaks vs structural changes, product-specific patterns, and self-calibration data.

## Calibration State

Run `scripts/calibration-check.sh` to see current state. Three independent sources:

1. **Founder profile** (`~/.claude/knowledge/founder-taste.md`) — weights dimensions by preference
2. **Design system** (`.claude/design-system.md`) — flags deviations as bugs
3. **Dimension knowledge** (`lens/product/eval/knowledge/*.md`) — per-dimension research rubrics

Partial calibration is better than none. See `references/calibration-guide.md` for full protocol.
