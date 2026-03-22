# Feature Lifecycle

## Maturity stages (computed from eval score, never manually set)

### planned (0-29)
Feature does not exist or is fundamentally broken. Skeleton may be in founder.yml but no working code delivers on the claim.

**What moves you to building:** First passing assertion. Any code that partially delivers on the `delivers:` claim. Score crosses 30.

### building (30-49)
Half-built. The shape is visible but gaps are obvious. Some assertions pass, some fail.

**What moves you to working:** Core delivery loop complete. User can get the promised value end-to-end, even if rough. Delivery sub-score reaches 50+.

### working (50-69)
It works. Delivers on the claim. Users can rely on it. Craft and viability may still be low.

**What moves you to polished:** Craft sub-score reaches 70+. Error handling, edge cases, output quality are all solid. No known failure modes in normal use.

### polished (70-89)
Solid. Ships and works well. You'd be comfortable showing this to anyone.

**What moves you to proven:** External validation. Someone outside the team used it and it worked. OR: 3+ /go sessions without regression AND all three sub-scores above 80.

### proven (90+)
Genuinely excellent. Battle-tested. Evidence from real usage.

**What moves you backward:** Assertion regression. Score drop after a change. New failure mode discovered. Maturity drops automatically when eval score drops.

## Kill criteria

A feature should be killed (`/feature [name] status killed`) when:

- Score <30 after 3+ /go sessions targeting it
- Weight 1-2 and no assertions passing after 2+ sessions
- Founder can't explain who wants it (the `for:` field is generic or empty)
- >50% overlap with another active feature (merge or kill one)
- Thesis pivot made the feature irrelevant (check roadmap.yml)

Killing is not failure. It is honest resource allocation. A killed feature with a clear `killed_reason:` is more valuable than a zombie feature nobody works on.

## Weight guide

| Weight | Meaning | Example |
|--------|---------|---------|
| 5 | Core value delivery. Product doesn't exist without this. | Scoring in founder-os |
| 4 | Important supporting feature. Users expect it. | Learning loop |
| 3 | Nice to have. Improves experience but not critical. | Install/onboarding |
| 2 | Peripheral. Could be dropped without user impact. | Self-diagnostic |
| 1 | Experimental or infrastructure-only. | Internal tooling |

**Weight inflation warning:** Founders overweight features they enjoy working on. Ask: "If this feature disappeared, would the user notice within a week?" If not, it's weight 1-2.
