# Requirements: founder-os

**Defined:** 2026-03-25
**Core Value:** Help founders figure out what to build (and what to kill) faster than they could alone

## v2.0 Requirements

Requirements for demand-side product thinking repositioning. Each maps to roadmap phases.

### Demand-Side Foundation

- [x] **DEMAND-01**: Skill routing disambiguation — each demand skill (/discover, /product, /strategy, /ideate, /research) has a non-overlapping job description and clear "use this when" trigger
- [x] **DEMAND-02**: config/founder.yml value hypothesis updated from measurement-first to demand-side thinking
- [x] **DEMAND-03**: mind/identity.md, mind/standards.md, mind/thinking.md updated to reflect demand-side thesis
- [x] **DEMAND-04**: Outcome hierarchy (outcome → opportunity → system → feature) surfaced as user-facing concept, not buried in /discover references
- [x] **DEMAND-05**: Three-dimension job statement construction (functional/emotional/social) added as a demand-side primitive
- [x] **DEMAND-06**: Evidence class labeling on all demand-side skill outputs (verified external / vault / LLM inference)
- [x] **DEMAND-07**: /blueprint skill integrated into founder-os skill set (currently global at ~/.claude/skills/blueprint/)

### Narrative & Onboarding

- [x] **NARR-01**: README.md rewritten to lead with demand-side thinking — JTBD, value props, feature architecture as the headline
- [x] **NARR-02**: Quick-start shows demand-side flow first (/discover, /blueprint, /decide) before build/measure commands
- [x] **NARR-03**: /onboard skill introduces demand-side thinking before measurement pipeline
- [x] **NARR-04**: All skills comply with Anthropic skill best practices (<500 lines SKILL.md, progressive disclosure, trigger-inclusive descriptions)

### Measurement Reframing

- [x] **MEAS-01**: /score, /eval, /taste descriptions and framing updated to position as demand-decision validation
- [x] **MEAS-02**: Kill conditions integrated into flow before /go — building requires passing a demand check
- [x] **MEAS-03**: /retro framed as demand-side learning (did the JTBD thesis hold up?) not just prediction grading

### Advanced Demand Features

- [x] **ADV-01**: Four forces mapping (push/pull/anxiety/inertia) available as a demand-side tool
- [x] **ADV-02**: Hire/fire switch analysis — when do customers hire vs fire the product

---

## v2.0.1 Requirements

Wiring the demand infrastructure into the actual product loop. v2.0 changed what we say — v2.0.1 makes the system actually behave differently.

### Demand Plumbing

- [ ] **PIPE-01**: `/feature bundle` mode — maps existing features to customer jobs, identifies merge candidates (same job), kill candidates (no job), and gaps (job with no feature)
- [ ] **PIPE-02**: Blueprint → founder.yml pipeline — `/blueprint` outputs auto-wire into founder.yml feature definitions (jobs, evidence, hierarchy tier)
- [ ] **PIPE-03**: Job statement fields in portfolio.yml schema — `functional_job`, `emotional_job`, `social_job` fields per idea, populated by /discover
- [ ] **PIPE-04**: `/discover` → `/blueprint` handoff — discover business case passes context to blueprint automatically, no re-entering the idea
- [ ] **PIPE-05**: Cross-skill job tracing — given a feature name, trace back to which customer job it serves and what evidence supports it

### Evidence Enforcement

- [ ] **EVID-01**: Evidence class enforcement — `/eval` or `/assert` mode that flags demand claims with no evidence class label
- [ ] **EVID-02**: Evidence quality stats in `/retro` — report % observed vs stated vs market vs inferred across all demand outputs
- [ ] **EVID-03**: Evidence staleness — flag [market] evidence older than 30 days, [stated] evidence older than 90 days

### Demand-Aware Measurement

- [ ] **DMEAS-01**: Demand tier in `/score` — actual scoring dimension for demand validation (jobs mapped? forces analyzed? evidence exists?) alongside health/delivery/craft/visual/viability
- [ ] **DMEAS-02**: `/plan` demand-aware bottleneck — bottleneck detection considers demand validation gaps, not just score gaps. Feature with no job statement ranks as bottleneck regardless of score.
- [ ] **DMEAS-03**: `/go` demand gate in `/quick` — quick skill currently bypasses /go's demand gate. Add the same soft gate.
- [ ] **DMEAS-04**: Four forces in `/retro` — re-run four forces analysis during audit to detect if push/pull/anxiety/inertia shifted since last check

