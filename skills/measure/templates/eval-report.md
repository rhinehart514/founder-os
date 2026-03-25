# Eval Report Templates

## Full eval output

```
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  eval  70/100  ██████████████░░░░░░  6 features
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

                                del  cra  Δ
  todo         42 █████░░░░░░░  48   35  ↓3
    one-line gap description
  scoring      58 ███████░░░░░  62   50
    one-line gap description
  commands     76 █████████░░░  78   72  ↑46
  learning     64 ████████░░░░  62   67  ↑13

  beliefs: 61/76 passing

  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  bottleneck  todo at 42  · /plan todo
  /score quick    unified number with viability
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
```

**Rules:**
- Same table pattern as /score: name(12), score(colored), compact bar(12), sub-scores, delta arrow
- Features sorted worst-to-best — worst score first, always
- Gap line indented below the feature row — one line, specific problem
- No DELIVERS/PARTIAL/MISSING labels — the score IS the verdict
- Beliefs are one summary line — pass count only
- Bold the bottleneck feature name
- Bottom: 2-3 next commands routed to specific actions
- Viability NOT shown (scored by /score, not /eval)

## Scoped eval output

```
◆ eval — feature_name

  delivery  ██████████████░░░░░░  68/100
    ✓ what works with file:line
    ✓ what works with file:line
    · what's missing or broken with file:line

  craft     ████████████░░░░░░░░  50/100
    ✓ what works with file:line
    · what's broken with file:line
    · system design issue

  total     █████████████░░░░░░░  58/100
  delta     ↑4 vs previous (54)
  rubric    anchored — feature.json last updated YYYY-MM-DD
```

## Blind eval output

```
◆ eval blind — N features

  feature     85  aligned
    code: what the code actually does
    claim: what delivers: says
    ✓ code matches claim closely

  feature     38  inflated
    code: what the code actually does
    claim: what delivers: says
    · specific discrepancy

  overall alignment: N/100
  N aligned, N inflated, N deflated, N disconnected
```

## Coverage audit output

```
◆ eval coverage

  feature     N assertions  tier N  ████████████████░░░░
    file_check: N  content_check: N  command_check: N  llm_judge: N
    · assessment of signal quality

  ideal: 30% mechanical, 50% content/command, 20% llm_judge
  flag: features with shallow coverage relative to weight
```

## Trend output

```
◆ eval trend

  stable pass  (N): list...
  stable fail  (N): list...
  flapping     (N): list...
    · diagnosis per flapping assertion
  recent change (N): list...

  diagnosis: pattern explanation
  recommendation: what to do about it
```

## Slop report output

```
◆ eval slop — feature

  slop score: N% human-quality

  ▾ slop found (N instances)
    · file:line — what's wrong

  ▾ clean code (good examples)
    · file:line — what's good

/go feature    fix the slop
```

## Cache format

Write to `.claude/cache/eval-cache.json` (merge with existing):

```json
{
  "feature_name": {
    "score": 58,
    "delivery_score": 62,
    "craft_score": 50,
    "gaps": ["specific problem with file:line"],
    "strengths": ["what works well"],
    "evidence": "one sentence overall judgment",
    "delta": "better",
    "delta_vs": 54,
    "cached_at": "2026-03-16T12:00:00Z"
  }
}
```
