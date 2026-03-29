# /ideate Reference — Output Templates

Loaded on demand. Protocol and routing are in SKILL.md.

---

## Product-level ideation

```
◆ ideate

  v8.0: **43%** · product: **64%** · bottleneck: **learning** (building, w:4, c:40)
  thesis: "Someone who isn't us can complete a loop without help"
  unproven: first-go · return

▾ ideas

  ▸ **Guided onboarding flow** — from wrong prediction
    evidence: prediction "users will find /plan naturally" was wrong.
    Cross-recommendations exist but new users don't know to start with /plan.
    what: After /onboard completes, show a 3-step guide: "1. /plan to see
    what needs work → 2. /go to build it → 3. /eval to measure." Not a
    tutorial — a signpost. One screen, three commands, done.
    who: stranger who just ran /onboard and sees a score but doesn't know
    what to do next.
    changes: delivery_score on commands +10, directly proves "reach-plan" evidence
    costs: 1 session. Defers learning feature work.
    kills it: users skip guidance and explore on their own anyway
    draft assertions:
      - commands: /onboard output includes next-step guidance
      - commands: /plan is reachable within 2 commands of /onboard

  ▸ **Mechanical prediction grading** — from sub-score gap
    evidence: learning craft_score is 40 (lowest across all features).
    Known Pattern: "prediction grading is manual, breaks the learning loop."
    16 predictions, only 10 graded.
    what: `bin/grade.sh` reads predictions.tsv, matches against eval-cache
    scores and git log, fills in result/correct for directional claims
    automatically. Runs on session start.
    who: the learning system itself — compounds across sessions.
    changes: learning craft_score 40→55+, directly proves "first-go" evidence
    costs: 1 session. Requires touching session_start hook (Known fragile).
    kills it: predictions too vague to grade mechanically
    draft assertions:
      - learning: grade.sh fills result column for >50% of predictions
      - learning: grading accuracy matches human judgment >80%

  ▸ **Steal: Linear's project updates pattern** — from market
    evidence: WebSearch shows Linear auto-generates project status from
    completed issues. founder-os has all the data (/go sessions, eval deltas,
    todo completion) but no auto-generated status update.
    what: `/founder` auto-generates a 3-sentence project update from the last
    session's data: what was built, what improved, what's next. Copyable
    for Slack/Discord/standup.
    who: founder who needs to tell someone what happened this week.
    changes: commands delivery_score +5, new capability for /founder
    costs: small — extends existing dashboard, doesn't block anything
    kills it: founders don't share status updates with anyone (solo = no audience)
    draft assertions:
      - founder: /founder output includes a copyable status update

▾ kill list

  ✗ **defer self-diagnostic feature** (w:2, working)
    reason: self-diagnostic doesn't advance the v8.0 thesis. It's working
    and stable. Every session spent on it is a session not spent on learning
    (w:4, building) or proving first-go.
    action: keep as-is, remove from active work, revisit in v9.0

  ✗ **kill todo [xx-09] "redesign dashboard layout"** (32 days stale)
    reason: dashboard works. This is polish on a non-bottleneck feature.

  ✗ **remove assertion "score-has-history"** (always passes, low signal)
    reason: history.tsv has existed since v7.0. This assertion will never
    fail and teaches nothing.

Which ideas to commit? Which kills to confirm? (pick numbers or "all")
```

## Feature improvement mode (`/ideate [feature]`)

