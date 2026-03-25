# Pitfalls Research

**Domain:** Developer tool repositioning — prompt-based AI plugin, demand-side thesis change
**Researched:** 2026-03-25
**Confidence:** HIGH (grounded in specific founder-os context + verified patterns)

---

## Critical Pitfalls

### Pitfall 1: Thesis Change Without Structural Change

**What goes wrong:**
You update the README and onboarding to say "demand-side thinking" but the skill hierarchy, quick-start commands, and `config/founder.yml` value hypothesis still lead with `/score` and `/go`. The repositioning is a veneer. Existing users get confused because the words changed but the flows didn't. New users follow the narrative into demand-side thinking, then hit skills that route them back to measurement loops. The product contradicts itself.

**Why it happens:**
Narrative changes are low-effort. Structural changes require touching 34 skills and 152 shell scripts — high perceived risk. The path of least resistance is "fix the README first, restructure later." Later never comes. This is confirmed as a known dead end in the project's own `PROJECT.md`: "Positioning AND restructuring, not just positioning — Thesis change without structural change is just a new README."

**How to avoid:**
Make the first commit structural, not narrative. Change the quick-start commands before you change the README. The README should describe what's already true, not aspire forward. Use the hierarchy in `config/founder.yml` as the canonical source of truth — if `value_hypothesis` still says "measurably better every session," the README can't credibly say "demand-side first."

**Warning signs:**
- README says "JTBD" but `/onboard` still runs `/score` as step one
- `config/founder.yml` `value_hypothesis` describes measurement outcomes, not decision quality
- New user quick start sequence is identical before and after v2.0

**Phase to address:** Phase 1 (structural hierarchy changes must precede narrative changes)

---

### Pitfall 2: Overlapping Skills Create Routing Ambiguity

**What goes wrong:**
Five skills currently occupy the "should I build this?" space: `/discover`, `/product`, `/strategy`, `/ideate`, `/research`. After restructuring, if boundaries aren't redrawn with explicit job separation, users face the same ambiguity. Worse: the LLM routing inside each skill reads adjacent skill names and sometimes routes to the wrong one. Users who typed `/product` now wonder if they should have typed `/discover`. The overlap taxes the mental model without adding value.

**Why it happens:**
Skills were added organically — each filled a gap at the time. The gap was real. But over time the gaps filled each other. Consolidation is harder than addition because it requires killing something that exists and works. The instinct is to keep everything and "just clarify the descriptions," which doesn't solve the routing problem because descriptions are read by humans, not embedded in the skill's decision logic.

**How to avoid:**
Map a clear job for each skill before touching any files. Use the Jobs-to-Be-Done criterion: what functional outcome does this skill produce that no other skill produces? If two skills produce the same outcome, one is redundant. The test is not "do they feel different?" — it's "given the same user situation, would a skilled PM always route to the same skill?" Merge or explicitly sequence before restructuring. `/discover` owns "idea to validated spec." `/product` owns "existing product pressure test." These should never be entry points to the same flow.

**Warning signs:**
- Two skills have identical `argument-hint` modes (e.g., both have a `refine` mode)
- A skill's `system integration / triggered by` list overlaps significantly with another skill's `triggers` list
- User asks "should I use /discover or /product?" with a new idea description

**Phase to address:** Phase 1 (map job separation before writing a single new skill file)

---

### Pitfall 3: LLM-Generated Business Analysis Presented as Grounded Evidence

**What goes wrong:**
The skills you're building are designed to help founders make go/kill decisions. But the LLM generating the analysis has a known failure mode: it produces plausible, fluent, internally consistent business cases that may be entirely ungrounded. Market sizing, competitor weaknesses, and customer pain signals are particularly vulnerable. The model weaves false information into accurate context, making detection difficult without domain expertise. LLMs are 34% more likely to use confident language ("certainly," "without doubt") precisely when hallucinating — the opposite of what you need for a go/kill decision.

**Why it happens:**
Next-token prediction optimizes for linguistic plausibility, not epistemic truth. The model has no access to real-time market data, private competitor pricing, or actual customer willingness to pay. It fills those gaps with statistically likely continuations. The danger is amplified in business analysis because the output sounds like research. Founders who don't know the space well cannot distinguish LLM-generated plausibility from actual evidence.

