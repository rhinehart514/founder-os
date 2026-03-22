# Standards — What Quality Means

This is judgment, not process. What separates ideas that become businesses from ideas that stay ideas — and what separates products users love from products that merely work.

## Part 1: Business Standards (Validation Phase)

### The Validation Hierarchy

Three tiers, in order of what kills ideas:

1. **Market** — Is there demand? (most ideas die here)
2. **Model** — Does the math work? (survivors die here)
3. **Moat** — Can you defend it? (everything else)

Most founders work bottom-up: build → price → find customers. Serial entrepreneurs work top-down: customers → price → build the minimum.

### The Idea Scorecard

Not a score to optimize — a lens to see clearly.

**Market (does anyone want this?)**
- **Named customer**: A real person, not a segment. You could email them today.
- **Existing budget**: They already spend money solving this problem (even badly).
- **Active pain**: They're doing something about this problem right now.
- **Willingness to switch**: The switching cost is lower than the pain of staying.

**Model (does the math work?)**
- **Unit economics**: LTV > 3× CAC at steady state.
- **Pricing power**: Can charge enough to build a real business, not just cover costs.
- **Retention**: Customers stay long enough to recover acquisition cost.
- **Scalable acquisition**: At least one channel that doesn't require the founder personally.

**Moat (can you defend it?)**
- **Wedge**: A specific entry point that's underserved by incumbents.
- **Why you**: Founder-market fit (knowledge, network, or experience others lack).
- **Why now**: A timing catalyst (regulation, technology shift, market change).
- **Compounding**: Gets harder to compete with over time (data, network, switching costs).

### Decision Standards

**Go** (commit to building): Named customer who would pay, unit economics that work on paper, a wedge buildable in weeks, kill condition tested, founder has differentiated insight.

**Kill** (stop pursuing): Kill condition confirmed, no named customer after 2 weeks, unit economics don't work even optimistically, wedge requires >6 months, pattern match to confirmed dead end.

**Park** (revisit later): Timing isn't right but thesis is sound, market is emerging, founder capacity is the constraint.

**Pivot** (change direction, keep kernel): Customer is real but problem differs, problem is real but customer differs, demand exists but pricing doesn't fit.

---

## Part 2: Product Standards (Build Phase)

### The Product Measurement Hierarchy

Three tiers, in order of what matters:

1. **Value** — Does the user get something they care about? (the only thing that matters)
2. **Craft** — Is the experience well-made? (amplifies value, can't replace it)
3. **Health** — Is the code clean and stable? (enables craft, invisible to users)

Score is a SUPPORTING metric. A 100/100 score with zero value is a beautiful corpse.

### The Product Journey

```
FIND → UNDERSTAND → TRY → GET VALUE → COME BACK → TELL SOMEONE → PAY
```

Every stage is a potential failure point. Measuring code quality while ignoring the journey is like tuning an engine in a car with no wheels.

### The Value Checklist

Before every feature:
1. **Who gets value?** — Name the human.
2. **What changes for them?** — After they use it, what's different?
3. **How do they find it?** — Where does your target user already look?
4. **How fast?** — Time from "I found this" to "I got value." Target: first session.
5. **Would they notice if it disappeared?** — If not, it's not value.
6. **What's the return trigger?** — Why come back tomorrow?
7. **Would they tell someone?** — Is there a shareable moment?
8. **Would they pay?** — Not "could we charge" but "would they pay to keep this."

### UX Checklist (Craft Layer)

After every feature or significant change, check your own work against these.

**Universal (every product surface):**
1. **5-second test** — Does a stranger understand what it does?
2. **Empty state** — What does a new user with zero data see?
3. **Dead ends** — After completing the action, where do they go?
4. **First-time experience** — Is it obvious what to do?
5. **User feedback** — After every action, does something visible change?
6. **Error communication** — Does the user understand what happened AND how to fix it?
7. **Next action clarity** — One action, not a menu.
8. **Information density** — Match density to task and expertise level.
9. **Consistency** — Same tone, formatting, hierarchy across touchpoints.
10. **Return trigger** — Reason to come back?

### Build Discipline

- **Unit of work = one intent.** A feature, a fix, a refactor. No artificial limits.
- **Atomicity = git commits.** Each commit is reviewable and revertable.
- **Mechanical keep/revert** — Assertion regressed → revert the commit. No negotiation.
- **Default ambitious.** Build whole features end-to-end, not single-file tweaks.
- **Simplicity bias** — Deleting code for equal results is always a keep.

---

## Anti-Gaming (Both Phases)

### Business Anti-Gaming
- **All green flags** — You haven't looked for red ones. Seek disconfirmation.
- **Infinite TAM** — "It's a $50B market" means nothing. What's YOUR serviceable wedge?
- **Competitive vacuum** — "Nobody's doing this" usually means nobody wants it.
- **Technology-first** — "AI can do X" is not a business. "Person Y will pay $Z because X" is.

### Product Anti-Gaming
- **Cosmetic-only changes** — If the user can't see the difference, the score shouldn't change.
- **Inflation** — 15+ point jump in one commit? Something's wrong.
- **Plateau** — Score hasn't moved in 3+ changes? Rethink, don't iterate.
- **Stage ceiling** — An MVP scoring 95/100? The score is wrong, not the product.

Fix the product, not the score. Fix the business, not the pitch.
