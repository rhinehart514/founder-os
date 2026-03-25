# Feature Research

**Domain:** Demand-side product thinking tools for solo founders (CLI/AI plugin context)
**Researched:** 2026-03-25
**Confidence:** MEDIUM — table stakes verified against existing JTBD/VPC ecosystem; differentiators assessed against existing skill inventory; anti-features derived from observed failure modes in the codebase

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features a demand-side product thinking tool must have. Missing these = founders return to Notion templates and post-it notes.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Named-customer anchoring | Every JTBD framework starts with "who specifically" — no customer profile = no demand-side work | LOW | Already in `/product` via `product-spec.yml`. Gap: not surfaced as a first-class step in the skill hierarchy |
| Job statement construction | Core JTBD primitive: "When [situation], I want to [motivation], so I can [outcome]" | LOW | Not explicitly in any skill. `/product` touches it implicitly but doesn't produce a structured job statement |
| Assumption enumeration | Founders can't pressure-test what they haven't named. Every serious product framework (Lean, JTBD, VPC) makes assumptions explicit | LOW | In `/discover` via `portfolio.yml` `assumptions:` field. Gap: not surfaced in `/product` output |
| Kill condition before building | Demand-side thinking requires naming what would falsify the hypothesis before investing in it | LOW | In `/decide` and `/discover`. Gap: not integrated into `/product` flow pre-build |
| Functional/emotional/social job dimensions | All three dimensions of a job (practical task, how they want to feel, how they want to be perceived) are table stakes in any JTBD tool | MEDIUM | Not present anywhere in the current skill set. This is the primary gap in the `/blueprint` area |
| Evidence tracking per assumption | Every assumption needs a status: untested / testing / confirmed / disproven | LOW | In `portfolio.yml` `assumptions[].tested` boolean. Gap: binary tested/untested loses the testing-in-progress state |
| Go/kill/pivot verdict with explicit reasoning | Decision gate with structured evidence for/against is expected by any sophisticated founder | MEDIUM | Fully built in `/decide`. Well-executed. |
| Progress-to-value mapping | "How fast does a new user get value?" — first value delivery moment matters for retention | MEDIUM | Touched in `/product user` mode (FIND→UNDERSTAND→TRY→GET VALUE journey). Not a standalone deliverable |

### Differentiators (Competitive Advantage)

Features that distinguish demand-side AI-assisted product thinking from a Notion template or generic PM tool.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Hire/fire switch analysis | Demand-side thinking's core insight: every purchase is a switch. What was fired? What forces drove the switch? This surfaces the real competitor (often inertia, not another product) | HIGH | Not in any current skill. This is the Bob Moesta demand-side contribution that separates JTBD from generic "user research" |
| Four forces mapping | Push (frustration with old), pull (attraction to new), anxiety (fear of change), inertia (habits of present) — the four forces that govern whether someone switches | HIGH | Not present. Differentiator because most product tools only model pull (features/benefits), not the push and inertia that actually govern adoption |
| Outcome vs. feature decomposition | Help founders work top-down: outcome → opportunity → system → feature, not feature-up | MEDIUM | In `/discover` via `references/hierarchy.md`. Gap: not exposed to users as a first-class tool, buried in skill references |
| Kill-first framing as a feature, not a warning | Most PM tools celebrate building. A demand-side tool that leads with "here's why this won't work" before "here's how to build it" is genuinely differentiated for sophisticated founders | LOW | Present in spirit via `/ideate kill`, `/decide`, and dead-end tracking. Gap: the positioning does not lead with this |
| Cross-venture pattern learning | Compounding knowledge across ideas and ventures (not just within one product) using the vault | MEDIUM | Present and validated in v1.0. Differentiator that generic tools can't replicate without long-term usage data |
| Evidence-to-prediction tracking | Logging predictions before acting and grading them afterward — building a calibrated model, not just a knowledge base | MEDIUM | Present in predictions.tsv + experiment-learnings.md. Differentiator if surfaced to users as a feature, not just internal plumbing |
| Coherence auditing (code vs. claims) | For existing products: automatically detect where what you're building diverges from what you claim to be building | MEDIUM | Present in `/strategy coherence` and `/product coherence`. Differentiator in AI-assisted context — no analog in manual frameworks |
| Stage-appropriate advice | Different advice at zero-user vs. 10-user vs. 100-user stages. Generic PM tools give the same advice at all stages | LOW | Present in `/strategy stage` and `/product` modes. Well-executed, should be surfaced as a named capability |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Competitive feature matrix | Founders want to know how they stack up | Encourages feature parity thinking — the opposite of demand-side. Surfaces what competitors have, not what customers need | `/strategy compete` already scopes this to "what would they do if they saw us" — competitive response, not feature checklist |
| Roadmap generation from features | Looks like strategy but isn't | A feature roadmap answers "what will we build" before answering "what job is underserved and by how much" — demand-side thinking requires reversing this order | Use `/decide` to gate commitment, then use GSD for roadmap — demand-side tools produce go/kill/pivot, not Gantt charts |
| Persona building with demographics | Standard PM tool feature, widely expected | Demographics don't predict switching behavior. Personas with age/gender/role are demand-side theater. Real JTBD analysis is situational, not demographic | Name the situation, not the person: "When [X] happens to someone doing [Y]..." — already the approach in `/discover` |
| Survey/feedback aggregation | "Collect more customer data" is intuitive | Surveys capture stated preferences, not actual switching behavior. The demand-side insight (four forces, hire/fire) comes from retrospective interviews about a specific switch decision, not general satisfaction surveys | `/research` should point toward switch interviews, not NPS surveys |
| Automated roadmap prioritization scoring | MoSCoW, RICE, weighted scoring — appears rigorous | Scoring systems create false precision and gameable metrics. Prioritization should be "what unblocks the job?" not "highest RICE score" | `/decide` with explicit reasoning and evidence is more honest than scoring formulas |
| Multi-idea portfolio scoring | Compare all ideas on a unified score | Creates pressure to chase score rather than validate assumptions. The score is only as good as the evidence behind it | Keep ideas in stage-based pipeline (`portfolio.yml`) and use `/decide` at each stage gate, not a unified ranking |

