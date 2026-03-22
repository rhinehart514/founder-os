# Scroll Experience

## Patterns (what good looks like)
- **Anchored entry points**: The most important content is above the fold. Users see value before they scroll. On HIVE's feed: Campus Pulse strip at top shows live data before the scroll begins.
- **Rhythm in vertical flow**: Content sections have consistent spacing. Reading down the page has a beat — content, gap, content, gap. Not uneven. Linear's issue list: every row is exactly 36px, gaps between groups exactly 24px.
- **Progressive revelation**: Scrolling reveals more of the same type of content, not surprises. HIVE's feed: sections get older as you scroll down (Live Now → Today → Trending). The user knows what's coming.
- **Sticky helpers**: Page-level sticky elements (header, nav) help maintain orientation during scroll. But sticky elements should be minimal — only what earns the space.
- **Scroll performance**: No janky scroll. No layout shifts. Images don't pop in. This is especially important for a feed-based product.

## Anti-Patterns (what bad looks like)
- **Infinite scroll without feedback**: Users scroll forever without knowing if there's more content. No loading indicator, no "you've reached the end" state.
- **Scroll-triggered layout shifts**: Images loading in, ads appearing, sticky headers changing size — all of these cause content to jump during scroll.
- **Critical content below the fold**: The most important information (the creator tool, the call to action, the primary value) is hidden until the user scrolls. Users who don't scroll miss it.
- **Scroll amnesia**: Navigating away and back resets scroll position. Common in SPAs without scroll restoration. Frustrating on long feeds.
- **Horizontal scroll on mobile**: Any content that requires horizontal scrolling on mobile (excluding carousels with clear affordances) is a scroll failure.

## HIVE-Specific Notes
- The feed is the primary scroll surface — scroll performance matters here more than anywhere else
- "Since you left" divider: this should appear at the right scroll position (top of new content), not require scrolling to find
- Space stream: single chronological feed means the user scrolls to go back in time — label this clearly
- Build page: mostly vertical flow (format picker, config), minimal scroll — less critical than feed
- Mobile: 56px bottom nav eats into viewport — content area is smaller, scroll starts sooner

## Scoring Guide
- **5**: Scroll feels natural and fluid. Critical content is above fold. Rhythm is consistent. Scroll position is preserved on back navigation. No layout shifts. End-of-content is signaled.
- **4**: Good scroll experience with one minor issue (maybe slight layout shift on image load, or scroll position not always preserved).
- **3**: Functional but imperfect. Either critical content is slightly below fold, or scroll position resets occasionally, or the rhythm is uneven in parts.
- **2**: Multiple scroll frustrations. Important content hidden below fold. Layout shifts on load. No end-of-content signal. Horizontal scroll on mobile.
- **1**: Scroll experience actively harms usage. Severe layout shifts. Critical actions only available after scrolling. Scroll position never preserved. Horizontal overflow on mobile.
