# Diversity Forcing

Run BEFORE convergence in NEW mode. The goal: prevent confirmation bias by forcing exploration across four axes before allowing the founder (or the AI) to commit to the obvious answer.

## Why this exists

Without forcing, discovery confirms whatever idea walked in the door. The AI generates a business case for the thing already described, finds articles that agree, and calls it validated. That's not discovery — it's rationalization.

## The Four Axes

For every idea, generate at least ONE alternative per axis before proceeding:

### 1. Different Customer
The founder named a customer. Who ELSE has this job?
- Adjacent role (not just the obvious buyer)
- Different company size (solo → team → enterprise, or reverse)
- Different industry with the same pain
- Non-obvious: who has this problem but doesn't know it yet?

**Output:** 2-3 alternative customers, each with a one-line job statement.

### 2. Different Mechanism
The founder described a solution. What's a fundamentally different way to solve the same job?
- Different surface (CLI → browser → mobile → API → hardware → human service)
- Different timing (proactive → reactive, or reverse)
- Different actor (AI does it → human does it → community does it → nobody does it)
- Different abstraction (tool → platform → marketplace → network)

"Different" means the user's workflow changes, not just the UI. A CLI app and a web app that do the same thing are NOT different mechanisms.

**Output:** 2-3 alternative mechanisms, each with a one-sentence description of how the user's workflow differs.

### 3. Different Model
The founder assumed a business model. What else works?
- Different pricing (free → freemium → per-seat → outcome-based → usage-based → one-time)
- Different channel (marketplace → direct → PLG → community → content → partnerships)
- Different retention (tool → data lock-in → network effects → switching cost → habit)
- Inversion: what if you charged 10x more and served 1/100th the customers?

**Output:** 2-3 alternative models with one-line unit economics sketch.

### 4. Devil's Advocate
Argue AGAINST the idea. Not pressure test (looking for cracks) — full adversarial position.
- What's the best way to solve this job WITHOUT this product?
- Why will this fail? Name the most likely death.
- Who tried this and quit? What did they learn?
- What would a smart person say to talk you out of this?

**Output:** The strongest 2-3 arguments against. The founder must respond to each before proceeding.

## Stage Awareness

The axes apply differently depending on where you are:

| Stage | Customer axis | Mechanism axis | Model axis | Devil's advocate |
|-------|--------------|----------------|------------|------------------|
| Raw idea | Explore wide | Explore wide | Explore wide | Kill-oriented |
| Researching | Narrow to 2-3 | Test top 2 | Test top 2 | Evidence-oriented |
| Building | Expand adjacently | Challenge current | Validate current | Churn-oriented |
| Shipped | Segment analysis | What's next? | Optimize | Retention-oriented |

**If `portfolio.yml` shows stage `building` or later:** Do NOT run full NEW mode. The diversity forcing shifts from "should we build this?" to "are we building for the right customer, with the right mechanism, at the right price?"

## Integration with /ideate techniques

The axes map to existing techniques:
- Customer axis → `techniques/user-states.md`
- Mechanism axis → `techniques/inversion.md`, `techniques/constraint.md`
- Model axis → `techniques/future-back.md`
- Devil's advocate → `techniques/killer.md`

Read the relevant technique file when generating alternatives for that axis.

## Anti-patterns

- Generating 3 alternatives that are all the same idea with different words
- "Different customer" that's the same person with a different job title
- "Different mechanism" that's the same workflow in a different UI
- Devil's advocate that pulls punches ("the only risk is execution speed")
- Skipping axes because "we already know" — you don't, that's the point
