# Architecture Research

**Domain:** Claude Code plugin — prompt orchestration with shell script data layer
**Researched:** 2026-03-25
**Confidence:** HIGH (based on direct codebase analysis)

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    LAYER 1: DEMAND-SIDE (Primary)               │
│  Purpose: figure out what to build and whether to kill it       │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │/discover │  │ /decide  │  │/strategy │  │  /money  │        │
│  │ idea →   │  │ go/kill/ │  │ position,│  │  unit    │        │
│  │ biz case │  │ pivot    │  │ timing   │  │  econ    │        │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘        │
│  ┌──────────────────────────────────────────────────────┐       │
│  │           /research  /ideate  /product               │       │
│  │      (evidence, generation, pressure-testing)        │       │
│  └──────────────────────────────────────────────────────┘       │
├─────────────────────────────────────────────────────────────────┤
│                    LAYER 2: BUILD (Secondary)                    │
│  Purpose: execute validated decisions efficiently               │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │  /plan   │  │   /go    │  │  /flow   │  │  /ship   │        │
│  │bottleneck│  │autonomous│  │ GSD wrap │  │ deploy   │        │
│  │  finder  │  │  build   │  │          │  │          │        │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘        │
├───────┴────────────┴────────────┴────────────┴───────────────── ┤
│                  LAYER 3: MEASUREMENT (Tertiary)                 │
│  Purpose: verify decisions, close learning loop                  │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │  /score  │  │  /eval   │  │  /taste  │  │  /retro  │        │
│  │  health  │  │ features │  │  visual  │  │  grade   │        │
│  │  number  │  │ delivery │  │  flows   │  │  learn   │        │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘        │
├───────┴────────────┴────────────┴────────────┴───────────────── ┤
│                 PERSISTENCE + IDENTITY LAYER                     │
├─────────────────────────────────────────────────────────────────┤
│  mind/identity.md   mind/standards.md   mind/thinking.md        │
│  config/founder.yml   config/portfolio.yml   ~/.obsidian-vault/  │
│  .claude/cache/   ~/.claude/knowledge/   hooks/                  │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Layer |
|-----------|----------------|-------|
| /discover | Idea → testable business case. Research-first, hierarchy-anchored | Demand |
| /decide | Go/kill/park/pivot gate. The most important skill | Demand |
| /strategy | Positioning, timing, wedge, competitive response | Demand |
| /money | Unit economics, pricing, runway, channel math | Demand |
| /research | Evidence gathering for business decisions | Demand (support) |
| /ideate | Evidence-weighted idea generation | Demand (support) |
| /product | Pressure-test assumptions, audit value hypothesis | Demand (support) |
| /plan | Find the bottleneck. Plan with world-awareness | Build |
| /go | Autonomous build loop with measurement wrapping | Build |
| /flow | GSD-integrated execution with vault intelligence | Build |
| /score | Unified health number | Measure |
| /eval | Per-feature delivery/craft/viability scores | Measure |
| /taste | Visual + flow quality checks | Measure |
| /retro | Grade predictions, update knowledge model | Measure |
| mind/ | Personality, standards, decision frameworks — always active | Identity |
| hooks/ | Session-lifecycle guardrails, status display | Infrastructure |
| bin/ | Measurement scripts, vault queries, data processing | Infrastructure |
| config/ | Feature definitions, scoring config, value hypothesis | Configuration |

## Recommended Project Structure

The current structure is valid. The restructuring is about **layering and routing within existing structure**, not physical reorganization. Two changes needed:

```
founder-os/
├── mind/                    # Identity layer — MODIFY: add demand-side framing
│   ├── identity.md          # "AI cofounder focused on demand-side thinking"
│   ├── standards.md         # Move demand-side criteria to top of hierarchy
│   ├── thinking.md          # No change needed
│   └── world.md             # No change needed
│
├── skills/                  # Skill layer — MODIFY routing and cross-references
│   │
│   ├── [DEMAND CLUSTER — primary]
│   ├── discover/            # Entry point. JTBD mapping, outcome anchoring
│   ├── decide/              # Go/kill gate. No change needed
│   ├── strategy/            # Positioning, timing, wedge
│   ├── money/               # Unit economics check
│   │
│   ├── [DEMAND SUPPORT — secondary within demand cluster]
│   ├── ideate/              # Collapse /product and /research routing here
│   ├── product/             # MODIFY: becomes /discover submode or peer
│   ├── research/            # MODIFY: reframe as evidence-gathering for decide
│   │
│   ├── [BUILD CLUSTER — secondary]
│   ├── plan/                # References demand cluster outputs
│   ├── go/                  # Autonomous execution
│   ├── flow/                # GSD integration
│   ├── ship/                # Deploy
│   │
│   ├── [MEASURE CLUSTER — tertiary]
│   ├── score/               # Health number
│   ├── eval/                # Feature delivery
│   ├── taste/               # Visual quality
│   ├── retro/               # Learning loop
│   │
│   ├── [SHARED — no cluster change]
│   ├── founder/             # Home screen — MODIFY: show demand cluster first
│   ├── onboard/             # MODIFY: quick-start leads with demand flow
│   └── ...
│
├── config/
│   └── founder.yml          # MODIFY: value hypothesis is demand-side, not measure
│
└── README.md                # MODIFY: demand-side narrative, new quick-start
```

