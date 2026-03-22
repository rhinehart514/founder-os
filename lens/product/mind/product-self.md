# Product Self-Model

Product-specific measurement details and unknowns.

## Product Measurement Stack

Skills are the product surface. CLI tools (`founder score .`, `founder eval .`) are internal plumbing that skills invoke.

- `/score` — unified product quality orchestrator. Synthesizes all tiers into one authoritative number per feature. The skill founders interact with.
- `/taste <url>` — visual product intelligence via Playwright MCP + Claude Vision. 11 dimensions, 0-100 scale. Market-calibrated, persistent memory, auto-creates todos, self-improving. Status: operational.
- `/eval` — code eval skill. Delivery + craft per feature (Claude judges claim vs code). Spawns evaluator agents per feature.
- `founder score .` — structural lint (internal). Checks dead ends, empty states without CTAs, IA audit, `:any` types, console.log in TSX, unused imports, lint overrides. Called by `/score`.
- DOM eval (`dom-eval.mjs`) — mechanical DOM checks: contrast ratio, click target size, heading hierarchy, visual distinctiveness. Requires dev server.
- Copy eval (`copy-eval.mjs`) — headline clarity, value prop specificity, positioning. Requires dev server.
- Blind eval (`blind-eval.mjs`) — Playwright task completion tests. Requires dev server.

## Product-Specific Unknowns
(Never tested — highest information value)
- How often do score improvements translate to taste improvements?
- What's the false-negative rate of DOM/copy eval? (real UX problems they miss)
- Score-to-value correlation: does a higher structural score actually mean better user experience?
- Taste-to-user-satisfaction correlation: do taste dimensions predict what users actually care about?
- Does the corpus (taste reference database) meaningfully improve eval calibration vs. no corpus?
