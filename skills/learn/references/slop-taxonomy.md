# Slop Taxonomy — 2026 Detection Rules

Slop is the visual equivalent of filler text. It looks like a product but communicates nothing specific. These patterns are the telltale signs that no human with taste made deliberate choices.

## Category 1: Copy Slop

AI-generated or template copy patterns. The headline test: could this headline appear on 1000 different products unchanged?

**Detection rules:**
- "Build [X] faster" / "Supercharge your [X]" / "The [X] platform for modern teams"
- "Loved by [N]+ teams worldwide" with no named customers
- "Simple. Powerful. Beautiful." or any 3-word adjective tagline
- Feature descriptions that are category names, not specific claims ("Analytics", "Collaboration", "Security")
- "Get started for free" as the only CTA copy (what am I getting started WITH?)
- Testimonials with stock photos or no company attribution
- "AI-powered" anywhere in the hero without specifying WHAT the AI does

**Crafted alternative:** Copy that names the specific user, specific problem, and specific mechanism. "See which deploys broke your error rate — before your users do" vs "Monitor your application performance."

## Category 2: Visual Slop

Template-derived visual patterns that signal "assembled, not designed."

**Detection rules:**
- Gradient hero section (especially purple-to-blue or blue-to-teal) with no functional purpose
- 3-column feature grid with icons + heading + paragraph, identical card heights
- Floating mockup screenshots with drop shadows on a gradient background
- Default shadcn component styling with zero customization (check: are border-radius, colors, shadows all framework defaults?)
- Background dot grid / mesh gradient / aurora effect as decoration (not serving content)
- "Dashboard preview" screenshot that shows fake data
- Logo cloud with 8+ logos at equal size in a horizontal row
- Alternating left-right feature sections (image + text, text + image, repeat)

**Crafted alternative:** Layout that serves the specific content. A deployment timeline doesn't need the same layout as a customer testimonial. Each section's visual structure should be dictated by what it contains, not by a template.

## Category 3: Interaction Slop

Default or absent interaction patterns.

**Detection rules:**
- Hover states are only opacity changes (0.7 opacity on hover for everything)
- No page transitions (hard cuts between routes)
- No loading states (spinner or nothing between actions)
- No micro-interactions on state changes (form submit → nothing visible happens)
- Modal/dialog is the answer to every secondary action
- No keyboard shortcuts or command palette in a productivity tool
- Scroll animations that are just "fade in from bottom" on every element

**Crafted alternative:** Interactions that match the product's personality. A creative tool should feel playful (spring physics, elastic transitions). A data tool should feel precise (snap transitions, grid-aligned animations). A calm tool should feel gentle (slow easing, minimal motion).

## Category 4: Structural Slop

Architecture patterns that betray template origins.

**Detection rules:**
- Every page has the same layout (header + hero + 3-column + CTA + footer)
- Settings page is a single long form with no sections
- Empty states show a sad face icon or "No data yet" with no guidance
- 404 page is the framework default or a cute illustration with no navigation
- Navigation is a flat horizontal list with no hierarchy
- Footer has 4 columns of links that don't correspond to the actual site structure

**Crafted alternative:** Structure that reflects the product's information architecture. Each page type has a layout that serves its purpose. Empty states guide the user toward value. Navigation reflects how users actually think about the product's features.

## Category 5: 2026-Specific Slop

Patterns that are trendy right now and therefore appearing in every AI-generated site.

**Detection rules:**
- Bento grid layout used decoratively (boxes with icons, no real content)
- "Dark mode first" with no light mode option (lazy, not a design choice)
- Monospace font for non-code content (aesthetic borrowing from dev tools)
- Vercel/Linear visual mimicry without the information density to justify it
- "Command-K" palette that searches 3 items
- Glassmorphism cards with no functional benefit
- Animated border gradients on cards
- "Powered by AI" badge/pill as a feature

**Crafted alternative:** Using 2026 patterns because they serve the content. Bento grid for a dashboard with genuinely different data types per cell. Dark mode because the product is used in low-light contexts. Monospace because the product involves code.

## Severity mapping

- **3+ patterns from categories 1-4**: verdict = "slop" → taste cap at 40
- **1-2 patterns, with some crafted elements**: verdict = "mixed"  → no cap, but flag each pattern
- **0 patterns OR patterns used with clear purpose**: verdict = "crafted" → no penalty

## How taste uses this

The anti-slop check runs BEFORE dimensional scoring. It reads `.claude/cache/anti-slop.md` (category-specific) and this taxonomy (universal). The verdict (crafted/mixed/slop) feeds into the scoring caps in taste's SKILL.md.
