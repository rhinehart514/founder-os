# Founder Taste Interview Protocol

This is not a survey. It's a conversation. The goal is to extract specific, actionable taste preferences that ground every future taste eval. Vague answers are worthless — push for specifics every time.

## Before the interview

1. Check if `~/.claude/knowledge/founder-taste.md` exists
2. If yes: show the current profile first, ask "has anything changed?"
3. Read `config/founder.yml` for product category context

## The questions

Ask via `AskUserQuestion`. One question at a time. Follow up on vague answers.

### Round 1: References (who do you admire?)

**Q1: "Name 2-3 products you think are beautifully designed. Not 'good' — beautiful. What specifically makes them beautiful?"**

Push for: specific elements, not vibes. "Linear's sidebar density" not "Linear is clean."
If they say "clean" or "minimal": "What specifically about it — the spacing? The type? The color restraint? The information density?"

**Q2: "Show me or name a product in your category that you think looks terrible. What specifically bothers you?"**

Push for: concrete visual/interaction failures. This reveals anti-patterns more than positives do.

### Round 2: This product (how do you see yours?)

**Q3: "In one word, what should someone FEEL when they use your product? Not 'productive' — an actual feeling."**

Reject generic answers. "Powerful" is generic. "Like I have X-ray vision into my data" is specific.

**Q4: "What's the ONE visual thing about your product right now that bothers you most?"**

This reveals the dimension they weight highest. If they say "the spacing feels off" — breathing_room matters most. If "it looks like every other app" — distinctiveness.

### Round 3: Dimensions (what matters most?)

**Q5: "I'm going to name some qualities. For each, tell me: critical, matters, or don't care."**

Read the list one at a time:
- How information is organized (hierarchy)
- Whitespace and breathing room
- Whether interactive things look clickable (contrast)
- Pixel-level polish and animation
- Personality and emotional tone
- Information density — too much or too little
- Can you always find your way (wayfinding)
- Does it look unique or generic (distinctiveness)
- Is scrolling rewarding
- Layout consistency
- Navigation structure

Map responses to dimension weights.

### Round 4: Anti-slop (what feels fake?)

**Q6: "What makes a product feel AI-generated or template-based to you? What are the tells?"**

This feeds directly into the anti-slop profile. Common answers: gradient heroes, "Build faster with..." headlines, 3-column feature grids, stock illustrations, default rounded corners everywhere.

**Q7: "Is there anything that most designers think looks good but you personally dislike?"**

This catches contrarian preferences that generic scoring would miss.

## After the interview

Write `~/.claude/knowledge/founder-taste.md` with this structure:

```markdown
# Founder Taste Profile

Updated: YYYY-MM-DD
Product category: [from founder.yml or interview]

## Admired products
- [Product]: [specific elements they love and why]

## Anti-patterns
- [What they hate]: [why, with specific visual/interaction evidence]

## Emotional target
[The one-word feeling + their elaboration]

## Current pain
[The ONE thing that bothers them most about their product now]

## Dimension weights
| Dimension | Weight | Evidence |
|-----------|--------|----------|
| [dim]     | critical/matters/low | [what they said] |

## Anti-slop triggers
- [What feels fake to them, in their words]

## Contrarian preferences
- [Things they dislike that most people like, or vice versa]
```

## Interview anti-patterns

- **Don't accept "clean and modern"** — that means nothing. Every product claims this.
- **Don't accept product names without specifics** — "I like Notion" is useless. "Notion's database views — dense information without feeling cluttered because of the consistent spacing scale" is useful.
- **Don't lead** — "Do you like minimalism?" is leading. "How much stuff should be on screen at once?" is neutral.
- **Don't interview for more than 5 minutes** — 7 questions max. Diminishing returns after that.
- **Don't skip Round 4** — anti-slop preferences are the highest-value data for scoring accuracy.
