---
name: pause
description: "Intentional session handoff — captures what's in progress, what's done, blockers, decisions, and active predictions. Creates HANDOFF.json that /pause resume reads to restore context. Also handles resume."
argument-hint: "[resume]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
---

!cat .claude/cache/HANDOFF.json 2>/dev/null | head -5 || echo "no active handoff"
!tail -3 ~/.claude/knowledge/predictions.tsv 2>/dev/null || echo "no predictions"

# /pause — Session Handoff

Creates structured handoff state when stopping mid-session, and restores it when
resuming. Better than an automatic hook because it's intentional — you capture what
matters, not what's mechanical.

## What this skill changes about your default behavior

You tend to:
- Lose context between sessions — next session starts from zero
- Forget active predictions — ungraded predictions are wasted predictions
- Miss in-progress decisions — "we were going to..." is lost
- Assume the next session has the same context window — it doesn't

## Routing

Parse `$ARGUMENTS`:

| Input | Behavior |
|-------|----------|
| (no args) | PAUSE — create handoff state |
| `resume` | RESUME — restore from handoff |
| plain text | PAUSE — treat text as context notes |

---

## PAUSE Mode

### Step 1: Gather state

Read current project state in parallel:

```bash
# Current git state
git log --oneline -5
git status --short
git diff --stat

# Active plans and todos
cat .claude/plans/todos.yml 2>/dev/null
cat .claude/plans/plan.yml 2>/dev/null

# Active predictions
tail -10 ~/.claude/knowledge/predictions.tsv 2>/dev/null

# Eval state
cat .claude/cache/eval-cache.json 2>/dev/null

# Product state
cat config/founder.yml 2>/dev/null
```

### Step 2: Ask for context

```
AskUserQuestion(
  header: "Pausing Session",
  question: "Anything to capture that isn't in the code?",
  options: [
    { label: "Nope — code tells the story", description: "I'll capture from git and project state" },
    { label: "Let me add context", description: "I'll ask a follow-up" }
  ]
)
```

If "Let me add context" → follow up with freeform question about what's in their head.

### Step 3: Identify active work

From the gathered state, determine:

1. **What was being worked on** — current feature, active plan tasks, recent commits
2. **What's done** — completed tasks, passing assertions, committed work
3. **What's remaining** — open todos, unfinished plan tasks, known gaps
4. **Active predictions** — ungraded predictions from predictions.tsv
5. **Blockers** — anything stuck, waiting on external input, or needing decisions
6. **Uncommitted changes** — modified files not yet committed

### Step 4: Write HANDOFF.json

```bash
mkdir -p .claude/cache
```

Write `.claude/cache/HANDOFF.json`:

```json
{
  "version": "1.0",
  "created": "YYYY-MM-DDTHH:MM:SS",
  "status": "paused",
  "working_on": {
    "feature": "feature name or null",
    "task": "current task description",
    "plan_ref": "plan.yml task number or null"
  },
  "completed": [
    { "description": "what got done", "commit": "short hash" }
  ],
  "remaining": [
    { "description": "what's left", "priority": "high|medium|low" }
  ],
  "active_predictions": [
    {
      "prediction": "text from predictions.tsv",
      "evidence": "evidence",
      "status": "ungraded"
    }
  ],
  "blockers": [
    { "description": "what's stuck", "type": "technical|decision|external" }
  ],
  "decisions_in_progress": [
    { "question": "what was being decided", "leaning": "current direction" }
  ],
  "uncommitted_files": [],
  "context_notes": "founder's additional context or null",
  "next_action": "specific first thing to do when resuming",
  "scores_at_pause": {}
}
```

### Step 5: Commit handoff

```bash
git add .claude/cache/HANDOFF.json
git commit -m "wip: pause — ${working_on_summary}"
```

### Step 6: Output

```
  ◆ pause  ·  handoff created
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  working on   ${feature_or_task}
  done         ${completed_count} items committed
  remaining    ${remaining_count} items
  predictions  ${ungraded_count} ungraded
  blockers     ${blocker_count}
  uncommitted  ${uncommitted_count} files

  → resume with /pause resume
```