### Demand Intelligence

- [ ] **DINT-01**: Demand evidence dashboard in `/founder` — show demand status per idea (jobs mapped? forces analyzed? evidence classes? hire/fire identified?)
- [ ] **DINT-02**: `/calibrate demand` — calibrate eval weights against what customers actually said matters (stated importance), not just founder preference
- [ ] **DINT-03**: Job pattern compounding — when a job is killed in one venture, the pattern (job type + why it failed) propagates to experiment-learnings.md for cross-venture learning

### Housekeeping

- [ ] **HOUSE-01**: TOC insertion for 19 reference files >100 lines (deferred from v2.0 Phase 3)
- [ ] **HOUSE-02**: v2.0 traceability table updated to Complete
- [ ] **HOUSE-03**: Update /flow skill to reference demand gate and evidence classes

## Future Requirements (v2.1+)

### Cross-Venture Demand Intelligence
- **XVENT-01**: JTBD patterns compound across ventures (kill a job in one project, pattern applies to next)
- **XVENT-02**: Value prop templates learned from successful ventures auto-suggested for new ideas
- **XVENT-03**: Kano classification integrated into feature lifecycle

### Demand Validation
- **VALID-01**: Switch interview script generation tied to specific JTBD findings
- **VALID-02**: Opportunity scoring with Ulwick formula when survey data available
- **VALID-03**: Customer language extraction from live forums/reviews feeds into value props

## Out of Scope

| Feature | Reason |
|---------|--------|
| Rewrite measurement skills from scratch | They work — just need purpose framing (done in v2.0) |
| New execution/build skills | GSD engine is sufficient |
| Plugin marketplace mechanics | Distribution is fine as-is |
| Survey infrastructure | Founders do interviews, not surveys at this stage |
| Directory restructuring / file moves | Would break install paths; hierarchy expressed through routing, not folders |

## Traceability

### v2.0 (Complete — shipped 2026-03-25)

| Requirement | Phase | Status |
|-------------|-------|--------|
| DEMAND-01 | Phase 1 | ✅ Complete |
| DEMAND-02 | Phase 1 | ✅ Complete |
| DEMAND-03 | Phase 1 | ✅ Complete |
| DEMAND-04 | Phase 1 | ✅ Complete |
| DEMAND-05 | Phase 2 | ✅ Complete |
| DEMAND-06 | Phase 2 | ✅ Complete |
| DEMAND-07 | Phase 2 | ✅ Complete |
| NARR-01 | Phase 3 | ✅ Complete |
| NARR-02 | Phase 3 | ✅ Complete |
| NARR-03 | Phase 3 | ✅ Complete |
| NARR-04 | Phase 3 | ✅ Complete |
| MEAS-01 | Phase 4 | ✅ Complete |
| MEAS-02 | Phase 4 | ✅ Complete |
| MEAS-03 | Phase 4 | ✅ Complete |
| ADV-01 | Phase 5 | ✅ Complete |
| ADV-02 | Phase 5 | ✅ Complete |

### v2.0.1 (Pending)

| Requirement | Category | Status |
|-------------|----------|--------|
| PIPE-01 | Demand Plumbing | Pending |
| PIPE-02 | Demand Plumbing | Pending |
| PIPE-03 | Demand Plumbing | Pending |
| PIPE-04 | Demand Plumbing | Pending |
| PIPE-05 | Demand Plumbing | Pending |
| EVID-01 | Evidence Enforcement | Pending |
| EVID-02 | Evidence Enforcement | Pending |
| EVID-03 | Evidence Enforcement | Pending |
| DMEAS-01 | Demand-Aware Measurement | Pending |
| DMEAS-02 | Demand-Aware Measurement | Pending |
| DMEAS-03 | Demand-Aware Measurement | Pending |
| DMEAS-04 | Demand-Aware Measurement | Pending |
| DINT-01 | Demand Intelligence | Pending |
| DINT-02 | Demand Intelligence | Pending |
| DINT-03 | Demand Intelligence | Pending |
| HOUSE-01 | Housekeeping | Pending |
| HOUSE-02 | Housekeeping | Pending |
| HOUSE-03 | Housekeeping | Pending |

**Coverage:**
- v2.0: 16/16 complete ✅
- v2.0.1: 18 requirements defined, 0 mapped to phases
- v2.1+: 6 future requirements parked

---
*Requirements defined: 2026-03-25*
*Last updated: 2026-03-25 — v2.0 shipped, v2.0.1 requirements added*
