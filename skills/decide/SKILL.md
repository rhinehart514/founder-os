---
name: decide
description: "The go/kill/pivot gate. Forces a decision on an idea with explicit evidence, confidence level, and reasoning. The most important skill — speed of kill is the serial entrepreneur's edge."
argument-hint: "[idea-name]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent
---

# /decide — Go, Kill, Park, or Pivot

This is the most important skill in founder-os. Serial entrepreneurs win by
deciding faster, not by researching deeper.

## How It Works

### Step 1: Gather All Evidence

Read everything about the idea:
- `config/portfolio.yml` → idea spec, hypotheses, evidence
- `~/.claude/knowledge/predictions.tsv` → predictions about this idea
- `~/.claude/knowledge/experiment-learnings.md` → relevant patterns
- `.claude/cache/last-research.yml` → latest research
- Check mind/patterns.md → any active failure patterns

### Step 2: Evidence Assessment

For each dimension (market/model/moat), assess:

```
### Market Evidence
Evidence FOR:
- [evidence] — source, strength (strong/moderate/weak)
Evidence AGAINST:
- [evidence] — source, strength
Verdict: [supported / mixed / unsupported / unknown]

### Model Evidence
[same structure]

### Moat Evidence
[same structure]
```

### Step 3: Pattern Check

Run through the 10 failure patterns. Flag any that are active.
Check against Dead Ends in experiment-learnings.md.

### Step 4: Spawn Founder Coach

```
Agent(subagent_type: "founder-os:founder-coach", prompt: "Decision check for [idea].
Portfolio state: [summary]. Evidence: [summary]. Active patterns: [list].
Is the founder seeing this clearly? Any blind spots?")
```

### Step 5: The Decision

Present as a clear recommendation:

```
  DECISION: [GO / KILL / PARK / PIVOT]
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  confidence   [X]%

  market       [██████░░░░]  [verdict]
  model        [████░░░░░░]  [verdict]
  moat         [██░░░░░░░░]  [verdict]

  FOR this idea:
  - [strongest evidence point]
  - [second strongest]

  AGAINST this idea:
  - [strongest counter-evidence]
  - [second strongest]

  ⚠ [any active failure patterns]

  coach says:  [founder-coach assessment, 1-2 sentences]

  → [ONE next action]
     GO: "Build the wedge. Start with /discover refine to sharpen the spec, then build."
     KILL: "Kill it. Update the model. Run /ideate for the next idea."
     PARK: "Park it. Revisit when [condition]. Focus on [other idea] instead."
     PIVOT: "Pivot to [new direction]. Run /discover pivot."
```

### Step 6: Record the Decision

Update `config/portfolio.yml`:
```yaml
  stage: [committed/killed/parked]
  decision:
    date: [today]
    verdict: [go/kill/park/pivot]
    confidence: [X]%
    reasoning: [1-2 sentences]
    evidence_for: [list]
    evidence_against: [list]
    patterns: [list]
```

Log prediction about the decision outcome:
```
I predict [idea] will [succeed/fail at next stage] because [reasoning].
I'd be wrong if [condition].
```

### Step 7: Model Update

If KILL or PIVOT:
- What did we learn that applies to future ideas?
- Update experiment-learnings.md with the pattern
- Move from Uncertain → Known or add to Dead Ends as appropriate

---

## Decision Framework

### GO when:
- Named customer exists AND would pay
- Unit economics work on paper
- Wedge can be built in weeks
- Kill condition tested (not necessarily resolved, but tested)
- No active fatal failure patterns

### KILL when:
- Kill condition confirmed
- No customer found after 2+ weeks
- Unit economics broken even optimistically
- Matches a confirmed dead end
- Founder can't articulate why this is different

### PARK when:
- Thesis is sound but timing is wrong
- Market is forming but no active pain yet
- Better idea in portfolio deserves the attention

### PIVOT when:
- Customer real, problem different
- Problem real, customer different
- Demand exists, model doesn't fit

---

## Rules

- Always recommend. Never "it depends." The founder can override, but you have a position.
- Confidence < 50% → explicitly say "this is a coin flip, here's what would raise confidence"
- If evidence is missing, the decision is "research X, then decide" — not "it's unclear"
- The founder makes the final call. You provide the clearest possible basis for that call.

## State Reads
- `config/portfolio.yml`
- `~/.claude/knowledge/experiment-learnings.md`
- `~/.claude/knowledge/predictions.tsv`
- `.claude/cache/last-research.yml`

## State Writes
- `config/portfolio.yml` — decision record, stage update
- `~/.claude/knowledge/predictions.tsv` — decision prediction
- `~/.claude/knowledge/experiment-learnings.md` — model update on kill/pivot
