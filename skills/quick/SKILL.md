---
name: quick
description: "Ad-hoc task execution without full /plan → /go ceremony. Lightweight plan (1-3 tasks), immediate execution, still logs predictions and measures before/after. Use for tasks that don't need roadmap-level planning."
argument-hint: "[task description] [--discuss] [--research]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, AskUserQuestion, WebSearch, WebFetch
---

!tail -3 ~/.claude/knowledge/predictions.tsv 2>/dev/null || echo "no predictions"
!command -v jq &>/dev/null && cat .claude/cache/eval-cache.json 2>/dev/null | jq 'to_entries | map({key, score: .value.score}) | from_entries' 2>/dev/null || echo "no eval cache"

# /quick — Ad-hoc Task Execution

For tasks that don't need the full /plan → /go cycle. "Just do this one thing well."

## What this skill changes about your default behavior

You tend to:
- Over-plan small tasks — spinning up full bottleneck analysis for a 10-minute fix
- Skip measurement on "small" changes — but small changes compound into regressions
- Forget to predict — even a quick task has a hypothesis worth logging
- Lose context on what changed — no record of ad-hoc work

Read `gotchas.md` before starting any quick task.

## Skill folder structure

- `gotchas.md` — failure modes for quick execution. **Read before starting.**

## Routing

Parse `$ARGUMENTS`:

| Input | Behavior |
|-------|----------|
| `[description]` | Plan and execute immediately |
| `[description] --discuss` | Surface gray areas first, then plan and execute |
| `[description] --research` | Investigate approaches first, then plan and execute |
| `[description] --discuss --research` | Discuss, then research, then plan and execute |
| (no args) | Ask what the user wants done |

Flags are composable. Parse them out of `$ARGUMENTS`, remainder is `$DESCRIPTION`.

---

## Step 1: Get the task

If `$DESCRIPTION` is empty after parsing flags, ask:

```
AskUserQuestion(
  header: "Quick Task",
  question: "What do you want done?",
  followUp: null
)
```

If still empty after response, re-prompt.

---

## Step 2: Snapshot baseline

Before any work, capture current state for before/after comparison:

```bash
# Capture baseline scores if eval-cache exists
cat .claude/cache/eval-cache.json 2>/dev/null > /tmp/quick-baseline.json
# Capture git state
git rev-parse --short HEAD > /tmp/quick-baseline-commit.txt
git diff --stat > /tmp/quick-baseline-diff.txt 2>/dev/null
```

Read `gotchas.md` now.

---

## Step 3: Predict

Every task has a hypothesis. Before any planning or building:

```
I predict [specific outcome of this task] because [evidence or reasoning].
I'd be wrong if [what would disprove this].
```

Log to `~/.claude/knowledge/predictions.tsv`:
```
date	prediction	evidence	result	correct	model_update
```

Leave `result`, `correct`, `model_update` empty — they get filled after measurement.

---

## Step 4: Discussion phase (only when --discuss)

Skip entirely if not `--discuss`.

**4a. Identify gray areas**

Analyze `$DESCRIPTION` to identify 2-4 gray areas — implementation decisions that
would change the outcome. Use domain-aware heuristics:

- Something users **SEE** → layout, density, interactions, states
- Something users **CALL** → responses, errors, auth, versioning
- Something users **RUN** → output format, flags, modes, error handling
- Something users **READ** → structure, tone, depth, flow
- Something being **ORGANIZED** → criteria, grouping, naming, exceptions

Each gray area: a concrete decision point, not a vague category.

**4b. Present and discuss**

```
AskUserQuestion(
  header: "Gray Areas",
  question: "Which areas need clarification?",
  options: [
    { label: "${area_1}", description: "${why_it_matters}" },
    { label: "${area_2}", description: "${why_it_matters}" },
    { label: "All clear", description: "Skip — I know what I want" }
  ],
  multiSelect: true
)
```

If "All clear" → skip to Step 5.

For each selected area, ask 1-2 focused questions with concrete options.
Max 2 questions per area. This is lightweight, not a deep dive.

Collect decisions into `$DECISIONS` for the planning step.

---

## Step 5: Research phase (only when --research)

Skip entirely if not `--research`.

Spawn a focused researcher:

```
Agent(subagent_type: "founder-os:explorer", prompt: "
Focused research for quick task: ${DESCRIPTION}

${DECISIONS ? 'User decisions: ' + DECISIONS : ''}

Investigate:
1. Best libraries/patterns for this specific task
2. Common pitfalls and how to avoid them
3. Integration points with existing codebase
4. Constraints or gotchas worth knowing

This is a quick task — target 1-2 pages of actionable findings, not a full survey.
Report findings directly.
")
```

Store findings as `$RESEARCH` for the planning step.

---

## Step 6: Plan

Create a lightweight plan — 1-3 tasks maximum.

Read the current codebase state:
- What files will be touched?
- What's the current structure/convention?
- Are there tests to update?

The plan is NOT a document to write to disk. It's your working plan:

