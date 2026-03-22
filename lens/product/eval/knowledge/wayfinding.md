# Wayfinding

## Patterns (what good looks like)
- **Active state clarity**: The current page/section is unambiguously marked. HIVE's sidebar nav uses gold — it should be impossible to not know where you are.
- **Back paths always exist**: Every deep screen has a way back. Vercel: breadcrumbs on deployment pages. Linear: Esc closes panels, back button in browser always works. HIVE drawers: X to close.
- **URL reflects location**: The URL bar tells users where they are. `/s/buffalo-hackers-club` > `/s/bhc` (unreadable slug). Deep links work — sharing a URL takes the recipient to exactly that place.
- **Destination preview**: Before clicking, the user knows where they're going. "View in Space" → goes to the space. "Deploy" → confirms and then shows success. No surprises.
- **Consistent nav position**: The sidebar doesn't rearrange between pages. The bottom bar items stay in the same order on mobile. Cognitive map is stable.

## Anti-Patterns (what bad looks like)
- **Dead ends**: Completing an action and landing on a blank screen with no next step. Common after "Create" actions that don't immediately place the user somewhere useful.
- **Orphaned pages**: Pages that can't be reached from the main nav. HIVE's `/s/[handle]` is reachable from discover feed and direct link but may not be bookmarkable for all users if auth state isn't handled.
- **Lost in depth**: Entering a modal/sheet/drawer and not being able to tell what level you're at. Especially bad in HIVE's SparkleCreateSheet → config editor flow.
- **No confirmation of location**: After signup/login, landing on the feed with no "you're logged in" signal. User wonders if they're actually authenticated.
- **Cross-surface confusion**: When navigating from build to space to profile, the layout shift is jarring enough that users lose their orientation.

## HIVE-Specific Notes
- Core loop: CREATE → PLACE → SHARE → ENGAGE → SEE IMPACT → CREATE AGAIN — each step should clearly signal the next
- After deploy: the success state should name the space the tool landed in and link to it
- Space feed: the scroll position should be maintained when returning from a deep link
- Build page: idle → format picker → config editor → deploy — each phase should make clear what phase the user is in
- Profile page: shows impact of creation — users should be able to navigate from a tool card on their profile back to that tool in its space

## Scoring Guide
- **5**: At every point, the user knows where they are, where they came from, and where they can go. No dead ends. Active states are clear. Deep links work. Back navigation always works.
- **4**: Good wayfinding with one or two minor gaps. Maybe one flow that doesn't make the next step obvious, or one case where the active state is slightly unclear.
- **3**: Core navigation is clear but some sub-flows have dead ends or unclear next steps. The main surfaces are navigable, but creation and completion flows sometimes leave users stranded.
- **2**: Multiple dead ends or unclear active states. Users can get lost in normal usage. Some major flows don't communicate next steps.
- **1**: No wayfinding. Active states missing. Completing actions leaves users on blank screens. Back navigation breaks. URLs don't reflect location.
