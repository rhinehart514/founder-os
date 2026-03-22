# Anti-Slop Detection

This is a supplementary knowledge file — not one of the 11 taste dimensions, but a mechanical detection layer that supports distinctiveness, polish, and emotional_tone scoring.

## The AI Aesthetic Fingerprint

The statistical median of 2019-2024 Tailwind CSS tutorials, now replicated by every LLM. Adam Wathan (Tailwind creator) publicly acknowledged that making every button `bg-indigo-500` five years ago "caused every AI-generated interface on Earth to turn purple."

| Element | AI Default | Why Recognizable |
|---------|-----------|-----------------|
| Fonts | Inter, Roboto, Arial, Open Sans | Training data median |
| Colors | Purple-to-blue gradients, `bg-indigo-500`, `bg-violet-600` | Tailwind/Shopify Polaris default |
| Layout | Three-card icon grid (features section) | Canonical AI section layout |
| Hover | `hover:scale-105`, `hover:scale-110` | Scale transforms on everything |
| Transitions | `transition-all duration-300` | Template-level specificity |
| Shadows | Same `shadow-md` on everything | No depth hierarchy |
| Radius | `rounded-lg` uniformly | No radius system |
| Spacing | Uniform padding everywhere | No density contrast |
| Symmetry | Perfect bilateral on every section | No intentional breaks |
| Palette | Evenly distributed, no dominant accent | No opinion |

## Complete Slop Pattern Catalog (30 patterns)

### Typography Slop
1. Default sans-serif only (`font-inter`, `font-roboto`, `font-arial`) — zero display/personality fonts
2. Timid weight range — only `font-normal` + `font-semibold`, no extremes
3. Small size jumps — 1.5x between heading levels (human design uses 2-3x)
4. No display font — everything is body font at different sizes

### Color Slop
5. Purple/indigo gradients — `from-purple-500 to-blue-500`, `bg-indigo-500`, `bg-violet-600`
6. Off-system colors — `text-gray-400`, `bg-zinc-900`, `text-slate-300` (raw Tailwind, not tokens)
7. Blue/teal/pink accents — colors not in the design system
8. Evenly distributed palette — every color at equal visual weight, no dominant accent
9. Pure black backgrounds — `bg-black`, `bg-[#000000]`

### Layout Slop
10. Three-card icon grid — `grid grid-cols-3` with identical children (icon + heading + text)
11. Perfect bilateral symmetry — no intentional asymmetric breaks anywhere
12. Full-viewport hero — hero >80vh with minimal content
13. Uniform spacing — same gap everywhere, zero density contrast

### Motion Slop
14. Scale on hover — `hover:scale-105`, `hover:scale-110`
15. Transition-all — `transition-all` instead of specific properties
16. Animate-pulse on interactives — on buttons/cards, not skeleton loaders
17. Spring/bounce/elastic — `animate-bounce`, spring physics
18. Parallax/scroll triggers — scroll-triggered transforms

### Surface Slop
19. Glassmorphism everywhere — `backdrop-blur` on non-overlay elements
20. Gradient fills on cards — `bg-gradient-to-*` on card surfaces
21. Heavy shadows — `shadow-lg`, `shadow-xl`, `shadow-2xl`
22. Neon glow effects — colored box-shadows >10% opacity

### Structural Slop
23. Deep className strings — >120 characters
24. Deep nesting — div > div > div > div (3+ levels)
25. Nested space-y — `space-y-*` inside `space-y-*`
26. Deep conditional rendering — ternary > ternary > ternary
27. Wrapper-only components — add a className and nothing else
28. 8+ prop components
29. useEffect for event handlers
30. Off-system opacity — values not in 1.0/0.7/0.5/0.3/0.05/0.03 system

## Programmatic Detection