### Structure Rationale

- **Physical files stay**: install paths and Claude Code skill discovery are path-dependent. Moving files breaks existing users.
- **Logical layering via routing**: the hierarchy is expressed by how skills reference each other and how /founder groups them.
- **Demand cluster expressed via cross-references**: /discover should reference /research and /ideate. /decide should reference /strategy and /money. This creates a coherent "demand flow" without renaming.

## Architectural Patterns

### Pattern 1: Skill Cross-Reference (demand flow stitching)

**What:** A skill's SKILL.md includes explicit "after this, use" or "before this, run" pointers to adjacent skills in the same logical cluster.

**When to use:** When two skills are sequentially related in the demand-side flow. /discover → /research → /decide is a sequence; each should name the next.

**Trade-offs:** Adds coupling between skills. Acceptable because the demand flow sequence is stable and intentional. Don't add bidirectional references — keep direction of flow consistent.

**Example:**
```markdown
## After this session

If you have a business case worth testing:
- Run `/research market [idea]` to validate assumptions with evidence
- Run `/strategy` to check positioning and timing
- Run `/money unit-economics` to check if the math works
- Then `/decide [idea]` to go/kill/park

If the idea is clearly dead: `/decide kill [idea]` and document why in vault.
```

### Pattern 2: Routing Consolidation (demand overlap resolution)

**What:** The 5 overlapping demand skills (/discover, /product, /strategy, /ideate, /research) are disambiguated by sharpening their routing descriptions to assign each a non-overlapping job.

**When to use:** When users face choice paralysis between similarly-named skills.

**Proposed disambiguation:**

| Skill | Sharpened job | Trigger phrase |
|-------|---------------|----------------|
| /discover | Raw idea → structured business case. Creates the artifact. | "I want to build X" |
| /research | Gather evidence for a decision already framed. Raw data gathering. | "Find proof that..." |
| /product | Pressure-test an existing product or spec. Assumes something exists. | "Is this working?" |
| /ideate | Generate options when you're stuck. Diverge, then kill. | "What should I build?" |
| /strategy | Diagnose positioning, timing, competitive response. One company in context. | "Is my approach right?" |
| /decide | Convert evidence into a go/kill/pivot commitment. The gate. | "Should I do this?" |

**Trade-offs:** Some overlap will always remain — that's acceptable. The goal is "mostly non-overlapping" not "zero overlap." Users navigating uncertainty will still start in multiple places.

### Pattern 3: Hierarchy-Gated Config (value hypothesis as demand statement)

**What:** `config/founder.yml` value hypothesis is rewritten from measurement-first to demand-first language. Feature ordering in the config reflects demand > build > measure.

**When to use:** Once. This is the canonical "what does this product do" statement that all other skills read.

**Current:**
```yaml
value:
  hypothesis: "A serial entrepreneur's product gets from idea to measurably better every session"
```

**Recommended:**
```yaml
value:
  hypothesis: "A serial entrepreneur figures out what to build — and kills what isn't working — before wasting time executing the wrong thing"
```

**Trade-offs:** Changes what /score viability checks against. Worth it — this is the thesis change.

### Pattern 4: Onboarding Flow Inversion (demand-first quick-start)

**What:** README and /onboard quick-start show demand-side commands first. /score and /go appear in phase 2, not phase 1.

**Current flow:**
```
1. /onboard → sets up config
2. /score → get baseline number
3. /go → build the bottleneck
```

**Recommended flow:**
```
1. /onboard → sets up config
2. /discover [idea] → is this worth building?
3. /decide → go/kill
4. (if go) /plan → what to build first
5. /go → build it
6. /score → did it improve?
```

