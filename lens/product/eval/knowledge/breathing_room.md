# Breathing Room

## Patterns (what good looks like)
- **Intentional density contrast**: Linear has tight list rows (32px) AND generous whitespace between sections (48px+). The contrast makes both feel deliberate. Dense areas are dense because they're data-rich; open areas are open because they're transitions or decision points.
- **Space around primary actions**: The CTA (deploy, create) has more breathing room than surrounding elements. Apple gives its hero buttons 32–48px padding. This signals "this is the moment."
- **Empty state breathing**: When a surface has no data, the empty state takes up its natural space with guidance. Not crammed into a corner, not drowning in whitespace.
- **Sentence-level leading**: Body text at 1.5 line-height. Reading a paragraph feels comfortable, not cramped. Titles at 1.1 — tight, punchy.
- **Card interior consistency**: 16px padding on all card sides. No inconsistency between top/bottom and left/right padding.

## Anti-Patterns (what bad looks like)
- **Desert UI**: Large margins as proxy for quality. 64px padding on a simple card. 30% of the viewport is empty on mobile. Spacing that adds no information and makes the product feel underdeveloped.
- **Cramped density without hierarchy**: Tight spacing with no visual grouping. A wall of text where nothing has room to breathe and there's no rhythm.
- **Inconsistent card padding**: p-4 on some cards, p-3 on others, p-6 on a few. No rhythm.
- **Footer desert**: Page content ends, then 80px of empty space before footer. Signals the page didn't have enough content.
- **Over-spaced inner surfaces**: When inner pages use more whitespace than the landing page, the product feels like it has no content.

## HIVE-Specific Notes
- HIVE's problem is NOT too much breathing room — it's under-density on inner surfaces (feel empty)
- The space feed should be compact: 8px between tool cards, generous space before section labels (16px)
- Build page: the prompt area should have clear whitespace around it (this is a creation moment), but the format picker below should be tighter
- Landing hero: breathing room is right (generous, deliberate)
- Golden ratio: tight list items → breathing between sections → generous around primary CTAs

## Scoring Guide
- **5**: Spacing feels intentional and purposeful at every level. Dense where data-rich, open where transitional. Primary actions have appropriate emphasis. No area feels either cramped or desert-like.
- **4**: Good rhythm overall. One area might feel slightly too open or too tight, but the overall spacing system is coherent.
- **3**: Mixed. Some surfaces have good rhythm, others feel like spacing was added by adding padding classes without a system. Either some desert areas or some cramped areas.
- **2**: Predominantly desert (over-spaced, empty-feeling) OR predominantly cramped (no breathing between elements). Spacing doesn't serve hierarchy.
- **1**: No spacing system. Elements touch when they shouldn't, or empty areas are vast. Reading rhythm breaks. The layout doesn't guide the eye.