```
◆ ideate — dashboard

  dashboard: 58/100 (d:62 c:50) — weakest: **craft 50**
  taste: 48/100 — weak dims: hierarchy 42, breathing_room 38, distinctiveness 35
  flows: 2 major issues (empty state blank, dead end after export)
  backlog: 4 todos tagged to dashboard
  reference products: Linear (project views), Notion (dashboards), Vercel (deploy overview)

▾ improvements (highest leverage first)

  ▸ **Add video/media preview grid above data table** — main dashboard view
    see: The dashboard opens to a flat data table with 12 columns. No visual
    hierarchy — every row looks identical. Users scan linearly instead of
    finding what matters.
    problem: hierarchy 42 (taste), distinctiveness 35 — "this could be any
    admin panel." Users can't distinguish important items at a glance.
    rx: Add a 3-column preview grid above the table showing the 3 most recent
        items with thumbnail, title, and status badge.
        Option 1: static thumbnails with lazy load — hierarchy +10pts, 2hrs
        Option 2: hover-to-preview with video playback — hierarchy +15pts,
        distinctiveness +12pts, 1 session
    reference: Vercel shows deploy previews with screenshot thumbnails.
    Loom shows video grid with hover-to-play. The visual preview pattern
    turns a data table into a product surface.
    impact: craft 50→62, hierarchy +10-15pts, distinctiveness +8-12pts
    cost: Option 1: 2 hours (new PreviewGrid component). Option 2: 1 session
    (video player + thumbnail generation).
    builds on: todo [db-07] "dashboard feels generic"

  ▸ **Replace blank empty state with guided first-run** — /dashboard (0 items)
    see: New user with zero data sees an empty table with column headers
    and nothing else. No explanation of what goes here or what to do.
    problem: flows audit: "MAJOR — empty state shows blank." delivery 62
    but first-time experience is broken. User bounces before creating value.
    rx: Replace blank state with a card containing:
        1. One sentence explaining what the dashboard tracks
        2. A screenshot/illustration of a populated dashboard
        3. A primary CTA: "Create your first [item]"
        Option 1: simple card component — delivery +5pts, 1hr
        Option 2: interactive walkthrough that creates a sample item —
        delivery +10pts, craft +5pts, half session
    reference: Linear shows "No issues yet" with a friendly illustration
    and "Create issue" button. Notion shows template gallery. The pattern
    is: show what success looks like, then offer the action.
    impact: delivery 62→70, fixes "empty state" flow issue
    cost: Option 1: 1 hour. Option 2: half session.
    builds on: flows audit 2026-03-18, UX checklist item #2 (empty states)

  ▸ **Add contextual sidebar with activity feed** — dashboard navigation
    see: After viewing an item, user clicks back and loses context. No
    way to see recent activity, no breadcrumb trail, no sense of momentum.
    problem: craft 50 — "functional and forgettable." breathing_room 38 —
    the layout is a single column with no spatial organization. Dead end
    after export action (flows issue).
    rx: Add a collapsible right sidebar showing:
        - Recent activity (last 5 actions)
        - Quick stats (items this week, completion %)
        - Contextual next action based on current state
        Option 1: always-visible sidebar — breathing_room +8pts, wayfinding +6pts
        Option 2: slide-in panel triggered by activity icon — breathing_room +5pts,
        less layout disruption
    reference: Linear's sidebar shows project activity + quick filters.
    GitHub's sidebar shows repo stats + recent pushes. Activity feeds
    create return triggers (UX checklist #10).
    impact: craft 50→60, fixes dead-end flow issue, creates return trigger
    cost: 1 session — new ActivitySidebar component + data aggregation
    builds on: todo [db-12] "add activity tracking", taste rx from 03-15

▾ simplify (what to remove or reduce)

  ✗ **Remove 4 low-value table columns** (status, updated, category, source)
    see: 12 columns in the data table. 4 of them have identical values across
    >80% of rows. They add visual noise without information.
    action: hide behind a "columns" dropdown — reduce default to 8 columns.
    impact: breathing_room +5pts, information_density improves

  ✗ **Kill advanced filter panel**
    see: 6-field filter panel that nobody uses (0 backlog items reference it,
    no assertions test it). Simplify to a single search bar.
    action: replace with command-palette search (faster, less UI surface)

Which improvements to build? Which simplifications to confirm? (pick numbers or "all")

/go dashboard         build the top improvement
/taste <url>          re-evaluate after changes
/eval dashboard       verify sub-score movement
```

## System-ideate mode (`/ideate system [name]`)

