# Hierarchy Lens

Shared reference for all skills. Read this when operating at any level of the product hierarchy to ensure you're asking the right questions at the right altitude.

## The 6-level stack

```
OUTCOME          What metric or behavior moves if this works?
OPPORTUNITY      What pain, unmet need, or desire makes this worth addressing?
SYSTEM           A coherent product domain with its own data model and ownership.
FEATURE          A discrete, shippable unit with a clear user goal.
MICRO-FEATURE    Behaviors that make a feature feel complete rather than 80% done.
INTERACTION      Atomic UI moments. Invisible until absent.
```

## Per-level question battery

Ask these when operating at each level. Skip levels that aren't relevant to the current task, but always check one level up and one level down from where you're working.

### OUTCOME
- What metric or behavior changes if this succeeds?
- Who cares about that metric? (Name the person, not "stakeholders.")
- How would we know it worked? What's the observable signal?
- What's the timeline — when should the metric move?
- Is this the right metric, or a proxy for the real one?

### OPPORTUNITY
- What pain, unmet need, or desire drives this?
- Is this stable across solutions, or tied to a specific implementation?
- What are the four forces? (push away from current, pull toward new, anxiety about switching, inertia keeping them)
- What's the hire/fire trigger — when do they reach for a solution?
- How do they solve this today without your product?

### SYSTEM
- What data model owns this domain?
- What are the boundaries — what's inside this system, what's outside?
- What other systems does it depend on? What depends on it?
- Can it evolve independently, or is it coupled to something else?
- Is this the right decomposition, or should it merge/split?
- See `skills/shared/system-thinking.md` for the full methodology.

### FEATURE
- What user goal does this serve?
- Can it be scoped, estimated, and shipped independently?
- Which system does it belong to?
- What job (functional/emotional/social) does it fulfill?
- What's the evidence that someone wants this? (Label: observed/stated/market/inferred)

### MICRO-FEATURE
- What behaviors make this feature feel complete vs 80% done?
- What do users expect that's invisible until absent?
- Which of these are missing: empty states, undo/redo, inline validation, smart defaults, keyboard shortcuts, optimistic UI, bulk actions, progressive disclosure?
- Is this polish or is it table stakes for the job?

### INTERACTION
- What's the atomic UI moment?
- What feedback does the user need? (visual, haptic, timing)
- What happens on error? On success? On waiting?
- Is this a UI problem or an inference problem? (Could an LLM handle this with the right context?)
- Examples: button press feedback, skeleton loaders, error copy, hover states, transition timing

## Level detection heuristic

When a user provides input, determine the operating level:

| Signal | Level |
|--------|-------|
| Names a metric, KPI, behavioral outcome | OUTCOME |
| Describes a pain, need, job, or desire | OPPORTUNITY |
| Names a product domain with its own data model (auth, payments, search, notifications) | SYSTEM |
| Names a shippable unit with a user goal | FEATURE |
| Describes a behavior within a feature (empty states, undo, validation) | MICRO-FEATURE |
| Describes an atomic UI moment (button feedback, skeleton loader, transition) | INTERACTION |

When ambiguous, default to FEATURE and note the ambiguity.

## Cross-level nudge

When operating at level N, always check:

- **One level up:** Does the work at this level serve the level above? A feature that doesn't serve an opportunity is orphaned. A system that doesn't enable features is over-engineering.
- **One level down:** Is the level below complete? A feature without its micro-features feels 80% done. An interaction without its feedback feels broken.

This is the reach mechanism — every skill that reads this file naturally looks up and down.

## Per-skill guidance

What each skill should do differently when hierarchy-aware:

### /demand
- **Outcome:** Already anchors here. Verify the outcome metric is named and measurable.
- **Opportunity:** Already strong (JTBD, four forces). Tag jobs by hierarchy level.
- **System:** Identify which system(s) would own new features. Flag cross-system features.
- **Feature:** Already strong (four-lens grid). Group by owning system.
- **Micro-feature:** For top features, name 3+ micro-features. Ask: "What makes this feel complete?"
- **Interaction:** Ask: "What interaction-level expectations exist for this job?"

### /measure
- **Outcome:** Check if the product measurably moves the claimed outcome. Flag unnamed outcomes.
- **Opportunity:** Check if customer pain decreased (requires demand-cache data).
- **System:** Audit system boundaries, coupling, data model coherence. See SYSTEMS mode.
- **Feature:** Already strong (delivery + craft per feature).
- **Micro-feature:** Rate micro-feature completeness as a dimension within feature eval.
- **Interaction:** Already strong (flows audit, visual eval).

### /build
- **Outcome:** Verify the outcome metric is named before building toward it.
- **Opportunity:** Demand gate already asks "who wants this?" — ensure it checks opportunity level.
- **System:** If building system-level work, read system-thinking.md for health checklist.
- **Feature:** Already strong (GO mode, bottleneck diagnosis).
- **Micro-feature:** Already strong (PUSH mode, five-rings).
- **Interaction:** QUICK tasks can be interaction-level. Name the level in task specs.

### /learn
- **Outcome:** Grade outcome-level predictions. Did the metric actually move?
- **Opportunity:** Already strong (AUDIT re-checks four forces, validates jobs).
- **System:** Ask: was this the right system decomposition? Did boundaries hold?
- **Feature:** Already strong (prediction grading per feature).
- **Micro-feature:** Track which micro-features were missing post-launch. Pattern detection.
- **Interaction:** Track interaction-pattern effectiveness. Did the pattern work?

### /ideate
- **Outcome:** Generate at least 1 outcome-level idea per session. "What metric could move differently?"
- **Opportunity:** "What other opportunities exist within this job?"
- **System:** See SYSTEM-IDEATE mode. "Should these systems merge/split/not exist?"
- **Feature:** Already strong (FEATURE-IMPROVE, GENERATE).
- **Micro-feature:** "What 10 ways could we handle this micro-interaction?"
- **Interaction:** "What interaction would make this feel inevitable vs functional?"

### /ship
- **Outcome:** Verify the outcome story is evidence-backed. Copy addresses outcomes, not just features.
- **Opportunity:** Copy speaks to the opportunity (the pain), not just the solution.
- **System:** Tag theses by level. System-level theses need architecture evidence.
- **Feature:** Already strong (release notes, copy per feature).
- **Micro-feature:** Already decent (empty-states copy, onboard copy).
- **Interaction:** Interaction-level polish in release notes signals craft.

### /founder
- **Outcome:** Dashboard shows portfolio at outcome level. Hierarchy coverage widget.
- **Opportunity:** BUNDLE maps features to jobs (opportunity-adjacent). DECIDE checks opportunity strength.
- **System:** BUNDLE includes system map. FEATURE new requires system assignment.
- **Feature:** Already strong (FEATURE mode).
- **Micro-feature:** Surface micro-feature gaps on dashboard when feature scores plateau.
- **Interaction:** Surface interaction-level work in TODO when craft scores are low.
