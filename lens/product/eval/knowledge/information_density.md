# Information Density

## Patterns (what good looks like)
- **Density = value/space+time, not pixels/area**: Matt Strom's framework — density is the value a user gets divided by time and space the interface occupies. Visual density, information density, and temporal density are separate axes. Bloomberg Terminal is dense AND fast because skilled users navigate dozens of charts in milliseconds.
- **Linear's technique — subtraction, not addition**: Precise sub-pixel alignment ("something you'll feel after a few minutes"), chrome dimming (sidebar "a few notches dimmer"), tab compaction, border softening, color restraint. High density through removing noise, not adding content.
- **Progressive disclosure with the 80/20 rule**: Show on surface if needed in >80% of visits (status, counts, primary CTA, identity). Hide behind click if <20% (settings, history, secondary actions). Patterns ranked by discoverability: inline expand > hover reveal > drawer > modal > separate page.
- **Density gradient within a single page**: Title area low density (signals location), action bar medium, content area high, footer low. Mirrors newspaper: headline (sparse) > lede (medium) > body columns (dense).
- **Content > chrome**: The data takes more space than the UI furniture. NNGroup benchmarks: excellent = 13:1 content-to-chrome ratio (The New Yorker mobile). Poor = 2:1.

## Research-Backed Measurements

### Row heights by density tier
| Density | Row Height | Use Case |
|---------|-----------|----------|
| Compact | 32-40px | Power users, data tables, issue trackers |
| Default | 44-52px | General purpose, mixed audiences |
| Relaxed | 56-64px | Reading-heavy, onboarding, casual |

### Product-specific measurements
- Linear issue rows: ~36px (compact)
- Material Design default component: 36dp buttons, 56dp text fields
- Apple HIG list row: 44pt (canonical touch target)
- Data table standard: condensed 40px, regular 48px, relaxed 56px
- Mobile touch target minimum: 48px (Material), 44pt (Apple)

### Typography at each density
- Compact: 13-14px body, 11px metadata, line-height 1.3-1.4
- Default: 14-15px body, 12px metadata, line-height 1.4-1.5
- Comfortable: 15-16px body, 13px metadata, line-height 1.5-1.6

### Cell/card padding
- Compact: 8px
- Standard: 15-16px
- Comfortable: 20-24px

## Dense vs Cluttered (the hierarchy problem)

| Property | Dense (good) | Cluttered (bad) |
|----------|-------------|----------------|
| Visual hierarchy | 3 clear levels | Everything same weight |
| Alignment | Precise grid, sub-pixel aligned | Elements float independently |
| Grouping | Related items clustered, whitespace between groups | Uniform spacing everywhere |
| Typography | 2-3 sizes with clear purpose | 5+ sizes, ambiguous purpose |
| Color | Restrained, color = meaning | Color = decoration |
| Chrome | Minimal, dimmed | Heavy borders/separators competing with content |
| Content ratio | >8:1 on mobile, >13:1 excellent | <4:1 (chrome dominates) |
| Motion | None or functional | Decorative motion adding noise |

**Key insight**: "When people comment that a design is 'busy,' they're really reacting to the fact that the design doesn't lead them smoothly around the page." Clutter is a hierarchy failure, not an information excess.

## Density by Surface Type

| Surface | Target Density | Row Height | Rationale |
|---------|---------------|-----------|-----------|
| Feed/dashboard | Medium-high | 48-56px per item | Scanning many items, quick pattern recognition |
| List/table | High | 36-44px per row | Power users processing items, minimize scrolling |
| Detail view | Medium | Mixed | Reading + comprehension, not scanning |
| Creation tool | Low-medium | Generous (16-24px pad) | Reduce cognitive load during complex tasks |
| Settings/admin | Medium | 48-56px per row | Infrequent use, clarity > density |
| Onboarding | Low | 64px+ per step | Comprehension is bottleneck |

## Anti-Patterns (what bad looks like)
- **Desert pages**: Large padding everywhere, content 20% of screen, furniture 80%. Common on dashboard homepages.
- **One piece of information per card**: Cards that take 200px to communicate "3 members." Information-to-area ratio is terrible.
- **Action-before-data**: Showing big buttons and CTAs before showing the data the user came for. Lead with information, follow with action.
- **Hiding primary signals**: Burying response counts, vote totals, or activity indicators behind clicks when they're the primary social proof signal.
- **Uniform density**: Treating a list of settings the same as a feed of social content. Density should match task urgency and data richness.
- **Over-layering progressive disclosure**: More than 2 disclosure levels deep = users get lost. The "..." menu trap.

## HIVE-Specific Notes
- Current token spacing: section 64px, item 48px, component 24px, tight 12px, minimal 8px. These are on the generous/comfortable side.
- Experiment learnings already confirm: "compact density over spacing" beats full-viewport heroes
- **Feed**: currently generous spacing. Should move toward 48px card heights to show more above the fold. Campus pulse strip should be densest (32-36px rows, 11px mono metadata).
- **Space**: stream benefits from medium density. App cards could use 40-48px compact rows for spaces with 5+ apps.
- **Build**: keep generous. Creation surfaces need breathing room.
- **Profile**: bento grid should use density gradient — dense stats at top, generous content below.
- 64px section gap may be too large for feed sections — Linear and GitHub use 16-24px in dense views.
- Above-the-fold item count on feed at 1280x800 is unknown — if <5 items, density is too low for "what's happening."

## Scoring Guide
- **5**: Information-to-area ratio is high. Data-dense without clutter. Density varies by surface type (feed compact, creation generous). Progressive disclosure used correctly. Content-to-chrome ratio >8:1. Social proof data (counts, activity) visible without clicks. The Linear model.
- **4**: Good density in most areas. One or two screens too sparse, but overall doesn't feel empty. Density gradient visible.
- **3**: Mixed. Some screens dense (feed), others desert (settings, profile). No clear density philosophy. Some social proof hidden behind clicks.
- **2**: Generally sparse. More padding/chrome than content. Social proof hidden. Above-the-fold shows <5 items on feed.
- **1**: Desert. Large empty areas. Content <40% of visible area. Users can't tell if the product has data.

## Sources
- Matt Strom — UI Density (mattstromawn.com)
- Linear UI Redesign (linear.app)
- NNGroup — Content-to-Chrome Ratio
- Pencil & Paper — Data Table UX Patterns
- Material Design — Applying Density (m2.material.io)
- Tufte — Data-Ink Ratio (via multiple sources)
- Envy Labs — Interface Information Density Best Practices
- Fresh Consulting — Data Density High-Level to Low-Level
