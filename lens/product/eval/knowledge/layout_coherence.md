# Layout Coherence

## Patterns (what good looks like)
- **Consistent grid**: Apple's layout is the same grid on every product page — content column, max-width, centered. The page isn't reinvented for each section. HIVE: 200px sidebar + fluid content on desktop, 56px bottom bar on mobile.
- **Surface-to-surface continuity**: Moving from the feed to a space to a profile feels like the same product. The sidebar is in the same place. The header height is consistent. Typography rules apply everywhere.
- **Predictable content width**: Long-form content (feed) at max 640px, profiles at 960px, full-width for space streams. When you know the rule, every surface makes sense.
- **Intentional breaks as emphasis**: One place per surface where the layout breaks (bleeds edge-to-edge, or a hero element spans the full width). This signals authorship. But it's ONE break, not many.
- **Component behavior consistency**: A card that expands inline on the feed also expands inline in a search result. Same behavior, different context. No surprises.

## Anti-Patterns (what bad looks like)
- **Surface-to-surface layout drift**: The feed is centered at 600px, the profile is left-aligned at full width, the space is centered at 800px. No consistent layout system.
- **Sidebar that disappears**: Layout with sidebar on some pages, full-bleed on others, for no clear reason. The cognitive map keeps resetting.
- **Inconsistent content width**: Reading content that jumps from 500px to 800px to full-width as you navigate. Exhausting.
- **Hero inflation**: Multiple elements per surface that try to be full-bleed heroes. One landing strip, one "create" CTA, one alert banner — all full-width, all competing. No hierarchy in the layout itself.
- **Misaligned breakpoints**: Mobile layout at 390px doesn't derive from the desktop layout. Different component choices, different nav. Feels like two separate products.

## HIVE-Specific Notes
- Defined layout: sidebar (200px) + content = the rule. Check that it's consistently applied across all surfaces
- Feed: max-width 640px centered — verify this is consistent across feed sections
- Space stream: full-width is the correct choice (matches "social stream" mental model)
- Profile: 960px bento grid — the bento tile spans should be intentional, not arbitrary
- Mobile: full-width + bottom bar — check that the bottom bar items are the same across all surfaces

## Scoring Guide
- **5**: Every surface feels like it belongs to the same product. Consistent grid, consistent sidebar, consistent content widths. Intentional full-bleed breaks are clearly intentional. Mobile and desktop layouts are clearly related.
- **4**: Coherent layout with one or two surfaces that slightly deviate. Maybe one page is too wide, or one mobile surface doesn't quite match the desktop version.
- **3**: Some coherence, some drift. The main surfaces (feed, space) feel consistent. Secondary surfaces (settings, profile, build) feel less intentional.
- **2**: Layout changes significantly between surfaces. The grid isn't consistent. Sidebar appears and disappears. Content width varies widely with no system.
- **1**: No layout system. Every surface was designed independently. The product doesn't feel like a product — it feels like a collection of pages.
