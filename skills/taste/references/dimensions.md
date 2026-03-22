# Taste Dimensions — Scoring Anchors & What Moves Each

Read on demand during Phase 4 (scoring). Each dimension includes what it measures, concrete anchors at key score bands, and what changes actually move the score.

## The 80+ Bar

80-100 is not "clean." It's exceptional. Products in this range demonstrate mastery — psychological grounding, unique layout thinking, sophisticated motion/interaction, and cross-device fluency. The bar:

**Psychology & cognition:** Fitts's law on CTAs (large targets, short distance). Gestalt grouping (proximity, similarity, continuity) used deliberately. Cognitive load managed via progressive disclosure, chunking, recognition over recall. Hick's law applied to option counts. Miller's number respected in navigation depth.

**Layout originality:** If Tailwind defaults + a component library could produce it, cap at 79. 80+ requires at least one of: asymmetric grid breaks with purpose, bento/editorial layout, spatial narrative (content position encodes meaning), viewport-aware composition that transforms (not just stacks) across breakpoints.

**Interaction craft:** Static pages cap at 75 for polish and scroll_experience. 80+ expects purposeful motion: choreographed enter/exit (Framer Motion, GSAP), scroll-driven sequences (Lenis, ScrollTrigger), micro-interactions on state changes (not just hover opacity), cursor/pointer awareness. Motion must serve comprehension, not decoration.

**Package sophistication (when used):** Raw CSS/HTML can score 80+ on layout and hierarchy. But for polish, scroll_experience, and distinctiveness — sophisticated use of external packages raises the ceiling: react-spring/framer-motion orchestration, three.js/r3f spatial elements, custom shader backgrounds (not generic gradients), Lottie animations for branded moments, custom cursor behaviors. The key word is *purposeful* — every package justifies its bundle size with user value.

**Accessibility as craft (not compliance):** 80+ treats a11y as a design dimension: `prefers-reduced-motion` alternatives that are still beautiful, `focus-visible` states that enhance rather than interrupt, screen reader narrative that tells a coherent story, color choices that work for all vision types without being boring.

If a product hits 80+ on most dimensions, it should be genuinely impressive to look at and use. If it isn't — the scores are wrong.

---

## Gate Dimensions

These cap the overall score at 30 if either scores below 30. Fix the skeleton before decorating.

### layout_coherence

Does the layout have a system? Same grid, same spacing logic, same component sizing across pages.

| Score | Anchor |
|-------|--------|
| 90-100 | Flawless grid with intentional breaks — asymmetric compositions, bento layouts, or editorial spacing that serves content hierarchy. Spacing scale is mathematical AND varied (not uniform padding everywhere). Cross-page consistency in the system, deliberate divergence in the moments. Uses CSS grid/subgrid capabilities beyond basic columns. (Stripe product pages, Vercel dashboard, Read.cv) |
| 70-89 | Clear grid system with occasional breaks. Spacing feels intentional. Pages share a skeleton. |
| 50-69 | Some alignment consistency but gaps visible. Mix of spacing values. Some pages feel different. |
| 30-49 | Elements float independently. Spacing is ad-hoc. Pages don't feel related. |
| 0-29 | No discernible system. Random placement. Different layout logic per page. |

**What moves this score:**
- Consistent spacing scale (4/8/16/24/32px, not arbitrary values)
- Shared layout components (same header/sidebar/content grid across routes)
- Alignment: elements that should align, do
- Removing one-off spacing overrides
- **80+ requires:** CSS grid/subgrid beyond 12-column, container queries for component-level responsiveness, layout that transforms across breakpoints (not just stack), at least one intentional asymmetric or editorial composition

**What doesn't move this score:**
- Color changes, font changes, adding decoration
- New features on existing layout (neutral unless they break the grid)

---

### information_architecture

Can you describe the organizing principle in one sentence? Does nav reach all destinations?