---

## Feature Dependencies

```
[Named customer] ──requires──> [Job statement construction]
                                    └──enables──> [Functional/emotional/social dimensions]
                                    └──enables──> [Assumption enumeration]

[Assumption enumeration]
    └──requires──> [Evidence tracking per assumption]
                       └──enables──> [Kill condition before building]
                       └──enables──> [Go/kill/pivot verdict]

[Hire/fire switch analysis] ──requires──> [Named customer]
                                └──enables──> [Four forces mapping]
                                └──informs──> [Kill condition before building]

[Outcome vs feature decomposition] ──enhances──> [Job statement construction]
[Coherence auditing] ──requires──> [Named customer] + [Assumption enumeration]

[Cross-venture pattern learning] ──enhances──> [Go/kill/pivot verdict]
[Evidence-to-prediction tracking] ──enhances──> [Assumption enumeration]
```

### Dependency Notes

- **Named customer requires job statement construction:** You cannot construct a well-formed JTBD statement without first naming a specific person in a specific situation. Generic customers produce generic jobs.
- **Four forces mapping requires hire/fire switch analysis:** The four forces model (push/pull/anxiety/inertia) only becomes actionable after you understand the specific switch event — what was fired and what was hired.
- **Kill condition requires evidence tracking:** A kill condition stated without a mechanism for tracking evidence against it is decorative. The condition must be checkable.
- **Coherence auditing conflicts with roadmap generation:** You cannot honestly audit "does code match claims?" if you are also auto-generating roadmaps that create new claims. These should be separate phases.

---

## MVP Definition (for v2.0 Demand-Side Repositioning)

This is a subsequent milestone, not a greenfield build. The MVP question is: what features need to be strengthened, clarified, or newly built to make the demand-side thesis real — not just positioned?

### Launch With (v2.0)

- [x] Named-customer anchoring surfaced as mandatory step in skill hierarchy — not buried in references — already built, needs repositioning as first-class entrypoint
- [ ] Job statement construction as explicit output — three dimensions (functional/emotional/social), structured format — new, not built anywhere currently
- [x] Assumption enumeration with evidence tracking — built in `/discover`, needs to propagate to `/product` flow
- [x] Kill condition before building — built in `/decide`, needs integration into skill hierarchy so it precedes `/go`
- [x] Go/kill/pivot verdict — fully built in `/decide`, no changes needed
- [ ] Outcome vs. feature decomposition exposed as a named user-facing tool — currently internal to `/discover` references, needs surface area

### Add After Validation (v1.x / v2.x)

- [ ] Hire/fire switch analysis mode — trigger: users ask "why did they switch?" or "who's the real competitor?" — new feature, HIGH complexity
- [ ] Four forces mapping — trigger: hire/fire analysis is proving useful and users want to understand switching resistance — HIGH complexity, requires the hire/fire primitive first
- [ ] Progress-to-value mapping as a standalone output — trigger: `/product user` mode is being used heavily

### Future Consideration (v3+)

