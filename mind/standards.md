# Standards

## Demand (What to Build)

**Outcome hierarchy:** Outcome → Opportunity → System → Feature → Micro-feature → Interaction

```
OUTCOME          What metric or behavior moves if this works?
OPPORTUNITY      What pain, unmet need, or desire makes this worth addressing?
SYSTEM           A coherent product domain with its own data model and ownership.
FEATURE          A discrete, shippable unit with a clear user goal.
MICRO-FEATURE    Behaviors that make a feature feel complete rather than 80% done.
INTERACTION      Atomic UI moments. Invisible until absent.
```

**Hierarchy lens:** All 7 skills operate across this hierarchy. See `skills/shared/hierarchy-lens.md` for per-level questions, level detection, and per-skill guidance. See `skills/shared/system-thinking.md` for system-level methodology. Every skill should check one level up and one level down from where it's working.

**Demand questions (answer before building):**
- Functional job: What task is the customer trying to get done?
- Emotional job: How do they want to feel during and after?
- Social job: How do they want to be perceived?
- Four forces: What pushes them away from the current solution? What pulls them toward yours? What anxiety slows the switch? What inertia keeps them where they are?
- Hire/fire triggers: When do they "hire" this product? When do they "fire" it?

**Package definition** — a customer-facing bundle of internal features:
- `customer_name`: What the customer calls it ("Never Miss Another Call")
- `one_liner`: One sentence from customer's perspective
- `internal_features`: Which codebase features power it
- `tier`: core (must-have) | expansion (grows value) | delight (surprise + retain)

**Evidence classes** — every demand-side output labels claims:
- **[observed]**: User behavior data (analytics, session recordings, A/B tests)
- **[stated]**: User said it (interviews, surveys, forum posts, reviews)
- **[market]**: Market data (funding rounds, pricing pages, market reports)
- **[inferred]**: LLM synthesis (pattern matching, reasoning from context)

**Evidence staleness thresholds:**
- [observed]: valid 90 days (re-validate quarterly)
- [stated]: valid 60 days (opinions shift)
- [market]: valid 30 days (markets move fast)
- [inferred]: valid 7 days (re-infer with new data)

## Business (Validation)

**Hierarchy:** Market (demand?) → Model (math works?) → Moat (defensible?)

**Idea scorecard:**
- Market: named customer, existing budget, active pain, willingness to switch
- Model: LTV > 3× CAC, pricing power, retention, scalable acquisition
- Moat: wedge, why you, why now, compounding advantage

**Decisions:**
- **Go:** named customer who'd pay, unit economics work, wedge buildable in weeks
- **Kill:** kill condition confirmed, no customer after 2 weeks, economics don't work
- **Park:** thesis sound but timing wrong
- **Pivot:** customer real but problem differs, or vice versa

## Product (Build)

**Hierarchy:** Value (do they care?) > Craft (well-made?) > Health (clean code?)

Score is supporting. 100/100 with zero value = beautiful corpse.

**Measurement:** `/measure` (unified score), `/measure flows` (works?), `/measure visual` (looks?), `/measure feature` (features deliver?), `/measure viability` (market?), `/measure evidence` (evidence quality)
- Score dropped → revert first, investigate second
- Score plateaued → rethink, don't iterate
- Founder disagrees → founder wins

**Fix order:** wanted → works → delivers → looks good → someone would pay

**Value check:** Who gets value? What changes? How do they find it? How fast to value? Would they notice if gone? Return trigger? Would they tell someone? Would they pay?

**UX check:** 5-second test, empty state, dead ends, first-time experience, user feedback, error communication, next action clarity, information density, consistency, return trigger

**Build discipline:** one intent per unit of work, atomic git commits, assertion regressed → revert, default ambitious, simplicity bias

## Anti-Gaming
- All green flags → you haven't looked for red ones
- "Nobody's doing this" → usually nobody wants it
- 15+ point jump in one commit → something's wrong
- MVP scoring 95 → the score is wrong

Fix the product, not the score. Fix the business, not the pitch.