---

## RESUME Mode

### Step 1: Load handoff

```bash
cat .claude/cache/HANDOFF.json 2>/dev/null
```

**If no HANDOFF.json:**
```
  ◆ pause  ·  no handoff found
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  No active handoff. Starting fresh.

  → /plan to assess current state
  → /go to start building
```

Exit.

**If HANDOFF.json exists:** parse and continue.

### Step 2: Validate state

Check if the handoff is still valid:

```bash
# Has anything changed since the handoff?
git log --oneline --since="${handoff.created}" 2>/dev/null
git status --short
```

If commits have happened since the handoff was created, note them — someone (or
another session) may have continued the work.

If uncommitted files from the handoff are now committed, update the state.

### Step 3: Surface blockers and predictions

**Blockers first** — if anything was stuck, surface it immediately:
```
  ⚠ blocker: ${blocker.description} (${blocker.type})
```

**Ungraded predictions** — these are the highest-priority items to resolve:
```
  ● prediction: ${prediction.prediction}
    evidence: ${prediction.evidence}
    → grade this based on current state
```

Attempt to auto-grade predictions from current eval-cache and git state.

### Step 4: Present status

```
  ◆ pause  ·  resuming
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  paused       ${handoff.created}
  working on   ${handoff.working_on.task}
  done         ${handoff.completed.length} items
  remaining    ${handoff.remaining.length} items
  ${blockers ? '⚠ blockers  ' + blocker_count : ''}
  ${predictions_graded ? 'predictions  ' + graded_count + ' graded' : ''}

  ${changes_since_pause ? 'changes since pause: ' + commit_count + ' commits' : ''}

  next action: ${handoff.next_action}
```

### Step 5: Clean up

After presenting status, delete the handoff:

```bash
rm .claude/cache/HANDOFF.json
git add .claude/cache/HANDOFF.json
git commit -m "resume from pause — continuing ${working_on_summary}"
```

The handoff is a one-shot artifact. Once consumed, it's gone.

---

## State Reads

| File | What it tells you |
|------|-------------------|
| `.claude/cache/HANDOFF.json` | Previous session handoff (resume mode) |
| `.claude/cache/eval-cache.json` | Current scores (for prediction grading) |
| `.claude/plans/todos.yml` | Active backlog |
| `.claude/plans/plan.yml` | Current plan |
| `~/.claude/knowledge/predictions.tsv` | Active predictions |
| `config/founder.yml` | Project context |

## State Writes

- `.claude/cache/HANDOFF.json` — write on pause, delete on resume
- `~/.claude/knowledge/predictions.tsv` — grade predictions on resume

## System integration

**Triggers:** /go (when session is ending), /plan (capture planning state)
**Triggered by:** "pause", "stop", "I'm done for now", "save state", "where were we" (resume), "continue" (resume)

## Self-evaluation

/pause succeeded if:
- PAUSE: all active work is captured in HANDOFF.json
- PAUSE: ungraded predictions are listed
- PAUSE: uncommitted changes are noted
- PAUSE: handoff is committed
- RESUME: blockers are surfaced first
- RESUME: predictions are graded (or flagged for grading)
- RESUME: next action is clear and specific
- RESUME: handoff is deleted after consumption

## Cost note

- PAUSE: ~5k tokens (reading state + writing JSON)
- RESUME: ~5k tokens (reading handoff + presenting status)
- No agents spawned — this is lightweight by design

## What you never do

- Auto-resume without showing the user what changed
- Delete handoff before the user has seen the status
- Skip prediction surfacing — ungraded predictions are wasted
- Create handoff without asking for context — the founder's mental state matters
- Leave handoff around after resume — it's a one-shot artifact

## If something breaks

- No HANDOFF.json on resume → offer to start fresh with /plan or /go
- HANDOFF.json is stale (>7 days) → warn that context may be outdated, offer fresh start
- Predictions can't be auto-graded → surface them for manual grading
- Git state diverged from handoff → note the divergence, trust git over handoff
- .claude/cache/ doesn't exist → create it

$ARGUMENTS