**Trade-offs:** Existing users have /score and /go muscle memory (named constraint in PROJECT.md). Don't remove them from onboarding — reframe them as "once you've decided to build" steps.

## Data Flow

### Demand-Side Flow (new primary path)

```
/discover [raw idea]
    ↓ (research-playbook.md, hierarchy.md)
/research market [idea]   /ideate [topic]
    ↓                          ↓
evidence gathered         options generated
    ↓                          ↓
/strategy [idea]  →  /money unit-economics
    ↓
strategic diagnosis + math check
    ↓
/decide [idea]
    ↓
go/kill/park/pivot written to config/portfolio.yml
    ↓
(if GO) → Build layer: /plan → /go → /flow
              ↓
         Measure layer: /score → /eval → /retro
              ↓
         Knowledge update: vault-sync → predictions.tsv
              ↓
         (next idea cycle)
```

### Build-Serves-Demand Signal Flow

```
/plan reads:
    config/portfolio.yml (what was decided and why)
    .claude/cache/eval-cache.json (what's underdelivering)
    → produces wave-grouped plan targeting demand-side decisions

/go reads:
    .claude/plans/plan.yml (demand-informed plan)
    → executes, measures, reverts on regression

/retro reads:
    predictions.tsv, experiment-learnings.md
    → updates knowledge model to improve next /decide
```

### Knowledge Compounding Flow

```
Idea killed in /decide
    ↓
vault-sync writes to ~/obsidian-vault/Knowledge/
    ↓
next /discover session pulls vault via bin/vault-query.sh
    ↓
"We tried this framing before — here's what we learned"
```

## Integration Points

### Between Demand and Build Layers

| Integration | Mechanism | Notes |
|-------------|-----------|-------|
| /decide → /plan | portfolio.yml written by /decide, read by /plan | /plan should surface the decided hypothesis in its orientation |
| /strategy → /plan | strategy.yml written by /strategy, read by /plan | /plan reads freshness and flags staleness |
| /discover → /go | product-spec.yml written by /discover, read by /go | /go should know what outcome the build is targeting |
| /decide kill → /retro | predictions.tsv updated on kill | /retro grades the prediction that this idea would work |

### Between Demand and Measurement Layers

| Integration | Mechanism | Notes |
|-------------|-----------|-------|
| /decide go → /score | /score viability dimension checks against value hypothesis in founder.yml | Rewriting value hypothesis (Pattern 3) makes /score viability reflect demand-side decisions |
| /eval → /product | eval-cache read by /product for "is this actually working?" mode | /product pressure-tests with score data as evidence |
| /retro audit → /decide | /retro's audit mode asks "does this feature still matter?" — output is a /decide input | This is the feedback loop that keeps demand-side thinking active |

### Within Demand Cluster

| Integration | Mechanism | Notes |
|-------------|-----------|-------|
| /discover → /research | /discover references research-playbook.md which should call /research for evidence | Currently implicit — make explicit in SKILL.md routing |
| /discover → /strategy | /discover references hierarchy.md; strategy is part of anchor check | Add /strategy reference to /discover's "after this" section |
| /research → /decide | /research produces evidence artifacts that /decide ingests | Both read .claude/cache/last-research.yml — this integration exists |
| /ideate → /discover | /ideate generates options; /discover converts chosen option to biz case | Add "take this to /discover" to /ideate output |
| /product → /decide | /product's pressure-test output should name a /decide recommendation | Currently implicit — add explicit routing |

### External Integrations

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Obsidian vault | bin/vault-query.sh (read) + vault-sync (write) | Demand skills should query vault before generating |
| GSD engine | hooks + /flow skill | Build layer only — demand layer is not GSD-integrated |
| Claude Code marketplace | plugin.json + install.sh | Distribution layer — unchanged |

## Anti-Patterns

### Anti-Pattern 1: Demand Skills That Read Eval-Cache First

**What people do:** Start demand-side skills (/product, /strategy, /discover) by reading eval-cache.json and score-cache.json as their primary orientation.

**Why it's wrong:** Measurement data is about what was built, not whether it's the right thing to build. Starting with scores anchors the demand analysis to execution quality instead of market fit. A 90/100 score on the wrong product is still the wrong product.

**Do this instead:** Demand skills start with vault query + market search. If they read scores, it's to populate a "what exists" section, not to set the analysis frame.

### Anti-Pattern 2: Overlapping Routing Without Disambiguation

**What people do:** /product, /discover, and /research all accept "I want to build X" as valid input without routing to a canonical home.

