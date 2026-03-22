# Product Thinking Gotchas

Built from real failure modes. Update this when /product fails in a new way.

## Sycophancy traps
- **"Your product is promising"**: Banned. If the conclusion is always "yes, build it," the pressure test isn't working. /product exists to catch bad ideas before they become bad products.
- **Softening bad news**: "The coherence could be improved" when the real finding is "your README lies about what the product does." Say the hard thing directly.
- **Praising effort instead of results**: "You've done a lot of work" is irrelevant. The question is whether the work produced value.

## Assumption blindness
- **Invisible assumptions**: The most dangerous assumptions are the ones you don't know you're making. Run `scripts/assumption-audit.sh` to surface them mechanically.
- **Citing your own prediction as evidence**: "I predicted X, therefore X" is circular. Predictions are hypotheses. Evidence is what HAPPENED.
- **"I would use this"**: You are not your user. Name the specific person who isn't you.
- **Market research as validation**: Finding that a market exists doesn't validate YOUR product in it. Competitors prove demand, not your solution.

## Coherence failures
- **Narrative drift**: The README says one thing, the code does another, and nobody noticed because they evolved separately. Run `scripts/coherence-check.sh` regularly.
- **Aspirational assertions**: Assertions that test what you WISH the product did, not what it actually does. If the assertion always passes, it might be testing nothing.
- **Thesis staleness**: A roadmap thesis older than 14 days that hasn't had evidence movement is probably stale or being avoided.

## Stage-inappropriate work
- **Polishing at stage one**: Craft score > delivery score + 15 means you're polishing something that doesn't work yet. Deliver value first.
- **Growth features with 0 users**: Distribution, analytics, and pricing optimization are premature when nobody uses the product.
- **All 9 lenses on everything**: Not every lens applies at every stage. Stage one needs: who, assumptions, pitch, coherence. Skip signals and delight until you have users.

## Agent failures
- **Customer agent with no context**: Spawning the customer agent without setting product context in founder.yml produces generic market analysis. The hypothesis must exist first.
- **Coach without startup-patterns.md**: The founder-coach agent reads mind/startup-patterns.md. If it's missing, the coach has no framework for failure detection.
