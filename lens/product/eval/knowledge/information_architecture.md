# Information Architecture

## Patterns (what good looks like)
- **Task-oriented nav**: Linear's nav items are verbs/nouns that match tasks (Issues, Projects, Teams). Not "Dashboard", "Analytics", "Management." HIVE: Make (create), Home (discover), Spaces (engage), You (prove) — four clear jobs.
- **4-5 top-level items is the sweet spot**: Research converges from NNGroup, Smashing Magazine, and cognitive load studies. Instagram uses 5. Discord uses 4 + server switcher. HIVE's 4-tab model sits in optimal range. Miller's 7+/-2 is the theoretical bound but practical UX targets lower.
- **Flat beats deep for social apps**: NNGroup's hospital study: users find content faster in broad/shallow hierarchies. Social/community apps (Discord, Instagram, TikTok) use almost completely flat nav — 1 tap to primary content. Productivity tools (Linear, Figma) tolerate 2-3 levels. HIVE is a hybrid (creation = productivity, consumption = social) but the dominant use case (member engaging) should be 1-tap flat.
- **Content grouping matches mental model, not database**: HIVE's feed sections (Campus Pulse → Live Now → Today → Trending → Activity → Discover) match how a student thinks about "what's happening." Gen Z thinks in moods ("chill cafe for Sunday"), not categories ("Restaurants > Cafes > Open Sundays").
- **Consistent terminology**: Same word for the same thing everywhere. Nielsen's Heuristic #4. HIVE policy: "apps" not "tools" in user-facing copy. NNGroup intranet research: internal/brand-specific labels in nav kills findability. Use "old, well-known words."
- **New features go INTO existing nav, not alongside**: Linear's redesign principle — they explicitly chose NOT to add nav items. Used headers, panels, and view modes within existing destinations. Settings creep kills IA.

## Research-Backed Numbers

### Optimal navigation structure
- Top-level items: 3-5 (mobile bottom bar), 4-7 (desktop sidebar)
- Max depth to primary content: 2-3 levels. At 4+ levels, users drop off (NNGroup)
- Task completion improvement from good IA: +37% (major study cited by UX Booth)
- 61% of websites have navigation-linked usability problems

### Gen Z expectations (HIVE's audience)
- "Mobile-only, not mobile-first" — mobile IS the product, not a secondary experience
- Reduced navigation increases satisfaction by 25% (UX Collective)
- 70% prefer dark mode
- Max 50 words per paragraph, 20 words per sentence on text-heavy surfaces
- Discover through social circles and peer recommendations, not search or hierarchical browsing

### Mobile vs desktop nav
- Hidden nav (hamburger) performs worse on every metric: task difficulty, time, success rate
- Bottom bar: 3-5 items max, both icon AND text label (icons alone unreliable)
- Desktop sidebar can hold more items — room to grow
- Best pattern for >5 destinations: 4-5 on mobile bottom bar, rest in profile/settings submenu

## Anti-Patterns (what bad looks like)
- **Database-mirroring IA**: Navigation reflecting data storage (Users, Organizations, Tools, Placements) rather than user tasks (Build, Find, Engage). Classic enterprise failure.
- **Too many top-level items**: 7+ primary nav items. Working memory overflow. PNC Bank cautionary tale: 194 nav links on homepage.
- **Hidden primary flows**: The most common task requires 3+ taps. If "Create an app" needs menu → create → format → config, too many steps.
- **Inconsistent naming**: HIVE concern — nav labels are "Make/Home/Spaces/You" but routes are `/build/discover/spaces/me`. Label-to-route mismatch. "Home" matchPattern includes `/discover`, `/feed`, `/events` — three URL concepts under one label.
- **Category-based browsing for social content**: A flat alphabetical/categorical list of 600+ spaces is a phone book. Research says surface by activity/relevance/social proof for Gen Z.
- **Orphan pages**: Pages reachable only by direct URL, not from any nav path. 40%+ task failure for new users.
- **Lateral motion between tabs**: Swipe transitions between bottom nav items confuse spatial mental models. Cross-fade is correct.

## HIVE-Specific Notes
- Four surfaces = four jobs. This is the right IA. Don't add a fifth unless it represents a fifth distinct job.
- The "tabs" in spaces were killed before being built (correct) — single stream is better IA for <50 users
- Build page IA: idle → format picker → config editor → preview → deploy. Each step is a distinct phase. Good.
- Notification IA: tapping a notification should deep-link into the specific tool/space, not just the feed
- Profile IA: shows created tools and their performance. This is the "proof" surface. Should not mix discovery features.
- **Tap depth concern**: Home (1 tap) → Spaces list (1 tap) → Specific space (2 taps) → App interaction (3 taps). That 3-tap depth to primary engagement is at the research boundary.
- **Terminology audit needed**: Codebase uses "tools" everywhere (tool-placement.ts, use-space-tools.ts, sidebar-tool-section.tsx) but users must only see "apps." Easy for a "tool" to slip into user-facing copy.
- **Spaces discovery**: If /spaces is a flat list of 600+ orgs, it's a phone book. Should surface by activity/relevance/social proof.
- **Settings creep defense**: As HIVE adds features (analytics, settings, admin, DMs), each lobbies for a tab. Resist — group under existing tabs. Document which tab absorbs each new feature.
- Mobile and desktop nav currently identical (4 items). Fine now, but desktop sidebar has room to grow (6-7 items) while mobile must stay at 4-5.

## Scoring Guide
- **5**: Navigation matches user mental model, not database structure. Primary flows are 1-2 taps. Consistent terminology everywhere. Max 3 levels for any primary task. 4-5 top-level items. Activity-ranked discovery. Users can explain the IA after 5 minutes.
- **4**: Good IA with one or two rough edges. Maybe one nav item ambiguously named, or one flow that's one tap longer than ideal. Terminology consistent on 90%+ of surfaces.
- **3**: Core IA is clear (main surfaces, primary tasks) but secondary areas confusing. Settings, notifications, or deep flows require non-obvious navigation. Some terminology inconsistency. Discovery is category-based, not activity-based.
- **2**: IA mismatch — navigation reflects system structure, not user tasks. Primary flows require 4+ taps. Terminology inconsistent across surfaces. Category-based browsing for social content.
- **1**: No coherent IA. Users must explore to find primary features. Navigation items ambiguous. Deep flows have no back path. Orphan pages.

## Sources
- NNGroup — Flat vs Deep Hierarchy (nngroup.com)
- NNGroup — 10 Usability Heuristics
- Smashing Magazine — Golden Rules of Mobile Navigation Design
- Smashing Magazine — Designing for Gen Z
- Linear — How We Redesigned the UI (linear.app)
- Pencil & Paper — Navigation UX Best Practices
- Fresh Consulting — Flat Navigation Principle
- UX Booth — Rules for Modern Navigation
- Fintech Labs — Navigation UX Choices
