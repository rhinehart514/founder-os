# /product Reference — Output Templates

Loaded on demand. Lenses and protocol are in SKILL.md.

---

## New idea mode

```
◆ product — "I want to build a CLI tool that measures product quality for solo founders"

▾ what I heard
  A CLI tool that tells solo founders if their product is getting better.
  Not code health — product quality. For people building alone who need
  an honest signal.

▾ market reality (WebSearch, 90 seconds)
  · exists: linters (ESLint), CI tools (GitHub Actions), code quality (SonarQube)
    — all measure code health, none measure product value delivery
  · adjacent: Linear Insights (project-level metrics), PostHog (product analytics)
    — both require users/data. This targets pre-traction stage.
  · failed: several "AI code review" tools pivoted — market wants more than review
  · complaints: HN thread (2025-11): "I shipped 50 PRs and have no idea if my
    product is better." 340 upvotes. Pain is real.

  verdict: validated gap. Nobody measures features against claims.
  differentiator: value measurement at pre-traction stage.

▾ the person
  "A solo founder who just pushed code and wants to know if their product
  got better. Uses Claude Code. No team to review. Has tried linters but
  those tell them the code is clean, not that the product is good."

  Is this specific enough? [Yes, continue] / [Let me refine]

▾ assumptions (ranked by risk × ignorance)
  1. **Solo founders want measurement** — risk:4 × ignorance:3 = 12
     HN thread suggests yes. But wanting ≠ paying/using.
     test: can we get 1 person to use it for a week?

  2. **LLMs can judge feature quality** — risk:5 × ignorance:2 = 10
     Early evidence: eval engine works internally. But ~15pt variance.
     test: run eval on 3 external projects, check if scores feel right

  3. **CLI is the right form factor** — risk:3 × ignorance:3 = 9
     Claude Code plugin reduces this. But CLI-in-CLI is weird.
     test: does /onboard → /eval feel natural?

  4. **Assertions replace testing** — risk:3 × ignorance:4 = 12
     Untested. Developers are used to tests, not beliefs.
     test: does a stranger understand beliefs.yml?

▾ value hypothesis (draft)

  hypothesis: "Solo founders can measure whether their product is delivering
  value — not just whether the code is clean — using per-feature assertions
  that Claude judges against the actual code"

  user: "Solo founder building with Claude Code, no team, wants honest signal"

  signals:
    - score_improves: "Score goes up when real product improvements are made"
    - external_loop: "Someone outside the team completes /onboard → /eval → /go"
    - assertions_useful: "Founder adds assertions naturally, not as a chore"

  [Edit] / [Approve]

⎯⎯ verdict ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  The gap is real — nobody measures product value at pre-traction. The HN
  thread and competitive whitespace confirm demand. Biggest risk is #4:
  "assertions replace testing" is a bet that developers will adopt a new
  mental model. Test this first — if strangers don't understand beliefs.yml,
  nothing else matters.

  v1.0 thesis: "One stranger can go from /onboard to an improved score
  without help."

/onboard           bootstrap with this hypothesis
/research "developer mental models for product assertions"
/ideate            brainstorm the specific features
```

## Existing product — full session (stage one)

```
◆ product — founder-os

  product: **64%** · score: 95 · stage: **one**
  thesis: "Someone who isn't us can complete a loop without help"

⎯⎯ who ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  entry: GitHub README → git clone → install.sh → /onboard
  friction: 1-install (2/5) → 2-first-command (3/5) → 3-understand-output (4/5)
  drop-off: **step 2** — after install, user sees a score but doesn't
  know what to do. No guided path from /onboard to /plan.

  research: CLI onboarding best practices (WebSearch) → "progressive
  disclosure works: show one action, not a menu" (Netlify CLI, Stripe CLI)

  gap: need guided next-step after /onboard → /ideate

⎯⎯ assumptions ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  1. **Solo founders want autonomous measurement** — risk:4 × ignorance:3 = 12
     Known Pattern confirms: "value score motivates, health score doesn't"
     BUT: 0 external users have confirmed this
     research: [no external validation yet — this is the thesis]

  2. **The prediction loop produces real learning** — risk:4 × ignorance:2 = 8
     63% accuracy, 10/16 graded. Loop works internally.
     BUT: does it work for someone who didn't build the system?

  3. **Commands are discoverable** — risk:3 × ignorance:3 = 9
     Cross-recommendations exist. Never tested on a stranger.

  gap: all top assumptions require external testing → /research

⎯⎯ pitch ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  elevator: "founder-os measures whether your product is delivering what
  you promised — not just whether the code compiles."
  tweet: "Your linter says the code is clean. But is your product better?
  founder-os scores features against claims. For solo founders in Claude Code."
  hero: "Know if your product is actually improving."
        "Per-feature scoring that measures value, not health."

  clarity: **pass** — names the person, states the difference, specific
  cross-check with narrative.yml: **match** ✓

⎯⎯ coherence ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  code vs claims: eval-cache shows 7 features avg 49/100 but score is 95
    ⚠ **disconnect** — assertion pass rate (95) and generative quality (49)
    tell different stories. The score is honest but confusing.

  narrative vs reality: narrative claims "tested on external projects"
    roadmap shows commander.js init→score only. Full loop untested.
    ⚠ **disconnect** — narrative overstates evidence

  README vs product: README describes 17 commands, accurate.
    ✓ **aligned**

⎯⎯ verdict ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  product clarity: **7/10**
  stage: one — no external users
  biggest risk: all assumptions untested externally
  biggest disconnect: narrative claims external validation that doesn't exist yet
  drop-off: step 2 — user sees score, doesn't know what to do next

  "The product knows what it is and the code delivers it internally. But
  you're at stage one and every assumption depends on 'does this work for
  someone else.' The score says 95 but the product has 0 external users.
  Until someone else completes the loop, the score is measuring your
  confidence, not your product."

/onboard [external-project]   the one thing that matters
/research "onboarding flow"   fix the drop-off point first
/ideate                       brainstorm from the gaps
```

