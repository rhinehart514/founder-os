# Contrast

## Patterns (what good looks like)
- **WCAG AA compliance for text**: 4.5:1 ratio for body text, 3:1 for large text (18px+ or 14px bold). HIVE's white (#FFF) on #0A0A09 background: ~21:1. Gold (#FFD700) on #0A0A09: ~12:1. Both comfortably pass.
- **Reading-level contrast tiers**: Primary text at full white. Secondary at 50% white (~7:1 on HIVE's dark bg). Tertiary at 35% white (~4.5:1). Metadata/ghost at 25% white (3:1 — borderline, use only for truly secondary info at 14px+).
- **Interactive contrast**: Buttons and interactive elements are visually distinguishable from static content. The gold border on a hovered format tile versus the white/5 border on a resting tile is a contrast signal.
- **State distinction**: The difference between a selected item and an unselected item should be immediately obvious, not a 10% opacity change.
- **Text on colored backgrounds**: Gold text on gold-subtle background (rgba 12%) — check this. Should maintain 4.5:1. If gold text appears on any colored surface, verify ratio.

## Anti-Patterns (what bad looks like)
- **Ghost text for real content**: Using text-white/30 (15% white) for content that users need to read. This passes at large sizes only. Failures common on mobile at 12–13px.
- **Muted borders as the only separator**: Border-white/[0.05] (4% white) is invisible on most monitors. If it's the only visual separator between content areas, low-contrast monitors will see no separation.
- **Disabled state confusion**: Items that are "coming soon" at 50% opacity — what exactly can the user click? Low contrast combined with opacity-based affordance is a trap.
- **Status color reliance**: Using color alone to distinguish error/success/warning states. Red text with no icon fails for colorblind users.
- **Gold at 12% opacity as UI element**: `--life-subtle` at rgba(255,215,0,0.12) is a background tint, not a foreground element. Using this for text or key UI elements fails contrast.

## HIVE-Specific Notes
- Text primary (white) on void (#0A0A09): ~21:1 — excellent
- Text secondary (white/50) on surface (#111110): ~6:1 — good
- Text tertiary (white/35) on surface: ~4.3:1 — borderline at small sizes, check at 12px
- Text muted (white/25) on surface: ~3.1:1 — only acceptable at 18px+ or 14px bold
- Gold (#FFD700) on void: ~12:1 — excellent
- "Coming soon" tiles: opacity-50 on all children. Verify the text is still readable.
- Border-white/[0.05] (4%): effectively invisible. Cards rely on bg-color difference, not border. This is fine.

## Scoring Guide
- **5**: All text passes WCAG AA. Interactive states are clearly distinguishable. Disabled/inactive states are obviously different from active. No content that users need to read is at contrast ratio < 4.5:1.
- **4**: Mostly passing. One or two minor instances of low-contrast metadata at small sizes. Primary content is always readable.
- **3**: Main text is readable but secondary/meta text at small sizes is borderline. Some interactive state distinctions are subtle (10% opacity changes).
- **2**: Multiple readability failures. Tertiary text at 12px on dark backgrounds. Status colors used without icon/text backup.
- **1**: Systematic contrast failures. White/30 used for body text. Gold-on-gold. Content is genuinely difficult to read.