```
Quick Task: ${DESCRIPTION}

Tasks:
1. [specific action] → [files] → [verify how]
2. [specific action] → [files] → [verify how]
3. [specific action] → [files] → [verify how]

${DECISIONS ? 'Locked decisions: ' + DECISIONS : ''}
${RESEARCH ? 'Research context: ' + RESEARCH : ''}
```

Present the plan to the user briefly:
```
  ◆ quick  ·  ${DESCRIPTION}
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  tasks    ${task_count} planned
  ${DECISIONS ? 'decisions  locked from discussion' : ''}
  ${RESEARCH ? 'research   informed by explorer' : ''}

  1. ${task_1_summary}
  2. ${task_2_summary}
  ${task_3 ? '3. ' + task_3_summary : ''}

  → executing now
```

---

## Step 7: Execute

Spawn the builder agent with worktree isolation:

```
Agent(subagent_type: "founder-os:builder", prompt: "
Execute this quick task:

${plan_from_step_6}

Constraints:
- Atomic commits — one per task
- Follow existing code conventions
- Run tests if they exist
- Do NOT modify eval harness files (score.sh, eval.sh, taste.mjs)

Report: what changed, which files, commit hashes.
", isolation: "worktree")
```

If the task is small enough (1 task, <3 files), execute inline instead of spawning.

**Decision heuristic for inline vs agent:**
- 1 task, clear scope, <3 files → execute inline
- 2+ tasks, or unclear scope, or touching >3 files → spawn builder

---

## Step 8: Measure after

Compare before/after:

```bash
# Check if scores changed
cat .claude/cache/eval-cache.json 2>/dev/null > /tmp/quick-after.json
# Check assertions
bash lens/product/eval/assertions.sh 2>/dev/null || echo "no assertions"
```

If assertions regressed (was passing, now failing) → revert the commit. No negotiation.

If scores dropped meaningfully (>5 points on any feature) → flag it, suggest revert.

---

## Step 9: Grade prediction

Go back to the prediction from Step 3. Now that the task is done:
- Was the prediction correct?
- If not, why?
- What does this update in the model?

Update `~/.claude/knowledge/predictions.tsv` with result, correct, model_update.

---

## Step 10: Output

```
  ◆ quick  ·  complete
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  task     ${DESCRIPTION}
  commits  ${commit_count} (${commit_hashes})
  files    ${files_changed}
  ${score_delta ? 'score    ' + before + ' → ' + after : ''}
  ${assertion_status ? 'assert   ' + assertion_status : ''}

  prediction: ${correct/partial/wrong}
  ${model_update ? '→ model: ' + model_update : ''}

  → ${next_action}
```

The next action should be context-aware:
- If score dropped → "revert with `git revert ${hash}`"
- If new assertions needed → "/assert add [what]"
- If this was part of a larger effort → "continue with /go [feature]"
- If standalone → done, no trailing suggestions

---

## State Reads

| File | What it tells you |
|------|-------------------|
| `.claude/cache/eval-cache.json` | Current feature scores for before/after |
| `~/.claude/knowledge/predictions.tsv` | Active predictions |
| `~/.claude/knowledge/experiment-learnings.md` | Known patterns |
| `config/founder.yml` | Feature names (optional) |

## State Writes

- `~/.claude/knowledge/predictions.tsv` — new prediction + grade
- `~/.claude/knowledge/experiment-learnings.md` — if prediction was wrong, update model

## Agent usage

- **founder-os:explorer** — research phase only (--research flag)
- **founder-os:builder** — execution (multi-task or complex scope)
- Inline execution for trivial tasks (1 task, <3 files)

## System integration

**Triggers:** /go (when task is too small for full loop), /plan (when scope is ad-hoc)
**Triggered by:** "just do this", "quick fix", "can you just", ad-hoc requests that don't need roadmap planning

## Self-evaluation

/quick succeeded if:
- Prediction was logged before any work started
- Baseline was captured before changes
- Each task was committed atomically
- Assertions didn't regress (or regression was reverted)
- Prediction was graded after completion
- Output shows before/after delta

## Cost note

- Base: inline execution, ~5k tokens
- --discuss: +1-2 AskUserQuestion rounds
- --research: +1 explorer agent (~20k tokens)
- Builder agent when spawned: ~30k tokens

## What you never do

- Skip the prediction — even "I predict this takes 1 commit" is a prediction
- Skip baseline capture — you can't measure what you didn't snapshot
- Skip assertion check after changes — regressions compound
- Over-plan — if you're writing a 10-task plan, use /go instead
- Modify eval harness files
- Auto-accept score drops — flag them, let the founder decide

## If something breaks

- No eval-cache → skip before/after score comparison, still check assertions
- No predictions.tsv → create it with the first prediction
- Builder agent fails → fall back to inline execution
- Assertions script missing → skip assertion check, note the gap
- Research returns nothing useful → proceed without research context, note the gap

$ARGUMENTS