**Why it's wrong:** User tries /product, gets a response, tries /discover, gets a different (possibly contradictory) response. Neither sticks because both feel equally authoritative. Creates duplicate work and contradictory artifacts.

**Do this instead:** Make /discover the canonical entry point for "I want to build X." /product handles "is this existing product working?" /research handles "find me evidence on X." Update all three SKILL.md descriptions to route overlap toward /discover explicitly.

### Anti-Pattern 3: Framing Build as the Value Delivery

**What people do:** README says "get from idea to measurably better every session." Onboarding leads with /score and /go.

**Why it's wrong:** It positions the measurement loop as the product. Users come for the demand-side thinking — "help me figure out what to build." Measurement is the proof layer, not the value layer.

**Do this instead:** README leads with the demand-side thesis. "/score and /go exist to verify you built the right thing." Measurement is validation of demand decisions.

### Anti-Pattern 4: Adding a New Skill Instead of Consolidating

**What people do:** See the 5 overlapping demand skills and add a 6th to "unify" them (e.g., /validate, /assess).

**Why it's wrong:** More commands without sharper routing makes the problem worse. The overlapping skills exist because each was added to fill a perceived gap. The gap is routing clarity, not skill count.

**Do this instead:** Sharpen the routing descriptions of existing skills. A /product skill with a clear "when to use this instead of /discover" note is more useful than a new /validate command that sits on top.

### Anti-Pattern 5: Changing Command Names

**What people do:** Rename /score to /measure or /evaluate to better reflect the demand-first hierarchy.

**Why it's wrong:** Existing users have muscle memory for /score and /go (explicit constraint in PROJECT.md). Breaking commands to match a new thesis is worse than keeping commands and updating their framing.

**Do this instead:** Keep all command names. Update their descriptions, quick-starts, and surrounding narrative to reflect the new hierarchy. A /score that says "verify your demand-side decisions worked" serves the new thesis without breaking anything.

## Restructuring Order (Phase Dependencies)

This is the recommended implementation sequence based on component dependencies:

```
Step 1: Foundation (no dependencies)
  → Rewrite config/founder.yml value hypothesis (demand-first language)
  → Update mind/identity.md to lead with demand-side framing
  Why: Everything else reads these. Fix the anchor first.

Step 2: Routing Disambiguation (depends on Step 1)
  → Sharpen SKILL.md descriptions for /discover, /product, /research, /ideate, /strategy
  → Add cross-references between demand skills (Pattern 1)
  → /discover becomes the canonical "I want to build X" entry point
  Why: Resolves the 5-skill overlap before touching onboarding or README

Step 3: Narrative Update (depends on Step 2)
  → Rewrite README with demand-side thesis as opening
  → Update /onboard quick-start to show demand flow first
  → Update /founder home screen to group skills by layer (demand / build / measure)
  Why: Narrative should reflect restructured skills, not vice versa

Step 4: Measurement Reframing (depends on Step 1, optional in this milestone)
  → Update /score, /eval, /taste, /retro to frame as "demand decision verification"
  → Update signals in founder.yml to include demand-side signals (idea_to_decide, kill_velocity)
  Why: Measurement skills work — they just need their purpose statement updated
```

## Scaling Considerations

This is a prompt-orchestration plugin, not a service. "Scaling" means: does it stay coherent as new skills and agents are added?

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Current (34 skills) | Cluster routing via /founder groups. Cross-references via SKILL.md. Works now. |
| +10 skills | Add a routing guide file per cluster (demand/build/measure) that /founder reads |
| +30 skills | Consider a skills registry (like CAPABILITIES.md) that auto-generates from skill frontmatter. The file already exists — populate it. |

### Scaling Priorities

1. **First bottleneck:** Routing ambiguity compounds as skills are added. The disambiguation pattern (Pattern 2) should be enforced as a standard for new skills before new ones ship.
2. **Second bottleneck:** Cross-skill context state. Right now each skill reads the same cache files independently. If the demand-side flow expands, a shared "session context" file (written by /discover, read by /decide, /strategy, /money) would reduce redundant reads.

## Sources

- Direct analysis of 34 skills in `/Users/laneyfraass/founder-os/skills/`
- `config/founder.yml` — feature groupings, value hypothesis, current signals
- `mind/identity.md`, `mind/standards.md` — behavioral framing
- `.planning/PROJECT.md` — v2.0 milestone constraints and decisions
- `skills/discover/references/hierarchy.md` — product hierarchy model (existing asset)

---
*Architecture research for: founder-os v2.0 demand-side repositioning*
*Researched: 2026-03-25*
