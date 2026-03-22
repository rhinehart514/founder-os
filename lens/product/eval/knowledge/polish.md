# Polish

## Patterns (what good looks like)
- **8-state completeness on every interactive element**: Default, hover, active/pressed, focus-visible, selected, disabled, loading, error. Most teams ship 3-4 of these. Polished products ship all 8.
- **Consistent radius system with inner-radius rule**: The golden rule: inner radius = outer radius - padding. A card with 16px radius and 16px padding should have inner elements at 0px radius (not also 16px). "A 2px change in border radius shifts how an entire interface feels."
- **Transition timing from a system, not ad-hoc**: 100ms hover, 150ms tooltip, 200ms panel, 250-300ms modal appear, 200-250ms modal dismiss (exits ~80% of enter duration). Never >500ms (feels like lag).
- **Skeleton loading with shimmer, not pulse**: Shimmer (wave sweep) for content-heavy layouts. Pulse for small isolated elements. Key trick: `background-attachment: fixed` so all skeleton elements shimmer in sync. Unsynchronized shimmer looks broken. 1.5-2s cycle.
- **Loading show-delay**: Show skeleton after 150-300ms (avoid flash on fast loads). Keep visible minimum 300-500ms (avoid flicker).
- **Focus ring on dark backgrounds**: Two-color technique is gold standard: `outline: 3px solid [brand]; box-shadow: 0 0 0 6px [contrast]`. HIVE's gold (#FFD700) outline has excellent contrast against warm blacks.

## Transition Timing Reference

| Action | Duration | Easing | Source |
|--------|----------|--------|--------|
| Hover (bg/color) | 100ms | ease-out | Vercel, HIVE rules |
| Button press/active | 50-100ms | ease-in | NN/g |
| Toggle/checkbox | 100ms | ease-out | NN/g |
| Tooltip show | 150ms | ease-out | Linear |
| Dropdown/panel open | 200ms | ease-out | NN/g |
| Modal appear | 250-300ms | ease-out | NN/g |
| Modal dismiss | 200-250ms | ease-in | NN/g (exits ~80% enter) |
| Tab switch | 150-200ms | ease-in-out | Common |
| Skeleton shimmer cycle | 1500-2000ms | linear | Frontend Hero |
| Loading show-delay | 150-300ms | n/a | Vercel |
| Loading min-visible | 300-500ms | n/a | Vercel |
| Count-up animation | 800ms | ease-out cubic | HIVE rules |
| Stagger between items | 50ms delay | n/a | HIVE rules |
| Max animation duration | 500ms | any | NN/g |

## Loading States Decision Matrix

| Scenario | Pattern | Why |
|----------|---------|-----|
| Full page load | Skeleton | Preserves layout, sets expectations |
| Component in page | Skeleton | Prevents layout shift |
| Button action (POST) | Inline spinner | Discrete action, user watching button |
| Background refresh | None or subtle indicator | User didn't initiate |
| Fast response (<300ms) | Nothing (show-delay prevents flash) | Avoid flicker |
| Slow response (>2s) | Skeleton + progress hint | User needs reassurance |
| Error after loading | Replace skeleton with error + retry | Never leave skeleton permanent |

## The Polish Audit: 10-Item Checklist

1. **State audit** — Tab through every interactive element. Visible focus-visible, hover, active, disabled on each?
2. **Radius audit** — List every radius value. From token scale? Inner = outer - padding respected in nested elements?
3. **Timing audit** — All transitions with explicit durations? No `transition: all`? Hover 100ms, panels 200ms, modals 250-300ms?
4. **Loading audit** — Every route has skeleton during data fetch? No layout shift? 150-300ms show-delay?
5. **Spacing audit** — 10 random elements. All margin/padding multiples of 4px? No rogue 5px, 7px, 10px, 15px?
6. **Error audit** — Disconnect network. Empty forms. API errors. Every failure has message + recovery action?
7. **Empty state audit** — Every screen with zero data has guidance, CTA, and personality?
8. **Motion audit** — Enable `prefers-reduced-motion`. All animations stop? Final states display correctly?
9. **Contrast audit** — Every text color against its background passes WCAG AA? Hover/focus/selected states distinguishable?
10. **Consistency audit** — 5 similar components (e.g. cards). Same padding, radius, border, text size, spacing?

## Anti-Patterns (what bad looks like)
- **Mixed radius on siblings**: Cards at rounded-md, buttons at rounded-full, inputs at rounded-lg. No system.
- **Inner radius = outer radius (nested)**: Creates uneven visual gap. Always subtract padding.
- **`transition: all`**: Transitions properties unintentionally, causes jank. Use explicit properties.
- **No loading state (white flash or blank)**: Signals "nobody tested this path."
- **Hover identical to default**: "Is this clickable?" confusion. Minimum: bg-white/[0.05] -> bg-white/[0.10].
- **Unsynchronized skeleton animations**: Multiple elements pulsing out of phase. Use `background-attachment: fixed`.
- **`animate-pulse` on interactive elements**: Feels like loading state, not resting state. Reserve for skeletons only.
- **Inconsistent spacing between similar sections**: Visual rhythm breaks. 4px grid + named tokens fix this.
- **Missing :active state**: Buttons without pressed feedback feel broken.
- **No prefers-reduced-motion respect**: Accessibility failure AND polish signal.

## HIVE-Specific Notes
- Design system has the right pieces: consistent radius (16px cards, full buttons), consistent transitions (150ms quick)
- 3328 TypeScript errors suggest the system isn't uniformly applied
- FeedSkeleton exists but uses animate-pulse (Tailwind default). Shimmer with background-attachment: fixed would feel more premium.
- Gold focus ring defined and correct — verify it appears on Tab navigation across all interactive elements
- Grain texture (3% opacity) is a polish signal — if applied inconsistently, remove entirely
- :active states are sparse — most buttons only define hover. Add active/pressed to all primary and secondary buttons.
- prefers-reduced-motion: rules mandate it (rule 25). Implementation needs verification — no motion-safe: or prefers-reduced-motion queries confirmed.
- Inner radius rule is likely violated: cards at rounded-2xl (16px) with inner elements at rounded-xl (12px) when padding is 16px (should be 0px)

## Scoring Guide
- **5**: Feels finished. 8 states on every interactive element. Transitions from a timing system. Skeletons with shimmer on every async path. Radius from a 3-5 token system with inner-radius rule. prefers-reduced-motion respected. The 10-item checklist passes fully.
- **4**: High polish with a few rough edges. Maybe one missing loading state or one screen with slightly inconsistent spacing. But the experience is tight overall.
- **3**: In-progress polish. Some surfaces tight, others inconsistent. Missing states on some components. Contrast between polished and unpolished sections is noticeable.
- **2**: Multiple obvious failures. Mixed radius values. Inconsistent spacing. Missing hover states. Broken mobile view. Feels unfinished.
- **1**: No polish. Spacing eyeballed. No transition system. Missing states everywhere. Breaks on content variations.

## Sources
- NN/g — Animation Duration (nngroup.com)
- NN/g — Skeleton Screens 101
- Vercel Web Interface Guidelines (vercel.com/design/guidelines)
- Sara Soueidan — Focus Indicators Guide
- W3C C40 — Two-Color Focus Indicator Technique
- Alexandra Basova — Corner Radius System (Medium)
- Frontend Hero — Skeleton Loaders
- Stan Vision — Micro Interactions 2025
- Montana Banana — Microinteractions + Accessibility
- Apple HIG — Dark Mode