**How to avoid:**
Every demand-side skill must clearly differentiate between evidence classes: (1) external verified — WebSearch results with URLs, (2) internal verified — vault data, experiment learnings, (3) LLM synthesis — explicitly labeled as "model inference, not evidence." The `/discover` skill already does this partially (research playbook runs before generation). But the output format doesn't label confidence levels. Add explicit evidence labels to every claim in the output. Require WebSearch before any market claim. The `gotchas.md` files in each skill are the right mechanism — they need to include "LLM-generated plausibility" as an explicit failure mode.

**Warning signs:**
- Output includes market sizing numbers without a URL source
- Competitor weakness analysis cites no external research
- "Based on my analysis" in output without citing which analysis
- No confidence labels on market claims

**Phase to address:** Phase 2 (demand-side skill strengthening) — before any skill goes live, add evidence labeling requirements to output format

---

### Pitfall 4: Backward Compatibility Break Disguised as "Reframing"

**What goes wrong:**
Users have `/score`, `/go`, `/eval` muscle memory. The instinct during repositioning is to "reframe" these as serving demand-side thinking — which is correct in principle, but in practice means changing what the commands do or what they say first. If `/score` now surfaces a demand-side question before running its measurement loop, users who relied on it as a fast measurement check have a worse experience. The "reframing" breaks a workflow without announcing it as a breaking change.

**Why it happens:**
Repositioning feels like it shouldn't cause breaking changes — you're just "changing emphasis." But when emphasis changes behavior (even subtly), it breaks workflows. The distribution constraint is hard: `PROJECT.md` states "Plugin marketplace — install path can't change." That constraint is well-understood. The less obvious constraint is behavioral: existing users' mental model of what each command does is a form of API contract.

**How to avoid:**
Treat behavior changes in existing commands as breaking changes requiring explicit versioning. The rule: existing commands can gain new preamble or output sections, but cannot change their core invocation behavior. Additions are safe. Substitutions are breaking. Specifically: `/score` can say "Demand context: your bottleneck is [feature]" as a first line without breaking anything. But if `/score` now prompts for a JTBD mapping before running, that's breaking. The demand-side layer must be additive to existing commands, not substitutional.

**Warning signs:**
- A measurement command now asks a demand-side question before executing
- `/go` has a new gate that didn't exist before
- A skill's `argument-hint` modes changed (removed or renamed)

**Phase to address:** Phase 3 (narrative and onboarding update) — when repositioning existing skill descriptions, audit for behavioral changes

---

### Pitfall 5: JTBD Maps That Are Too Abstract to Drive Decisions

**What goes wrong:**
The `/blueprint` skill (JTBD mapping, value props, feature architecture) captures the right job but isn't integrated. When you integrate it, the risk is that JTBD outputs are too abstract to be actionable. "Founders hire tools to reduce decision uncertainty" is a real job, but it doesn't help a founder know whether to build the JTBD mapping skill or the go/kill decision skill first. Abstract JTBD maps produce "insights" that all feel true and none of which narrow the decision space.

**Why it happens:**
JTBD is often taught and practiced at the outcome level (what the customer is trying to accomplish), but actionable product decisions require the job-level — who, in what context, struggling with what specific obstacle. The abstraction creep is natural because high-level jobs feel strategic. The implementation problem is that "help founders make better decisions faster" is so broad it could justify building almost anything.

