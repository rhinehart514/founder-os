# Project Research Summary

**Project:** founder-os v2.0 — Demand-Side Repositioning
**Domain:** Prompt-based AI plugin / Claude Code extension — demand-side product thinking for solo founders
**Researched:** 2026-03-25
**Confidence:** HIGH

## Executive Summary

founder-os v2.0 is a repositioning of an existing Claude Code plugin from a measurement-first tool ("get from idea to measurably better every session") to a demand-side thinking tool ("figure out what to build and kill what isn't working before executing the wrong thing"). The product is built entirely in markdown + shell — no traditional software stack. The "stack" is a set of canonical frameworks: Christensen/Moesta JTBD for demand discovery, Osterwalder's Value Proposition Canvas for structuring jobs/pains/gains, Kano Model for feature classification, and Cooper's Stage-Gate for go/kill decisions. All are well-documented canonical sources with HIGH confidence.

The recommended approach is structural-first, narrative-second. The single most consistent finding across all four research files is that a thesis change that only touches the README will fail: the quick-start commands, config/founder.yml value hypothesis, and skill routing logic must change before the narrative does. The 34 existing skills are organized into three layers (Demand, Build, Measure) but currently five demand-side skills overlap in ways that create routing ambiguity. The restructuring work is primarily routing disambiguation and cross-reference stitching — not new skill creation. Two new features are genuinely missing: explicit three-dimension job statement construction (functional/emotional/social), and hire/fire switch analysis (the Moesta differentiator that surfaces the real competitor — often inertia, not another product).

The key risk is well-named in the project's own dead-end log: "Research without user validation — competitive analysis is not user validation." The parallel risk for this repositioning is that LLM-generated demand analysis gets presented as grounded evidence. Every demand-side skill output must distinguish between verified external evidence (URLs), vault-backed learnings, and LLM synthesis. Backward compatibility is a hard constraint: existing users have /score and /go muscle memory. Repositioning must be additive to those commands, not substitutional. Recovery from a backward-compat break is rated HIGH cost.

## Key Findings

### Recommended Stack (Frameworks)

This product is prompt-based — there is no software stack in the traditional sense. The "stack" is the canonical frameworks that demand-side product thinking must encode. All are HIGH confidence sources with direct citation to original authors.

**Core frameworks:**
- **Christensen/Moesta JTBD (Four Forces + Switch Interview)** — demand discovery method — the struggling moment is the unit of analysis; switch interviews reconstruct the purchase timeline to surface push/pull/anxiety/inertia forces
- **Ulwick Opportunity Scoring (ODI)** — prioritization formula — Importance + max(0, Importance - Satisfaction); scores above 12 are underserved; best for post-product customer surveys
- **Klement Job Story format** — output artifact — "When [struggling moment], I want to [motivation], so I can [outcome]"; the "When" is load-bearing; without it the story has no predictive power
- **Osterwalder Value Proposition Canvas** — structure tool — maps customer jobs/pains/gains against pain relievers/gain creators; fit condition is addressing 50-70% of highest-ranked pains and gains
- **Kano Model** — feature classification — Must-Be / Performance / Delighter; categories degrade over time; Must-Bes are table stakes (never a differentiator), Delighters are the wedge
- **Torres Opportunity Solution Tree** — discovery discipline — never jump from outcome to solution; map through customer opportunities first; prevents supply-side product thinking
- **Cooper Stage-Gate (startup-adapted)** — go/kill criteria — pre-commit kill conditions before each gate; standard outcomes: Go / Kill / Hold / Recycle
- **Ellis/Vohra 40% Rule** — PMF signal — 40%+ "very disappointed" = PMF signal; requires existing users; pre-product, use switch interviews instead

**Framework decision matrix:** Pre-product → Moesta switch interviews; have customers + want to find opportunities → Ulwick opportunity scoring; writing requirements → Klement job stories; classifying features → Kano; choosing what to ship → RICE (with data) / ICE (without); go/kill → Stage-Gate + 40% rule.

Full detail: `.planning/research/STACK.md`

### Expected Features

The v2.0 milestone is a repositioning of an existing product, not a greenfield build. The MVP question is which features need to be strengthened, clarified, or newly built — not what to create from scratch.

**Must have (table stakes for demand-side thesis to be credible):**
- Named-customer anchoring as a mandatory first step — currently present in /discover, optional elsewhere; must become required across demand-side skills
- Job statement construction with three explicit dimensions (functional/emotional/social) — not present anywhere in the current skill set; this is the primary gap
- Assumption enumeration in /product flow — present in /discover via portfolio.yml, missing in /product
- Kill condition integrated into skill flow before /go — present in /decide, not connected to pre-build entry point
- Outcome vs. feature decomposition exposed as a named user-facing tool — exists in /discover/references/hierarchy.md, buried; needs surface area

