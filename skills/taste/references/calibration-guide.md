# Calibration Guide

Calibration is now its own skill: `/calibrate`. This guide explains what taste needs from calibration and how taste reads the artifacts.

## What calibration does for taste

Uncalibrated taste evals use generic anchors and are capped at 70 overall. Calibration grounds the eval in real data:

1. **Founder taste profile** (`~/.claude/knowledge/founder-taste.md`) — weights which dimensions get more attention
2. **Design system** (`.claude/design-system.md`) — deviations from this are bugs, not style choices
3. **Anti-slop profile** (`.claude/cache/anti-slop.md`) — category-specific generic pattern detection
4. **Market landscape** (`.claude/cache/taste-market.json`) — what "good" looks like in this category
5. **Market snapshot** (`.claude/cache/market-snapshot.md`) — current design trends (spring 2026)

## How taste reads calibration

During Phase 2 (Load Context), taste checks for these artifacts:

- **0 artifacts** → DEGRADED MODE, cap overall at 70
- **1-2 artifacts** → partial calibration, cap overall at 80
- **3+ artifacts** → fully calibrated, no calibration cap

The founder profile is the most important artifact. It shifts ATTENTION (which dimensions get more scrutiny) but not SCORES (a bad product is still bad regardless of founder preferences).

The anti-slop profile feeds Phase 0 (Slop Check). Without it, only the universal slop taxonomy applies.

## When to suggest /calibrate

- Before the first taste eval on any project
- When `scripts/calibration-check.sh` shows stale or missing artifacts
- When the founder says scores "feel wrong"
- After a product pivot or major redesign

## Calibration commands

All calibration is now done via `/calibrate`:
- `/calibrate` — full calibration (all modes)
- `/calibrate profile` — founder interview
- `/calibrate design-system` — extract tokens from code
- `/calibrate anti-slop` — category-specific slop profile
- `/calibrate market` — competitive landscape + trends
- `/calibrate verify` — check calibration accuracy
- `/calibrate drift` — detect preference/market shift
- `/calibrate refresh` — re-run only stale artifacts

## Calibration traps

- **Calibrating to inflate scores** — calibration makes taste honest, not generous
- **Over-calibrating** — stable for weeks, not per-eval
- **Stale calibration worse than none** — freshness-check.sh exists for this reason
