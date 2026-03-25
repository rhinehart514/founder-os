# Scoring Guide

## Score Scale

| Range | Label | Meaning | Evidence bar |
|-------|-------|---------|-------------|
| 90-100 | proven | Genuinely excellent. You'd show this as an example. | External validation, named users, measurable outcomes |
| 70-89 | polished | Solid. Ships and works. Rough edges but nothing embarrassing. | Full error handling, tested edge cases, clear architecture |
| 50-69 | working | Works but not proud of it. Ships because it has to. | Core loop complete, known gaps documented |
| 30-49 | building | Half-built. Skeleton without real delivery. | Partial implementation, major paths missing |
| 0-29 | planned | Does not exist or fundamentally broken. | Little or no functional code |

## Two Dimensions

**Formula:** `delivery * 0.60 + craft * 0.40`

NOTE: Viability (market fit, UVP) is scored separately by `/score` using agent-backed research. Eval focuses on what it can measure from code: delivery and craft.

### Delivery (60%)

Does this feature deliver real value to its target user? Not "does code exist" but "would a human care?"

Read the `delivers:` field (the promise) and `for:` field (who it promises to). Then read ALL the code. Judge: is this complete, useful, worth someone's time?

**Scoring anchors:**
- 90+: A user would notice and complain if this disappeared
- 70-89: Core promise fulfilled, some secondary paths missing
- 50-69: Basic loop works, but gaps visible in first use
- 30-49: Skeleton exists, but a user couldn't get value from it
- 0-29: Claim exists, code doesn't deliver it

**Delivery includes user understanding.** Code that works but confuses the user is not delivering. For every feature, evaluate the product surface the user actually touches — the output they see, the interface they interact with, the feedback they receive. Ask these questions:

1. **5-second test:** If someone encounters this feature cold, do they understand what it does and what to do in 5 seconds? If not, delivery is capped at 69 regardless of code quality.
2. **Value moment:** How many steps from first encounter to "I got something useful"? Every step is friction. One step = potential 90+. Five steps = cap at 70.
3. **Next action clarity:** After the feature runs/renders/responds, does the user know what to do next? No clear next action = cap at 75.
4. **Error communication:** When something goes wrong, does the user understand what happened AND how to fix it? Generic errors or silent failures = delivery penalty.
5. **Return trigger:** Is there a reason to come back? Features without pull are furniture.

These apply to ANY product surface:
- **Web UI:** Does the page communicate its purpose? Is the CTA obvious? Does the loading state reassure?
- **CLI output:** Is it scannable in 2 seconds? Does it name the next command? Is signal separated from noise?
- **API response:** Is the shape intuitive? Are errors actionable? Does the response give enough context to proceed?
- **Docs/onboarding:** Does the reader know what to do after reading? Or just what exists?
- **Email/notification:** Does the recipient know why they got this and what action to take?

**Hard rule:** Delivery > 80 requires evidence that the product surface (not just the code) communicates clearly. Cite the specific output, UI element, or response that proves the user would understand.

### Craft (40%)

Is this well-made — both the code AND the experience? Three layers:

**Code craft:** Error handling, architecture, code taste. When this breaks at 3am, will you know? Are errors swallowed? Is state managed cleanly?

**System design:** Is the information architecture sound? Do routes/data flows/component hierarchy serve the user's mental model? Are layout decisions intentional or accidental? Does the abstraction level match the problem?

**Product surface craft:** Is the output/interface/response well-made as an experience? This is where code craft meets user perception:
- **Web:** Visual hierarchy, interaction feedback, loading states, responsive behavior, animation purpose
- **CLI:** Output formatting, scanability, information density, color-as-signal (not decoration), consistent structure across commands
- **API:** Response shape consistency, error format quality, pagination/filtering ergonomics, documentation accuracy
- **Any surface:** Consistency across touchpoints (does the feature feel like the same product everywhere the user encounters it?)

**Scoring anchors:**
- 90+: Elegant code AND polished experience. You'd study both to learn from them. The product surface delights — not just works.
- 70-89: Solid engineering, zero critical unhandled error paths, product surface is clear and consistent.
- 50-69: Works but fragile. Product surface is functional but generic or inconsistent.
- 30-49: Functional but messy. Product surface confuses or frustrates.
- 0-29: Hacked together. Product surface is an afterthought.

**Hard rules:**
- craft > 70 requires zero critical unhandled error paths
- craft > 80 requires evidence of intentional product surface design (not just working code that happens to output something)

### Viability — Scored by /score, NOT eval

Viability (market fit, UVP, competitive position) is scored by `/score` using agent-backed research — market-analyst and customer agents gather real evidence. See `skills/score/references/viability-guide.md`.

**Why this moved:** An LLM reading code and guessing market fit produced self-assessment bias (85-92 scores with zero external data). Agent-backed viability requires cited evidence from market-context.json and customer-intel.json. No evidence = capped at 30.

## Honesty Rules

1. Score what EXISTS in code, not what's planned or documented
2. Cite specific file:line evidence for every sub-score
3. Missing functionality = 0 on that criterion, not "partial credit"
4. Compare against rubric history — same code should get same score
5. Stage-appropriate expectations — MVP at 75+ needs justification
6. When uncertain, score lower — inflation is harder to fix than underscoring
7. Any sub-score > 80 requires extraordinary evidence
8. Early-stage code averaging 75+ is suspicious. Be honest about the stage.
9. If you find zero problems, say so explicitly and justify

## Anti-Inflation Checklist

Run this mentally before publishing any score:

- [ ] Every sub-score >80 has file:line evidence of excellence
- [ ] No dimension scored higher than what the code actually delivers
- [ ] Rubric variance check passed (delta <15 from last score)
- [ ] Stage ceiling respected (MVP features shouldn't average 75+)
- [ ] Delivery score reflects actual user value, not code completeness
- [ ] craft > 70 means zero critical unhandled error paths

## Maturity Mapping

Maturity is computed from eval score, not declared:
- 0-29 = planned
- 30-49 = building
- 50-69 = working
- 70-89 = polished
- 90+ = proven