```
◆ ideate system — measurement

  systems detected: measurement (4 features), discovery (3 features),
  execution (2 features), learning (1 feature)

  measurement system: scoring + evaluation + taste + assertions
  boundary: owns eval-cache.json, score-cache.json, beliefs.yml
  coupling: evaluation reads demand-cache.json (discovery system)
  health: 3/5 — boundary mostly intact, one coupling point

▾ system-level ideas

  ▸ **Merge scoring + evaluation into one system** — from coupling
    evidence: scoring and evaluation always change together. 80% of
    commits that touch eval-cache also touch score-cache. They share
    the same data model (per-feature scores with sub-dimensions).
    boundary change: single "measurement" system with one cache file
    instead of two. Simpler state, fewer staleness bugs.
    affects: scoring feature, evaluation feature, /measure unified mode
    impact: reduces state management complexity, eliminates cache
    staleness bugs between score-cache and eval-cache
    kills it: scoring needs 5-min cache while eval needs 24h cache —
    different freshness requirements may justify separation
    hierarchy level: SYSTEM

  ▸ **Extract "evidence" as its own system** — from pattern
    evidence: evidence classification ([observed/stated/market/inferred])
    is used by demand, measure, learn, and ideate. Currently scattered
    across demand-cache.json, eval-cache.json, and predictions.tsv.
    No single owner.
    boundary change: new "evidence" system owns all evidence metadata.
    Other systems reference evidence IDs instead of duplicating labels.
    affects: demand, measure, learn — all skills that label evidence
    impact: single source of truth for evidence freshness and class
    kills it: overhead of indirection may exceed benefit for a small product
    hierarchy level: SYSTEM

  ▸ **Kill the learning system boundary** — from over-decomposition
    evidence: learning has 1 feature (learning) with craft_score 40.
    It's the weakest system by far. Its data (predictions.tsv,
    experiment-learnings.md) is consumed by every other system.
    boundary change: dissolve learning into measurement (predictions
    are measurement of accuracy) and discovery (learnings inform
    demand research).
    affects: /learn skill, prediction grading, experiment-learnings.md
    impact: simplifies architecture, removes the weakest system
    kills it: learning has a distinct lifecycle (grade → consolidate →
    prune) that doesn't fit measurement or discovery rhythms
    hierarchy level: SYSTEM

▾ kill list

  ✗ **Kill separate score-cache and eval-cache**
    reason: two caches for the same domain creates staleness bugs.
    One system, one cache.

Which ideas to commit? Which kills to confirm?

/measure systems        audit all system boundaries
/founder bundle         see jobs-to-features-to-systems map
/demand features        re-run feature grid grouped by system
```

## Wild mode

```
◆ ideate wild

  3 high-conviction bets. Not experiments — committed directions.

  ▸ **Kill the CLI entirely**
    evidence: Known Pattern — "commands are the product, CLI is the wrapper."
    Founder said "transform from CLI to within Claude Code." Plugin mode
    already works. The CLI is legacy.
    what: Remove bin/ scripts as user-facing tools. Everything is a slash
    command. Score, eval, taste — all /eval, not founder eval. The CLI
    becomes an internal build tool only.
    who: every Claude Code user — zero install friction
    burns: CI/script integration. External tooling that calls founder directly.
    draft assertions:
      - all user-facing operations work via slash commands
      - no README references bin/ scripts as user commands

  ▸ **Agent-native architecture**
    evidence: /go beta showed speculative branching produces better outcomes.
    Claude Code agent teams are designed for this. Nobody else ships
    autonomous multi-agent product development.
    what: Every /go session spawns a team — builder, measurer, reviewer
    working in parallel. Not sequential. The founder watches, not directs.
    burns: single-agent simplicity. Debug complexity. Token cost 5x.

  ▸ **Plugin marketplace — be the platform**
    evidence: .claude-plugin format works. Skills are portable. No other
    Claude Code plugin has a measurement layer. Be the App Store, not an app.
    what: founder-os becomes the distribution layer for Claude Code skills.
    Other developers publish skills. founder-os handles measurement, scoring,
    quality gates. `/skill install` becomes the npm of Claude Code.
    burns: focus. Building a platform before the product is proven for one user.

Which direction? (These are irreversible — pick carefully)
```

## Formatting rules

- Header: `◆ ideate — [scope]`
- State bar: version completion + product completion + bottleneck with sub-score
- Ideas: `▸ **[Name]** — [evidence source]` (not quadrant labels)
- Brief fields: evidence/what/who/changes/costs/kills it/draft assertions
- `evidence:` is FIRST — every idea leads with why, not what
- Kill list: `✗ **[what to kill]**` with reason and action
- Kill list is mandatory — at least one kill per session
- AskUserQuestion at end — founder picks commits and kills
- Bottom: 2-3 relevant next commands