**Should have (strengthen the demand-side differentiator):**
- Hire/fire switch analysis mode — the Moesta contribution that surfaces the real competitor; not in any current skill; HIGH complexity but HIGH value
- Evidence-to-prediction tracking surfaced as a feature — already built (predictions.tsv + experiment-learnings.md), needs documentation and positioning
- Cross-venture pattern learning positioned explicitly as a differentiator — present and validated; surfaces the moat that generic PM tools can't replicate

**Defer (v2.x / v3+):**
- Four forces mapping — depends on hire/fire primitive being built and proven useful first
- Retrospective switch interview guide generation — automated scripts based on known customer + job + current solution
- Demand-signal detection from public sources (job listings, Reddit, support forums)

**Anti-features (commonly requested, do not build):**
- Competitive feature matrix — encourages feature parity thinking; use competitive response framing (/strategy compete) instead
- Roadmap generation from features — answers "what will we build" before "what job is underserved"; demand-side tools produce go/kill/pivot decisions, not Gantt charts
- Persona building with demographics — demographics don't predict switching behavior; use situational framing
- Automated roadmap prioritization scoring — creates false precision and gameable metrics

Full detail: `.planning/research/FEATURES.md`

### Architecture Approach

The architecture is three-layer: Demand (primary — discover/decide/strategy/money + support skills research/ideate/product), Build (secondary — plan/go/flow/ship), and Measure (tertiary — score/eval/taste/retro), backed by a Persistence + Identity layer (mind/, config/, vault). The layers already exist in the codebase. The restructuring is about routing and cross-references within the existing file structure, not physical reorganization — moving files would break install paths and Claude Code skill discovery.

**Major components:**
1. **Demand Cluster** — /discover (entry point), /decide (gate), /strategy (positioning), /money (unit economics) + support skills; owns the demand-side flow; must be sequentially cross-referenced
2. **Build Cluster** — /plan, /go, /flow, /ship; executes validated decisions; reads portfolio.yml and product-spec.yml written by demand layer
3. **Measure Cluster** — /score, /eval, /taste, /retro; verifies decisions; currently incorrectly positioned as the product's primary value delivery
4. **Persistence Layer** — config/founder.yml (canonical value hypothesis), portfolio.yml (idea pipeline + evidence), ~/.obsidian-vault (cross-venture knowledge), predictions.tsv (prediction grading)
5. **Identity Layer** — mind/identity.md, mind/standards.md — always active; must be updated to lead with demand-side framing before any skill changes

