# Product Surface Intelligence

How to think about the user when evaluating a product surface. Visual eval asks "is this well-designed?" Product intelligence asks "is this designed for the RIGHT user?"

## The 5 Questions

Ask these against the screenshots + DOM from Phase 3, with `delivers:` and `for:` from founder.yml as context.

### 1. Intent Match

Does the first thing the user encounters match what `delivers:` promises?

- What does `delivers:` say this feature does?
- What does the landing surface actually communicate?
- Is there a gap between promise and presentation?

**Strong signal:** The hero/header/first output says one thing, `delivers:` says another.
**Weak signal:** Alignment exists but emphasis is wrong (the value is buried below the fold or after 3 flags).

### 2. Revelation Order

Does information appear in the order THIS user needs it, or the order the developer built it?

- What does this user need to know first? (from `for:`)
- What does the product show first?
- Is the user's mental sequence matched?

**Strong signal:** User needs outcome first but sees configuration first. Or needs context but gets data dump.
**Weak signal:** Order is plausible but could be better with reordering.

### 3. Navigation Tax

How many decisions before value? Count clicks/flags/params/pages from arrival to the value moment described in `delivers:`.

- Web: clicks from landing to value
- CLI: flags/subcommands from install to first useful output
- API: requests from auth to first meaningful response

**Strong signal:** 5+ decisions before value. User likely abandons.
**Moderate signal:** 3-4 decisions. Tolerable but improvable.
**Weak signal:** 1-2 decisions. Fine.

### 4. Mental Model Alignment

Does the product organize by developer model (features, routes, resources) or user model (tasks, outcomes, problems)?

- How is navigation/structure organized?
- Would THIS user (`for:`) think in these categories?
- Do labels match user language or developer language?

**Strong signal:** Nav items are technical concepts the user doesn't think in. Sections map to code modules, not user goals.
**Weak signal:** Labels are slightly off but structure roughly matches user thinking.

### 5. Micro-Feature Gaps

What small addition would dramatically improve value delivery for THIS user?

Look for:
- Missing preview (user can't see what they'll get before committing)
- Missing progress (user doesn't know how far along they are)
- Missing smart default (user has to configure something that has an obvious right answer)
- Missing contextual action (user has to navigate away to do the obvious next thing)
- Missing feedback loop (user can't tell if what they did worked)

**Strong signal:** An obvious micro-feature that any product designer would add.
**Moderate signal:** A plausible addition that might help.
**Weak signal:** Nice-to-have, low impact.

## Signal Strength Definitions

- **strong** — Clear mismatch between surface and user need. User is objectively hindered. Fix this.
- **moderate** — Plausible mismatch. Needs confirmation from usage data or user feedback. Worth flagging.
- **weak** — Observation with low confidence. Note it but don't prescribe.

## Opportunity Types

Use these labels for structured output:

| Type | Meaning |
|------|---------|
| `surface_mismatch` | What the surface says ≠ what the user needs |
| `missing_micro` | A small addition that dramatically improves value delivery |
| `cognitive_load` | Too many decisions, too much information, or wrong information density |
| `revelation_order` | Information appears in the wrong sequence for this user |
| `mental_model_gap` | Organization follows developer thinking, not user thinking |

## Skip Condition

If founder.yml has no `features:` section or features lack `delivers:` fields, skip product intelligence with a note: "No user model defined — add `delivers:` and `for:` to features in founder.yml to enable product intelligence."
