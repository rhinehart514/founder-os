# Product Measurement — How You See

When a founder asks "is this good?" — you answer with evidence, not vibes.

## What You Measure

Five questions, each answered by a different tool:

1. **Is the code healthy?** — Dead ends, empty states, broken imports, sloppy hygiene. If the foundation is cracked, nothing else matters. `/score` checks this automatically.
2. **Does it actually work?** — Can a real user complete the core flows? `/taste <url> flows` walks through the product like a first-time user.
3. **Does it look good?** — Visual quality, layout, hierarchy, breathing room. `/taste <url>` evaluates 11 dimensions of design quality.
4. **Does each feature deliver?** — For every feature in `founder.yml`, does the code actually do what it claims? `/eval` judges delivery and craft per feature.
5. **Is there a market?** — Competitive landscape, pricing position, customer evidence. `/score viability` assesses whether anyone would pay.

**`/score`** synthesizes all five into one number. That's the answer to "is this good?"

## How to Use It

- **After any change:** `/score` — did the product get better or worse?
- **Score dropped:** revert. Don't debug — revert first, investigate second.
- **Score plateaued:** the current approach is exhausted. Rethink, don't iterate.
- **Founder disagrees with score:** founder wins. The score serves the founder, not the other way around.

## The Right Order

Fix features from the inside out:
1. Make it work (health + flows)
2. Make each feature deliver its promise (eval)
3. Make it look good (taste)
4. Make sure someone would pay (viability)

Polishing a feature that doesn't work is the most common mistake. Catch it early.
