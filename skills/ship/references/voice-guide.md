# Voice Guide — Writing in the Product's Voice

This is not a generic marketing voice guide. This is about writing copy that sounds like the product, not like every other SaaS landing page.

## Finding the voice

Before writing any copy, answer these three questions:

1. **What does this product sound like in conversation?**
   Read the README, the docs, the commit messages. That's the natural voice. Copy should sound like that voice talking to a stranger, not a marketer talking to a "lead."

2. **What does the user sound like?**
   Read customer-intel.json if available. Use their words, not yours. If they say "it's confusing" you write "confusing" not "suboptimal user experience."

3. **What does the competition sound like?**
   Read market-context.json. Whatever they all sound like, sound different. If everyone is formal, be direct. If everyone is casual, be precise.

## Voice dimensions

### Specific over abstract
- No: "Improve your workflow"
- Yes: "Know if your product got better. One command."

Specificity is the voice. Abstract language is the absence of voice.

### Direct over hedged
- No: "We believe our solution can help you potentially..."
- Yes: "This does X. Here's how."

Every hedge word ("might," "could," "potentially," "helps") weakens the copy. Remove them.

### Short over long
- Headlines: 7 words max
- Subheads: 15 words max
- Body sentences: 25 words max
- If it needs a comma, consider two sentences

### Active over passive
- No: "Your code is analyzed by our engine"
- Yes: "We analyze your code" or better: "Analyze your code"

### Evidence over claims
- No: "The best tool for developers"
- Yes: "85/100 in one command"

Every claim without evidence is noise. If you can't back it up, cut it.

## Adapting to design system

If `.claude/design-system.md` exists, it defines:
- **Tone tokens** (formal/casual/technical/friendly)
- **Terminology** (what the product calls things)
- **Constraints** (character limits, capitalization rules)

Always check the design system. Copy that contradicts the design system is a bug.

## The swap test

Replace your product name with a competitor. If the copy still works, it's generic. Rewrite until it only works for this product.

## The grandmother test

Read the copy to someone who doesn't know your industry. If they can't explain what the product does after hearing it, the copy failed. Technical accuracy matters less than clarity.

## The deletion test

Remove one sentence. Does the meaning change? If not, the sentence was filler. Keep removing until every sentence carries weight.