### Tier 1: Grep (pre-commit hook, instant, zero deps)
```bash
# Banned classes
grep -rn 'hover:scale-' src/**/*.tsx
grep -rn 'transition-all' src/**/*.tsx
grep -rn 'shadow-lg\|shadow-xl\|shadow-2xl' src/**/*.tsx
grep -rn 'bg-gradient-to' src/**/*.tsx
grep -rn 'animate-bounce' src/**/*.tsx
grep -rn 'bg-black' src/**/*.tsx

# Off-system colors
grep -rn 'text-gray-\|bg-zinc-\|text-slate-\|bg-slate-' src/**/*.tsx
grep -rn 'text-blue-\|bg-blue-\|text-purple-\|bg-purple-' src/**/*.tsx
grep -rn 'text-teal-\|bg-teal-\|text-pink-\|bg-pink-' src/**/*.tsx

# Banned fonts
grep -rn 'font-inter\|font-roboto\|font-arial' src/**/*.tsx
```

### Tier 2: ESLint (CI, blocks deploy)
- `eslint-plugin-tailwindcss` — `no-custom-classname` blocks non-token classes
- Custom `no-restricted-syntax` for banned patterns
- Already has `@typescript-eslint/no-explicit-any`

### Tier 3: Stylelint (CSS token enforcement)
- `stylelint-plugin-rhythmguard` — spacing scale enforcement, autofixes to nearest token
- `@tempera/stylelint` — detects unofficial token values, suggests nearest official token
- ESLint native CSS support (Feb 2025) — enforces tokens in .css files

## HIVE's Current State

**What HIVE does well (ahead of industry):**
- ui-generation.md has 67 rules — more comprehensive than Anthropic's official frontend-design skill
- Color system (warm blacks + gold + white + status, no blue/purple/pink/teal) is tighter than any published guide
- 4-level opacity system (1.0/0.7/0.5/0.3) is unique and intentional
- Anti-Slop Patterns section (rules 52-67) is the most comprehensive banned-pattern list found in any codebase
- Motion rules are unusually precise: 5 allowed patterns, everything else banned, specific durations
- Codebase is already clean: zero `scale-105`, zero `transition-all`, zero `shadow-lg/xl/2xl`

**Where HIVE falls short:**
- **Zero programmatic enforcement** — every rule is a prompt instruction, not a lint rule or CI check
- No `eslint-plugin-tailwindcss` installed
- No pre-commit hook scans for banned classes
- 6 off-system color hits in admin components (`text-gray-*`, `bg-zinc-*`)
- 1 gradient-on-surface hit in EventDetailDrawer

## Anti-Slop CI/CD Checklist

1. **Pre-commit hook** — grep for banned classes (instant, zero deps)
2. **ESLint plugin** — `eslint-plugin-tailwindcss` with `no-custom-classname` + whitelist
3. **Custom ESLint rules** — `no-restricted-syntax` for 16 banned patterns from rules 52-67
4. **Component size check** — no file >200 lines in components/
5. **className length check** — no className >120 chars
6. **Visual regression** — Playwright screenshots on key surfaces
7. **Taste eval** — `/taste` as the visual quality gate post-deploy

## How Slop Maps to Taste Dimensions

| Slop Category | Taste Dimension Affected | Impact |
|---------------|------------------------|--------|
| Typography slop (1-4) | distinctiveness (−2), hierarchy (−1) | Generic fonts = kit identity |
| Color slop (5-9) | distinctiveness (−2), emotional_tone (−1) | Purple/blue = AI fingerprint |
| Layout slop (10-13) | distinctiveness (−1), breathing_room (−1) | Three-card grid = canonical AI |
| Motion slop (14-18) | polish (−1), distinctiveness (−1) | Scale-105 = AI indicator #1 |
| Surface slop (19-22) | polish (−1), emotional_tone (−1) | Glassmorphism/neon = decoration |
| Structural slop (23-30) | polish (−1) | Code quality visible in output |

## Sources
- prg.sh — Why Your AI Keeps Building the Same Purple Gradient Website
- Anthropic — Improving Frontend Design Through Skills (claude.com/blog)
- Tech Bytes — Escape AI Slop Frontend Design Guide
- Jack Pearce — Purple Gradient AI Aesthetics
- eslint-plugin-tailwindcss (npm)
- stylelint-plugin-rhythmguard (npm)
- ESLint — CSS Support (eslint.org/blog/2025/02)
- UX Trends 2026 — The New Rules of Design (blog-ux.com)
- AI Slop Detection Techniques (glukhov.org)