- [ ] Retrospective switch interview guide generation — automated interviewing scripts based on known customer + job + current solution
- [ ] Demand-signal detection from public sources (job listings, Reddit, support forums) to ground job validation without first-person interviews

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Job statement construction (3 dimensions) | HIGH — closes the biggest gap in demand-side toolkit | LOW — prompt restructure in `/product` and `/blueprint` | P1 |
| Outcome vs. feature decomposition (surface-level) | HIGH — stops feature-first thinking | LOW — already in `/discover/references/hierarchy.md`, needs exposure | P1 |
| Named-customer anchoring as mandatory first step | HIGH — repositioning requires this to be first, not optional | LOW — narrative change + skill routing update | P1 |
| Kill condition integrated into skill flow before `/go` | HIGH — demand-side thesis requires kill-first framing | LOW — routing/ordering change only | P1 |
| Assumption enumeration in `/product` flow | MEDIUM — present in `/discover`, missing in `/product` | LOW — add to `/product` output template | P2 |
| Hire/fire switch analysis | HIGH — true demand-side differentiator | HIGH — new skill or major `/product` extension | P2 |
| Four forces mapping | HIGH — surfaces switching resistance, not just features | HIGH — depends on hire/fire primitive | P3 |
| Evidence-to-prediction tracking surfaced as a feature | MEDIUM — differentiator if users know it exists | LOW — already built, needs documentation/positioning | P2 |

**Priority key:**
- P1: Required for v2.0 demand-side repositioning to be credible
- P2: Strengthens thesis, add when P1 is done
- P3: Differentiating but complex, defer until validated

---

## Competitor Feature Analysis

| Feature | Generic PM tools (ProductBoard, Notion templates) | JTBD frameworks (manual) | founder-os current state | founder-os v2.0 target |
|---------|------|------|------|------|
| Named customer | Optional field | Required, situational | Present in `/discover`, optional in `/product` | Required as first step across all demand-side skills |
| Job statement | Not present (persona-based) | Core output (When/Want/So I can) | Not present | New: explicit 3-dimension output |
| Assumption tracking | Feature request boards, not assumptions | Manual sticky notes | `portfolio.yml` structured field | Propagate to `/product` output |
| Kill condition | Not present | Not present (frameworks don't have kill gates) | Present in `/decide` | Integrate into skill flow before `/go` |
| Four forces | Not present | Expert practitioner knowledge | Not present | v3+ consideration |
| Hire/fire analysis | Not present | Taught in JTBD workshops | Not present | P2 new skill or `/product` extension |
| Go/kill/pivot gate | Informal | Not present | Best-in-class in `/decide` | No changes needed |
| Cross-venture learning | Not present | Not present | Present and validated | Surface as differentiator in positioning |

---

## Existing Skill Overlap Assessment

The current set of 5 overlapping demand-side skills (`/discover`, `/product`, `/strategy`, `/ideate`, `/research`) has redundancy that creates user confusion about which to use when:

| Skill | Core job it does | Overlap risk |
|-------|-----------------|--------------|
| `/discover` | Raw idea → structured business case | Overlaps with `/product` on "should I build this?" |
| `/product` | Pressure-test assumptions on an existing idea | Overlaps with `/discover` and `/strategy` |
| `/strategy` | Positioning, timing, competitive response | Overlaps with `/product` on coherence/positioning |
| `/ideate` | Generate ideas, improvement prescriptions | Low overlap — distinct enough in its "WHAT" role |
| `/research` | Gather evidence before deciding | Low overlap — distinct information-gathering role |

**Recommended separation:**
- `/discover` = BEFORE you have a product: idea → business case → commit or kill
- `/product` = AFTER you've committed: pressure-test the existing product hypothesis
- `/strategy` = HOW to compete: positioning, timing, competitive response (not "should this exist")
- This separation is the structural change that makes the demand-side thesis legible

---

## Sources

- [JTBD Framework — ProductSchool](https://productschool.com/blog/product-fundamentals/jtbd-framework)
- [Jobs to Be Done Guide 2026 — GreatQuestion](https://greatquestion.co/blog/jobs-to-be-done)
- [JTBD in UX Research — UserInterviews](https://www.userinterviews.com/ux-research-field-guide-chapter/jobs-to-be-done-jtbd-framework)
- [Value Proposition Canvas — IxDF](https://ixdf.org/literature/topics/value-proposition-canvas)
- [AI for Product Discovery — Pendo](https://www.pendo.io/pendo-blog/the-ultimate-guide-to-using-ai-for-product-discovery/)
- [Keep Kill or Pivot — CoinJar Insights](https://www.coinjarinsights.com/post/keep-kill-or-pivot-a-strategic-guide-to-critical-product-decisions)
- [Demand-Side JTBD — Commoncog](https://commoncog.com/jobs-to-be-done-understand-demand/)
- Existing skill inventory: `/skills/product/SKILL.md`, `/skills/discover/SKILL.md`, `/skills/decide/SKILL.md`, `/skills/strategy/SKILL.md`, `/skills/ideate/SKILL.md`, `/skills/feature/SKILL.md`

---
*Feature research for: demand-side product thinking repositioning — founder-os v2.0*
*Researched: 2026-03-25*