## Single lens: `/product assumptions`

```
◆ product assumptions — 6 assumptions, 2 high-risk

  ⚠ 1. Solo founders want autonomous measurement   risk:4 × ign:3 = **12**
     evidence: HN thread (anecdotal), internal usage (tested)
     competitors validate demand but not this specific mechanism
     test: 1 external user completes the loop

  ⚠ 2. Assertions replace testing                  risk:3 × ign:4 = **12**
     evidence: none — beliefs.yml is novel, never tested on strangers
     test: stranger creates an assertion without guidance

  · 3. Commands are discoverable                    risk:3 × ign:3 = **9**
     evidence: cross-recommendations exist (tested internally)

  · 4. Prediction loop compounds                    risk:4 × ign:2 = **8**
     evidence: 63% accuracy (tested), but only internally

  · 5. LLMs can judge feature quality               risk:5 × ign:2 = **10**
     evidence: eval engine works, ~15pt variance (tested)

  · 6. Plugin install is frictionless               risk:2 × ign:2 = **4**
     evidence: commander.js install worked (tested)

  top risk: **#1 and #2 are both untested externally**
  recommendation: test #2 first — if strangers don't get assertions,
  nothing downstream works

/research "developer mental models for assertions"
/go commands    fix the drop-off before external testing
/strategy       check if this changes the bottleneck
```

## Single lens: `/product coherence`

```
◆ product coherence — 2 disconnects

  ▾ code vs claims
    ✓ scoring: delivers "honest number" — eval confirms (58/100)
    ✓ commands: delivers "intent routing" — 17 commands working
    ⚠ learning: claims "gets smarter every session" — craft_score 40,
       grading is manual, no automatic improvement mechanism
       **the claim overstates the code**

  ▾ narrative vs evidence
    narrative.yml says: "tested on 2 external projects"
    roadmap.yml shows: commander.js init→score (partial), full loop untested
    ⚠ **narrative overstates evidence** — update narrative or prove the claim

  ▾ README vs product
    ✓ feature list matches founder.yml
    ✓ install instructions match install.sh
    ⚠ README says "autonomous build loop" — /go is BETA, untested externally

  ▾ pitch vs positioning
    pitch says: "measures whether your product is delivering"
    positioning says: "no retention data, /go untested externally"
    ⚠ pitch assumes things positioning admits are unproven

  disconnects: **3** — learning claim, narrative evidence, /go maturity

  recommendation: either downgrade claims or prove them. Don't ship
  a narrative that the evidence doesn't support.

/roadmap narrative   regenerate from proven evidence only
/go learning         close the learning quality gap
/eval blind          honest cold-read of what code actually delivers
```

## Formatting rules

- Header: `◆ product — [project name or idea description]`
- New idea mode: market reality → person → assumptions → hypothesis → verdict
- Existing product: stage-appropriate lenses → synthesis → verdict
- Each lens uses labeled `⎯⎯` dividers per OUTPUT_FORMAT.md
- Assumptions ranked by risk × ignorance score, highest first
- Coherence check: ✓ aligned / ⚠ disconnect for each pair
- Verdict: product clarity score, stage, biggest risk, biggest disconnect, drop-off, opinionated paragraph
- Anti-sycophancy: no "promising," no "solid foundation," no "good progress"
- Every claim in verdict must cite evidence
- Bottom: exactly 3 next commands