**Implementation sequence (dependency order):**
- Step 1: config/founder.yml + mind/identity.md (everything reads these — fix the anchor first)
- Step 2: Routing disambiguation for 5 overlapping demand skills
- Step 3: Narrative and onboarding update (README should describe what's already true)
- Step 4: Measurement skill reframing as demand verification (optional in this milestone)

Full detail: `.planning/research/ARCHITECTURE.md`

### Critical Pitfalls

1. **Thesis change without structural change** — updating the README while quick-start commands and founder.yml still lead with /score and /go. First commit must be structural (founder.yml value hypothesis), not narrative. Warning sign: new user quick start sequence is identical before and after v2.0.

2. **Overlapping skills routing ambiguity** — five demand skills (/discover, /product, /strategy, /ideate, /research) cover the same "should I build this?" space. Descriptions don't solve routing — logic does. Map non-overlapping job for each skill before touching any files. /discover owns "idea to validated spec"; /product owns "existing product pressure test."

3. **LLM-generated business analysis presented as evidence** — models produce plausible, fluent business cases that may be entirely ungrounded. Demand-side skills must label every claim by evidence class: verified external (URL), vault-backed, or LLM synthesis. This is not optional for a go/kill tool.

4. **Backward compatibility break disguised as reframing** — existing users have /score and /go muscle memory. Repositioning must be additive (new preamble, new output sections), never substitutional (new gates, renamed modes, removed arguments). Recovery from a compat break is HIGH cost.

5. **JTBD outputs too abstract to drive decisions** — "founders hire tools to reduce decision uncertainty" is a real job but it can't produce a feature bet. Require all JTBD outputs to name: specific struggling moment, functional job, emotional job, social job. If a JTBD session produces no feature candidates, it's too abstract.

6. **Consolidation collapses the wrong skill** — the most-used skill under the old thesis (measurement-first) may not be the best fit for the new thesis. Popularity is not fitness. Evaluate consolidation decisions on demand-side job fit, not usage frequency.

Full detail: `.planning/research/PITFALLS.md`

## Implications for Roadmap

Based on combined research, the restructuring has four natural phases with clear dependency ordering. The architecture research provides the implementation sequence; the pitfalls research provides the sequencing rationale; the features research provides what's in scope per phase.

### Phase 1: Foundation and Routing Disambiguation

**Rationale:** Everything reads config/founder.yml and mind/identity.md. If the canonical product definition still says "measurably better every session," every skill that reads it will anchor to measurement. This is the #1 pitfall — structural change must precede narrative change. Routing disambiguation must happen before skill content changes, because you cannot write a coherent skill SKILL.md without knowing what non-overlapping job that skill owns.

**Delivers:** Unambiguous demand-first canonical definition; clear job map for each of the 5 overlapping demand skills; no user-visible changes yet (no breakage risk)

**Addresses features:** Named-customer anchoring as mandatory step (routing change); kill condition integrated into skill flow before /go (routing change)

**Avoids:** Pitfall 1 (thesis-only repositioning), Pitfall 2 (routing ambiguity), Pitfall 6 (consolidation collapses wrong skill)

**Work items:** Rewrite founder.yml value hypothesis; update mind/identity.md demand framing; document non-overlapping job for each demand skill; make /discover the canonical "I want to build X" entry point

**Research flag:** Standard patterns — no deeper research needed. This is a routing and config change with well-defined output (each skill has exactly one non-overlapping job statement).

### Phase 2: Demand-Side Skill Strengthening

**Rationale:** With routing disambiguated, the skills can be updated without creating contradictions. The two biggest feature gaps (job statement construction with three dimensions, and outcome vs. feature decomposition as a named tool) are content changes to existing skills — not new skills. Evidence labeling (Pitfall 3) must be applied to all demand-side skill outputs before they go live; this is the phase to do it.

**Delivers:** Explicit three-dimension job statement output in /discover and /blueprint; outcome vs. feature decomposition exposed as named user-facing tool; assumption enumeration in /product flow; evidence class labeling on all demand-side outputs

**Addresses features:** Job statement construction (P1 gap); outcome vs. feature decomposition (P1); assumption enumeration in /product (P2); evidence-to-prediction tracking surfaced as feature (P2)

**Avoids:** Pitfall 3 (LLM analysis as evidence), Pitfall 5 (JTBD too abstract)

**Uses:** Klement Job Story format (When/Want/So I can); Osterwalder VPC (jobs/pains/gains taxonomy); Torres OST (outcome → opportunity → solution structure)

**Research flag:** Needs `/gsd:research-phase` for blueprint integration — the /blueprint skill is referenced but its current state relative to /discover needs investigation before integration decisions are made.

### Phase 3: Narrative and Onboarding Update

**Rationale:** By Phase 3, the product actually is demand-first. The README and onboarding can now describe something that's already true. The onboarding flow inversion (demand-first quick-start instead of /score-first) is a narrative expression of structural changes already made. Backward compat audit happens here before any user-visible changes ship.

**Delivers:** Rewritten README with demand-side thesis as opening; /onboard quick start showing demand flow (discover → decide → plan → go → score); /founder home screen grouped by layer (demand / build / measure); backward compat audit confirming /score, /eval, /go core behavior unchanged

**Addresses features:** Kill-first framing as positioning (not a warning); cross-venture pattern learning surfaced as named differentiator

**Avoids:** Pitfall 4 (backward compat break), Pitfall 3 (narrative should describe, not aspire)

**Research flag:** Standard patterns — no deeper research needed. This is copy/narrative work with a clear constraint (additive only, never substitutional).

### Phase 4: Measurement Layer Reframing (Optional in Milestone)

**Rationale:** Measurement skills (/score, /eval, /taste, /retro) work correctly. They only need their purpose statement updated to frame them as "demand decision verification" — did the thing we built deliver the outcome we decided to build toward? This is the last phase because it depends on the demand-side thesis being coherent first. If measurement skills describe themselves as verification of demand decisions but no demand-decision infrastructure exists, the framing is hollow.

**Delivers:** /score, /eval, /retro surface demand context (which decided hypothesis does this score reflect?); founder.yml signals include demand-side signals (idea_to_decide, kill_velocity) alongside build signals; demand-side skill vault write-back (JTBD findings and validated assumptions written to vault like measurement skills do)

**Addresses features:** Evidence-to-prediction tracking completing the loop; progress-to-value mapping as consideration

**Avoids:** Pitfall 4 (measurement skills' core behavior stays unchanged — only purpose framing updates)

**Research flag:** Standard patterns for reframing existing skills. Vault write-back from demand skills may need investigation — verify vault-sync.sh picks up portfolio.yml JTBD fields before declaring done.

### Phase Ordering Rationale

- **Config before skills before narrative:** config/founder.yml is the canonical source that skills read; skills must be coherent before the narrative describes them; narrative describes what exists, not what's aspired to
- **Routing disambiguation before content changes:** writing new skill content into an undisambiguated skill hierarchy creates new contradictions; map jobs first, write content second
- **Structural changes before backward compat audit:** audit what changed only after all structural changes are in; auditing mid-stream gives false confidence
- **Measurement reframing last:** measurement skills gain their demand-side framing only after the demand layer they're framing exists

### Research Flags

Phases needing deeper research during planning:
- **Phase 2:** Blueprint skill integration — current state of /blueprint relative to /discover is not fully characterized; needs skill file inspection before integration plan is written

Phases with standard patterns (skip research-phase):
- **Phase 1:** Config and routing changes — well-defined inputs and outputs, no external dependencies
- **Phase 3:** Narrative and onboarding — copy work with a hard backward-compat constraint that defines the boundary clearly
- **Phase 4:** Measurement reframing — additive framing changes, vault write-back is the only unknown (low risk)

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack (frameworks) | HIGH | All frameworks cited to original authors (Christensen, Moesta, Ulwick, Osterwalder, Torres, Kano, Cooper). No third-party interpretation needed — canonical sources direct. |
| Features | MEDIUM | Table stakes verified against existing JTBD/VPC ecosystem. Differentiators assessed against existing skill inventory (internal analysis). Anti-features derived from observed failure modes in codebase. Customer validation not done — this is desk research. |
| Architecture | HIGH | Based on direct codebase analysis of 34 skills, config files, and project documents. No inference needed — architecture is observed, not hypothesized. |
| Pitfalls | HIGH | Grounded in specific founder-os context (PROJECT.md dead-ends, codebase constraints) plus verified external sources on LLM hallucination and repositioning failure modes. |

**Overall confidence:** HIGH for the structural work (Phases 1, 3, 4). MEDIUM for skill content decisions in Phase 2, where what's "right" depends on how founders actually use the demand-side tools — not something desk research can fully answer.

### Gaps to Address

- **Blueprint skill state:** /blueprint is referenced in PITFALLS.md as the JTBD integration point but its current file state is not characterized in the research. Inspect /blueprint/SKILL.md before Phase 2 planning.
- **Customer validation of demand-side framing:** The confirmed dead end is "research without user validation." The v2.0 demand-side repositioning is itself a hypothesis. Kill condition for the repositioning should be named before Phase 3 ships (if users still lead with /score and /go after onboarding change, the repositioning is failing).
- **Hire/fire switch analysis complexity:** Rated HIGH complexity in FEATURES.md but not fully scoped. Before committing to Phase 2+ scope, verify whether this is a new skill, a /product submode, or a /discover extension.

## Sources

### Primary (HIGH confidence)
- Christensen, C. — "Competing Against Luck" (2016) — JTBD theory, four forces
- Moesta, B. — "Demand-Side Sales 101" (2020) — switch interview methodology
- Klement, A. — "When Coffee and Kale Compete" (2016) — job story format, jtbd.info
- Ulwick, T. — "Jobs to Be Done: Theory to Practice" (2016) — ODI, opportunity algorithm
- Osterwalder, A. et al. — "Value Proposition Design" (2014) — VPC, strategyzer.com
- Torres, T. — "Continuous Discovery Habits" (2021) — OST, producttalk.org
- Kano, N. — "Attractive Quality and Must-Be Quality" (1984) — feature classification
- Cooper, R.G. — "Winning at New Products" (1986/2011) — Stage-Gate, go/kill criteria
- Internal: 34 skill files in /skills/, config/founder.yml, mind/identity.md, .planning/PROJECT.md

### Secondary (MEDIUM confidence)
- Ellis, S. / Vohra, R. — First Round Review (2019) — 40% PMF rule (requires existing users; limited applicability pre-product)
- gopractice.io — JTBD framework comparison (Christensen/Moesta/Ulwick synthesis)
- ProductSchool, GreatQuestion, UserInterviews — JTBD practitioner sources
- Pendo, CoinJar — AI product discovery, go/kill decision framing

### Tertiary (LOW confidence — used only for pitfall verification)
- Signal Fire, DevelopmentCorporate — LLM hallucination patterns
- Words on Product — AI roadmap failure modes
- SegmentationStudyGuide — repositioning challenges

---
*Research completed: 2026-03-25*
*Ready for roadmap: yes*
