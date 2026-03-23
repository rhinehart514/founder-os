# LLM Copy Failure Modes

Real failure modes from AI-generated copy. Read before generating any copy.

## The adjective problem
LLMs reach for adjectives when they lack specifics. "Powerful, intuitive, seamless experience" means the model doesn't know what the product does. **Fix:** Replace every adjective with a specific. "Powerful" becomes the specific power. "Intuitive" becomes the actual learning curve.

## Generic value props
"Save time and increase productivity" could describe any tool ever made. If the value prop works for a competing product, it's not differentiated. **Fix:** The swap test. Replace your product name with a competitor. If the copy still works, it's generic. Rewrite.

## Feature-listing as copy
"Our product features include: real-time collaboration, AI-powered insights, customizable dashboards..." This is a spec sheet, not copy. **Fix:** Each feature becomes a benefit sentence for the named person.

## Aspirational claims
Describing what the product will be, not what it is. "The future of product development" is aspiration. **Fix:** Only claim what the eval score supports. Features scoring <50 are not claims.

## Missing person
Copy that talks about the product but never names who uses it. "A tool for building better products" — who? **Fix:** Every piece of copy starts from the person in `founder.yml value.user`. Empty field = fix that first.

## Hollow differentiation
"Unlike other tools, we focus on quality." They all say that. **Fix:** Name the specific competitor. Name the specific difference. "Unlike X, which does Y, this does Z" — with evidence.

## Social proof fabrication
Inventing testimonials, inflating metrics, stock photos as "customers." **Fix:** If you don't have proof, don't fake it. "No social proof yet" is acceptable at stage one. Fake proof is never acceptable.

## Tone mismatch
Copy that contradicts the product's design system or the founder's voice. **Fix:** Read `.claude/design-system.md`. Match documented tone. No design system = match existing README and docs.

## The slop relapse
LLMs will sneak banned words back in on revision. "Let me rephrase that" often produces more slop, not less. **Fix:** Always run `slop-check.sh` after every revision, not just the first draft. The script catches what the LLM misses about its own output.

## Over-generating
Asked for a headline, produces a page. Asked for one option, produces five. **Fix:** Match output to request. If they asked for a headline, give them 2-3 headline options and stop.

## Context amnesia
Forgetting the market context mid-generation and defaulting to generic positioning. **Fix:** Re-read market-context.json before the quality gate check, not just at the start.

## Marketer voice instead of customer voice
Writing "boost your productivity" when founders actually say "I can't tell if my product is good." The customer language library (`references/customer-language.md`) has exact phrases. **Fix:** Read the library before writing. Use their words — "building in circles," "shipping to crickets," "nobody told me I was focused on the wrong thing." Not yours.

## AI fatigue blindness
Positioning around "AI helps you do X faster" when the target user is burned out on AI promises. Founders say: "I shipped more code than any quarter. I also felt more drained than any quarter." They don't want more AI output — they want understanding and ownership back. **Fix:** Frame around judgment, not speed. Around knowing, not producing. Never lead with "AI-powered."

## The 70% problem framing
AI tools solve 70% of the task but leave founders stranded on the hard 30%. This is a named concept in developer culture. If your product addresses the judgment/decision layer, contrast explicitly against the 70% problem. **Fix:** "We don't write your code — we tell you if you're building the right thing."
