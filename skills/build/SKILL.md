---
name: build
description: "Build the product once you've committed. Creates projects, scaffolds apps, and ships MVPs using Claude Code's full capabilities. The bridge from validation to code."
argument-hint: "[idea-name | scaffold | ship | status]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebFetch, WebSearch
---

# /build — From Decision to Product

You only get here after /decide says GO. This skill bridges validation to implementation.
It uses Claude Code's native building capabilities but keeps the founder-os measurement
loop active.

## Routing

Parse `$ARGUMENTS`:

- **`[idea-name]`** → `PLAN` mode (create build plan from spec)
- **`scaffold [idea]`** → `SCAFFOLD` mode (generate project structure)
- **`ship [idea]`** → `SHIP` mode (prepare for deployment)
- **`status [idea]`** → `STATUS` mode (where is the build?)
- **No args** → show committed ideas ready to build

---

## PLAN Mode — "/build [idea-name]"

### Prerequisites
1. Read `config/portfolio.yml` — verify idea stage is `committed`
2. If not committed: "Run /decide [idea] first. Don't build what you haven't validated."

### Step 1: Extract Build Spec from Validation

From the idea's portfolio entry, derive:
- **Wedge scope**: The smallest thing that delivers value to the named customer
- **Tech requirements**: What stack fits the wedge? (infer from customer type + product type)
- **Must-have features**: Only what the wedge requires. Nothing else.
- **Success metric**: How do we know the wedge works? (one metric, from hypotheses)
- **Kill metric**: What would prove the wedge failed? (from kill_condition)

### Step 2: Create Build Plan

```yaml
# .claude/plans/build-[idea-slug].yml
idea: [name]
wedge: [one sentence]
customer: [from portfolio]
success_metric: [one metric]
kill_metric: [one metric]

phases:
  - name: scaffold
    tasks:
      - [task]: [description]
    done_when: "project runs locally"

  - name: core
    tasks:
      - [task]: [description]
    done_when: "[success metric is measurable]"

  - name: ship
    tasks:
      - [task]: [description]
    done_when: "customer can use it"

tech:
  stack: [framework, language, platform]
  rationale: [why this stack for this customer]
```

### Step 3: Log Prediction

```
I predict the wedge can be built in [X] sessions because [evidence].
I'd be wrong if [complexity I'm not seeing].
```

Present the plan. Founder approves, then scaffold.

---

## SCAFFOLD Mode — "/build scaffold [idea]"

Generate the project:
1. Create project directory (under the idea slug)
2. Initialize with appropriate stack (Next.js, Vite, CLI, API — based on plan)
3. Set up basic structure per the build plan
4. Initialize git
5. Create CLAUDE.md with project context from portfolio

The scaffolded project should be runnable immediately (`npm run dev` or equivalent).

---

## SHIP Mode — "/build ship [idea]"

Prepare for first customer:
1. Check build status against plan
2. Verify success metric is measurable
3. Deploy (Vercel, or appropriate platform)
4. Create a way for the customer to access it
5. Update portfolio stage to `shipped`

Log prediction:
```
I predict [customer] will [use it / pay / retain] because [evidence].
I'd be wrong if [the wedge doesn't actually solve their problem].
```

---

## STATUS Mode — "/build status [idea]"

Show build progress:
- Phase: [scaffold/core/ship]
- Tasks: [done/total]
- Time spent: [sessions]
- Prediction accuracy on build estimates
- Blockers or unknowns

---

## The Measurement Bridge

While building, maintain the founder-os loop:
- Every build session starts with a prediction
- After each session, check: did the build prediction hold?
- If the build is taking longer than predicted, ask why (scope creep? wrong stack? wedge too big?)
- If customer feedback arrives during build, route to /discover refine

The build is a HYPOTHESIS TEST, not a project plan.

---

## State Reads
- `config/portfolio.yml` — idea spec
- `.claude/plans/build-*.yml` — existing build plans

## State Writes
- `.claude/plans/build-[slug].yml` — build plan
- `config/portfolio.yml` — stage updates
- `~/.claude/knowledge/predictions.tsv` — build predictions
