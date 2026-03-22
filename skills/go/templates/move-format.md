# Move Output Format

Reference for formatting /go loop output. Adapt to the situation — this is a guide, not a template to fill.

## Per-move output (safe mode)

```
◆ move 1 — error boundary hardening

  predict: craft_score +15 (50→65) from wrapping file I/O in try/catch
  because: Known Pattern — error handling is mechanical, high keep rate
  wrong if: subprocess calls need different error handling than file I/O

  result:  craft_score +8 (50→58). File I/O paths covered, subprocess paths still open.
  verdict: ✓ kept (scoring 58 → 63, d:62→68 c:50→58 v:60→65)

  graded: **partial** — subprocess error handling needs separate approach
  model update: file I/O and subprocess error handling are different patterns (Uncertain)
```

## Per-move output (speculative)

```
◆ move 2 — trend visualization  [SPECULATIVE]

  predict: delivery_score +10 from adding sparkline to score output
  because: Exploring — no data on visualization impact

  ▾ speculative branching (2 approaches)
    branch A: inline ASCII sparkline in score output
      result: delivery_score +6, craft_score -2
      reviewer: KEEP

    branch B: separate `founder trend` command with full chart
      result: delivery_score +3, craft_score +0
      reviewer: KEEP_WITH_FIXES

  winner: **branch A** (+6 value vs +3, quality regression is minor)
  verdict: ✓ kept (scoring 58 → 64)
```

## Adversarial revert

```
◆ move 3 — auto-grade predictions

  predict: learning feature +12 from wiring auto-grade into session_start hook
  result: assertions stable (no regression)
  reviewer: **REVERT** — hook now adds 2-3s latency, silent failure when
    predictions.tsv is empty. No graceful degradation.
  verdict: ✗ reverted
```

## Session end

```
◆ go — session complete

  v8.0: **48%** → **55%** ↑7 · score: 58 → 66 ↑8
  moves: **3** completed · 1 reverted
  predictions: 2/3 correct (67%)

▾ verification
  Session started with 52/63 assertions passing, ended with 56/63. Net: +4.

▾ product map (after)
  scoring    ████████████████░░░░  working  w:5  58→66 ↑8
  learning   ██████░░░░░░░░░░░░░░  building w:4  48→48 —  ← bottleneck

▾ what changed
  ✓ move 1: error boundary hardening (+5 scoring, c:50→58)
  ✗ move 3: auto-grade predictions (reverted)

▾ model updates
  · file I/O vs subprocess error handling are different patterns (Uncertain)
  · session_start hook confirmed fragile (→ Known Pattern)

bottleneck: **learning** (building, w:4) — unchanged

/eval full         validate session results
/plan              next session
```

## Formatting conventions

- Per-move: `◆ move N — [title]`, predict/because/wrong-if, result/verdict, graded/model-update
- Speculative moves: show branches with scores, name the winner
- Session summary: moves count, score trajectory, prediction accuracy
- What changed: ✓/✗ per move with sub-score deltas
- Model updates: as experiment-learnings entries with confidence level
- Bottom: 2-3 next commands
