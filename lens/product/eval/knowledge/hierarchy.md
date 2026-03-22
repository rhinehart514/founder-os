# Hierarchy

## Patterns (what good looks like)
- **One dominant focal point per screen**: Linear's issue list — the issue title is 2x heavier than everything else. The eye lands there, then moves down the information order. Zero competition.
- **Typography as hierarchy, not decoration**: Apple product pages use weight, size, and color to create 3-4 clear reading levels. No icons or badges needed to establish priority.
- **Recessive chrome**: Vercel's sidebar nav recedes (small, muted) so the main content area dominates. Linear dimmed their sidebar "a few notches" in their redesign — chrome that commands attention is stealing from content.
- **Group before rank**: Related items cluster visually before the eye assigns importance within clusters. White space between groups, not between items.
- **Single primary action**: HIVE's gold button should be the one thing your eye hits on any screen before anything else.
- **Layered surface elevation**: Build hierarchy through 3-5 distinct background luminance levels. Each layer up gets slightly lighter. In dark mode, this is the primary hierarchy cue because shadows and borders are weakened. (Material Design, Linear, Vercel all use this.)
- **Asymmetric heading spacing**: Space BEFORE a heading should be 2-2.5x the space AFTER it (e.g. 25px before, 10px after). This creates parent-child grouping through proximity alone. (Source: Pimp My Type)

## Anti-Patterns (what bad looks like)
- **Competing for attention**: Two or more elements of equal visual weight on the same screen. Usually happens when every button gets a filled style.
- **Flat hierarchy**: Everything is 14px/400 weight and light gray. Shadcn default output. The eye has nowhere to go.
- **Decorative emphasis**: Icons, badges, and colors applied to every item to "make it clear." Creates noise, not clarity.
- **Hero-less pages**: Inner pages where no element dominates. Common on "list of settings" screens and profile pages.
- **Uniform text opacity**: When all text is the same opacity, the eye has no entry point. Users scan randomly. Minimum 3 distinct opacity levels with gaps of 20+ points between them.
- **Equal spacing everywhere**: When every gap is the same (e.g. 16px everywhere), there is no grouping. The eye cannot determine what belongs together. Use at least 3 distinct spacing values.
- **Relying on borders for separation**: In dark mode, borders either disappear or look harsh. Use surface color differences for grouping instead. Reserve borders for interactive elements.

## Research-Backed Numbers

### Type scale ratios
- Page title : body = 2:1 to 3:1 (e.g. 32px : 16px). HIVE: 32/15 = 2.13:1 — within range.
- Section heading : body = 1.25:1 to 1.5:1 (e.g. 20px : 16px). HIVE: 20/15 = 1.33:1 — good.
- Label/meta : body = 0.69:1 to 0.875:1 (e.g. 11-14px : 16px). HIVE: 11/15 = 0.73:1 — good.
- Recommended app scale ratio: 1.2 (Minor Third) to 1.25 (Major Third). HIVE's scale is ~1.2.

### Weight contrast
- Page title to body: 300 weight units apart (700 vs 400)
- Section heading to body: 200 weight units (600 vs 400)
- Labels compensate small size with medium weight: 500-600 at 11-12px

### Dark mode text opacity (two competing systems)
- **Material Design**: 87% / 60% / 38% (gap: 27, 22). Conservative — prevents halation.
- **HIVE current**: 100% / 70% / 50% / 30% (gap: 30, 20, 20). Even stepping.
- Key insight: primary text at 100% white risks halation (text glow/bleed) on cheaper monitors. 87-90% is safer for body text. Headings at 100% are fine because they're large (24px+) and bold.
- The GAP between levels matters more than absolute values. Minimum perceptual gap: 20 points.

### Dark mode elevation
- Each elevation step: +2-4% luminance above the base
- Maximum 4-5 distinct surface levels
- HIVE's 4 levels (void/surface/card/card-hover) is within recommended range

### Dark mode scanning behavior (ACM 2025 eye-tracking study)
- Dark mode improved accuracy at MEDIUM task complexity
- Fewer fixations while maintaining higher accuracy — more efficient scanning
- Users scan MORE and read LESS in dark mode — making hierarchy even more critical
- High-contrast elements attract fixation more aggressively on dark backgrounds
- Implication: HIVE is dark-only, so opacity/size hierarchy is MORE important than it would be in light mode

## HIVE-Specific Notes
- Landing page: Clash Display 32-48px at top, then section titles, then content — hierarchy exists
- Inner surfaces (space feed, build page): flat hierarchy is the pain point — everything reads at same weight
- Gold should anchor hierarchy on every screen — if there's no gold element, hierarchy is probably broken
- HIVE's 100% primary text may cause halation on cheap laptop screens. Consider testing 90% opacity for body text.
- The 1.2 type scale ratio is on the subtle end — if inner surfaces feel flat, bumping to 1.25 would widen the gap between heading levels

## Scoring Guide
- **5**: Immediate visual order. Eye flows naturally from most to least important without effort. One dominant element per screen. Typography does the work. 3+ distinct opacity levels with clear gaps. Asymmetric heading spacing creates grouping.
- **4**: Clear hierarchy with minor competition. Maybe two elements of similar weight, but the overall order is readable. Surface elevation creates depth.
- **3**: Some structure, but the eye hesitates. Unclear what to look at first on at least one major screen area. Only 2 opacity levels. Uniform spacing.
- **2**: Flat or competing — several elements at similar weight, no dominant focal point. Same opacity on most text.
- **1**: No hierarchy. Everything screams. Or everything whispers. Either way: no order.

## Sources
- Linear UI Redesign (linear.app/now/how-we-redesigned-the-linear-ui)
- Material Design Dark Theme (m2.material.io/design/color/dark-theme.html)
- Pimp My Type — Typographic Hierarchy (pimpmytype.com/hierarchy/)
- ACM 2025 Eye Tracking Dark/Light Themes (dl.acm.org/doi/10.1145/3715669.3725879)
- Uxcel — 12 Principles of Dark Mode Design
- NNGroup — Content-to-Chrome Ratio
