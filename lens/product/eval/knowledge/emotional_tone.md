# Emotional Tone

## Patterns (what good looks like)
- **Warm color temperature in backgrounds**: Pure neutral grays (#121212) feel clinical. Warm off-blacks with yellow/olive undertone feel inhabited. HIVE's #0D0D0C has R:13,G:13,B:12 — subtle warm shift. Going warmer (toward #110F0B) risks looking "brown and dingy" (James Robinson). Current position is near the sweet spot.
- **Campus-specific copy as identity signal**: Real building names, org names, dining locations. Research confirms context-specific content is the strongest non-visual distinctiveness signal. HIVE's campus copy experiments: 6/6 keep rate (highest-ROI pattern confirmed).
- **Conversational microcopy with character**: Slack's principle: "confident, never cocky. Witty, never silly." Copy should feel like a specific person, not a brand. Contractions ("you'll" not "you will"), personal pronouns ("you" and "we"), preemptive transparency (Modcloth: "We'll only text you if there's an order issue").
- **Ambient aliveness**: Subtle signals that people are here (presence dots, recent activity, live counts). Not pushed hard — just visible.
- **Edge lighting for depth warmth**: In dark mode, shadows are nearly invisible. Linear uses edge lighting (thin bright border on top edge of elevated surfaces). Material 3 uses brand-color overlay on elevated surfaces — for HIVE, gold at 1-2% opacity on cards would reinforce brand AND create warmth simultaneously.

## Anti-Patterns (what bad looks like)
- **Generic dark mode feel**: Pure #000 background, white text at 60% opacity, blue accent. Reads as terminal, not social product. Vercel uses #000 intentionally — it's cold and surgical, targeting developers. HIVE serves students who want belonging, not precision.
- **Performative warmth**: "You're doing great! 🚀" on a settings page. Mismatched tone — enthusiasm that isn't earned.
- **Personality drop on inner surfaces**: Landing page has personality, everything inside is generic SaaS. Users feel the drop immediately. This is HIVE's identified pain point.
- **Copy that could be any product**: "Manage your settings." "View your profile." "No items yet." No specificity, no voice, no character.
- **Uniform border treatment**: When every card has the same `border-white/[0.05]`, the UI looks generated. Variation in border treatment (some borderless, some with edge lighting, some with brand-tint) creates the hand-crafted feel.

## Warm vs Cold Dark Mode Reference

| Approach | Base Background | Undertone | Products | Feel |
|----------|----------------|-----------|----------|------|
| Pure black | #000000 | None | Vercel, OLED apps | Surgical, void, premium-dev |
| Neutral dark | #121212 | None | Material Design 3 | Standard, clean, safe |
| Cool dark | #0A0F1A | Blue shift | Linear (original), many SaaS | Night, focused, technical |
| Warm dark | #0D0D0C | Yellow/olive | HIVE (current) | Inhabited, campus, social |
| Over-warm | #110F0B+ | Amber/brown | — | Risks looking dingy |

## Microcopy: Personality vs Generic

| Context | Generic (bad) | With character (good) |
|---------|--------------|----------------------|
| Empty space | "No apps yet. Create one to get started." | "This space is wide open. First app gets prime real estate." |
| Empty feed | "Nothing to show." | "Campus is quiet. Suspiciously quiet." |
| Error | "Something went wrong." | "That didn't work. Try again — we're rooting for you." |
| Loading | "Loading..." | (No text — skeleton only. Silence > filler.) |
| First creation | "App created successfully." | (Celebration animation + gold ring. Let the moment breathe.) |
| Rating scale | "1 star" / "5 stars" | "Eek. Methinks not." / "Woohoo! As good as it gets!" (Yelp) |

Slack's key insight: the personality comes from having CONSTRAINTS on the voice ("never cocky", "never silly"), not from adding personality ("be fun!"). Define what the voice is NOT.

## HIVE Voice Definition (proposed)
- Confident, never corporate
- Specific, never generic (use campus nouns)
- Direct, never hedging ("Fill in all fields" not "Please ensure all required fields are completed")
- Warm, never performative (no "You're doing great!")
- Self-aware, never try-hard (mild humor is fine, forced jokes aren't)

## HIVE-Specific Notes
- The problem is tone inconsistency: landing (warm, campus-specific, personality) vs inner surfaces (generic SaaS)
- Fix: every empty state, every label, every loading message should have character
- Gold dot pulse = aliveness signal. If it's absent or broken, the product feels dead
- "Since you left" divider is the right instinct — temporal personality, not just functional info
- Gold surface tinting (1-2% on elevated cards) is worth experimenting with — would reinforce brand subconsciously
- Directional edge lighting (border-t border-white/[0.08]) would add material warmth to cards
- HIVE's copy is currently "informational with campus nouns." The gap: it's not a CHARACTER. A character has opinions.

## Scoring Guide
- **5**: The product has a distinct voice that's consistent from landing to deep inner surfaces. Copy is specific to the user's context. Background has material warmth. Edge lighting or brand-tint elevation creates depth. Feels like a person built this.
- **4**: Strong voice on main surfaces, occasional generic copy on inner screens. Warm but not perfectly consistent. Most empty states have personality.
- **3**: Clear product personality on entry but it fades. Inner surfaces feel generic. One surface feels alive, the rest don't. Generic empty states.
- **2**: Generic throughout. Could be any dark-mode SaaS product. No campus specificity, no voice. Pure #000 or cold gray backgrounds.
- **1**: Cold or performatively cheerful. Terminal-like OR emoji-heavy with no substance. Copy could belong to any product in any industry.

## Sources
- James Robinson — A Guide to Dark Mode Design (jamesrobinson.io)
- Slack Voice Principles (slack.design/articles/thevoiceofthebrand-5principles/)
- Anna Pickard on Slack's Editorial Soul (contagious.com)
- Material Design 3 Elevation (m3.material.io/styles/elevation/applying-elevation)
- Linear UI Redesign — LCH color space (linear.app)
- Econsultancy — 15 Microcopy Examples
- TechCrunch on Fizz campus app design
- UI Color Trends 2026 (updivision.com)
