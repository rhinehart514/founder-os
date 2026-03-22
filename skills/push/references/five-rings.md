# Five Rings of Ideation

Ideation in /push isn't just "how to fix this code." It's five concentric rings, from inside out:

```
CODE → FEATURE → PRODUCT → MARKET → VISION
```

For EVERY push session, think at all five rings. Weight shifts with maturity — at score 40, mostly code+feature. At score 70, mostly product+market. At score 90, mostly vision.

## Ring 1: Code

What code change would fix this gap?
- Specific file:line improvements
- Architecture refactors that unblock multiple gaps
- "This function does X but should do Y"

## Ring 2: Feature

What capability is missing?
- Features that don't exist but the product needs
- Features that exist but don't deliver their promise
- Features that should be killed (yes, killing is a push action)
- "Users expect X but we don't have it"

## Ring 3: Product surface

Is the full user journey covered? Walk the journey: FIND → UNDERSTAND → TRY → VALUE → RETURN → SHARE → PAY

- Does a landing page / README exist that passes the 5-second test?
- Can someone go from "never heard of this" to value in one session?
- Is there a pricing model? Does the free/paid boundary make sense?
- What happens when it breaks? Is there a support path?
- Is there something shareable — output worth screenshotting?
- Would they notice if it disappeared tomorrow?

For each missing surface, generate a task. Not all require code — some are "create a landing page" or "add a pricing section to README."

## Ring 4: Market

What's happening outside this codebase? Read accumulated intelligence first: `market-context.json`, `customer-intel.json`, `strategy.yml`, experiment-learnings.md.

- What are competitors doing that this product isn't?
- What user behavior is shifting right now?
- What platform changes create new opportunities or threats?
- What would kill this product in 12 months?
- What's the adjacent problem 10x bigger than the current one?

Use WebSearch for fresh signal when intelligence is stale (>7 days). Spawn `founder-os:explorer` for deep research if the question is complex.

## Ring 5: Vision

What could this become?
- What's the 10x version? Not 10% better — 10x different.
- What would make this product inevitable, not just useful?
- What would make someone say "how did I work without this?"
- What assumption are we making that might be wrong?
- If we could only build ONE more thing, what would it be?

## Tagging

Tag ideated tasks by ring:
- `source: /push:code` — specific code improvement
- `source: /push:feature` — missing or broken capability
- `source: /push:product` — user journey or surface gap
- `source: /push:market` — competitive or market-driven
- `source: /push:vision` — strategic direction
