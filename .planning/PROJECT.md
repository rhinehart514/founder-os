# founder-os

## What This Is

A Claude Code plugin that gives solo founders an AI cofounder focused on demand-side product thinking — figuring out what's worth building before building it. JTBD mapping, value prop design, feature architecture, go/kill decisions. Build and measurement serve that thinking, not the other way around.

## Core Value

Help founders figure out what to build (and what to kill) faster than they could alone — grounded in evidence, not encouragement.

## Current Milestone: v2.0 Demand-Side Product Thinking

**Goal:** Reposition founder-os around demand-side product thinking as the core thesis. Restructure skills so demand-side thinking is primary, build is secondary, measurement is tertiary.

**Target features:**
- Reposition product narrative (README, onboarding, quick start) to lead with demand-side thinking
- Restructure skill hierarchy: demand-side as primary, build as secondary, measurement as tertiary
- Strengthen/consolidate demand-side skills (JTBD mapping, value props, feature architecture, go/kill)
- Ensure build and measurement skills clearly serve the demand-side thesis

## Requirements

### Validated

- ✓ Full lifecycle loop works: discover → decide → go → score (v1.0)
- ✓ Cross-venture knowledge compounding via Obsidian vault (v1.0)
- ✓ Measurement pipeline: /score, /eval, /taste (v1.0)
- ✓ Autonomous build loop: /go with score-gated commits (v1.0)
- ✓ GSD execution engine integration (v1.0)

### Active

- [ ] Product narrative leads with demand-side thinking
- [ ] Skill hierarchy reflects demand > build > measure
- [ ] Demand-side skills are coherent and non-overlapping
- [ ] Build and measurement skills frame as serving demand-side thesis

### Out of Scope

- Full rewrite of measurement skills — they work, just need repositioning
- New execution/build skills — the GSD engine is sufficient
- Plugin marketplace mechanics — distribution is fine as-is

## Context

- 34 skills, 32 agents, 152 shell scripts — prompt orchestration, not application code
- Current positioning leads with measurement loops ("score, bottleneck, build, measure again")
- 5 skills overlap in "should I build this?" space: /discover, /product, /strategy, /ideate, /research
- The blueprint skill (JTBD, value props, feature architecture) captures the core job but isn't integrated
- README quick start shows /score and /go before any demand-side commands
- Value hypothesis in founder.yml centers on "measurably better every session" — measurement-first framing

## Constraints

- **Platform**: Claude Code plugin — all "code" is markdown prompts and shell scripts
- **Distribution**: Plugin marketplace — install path can't change
- **Backward compat**: Existing users have /score, /go, /eval muscle memory — don't break commands, reframe them

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Positioning AND restructuring, not just positioning | Thesis change without structural change is just a new README | — Pending |
| v2.0 not v1.1 | This is a thesis change, not an incremental feature | — Pending |
| Demand > Build > Measure hierarchy | The job is "figure out what to build" not "measure what you built" | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-25 after milestone v2.0 started*