| Score | Anchor |
|-------|--------|
| 90-100 | Mental model is instant — user can draw the sitemap after 30 seconds. Nav anticipates next action (contextual, not just global). Spatial memory reinforced: consistent positions, animated transitions between levels, breadcrumb or location signal on every view. (Notion sidebar, Linear command palette, GitHub repo nav) |
| 70-89 | Strong organizing principle. Most pages reachable from nav. Occasional dead end. |
| 50-69 | Organization exists but isn't obvious. Some orphan pages. Nav has gaps. |
| 30-49 | Hard to describe the structure. Multiple orphan routes. Nav feels incomplete. |
| 0-29 | No coherent organization. Can't find things. Pages exist without nav access. |

**What moves this score:**
- Complete navigation that reaches all routes
- Breadcrumbs or location indicators
- Consistent content grouping (all settings in one place, not scattered)
- Removing orphan pages or linking them into the nav

**What doesn't move this score:**
- Visual styling of nav elements (that's polish)
- Adding new content without adding it to nav (actually hurts)

---

## Visual Dimensions

Scored primarily from screenshots.

### hierarchy

Do I know what this is and where to look? Clear primary element per screen, one primary action per view.

| Score | Anchor |
|-------|--------|
| 90-100 | Eye path is choreographed — size, weight, color, position, and motion all conspire to guide attention in sequence. Primary action has 3x+ visual weight of secondary. Uses Gestalt principles (proximity groups related items, similarity signals function, continuity guides flow). Negative space is active — it directs, not just separates. (Apple product pages, Stripe homepage, Linear issue view) |
| 70-89 | Clear primary element. Good size/weight differentiation. Minor competing elements. |
| 50-69 | Can find the primary element but it doesn't command attention. Multiple elements compete. |
| 30-49 | Everything same visual weight. No clear starting point. Multiple "loud" elements. |
| 0-29 | Visual chaos. Can't determine what matters. |

**What moves this score:**
- Size contrast between primary and secondary elements (2x+ difference)
- Reducing visual weight of secondary elements (lighter color, smaller text)
- One CTA per viewport, clearly distinguished
- Heading hierarchy (h1 > h2 > h3 with visible size steps)
- **80+ requires:** Fitts's law applied (primary CTA is large + near cursor path), Gestalt grouping visible in layout, negative space used directionally, entrance animations that guide eye to primary element first

### breathing_room

Does this feel calm or chaotic? Whitespace that aids comprehension.

| Score | Anchor |
|-------|--------|
| 90-100 | Whitespace is a design element, not absence of content. Rhythm varies — generous around hero/key moments, tighter in data-dense sections. Gestalt proximity actively groups related elements while separating unrelated. Padding ratios between nested elements follow a visible scale (not uniform). (Stripe docs, Vercel dashboard, Notion pages) |
| 70-89 | Good spacing between sections. Some tight areas but nothing cramped. |
| 50-69 | Adequate spacing but doesn't feel generous. Some areas feel busy. |
| 30-49 | Cramped. Elements crowd each other. Little separation between sections. |
| 0-29 | Wall of content. No breathing room. Hostile density. |

**What moves this score:**
- Increasing section padding (24px to 48px between major sections)
- Line height on body text (1.5+ for readability)
- Margin between cards/list items
- Reducing content per viewport (progressive disclosure instead of showing everything)

### contrast

Can I tell what's clickable? Color and weight contrast between interactive and static elements.

| Score | Anchor |
|-------|--------|
| 90-100 | Interactive affordance is multi-layered: visual distinction (color/weight/shape) + state feedback (hover, active, focus, disabled all distinct) + motion cues (subtle scale/shadow on hover). WCAG AAA contrast where possible. Dark/light mode both excellent. Focus-visible states are designed, not browser defaults. Keyboard navigation has visible, beautiful focus rings. |
| 70-89 | Most interactive elements distinguishable. Good color contrast. Minor ambiguity. |
| 50-69 | Can figure out what's clickable but requires scanning. Some low-contrast text. |
| 30-49 | Frequently confused about what's interactive. Low contrast text. Links blend with body. |
| 0-29 | Can't distinguish interactive from static. Fails WCAG contrast. |

**What moves this score:**
- Color differentiation for interactive elements (not just underlines)
- WCAG AA contrast ratios (4.5:1 for text, 3:1 for large text)
- Hover/focus states on all interactive elements
- Consistent interactive element styling (all links look like links)

### polish

Does this feel like someone cared? Pixel-level refinement.

| Score | Anchor |
|-------|--------|
| 90-100 | Pixel-perfect AND alive. Consistent radius/shadow/elevation system. Micro-interactions on every state change (not just hover — loading, success, error, empty all have distinct motion). Choreographed page transitions (Framer Motion layout animations, shared element transitions). Custom scrollbar, custom selection color, custom cursor where appropriate. Typography has optical adjustments (tracking varies by size, font-feature-settings enabled). Nothing feels default. (Linear, Raycast, Vercel, Arc) |
| 70-89 | High overall quality with rare imperfections. Consistent component styling. |
| 50-69 | Serviceable but generic. Some inconsistencies in radius, spacing, or icon sizing. |
| 30-49 | Visible shortcuts. Misaligned elements, inconsistent component styling, default browser UI leaking through. |
| 0-29 | Unfinished. Broken layouts, unstyled defaults, placeholder content visible. |

**What moves this score:**
- Consistent border-radius across all components
- Aligned icons (same size, same visual weight)
- Proper line-height and letter-spacing
- Eliminating default browser UI (unstyled scrollbars, default focus rings)
- Consistent shadow and elevation system
- **80+ requires:** Micro-interactions on state changes (loading/success/error/empty), page/route transitions animated, custom selection/scrollbar/focus styling, typography with optical sizing (tracking, font-feature-settings), motion library in use (Framer Motion, GSAP, react-spring) with choreographed sequences not just fade-in

### emotional_tone

Would I tell a friend about this? Does the visual design match the product's personality?

| Score | Anchor |
|-------|--------|
| 90-100 | Personality is unmistakable and multi-sensory — color, type, motion, copy, and sound (if present) all reinforce one emotional frequency. The vibe is describable in one word AND that word is different from competitors. Design choices provoke a feeling, not just communicate information. Custom illustrations/iconography that couldn't belong to another product. (Notion: calm productivity. Linear: precise engineering. Figma: playful creation. Amie: warm efficiency.) |
| 70-89 | Personality visible. Design choices feel deliberate. Tone is consistent. |
| 50-69 | Neutral. Professional enough but no personality. Could be any product. |
| 30-49 | Mixed signals. Some elements say "fun" while others say "enterprise." Incoherent tone. |
| 0-29 | Design actively undermines the product's purpose (playful UI for security product, corporate for creative tool). |

**What moves this score:**
- Color palette that matches the product's personality
- Microcopy with voice (not generic "Welcome to your dashboard")
- Illustration or visual elements that reinforce tone
- Consistency — one personality, not a committee

### distinctiveness

Would I recognize this tomorrow? Or does it look like every other app?

| Score | Anchor |
|-------|--------|
| 90-100 | A stranger could identify this product from a cropped screenshot. Has a visual signature: a unique interaction pattern, a distinctive layout approach, a color/shape language that's ownable. Domain-specific visualization or interaction that couldn't exist in another category. Uses technical craft (shaders, canvas, SVG animation, 3D elements) to create moments that feel invented, not assembled. (Figma's multiplayer cursors, Arc's spaces, Superhuman's command flow, Stripe's gradient mesh) |
| 70-89 | Notable design choices. Would recognize in a screenshot lineup. Some borrowed patterns. |
| 50-69 | Clean but generic. Could be any SaaS app. Tailwind/shadcn energy. |
| 30-49 | Template-based. No element that's specific to this product. |
| 0-29 | Default framework output. AI-generated landing page energy. |

**What moves this score:**
- One element that only makes sense for THIS product (domain-specific visualization, unique interaction)
- Custom color palette (not shadcn defaults)
- Microcopy with personality (not "Sign up for free")
- A visual signature (specific shape, pattern, or layout unique to this product)

**Slop rule applies here:** If the page could be generated by prompting an AI with "build me a [category] page" — cap at 30.

### scroll_experience

Does below-the-fold content reward scrolling? Not just more of the same.

| Score | Anchor |
|-------|--------|
| 90-100 | Scroll is an experience, not just navigation. Content types shift (text → visual → interactive → data). Scroll-driven animations (parallax with purpose, reveal sequences, sticky context headers). Scroll position communicates progress. Below-fold content rewards the scroll with something the above-fold promised but didn't deliver. Uses Intersection Observer or scroll libraries (Lenis, GSAP ScrollTrigger) for choreographed sequences. (Apple product pages, Stripe Atlas, Linear changelog) |
| 70-89 | Good content progression. Some variety below fold. Clear sections. |
| 50-69 | Content continues but doesn't surprise. Same pattern repeating. |
| 30-49 | Long scroll with no new information type. Card grid extending forever. |
| 0-29 | Nothing below the fold worth seeing. Or excessive scroll for minimal content. |

**What moves this score:**
- Content type variety (text section, then visual, then testimonial — not card, card, card)
- Section-level visual breaks (background color changes, full-width elements)
- Progressive information disclosure (overview first, detail as you scroll)
- Sticky elements that contextualize scroll position
- **80+ requires:** Scroll-driven animation (not just fade-on-enter — choreographed sequences, parallax with purpose, sticky transforms). Uses Intersection Observer, Lenis, GSAP ScrollTrigger, or equivalent. Static long-scroll caps at 75.

---

## System Dimensions

Scored from code + screenshots combined.

### wayfinding

Do I know what to do next? Can I get back? Requires understanding the nav model + data flow.

| Score | Anchor |
|-------|--------|
| 90-100 | Orientation is effortless — spatial memory is reinforced through consistent positioning, animated transitions between views (shared element transitions, layout morphs), and contextual next-actions that adapt to state. Command palette or keyboard shortcuts for power users. Deep links work perfectly. Browser back/forward feel native, not broken. Optimistic UI: actions feel instant because state updates before server confirms. (Linear cmd+k, Notion breadcrumbs, Figma's spatial canvas) |
| 70-89 | Good orientation. Active states in nav. Most flows have clear next steps. Rare dead ends. |
| 50-69 | Can navigate but requires thinking. Some dead ends after completing actions. |
| 30-49 | Frequently lost. Dead ends after key actions. No active state in nav. |
| 0-29 | Can't find your way. No back button logic. Stranded after actions. |

**What moves this score:**
- Active states in navigation (user knows where they are)
- After every action, clear next step or return path
- Breadcrumbs for deep hierarchies
- Removing dead ends (every page leads somewhere)

### information_density

Am I informed or overwhelmed? Right amount for the task. Requires understanding what data is shown and why.

| Score | Anchor |
|-------|--------|
| 90-100 | Density adapts to context AND user expertise — progressive disclosure that reveals depth on demand, not all at once. Data-heavy views have filtering, sorting, and view-switching (table/card/list). Onboarding is sparse with clear single-action focus. Information architecture respects Miller's number (7±2 items per group). Hick's law applied: fewer choices per decision point, more decision points if needed. Tooltips/popovers for secondary info instead of cluttering the primary view. (Notion databases, Linear filtering, Vercel deployment views) |
| 70-89 | Good density calibration. Most information is relevant. Minor clutter or gaps. |
| 50-69 | Acceptable but not optimized. Some screens too sparse, others too dense. |
| 30-49 | Mismatch between content and purpose. Dashboard that's empty. Settings page that's overwhelming. |
| 0-29 | Hostile density (wall of text) or hostile sparsity (page with one button and no context). |

**What moves this score:**
- Progressive disclosure (show summary, expand for detail)
- Empty states with guidance (not blank pages)
- Density matched to task (data-heavy screens can be dense, onboarding should be sparse)
- Removing information that doesn't serve the current view's purpose
