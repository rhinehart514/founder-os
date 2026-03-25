# Stack Research: Demand-Side Product Thinking Frameworks

**Domain:** JTBD, value proposition design, feature architecture, go/kill decisions for solo founders
**Researched:** 2026-03-25
**Confidence:** HIGH (canonical sources, original authors, documented frameworks)

---

## The Framework Landscape

This is not a technology stack in the traditional sense — founder-os is prompt-based (markdown + shell). The "stack" here is the set of canonical frameworks, templates, and decision methods that demand-side product thinking skills should encode.

---

## Core Framework 1: JTBD — Three Schools

### Christensen / Moesta (Progress-Based School)

**Source:** Clayton Christensen, Bob Moesta, Alan Klement — "Competing Against Luck" (2016), "Demand-Side Sales 101" (2020), "When Coffee and Kale Compete" (2016)

**Core claim:** Customers "hire" products to make progress in specific circumstances. The unit of analysis is the struggling moment, not the demographic or persona.

**The Four Forces of Progress** (Moesta's operationalization of Christensen):
| Force | Direction | Description |
|-------|-----------|-------------|
| Push of the problem | Toward change | What makes today's situation intolerable |
| Pull of the new solution | Toward change | What attracts them to the new product |
| Anxiety of the new | Against change | Fear that the new thing won't work |
| Habit of the present | Against change | Inertia of current behavior |

**Decision rule:** F1 + F2 > F3 + F4 → customer switches. Map these forces to understand what drives and blocks adoption.

**The Switch Interview** (Moesta's canonical method):
- Recruit customers who switched to your product within last 1-3 months
- Reconstruct the **purchasing timeline**: First Thought → Passive Looking → Active Looking → Deciding → Onboarding
- Opening question: "Why did you buy [product] and where were you when you bought it?"
- Key probes: "Walk me through the day you realized your current approach wasn't working."
- Do NOT ask "why" repeatedly — ask "tell me more" and "give me an example"
- Fill the timeline first; sort the forces after

**Job Story format** (Klement's artifact):
```
When [struggling moment / circumstance],
I want to [motivation / progress sought],
So I can [expected outcome].
```
The "When" is the struggling moment — the specific context that triggers demand. Without it, the story has no predictive power.

**Confidence:** HIGH — original sources, well-documented methodology

---

### Ulwick / ODI (Outcome-Driven Innovation School)

**Source:** Tony Ulwick — "Jobs to Be Done: Theory to Practice" (2016), Strategyn (strategyn.com)

**Core claim:** Jobs are stable, solutions change. Define markets around the job, not the product. Measure progress with outcome statements customers can rate.

**Desired Outcome Statement structure:**
```
[Direction of improvement] + [metric] + [object] + [context]
Example: "Minimize the time it takes to find the root cause of a build failure during a CI run"
```

**The Opportunity Algorithm** (Ulwick's formula):
```
Opportunity Score = Importance + max(0, Importance − Satisfaction)
```
Scale: 1-10 for both. A score above 10 is overserved (ripe for disruption from below). Score 12-15 is underserved (highest opportunity).

**What it reveals:**
- High Importance + Low Satisfaction = underserved → build here
- Low Importance + High Satisfaction = overserved → cut or commoditize
- Low Importance + Low Satisfaction = not worth addressing

**Confidence:** HIGH — formula is cited in peer-reviewed sources and Ulwick's own publications

---

### Klement (Motivational / Systems School)

**Source:** Alan Klement — "When Coffee and Kale Compete" (2016), jtbd.info

**Core claim:** JTBD is about the system of progress customers are trying to create in their lives. Products compete with any alternative that serves the same progress, including inaction.

**Klement's JTBD definition:** "When I [situation], I want to [motivation], so I can [expected outcome]."

**Key distinction from Ulwick:** Klement focuses on the motivational context and system of progress, not measurable process steps. More useful for consumer products and positioning; less useful for quantitative prioritization.

**Confidence:** MEDIUM — well-documented but Klement/Ulwick have a public dispute on whose framing is correct; both are valid for different use cases

---

## Core Framework 2: Value Proposition Design

**Source:** Alexander Osterwalder, Yves Pigneur et al. — "Value Proposition Design" (2014), strategyzer.com

**The Value Proposition Canvas** — two-sided tool:

**Customer Profile (right side):**
| Element | What to capture |
|---------|----------------|
| Customer Jobs | Functional, social, and emotional jobs they're trying to get done |
| Pains | Negative outcomes, risks, and obstacles when doing the job |
| Gains | Outcomes and benefits they want — required, expected, desired, unexpected |

**Value Map (left side):**
| Element | What to capture |
|---------|----------------|
| Products & Services | The list of what you offer (not the value — the offering) |
| Pain Relievers | How your offering reduces or eliminates specific pains |
| Gain Creators | How your offering produces gains customers expect or desire |

**Fit condition:** Your pain relievers and gain creators address the most important jobs, pains, and gains from the customer profile. Rule of thumb: address 50-70% of their highest-ranked pains and gains.

**Three types of fit to progress through:**
1. **Problem-Solution Fit** — your value map resonates on paper
2. **Product-Market Fit** — evidence customers want what you built
3. **Business Model Fit** — the economics work at scale

**Jobs taxonomy** (from Osterwalder):
- **Functional jobs:** The practical tasks ("send a file")
- **Social jobs:** How they want to be perceived ("look professional")
- **Emotional jobs:** How they want to feel ("feel in control")
- **Supporting jobs:** Buyer jobs (comparing options), co-creator jobs (giving feedback)

**Confidence:** HIGH — published framework, canonical source, widely validated

---

## Core Framework 3: Feature Classification

### Kano Model

**Source:** Noriaki Kano — "Attractive Quality and Must-Be Quality" (1984)

**Three primary categories:**

| Category | Also called | When present | When absent | Application |
|----------|-------------|-------------|------------|-------------|
| Must-Be | Basic/Threshold | Neutral | Very dissatisfied | Never a differentiator; table stakes |
| Performance | One-Dimensional | More = more satisfied | Less = less satisfied | Competitive battleground |
| Delighter | Attractive | Surprised/delighted | No dissatisfaction | Innovation and differentiation |

**Key insight:** Categories degrade over time. Delighters become Performance features become Must-Bes as the market matures. Mobile banking was a delighter in 2010, Performance in 2015, Must-Be by 2020.

**Practical use:** Before building a feature, classify it. If it's a Must-Be, the goal is "don't fail," not "impress." If it's a Delighter, it can be a wedge. Build Performance features to win on your chosen axis.

**Confidence:** HIGH — peer-reviewed original source, 40+ years of validation

---

### Opportunity Solution Tree (Teresa Torres)

**Source:** Teresa Torres — "Continuous Discovery Habits" (2021), producttalk.org

**Structure:**
```
Desired Outcome
  └── Opportunity 1 (unmet need / pain / desire)
        └── Solution A
              └── Assumption Test
        └── Solution B
              └── Assumption Test
  └── Opportunity 2
        └── Solution C
              └── Assumption Test
```

**Key discipline:** Never jump from outcome to solution. Always map through opportunities first. An opportunity is something you learned from a customer, not something you invented.

**Why it matters for demand-side thinking:** Forces the team to distinguish between customer opportunities (demand) and solutions (supply). Prevents the most common failure mode: building solutions without understanding the opportunity they address.

**Confidence:** HIGH — published book, Teresa Torres is the current practitioner authority on continuous discovery

---

## Core Framework 4: Feature Prioritization

### RICE (Intercom's method)

**Source:** Intercom product team, ~2016

```
RICE Score = (Reach × Impact × Confidence) / Effort
```

| Factor | Definition | Unit |
|--------|-----------|------|
| Reach | How many users affected in a time period | Users/period |
| Impact | How much it moves the metric (0.25=minimal to 3=massive) | Multiplier |
| Confidence | How certain you are (100%=high, 50%=low) | % |
| Effort | Person-months to build | Person-months |

**Best for:** Teams with user data, comparing features across a roadmap. Requires "Reach" data to be meaningful. Falls apart for 0→1 products with no user base.

---

### ICE (Sean Ellis's method)

**Source:** Sean Ellis (GrowthHackers), ~2012

```
ICE Score = Impact + Confidence + Ease (each rated 1-10)
```

**Best for:** Early-stage, rapid experimentation, growth experiments. No user base required — all estimates. Fast but noisier than RICE.

**Honest limitation:** Highly subjective. Two people rating the same feature can produce 30-point differences. Use for relative ranking within a session, not cross-team or cross-time comparison.

---

### Ulwick's Opportunity Scoring (ODI method)

**Source:** Tony Ulwick, Strategyn — strategyzer.com and strategyn.com

```
Opportunity Score = Importance + max(0, Importance − Satisfaction)
(both rated 1-10 by customers)
```

**Best for:** When you have customer survey data and need to find where to innovate. Surfaces the needs that matter most and are least served. Most rigorous of the three — grounded in customer data, not internal estimates.

**Confidence:** HIGH for all three — cited primary sources

---

## Core Framework 5: Go/Kill Decision Criteria

### Stage-Gate (Cooper's original framework, startup-adapted)

**Source:** Robert G. Cooper — "Winning at New Products" (1986/2011), stage-gate.com

**Gate criteria for early-stage founders (stripped down):**

| Gate | Trigger | Kill criteria |
|------|---------|--------------|
| Gate 1: Idea | Idea generated | No named customer with active pain |
| Gate 2: Scope | Discovery done | No evidence of demand, no unit economics path |
| Gate 3: Build | Scope locked | Customer interviews contradicted hypothesis |
| Gate 4: Validate | Built | No one will pay; retention < threshold |
| Gate 5: Scale | Validation done | CAC > LTV; no repeatable acquisition |

**Key principle:** Define kill criteria BEFORE the gate, not after. Confirmation bias prevents killing at the gate if criteria aren't pre-committed.

**Standard gate outcomes:** Go, Kill, Hold (pause for conditions), Recycle (rework then re-gate)

---

### The 40% Rule (Rahul Vohra / Sean Ellis PMF test)

**Source:** Sean Ellis, Superhuman's Rahul Vohra — published in "How Superhuman Built an Engine to Find Product/Market Fit" (First Round Review, 2019)

**Method:** Survey customers: "How would you feel if you could no longer use [product]?" If 40%+ say "very disappointed," you have signal for PMF.

**Limitation:** Requires existing users. Pre-product, use JTBD switch interviews and willingness-to-pay tests instead.

---

### Demand-Side Kill Signals (founder-specific synthesis)

Based on Christensen, Moesta, and Ellis across sources:

| Signal | Interpretation |
|--------|---------------|
| No one can articulate the struggling moment | No push force — demand doesn't exist |
| Users understand the job but not your solution | Positioning problem, not demand problem |
| Users know the job, understand the solution, still won't pay | Economics problem or wrong segment |
| Customers love it but won't refer | Weak pull force — not actually transformative |
| Retention drops after first session | Job story was wrong — product doesn't deliver the progress |

---

## Framework Decision Matrix

Which framework to apply when:

| Situation | Use This | Why |
|-----------|----------|-----|
| Pre-product, 0 customers | Christensen/Moesta JTBD interviews | Need to discover the struggling moment |
| Have customers, want to find opportunities | Ulwick Opportunity Scoring | Quantifies where importance > satisfaction |
| Writing product requirements | Klement Job Stories | Forces circumstance + motivation + outcome |
| Designing the value prop | Osterwalder VPC | Structures jobs/pains/gains → pain relievers/gain creators |
| Classifying features to build | Kano Model | Must-be vs performance vs delighter |
| Choosing which features to ship next | RICE (with data) / ICE (without data) | Prioritizes across a list |
| Mapping discovery to solutions | Torres Opportunity Solution Tree | Prevents solution-first thinking |
| Deciding to kill or continue | Stage-Gate + 40% rule | Pre-committed criteria prevent bias |

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Ulwick Opportunity Scoring | Net Promoter Score (NPS) | NPS is better for tracking satisfaction over time; opportunity scoring is better for finding where to build |
| Klement Job Stories | User Stories ("As a [persona]...") | User Stories are fine for implementation; Job Stories are better for discovery because they include the circumstance |
| Torres OST | Feature roadmap backlog | OST when you need to stay rooted in customer opportunities; backlog when execution is sorted and you just need prioritization |
| JTBD Switch Interviews | Customer surveys | Surveys for scale; interviews for depth and discovering the struggling moment |
| Four Forces analysis | Competitive analysis | Four Forces is demand-side; competitive analysis is supply-side. Both useful but different questions |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Persona-based requirements | Personas describe who, not why. They don't predict switching behavior. | Job Stories with struggling moment |
| Generic "pain/gain" frameworks without job context | "Pain" without knowing the job creates solutions for symptoms, not causes | Osterwalder VPC grounded in JTBD interviews first |
| ICE scoring as the only prioritization method | High subjectivity, gameable, no grounding in actual customer data | Pair ICE with Opportunity Scoring or validate ratings with interview data |
| Surveys before qualitative interviews | Surveys confirm hypotheses; interviews generate them. Surveying before interviewing optimizes for the wrong question. | Switch interviews first, surveys to validate at scale |
| Roadmap-driven discovery | Roadmaps express supply-side commitments. They suppress demand signals. | Torres OST as the discovery artifact; roadmap only for committed execution |

---

## Framework Patterns by Use Case

**If pre-product, building from scratch:**
- Start with switch interviews (Moesta timeline method)
- Extract struggling moments → Job Stories (Klement format)
- Map job stories to VPC (Osterwalder)
- Use Kano to classify what table stakes exist vs where you can differentiate

**If post-product, finding growth opportunities:**
- Survey customers with Ulwick importance/satisfaction pairs
- Calculate opportunity scores → rank by score
- Map top opportunities to OST (Torres)
- Prioritize solutions with RICE (if data) or ICE (if not)

**If evaluating whether to kill a feature:**
- Check: does this address a struggling moment? (Christensen/Moesta)
- Check: what is the opportunity score for the underlying job? (Ulwick)
- Check: is this Must-Be, Performance, or Delighter? (Kano)
- Kill if: Must-Be that's already "good enough," low opportunity score, or no struggling moment mapped to it

**If repositioning an existing product:**
- Re-run switch interviews with recent adopters
- Re-map Four Forces — what changed in push/pull?
- Re-run VPC — do pain relievers still address top pains?

---

## Sources

- Christensen, C. — "Competing Against Luck" (2016) — JTBD theory, four forces origin
- Moesta, B. — "Demand-Side Sales 101" (2020) — Switch interview methodology, demand-side framing
- Klement, A. — "When Coffee and Kale Compete" (2016) — Job Story format, struggling moment, jtbd.info
- Ulwick, T. — "Jobs to Be Done: Theory to Practice" (2016) — ODI, opportunity algorithm, strategyn.com
- Osterwalder, A. et al. — "Value Proposition Design" (2014) — VPC template, fit definition, strategyzer.com
- Torres, T. — "Continuous Discovery Habits" (2021) — OST framework, producttalk.org
- Kano, N. — "Attractive Quality and Must-Be Quality" (1984) — Feature classification model
- Cooper, R.G. — "Winning at New Products" (1986/2011) — Stage-Gate, go/kill criteria, stage-gate.com
- Ellis, S. / Vohra, R. — First Round Review (2019) — 40% PMF rule
- gopractice.io — JTBD framework comparison (verified, MEDIUM confidence on synthesis)
- [GoPractice JTBD comparison](https://gopractice.io/product/jobs-to-be-done-the-theory-and-the-frameworks/) — Christensen/Moesta/Ulwick comparison
- [Ulwick opportunity algorithm](https://www.marketingjournal.org/the-path-to-growth-the-opportunity-algorithm-anthony-ulwick/) — Formula verification
- [Strategyzer VPC template](https://www.strategyzer.com/library/the-value-proposition-canvas) — Official canvas
- [Teresa Torres OST](https://www.producttalk.org/opportunity-solution-trees/) — Canonical OST reference
- [RICE scoring model](https://www.productplan.com/glossary/rice-scoring-model/) — Formula and components
- [Bob Moesta on JTBD interviews](https://www.june.so/blog/how-to-run-a-jtbd-interview-like-the-co-creator-of-the-framework) — Switch interview methodology

---
*Stack research for: Demand-side product thinking frameworks (founder-os v2.0)*
*Researched: 2026-03-25*