**How to avoid:**
Require JTBD outputs to always name: (1) the specific struggling moment — not "when building a product" but "when deciding whether to kill a feature after 3 weeks of no traction," (2) the functional job (what they're trying to do), (3) the emotional job (how they want to feel), and (4) the social job (what they want to be seen doing). If the JTBD map can't produce a feature bet from those four elements, it's too abstract. The `/blueprint` skill needs to be grounded to these four elements before integration.

**Warning signs:**
- JTBD output uses "founders" as the customer without naming a specific situation
- Job statement is more than 15 words
- Output includes more than 3 "jobs" for a single product (scope collapse)
- A JTBD session produces no feature candidates

**Phase to address:** Phase 2 (demand-side skill strengthening) — specifically when integrating `/blueprint` into the primary flow

---

### Pitfall 6: Consolidation Collapses the Wrong Skill

**What goes wrong:**
You have 5 overlapping demand-side skills. You decide to consolidate. The consolidation logic — "which skill is most used? which has the clearest scope?" — may lead you to kill the skill that best embodies the new thesis and keep the one that's most popular under the old thesis. The "most used" skill may be the one that leads with measurement framing. Popularity under the old thesis is not evidence of fitness for the new thesis.

**Why it happens:**
Without explicit criteria for which skill "wins" in a consolidation, you default to usage data or complexity. Both are proxies for the wrong thing. The question is not "which skill do users use most?" — it's "which skill best delivers the demand-side job?" Those may be different skills.

**How to avoid:**
Before consolidating, define the demand-side job each skill should serve and evaluate fitness against that job, not against usage. Map: (1) what job does this skill serve in the demand-side hierarchy, (2) which skill currently best serves that job, (3) which elements from other skills need to be absorbed. The result might be: keep `/discover` as the primary demand-side skill, absorb the "should I build this" modes from `/product` and `/strategy`, and redirect the remainder to their non-overlapping specialties.

**Warning signs:**
- Consolidation plan uses usage frequency as primary criterion
- The skill marked for absorption has the clearest demand-side job description
- Post-consolidation, the winning skill still routes to measurement within 2 steps

**Phase to address:** Phase 1 (before any skill files are modified, complete the job mapping)

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Update README before restructuring skills | Fast visible progress | Product contradicts itself; README is aspirational not descriptive | Never — structural changes must precede narrative changes |
| Add demand-side preamble to measurement skills without changing routing | Looks repositioned, zero breakage | Users get demand-side question then immediately hit measurement flow; incoherent experience | Only if explicit bridge logic routes demand questions to demand skills |
| Keep all 5 overlapping skills and just update descriptions | Zero breakage risk | Routing ambiguity persists; user mental model doesn't change; problem deferred | Never — descriptions don't solve routing |
| Integrate JTBD at high abstraction level ("founders need to understand their market") | Quick integration | JTBD becomes decoration, not decision infrastructure | Never for primary flows; acceptable in documentation/reference only |
| Skip evidence labeling on LLM outputs | Faster skill implementation | Founders treat LLM inference as market evidence; go/kill decisions become ungrounded | Never in demand-side primary flows |

---

## Integration Gotchas

Common mistakes when connecting demand-side skills to existing infrastructure.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `/blueprint` + `/discover` | Treating blueprint as a sub-step inside discover | Blueprint owns the framework layer; discover calls it at step 3 with explicit evidence grounding |
| `config/founder.yml` `value_hypothesis` | Updating only README, leaving founder.yml with measurement framing | `founder.yml` is the canonical product definition; README derives from it |
| `portfolio.yml` idea specs + JTBD | Adding JTBD fields to the yaml schema as optional | JTBD fields must be required for any idea at `stage: validating` or beyond |
| Vault knowledge + demand-side outputs | Vault stores experiment learnings but demand-side outputs don't write back | Demand-side skills must write JTBD findings and validated assumptions to vault like measurement skills do |
| Measurement skills (`/score`, `/eval`) + repositioned narrative | Adding demand-side framing to measurement skill output | The demand-side framing must be in onboarding/orientation, not bolted onto measurement output |

---

## Performance Traps

N/A for this domain — this is a prompt-based plugin, not a performance-constrained application. At the scale of a solo founder's tool, token budget and agent spawn counts are the relevant constraints, not throughput.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Spawning agents for every demand-side analysis | Token budget exceeded; user waits; cost perception | Demand-side thinking is primarily reasoning, not research; agents only for external market signal | Any time agents are spawned as default, not conditional |
| Running all JTBD dimensions on every `/discover` call | Slow output; abstraction overload | Gate depth on idea stage — quick kill check first, full JTBD only if idea survives | When idea fails quick kill but JTBD runs anyway |

---

## UX Pitfalls

Common user experience mistakes specific to repositioning a prompt-based tool.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Renaming commands users have in their muscle memory | Broken workflows; confusion; lost trust | Keep command names stable; reframe what they do, not what they're called |
| Demand-side onboarding that doesn't connect to existing vault/score data | New users get framework; no continuity for existing users | Demand-side onboarding detects existing vault/portfolio.yml and adapts |
| JTBD output that doesn't end with a concrete command | User gets insight but no action; doesn't change behavior | Every demand-side skill output must end with one next command, not a list |
| Measurement skills that now feel demoted | Existing users feel their primary workflow is deprecated | Measurement skills maintain their identity; repositioning is about entry points, not hierarchy of importance within a session |
| Quick start that doesn't differentiate new vs returning users | Returning users hit onboarding content they've already seen | Quick start routes on vault health: no vault = demand-side intro; vault exists = show current bottleneck |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Narrative repositioning:** README updated — verify `config/founder.yml` `value_hypothesis` also reflects demand-side framing, not "measurably better every session"
- [ ] **Skill consolidation:** Overlapping skills merged — verify the merged skill's routing logic doesn't fall back to measurement within 2 steps for a new-idea use case
- [ ] **JTBD integration:** Blueprint skill integrated — verify output includes all four JTBD elements (functional, emotional, social, struggling moment) and produces at least one feature bet
- [ ] **Evidence labeling:** Demand-side outputs updated — verify every market claim has an explicit evidence class (verified external / vault / LLM inference)
- [ ] **Backward compat:** Existing commands reframed — verify `/score`, `/eval`, `/go` core behavior unchanged by running each command and comparing output structure to v1.0 baseline
- [ ] **Vault write-back:** Demand-side skills produce vault-writable outputs — verify portfolio.yml JTBD fields are populated and vault-sync.sh picks them up

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Thesis-only repositioning shipped (README changed, structure unchanged) | MEDIUM | Audit quick start sequence; identify first measurement-first decision point; restructure that one entry point before next commit |
| Overlap consolidation chose wrong skill | MEDIUM | Re-read both skills' job descriptions; map which serves demand-side job better; do targeted port of best elements; kill the other |
| JTBD outputs too abstract to drive decisions | LOW | Add required struggling-moment field to blueprint output format; reject outputs that don't name a specific context |
| Backward compat break found after merge | HIGH | Immediately revert behavioral change; add as additive layer only; document as explicit constraint in skill file header |
| LLM business analysis presented as evidence without grounding | MEDIUM | Add evidence class labeling to gotchas.md for affected skills; add pre-submission check to research playbook requiring URL for any market claim |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Thesis change without structural change | Phase 1: Skill hierarchy restructuring | Quick start sequence leads with demand-side command before measurement command |
| Overlapping skills routing ambiguity | Phase 1: Job separation mapping | Given "I want to build X" input, only one skill is the correct entry point |
| LLM business analysis as evidence | Phase 2: Demand-side skill strengthening | Every market claim in skill output has explicit evidence class label |
| Backward compat break | Phase 3: Narrative and onboarding | `/score`, `/eval`, `/go` core output structure unchanged from v1.0 |
| JTBD too abstract | Phase 2: Blueprint integration | Blueprint output produces at least one specific feature bet from a named struggling moment |
| Consolidation collapses wrong skill | Phase 1: Before any file changes | Consolidation decision is based on demand-side job fitness, documented before files are touched |

---

## Sources

- [Don't Let AI Build Your Roadmap — Words on Product](https://www.wordsonproduct.com/p/dont-let-ai-build-your-roadmap)
- [Why most people get Jobs to be Done wrong — The Rewired Group](https://therewiredgroup.com/learn/jobs-to-be-done-mistakes/)
- [LLM hallucinations aren't bugs — Signal Fire](https://www.signalfire.com/blog/llm-hallucinations-arent-bugs)
- [The Risk of LLM Hallucinations in SaaS Competitive Analysis](https://developmentcorporate.com/product-management/llm-hallucinations-saas-competitive-analysis/)
- [The Expert Trap: Why AI Hallucinations Are Most Dangerous When Your Team Knows Better](https://developmentcorporate.com/saas/the-expert-trap-why-ai-hallucinations-are-most-dangerous-when-your-team-knows-better/)
- [Challenges of Repositioning — Segmentation Study Guide](https://www.segmentationstudyguide.com/understanding-repositioning/challenges-of-repositioning/)
- [Versioning, Rollback & Lifecycle Management of AI Agents](https://medium.com/@nraman.n6/versioning-rollback-lifecycle-management-of-ai-agents-treating-intelligence-as-deployable-deac757e4dea)
- [Refactoring Agent Skills: From Context Explosion to a Fast, Reliable Workflow](https://dev.to/superorange0707/refactoring-agent-skills-from-context-explosion-to-a-fast-reliable-workflow-5hg6)
- Internal: `founder-os/skills/discover/SKILL.md`, `founder-os/skills/product/SKILL.md`, `founder-os/.planning/PROJECT.md`
- Internal dead end confirmed: "Research without user validation — competitive analysis ≠ user validation. The model was too confident in desk research." (founder-priorities.md)

---
*Pitfalls research for: founder-os v2.0 demand-side repositioning*
*Researched: 2026-03-25*
