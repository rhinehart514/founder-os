---
name: go
description: "Use when the user says 'just build it', 'go', 'fix everything', or wants autonomous building. Wave-based parallel execution with measurement wrapping. '/go auth' scopes to a feature, '/go --safe' disables parallel execution."
argument-hint: "[feature...] [--safe] [--speculate N] [--interactive]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, AskUserQuestion, WebSearch, WebFetch, TaskCreate, TaskGet, TaskList, TaskUpdate
---

!command -v jq &>/dev/null && cat .claude/cache/eval-cache.json 2>/dev/null | jq 'to_entries | map({key, score: .value.score, delta: .value.delta}) | from_entries' 2>/dev/null || echo "no eval cache (jq missing or cache empty)"
!command -v jq &>/dev/null && cat .claude/cache/product-value.json 2>/dev/null | jq '{loop: .value_loop[:5], type: .product_type}' 2>/dev/null || echo "no product-value cache (jq missing or cache empty)"
!tail -3 ~/.claude/knowledge/predictions.tsv 2>/dev/null || echo "no predictions"

# /go

Autonomous creation loop with wave-based parallel execution. Measure, plan, predict, execute in waves, verify, learn. No human in the loop until you hit a wall or plateau.

Combines founder-os's measurement discipline (predict, measure, revert-on-regression) with GSD's wave-based parallel execution engine (dependency-grouped waves, fresh context per executor, XML task specs).

## Skill folder

- `scripts/assertion-gate.sh` — checks assertion pass/fail. Run after every build.
- `scripts/pre-build-scan.sh` — state snapshot. Use to VERIFY your reading.
- `scripts/plateau-check.sh` — detects N consecutive flat moves. Use to VERIFY plateau judgment.
- `scripts/build-log.sh` — persistent session log across conversations.
- `references/keep-revert-matrix.md` — when to keep vs revert. Read before first decision.
- `references/build-patterns.md` — patterns that work and anti-patterns.
- `references/beta-features.md` — speculative branching + adversarial review (opt-in).
- `references/wave-execution.md` — GSD wave-based parallel execution model.
- `references/xml-task-format.md` — XML task structure that executors receive.
- `templates/move-format.md` — output formatting reference.
- `templates/build-session.md` — session log structure.
- `templates/prediction.md` — prediction format and quality checks.
- `gotchas.md` — real failure modes. **Read before entering the loop.**

## Modes

| Argument | Behavior |
|----------|----------|
| `/go` | Full loop with wave-based parallel execution |
| `/go --safe` | Sequential single-agent execution, no parallelism |
| `/go --interactive` | Sequential inline execution with user checkpoints between tasks |
| `/go --speculate N` | Force N parallel approaches for uncertain moves (default: 2) |
| `/go [feature]` | Scope to a single feature. Multiple = work sequentially. None = target bottleneck. |

## The build loop

### Step 1: Pre-build measurement (founder-os)

Read in parallel: `eval-cache.json`, `founder.yml`, `plan.yml`, `predictions.tsv`, `todos.yml`, `product-spec.yml`, `preferences.yml`. Also read `gotchas.md` and `references/build-patterns.md`. Verify with `bash scripts/pre-build-scan.sh`.

Capture baseline:
- Assertion count and pass/fail via `bash scripts/assertion-gate.sh`
- Feature scores from eval-cache.json
- Current score from score-cache

Identify bottleneck: lowest eval score among highest-weight features. This is the target.

### Demand Gate (soft)

Before executing, check: does this feature have a demand anchor?

**Check for evidence:**
- `config/portfolio.yml` — does the target feature's idea have a validated customer job?
- `.claude/cache/customer-intel.json` — any demand signals?
- eval-cache.json — does the feature have prior eval data?

**If no demand evidence exists**, present via AskUserQuestion:
> "No demand evidence for [feature]. What customer job does this serve? (functional/emotional/social)"
>
> Evidence classes: [observed] user behavior, [stated] user said, [market] market data, [inferred] LLM synthesis.

**Gate behavior:**
- `autonomy: autonomous` or `full-auto` → skip gate, log warning
- All other modes → ask, then proceed regardless of answer (soft gate)

This gate doesn't block — it forces the demand question into consciousness before building.

### Step 2: Plan — create or load task specs (hybrid)

Three sources, checked in order:

**Source A: GSD-style plan exists.** If `.planning/` contains PLAN.md files with `<tasks>` XML blocks, use them directly. Extract wave assignments from frontmatter `wave:` fields. Skip to Step 3.

**Source B: /plan created a plan.yml.** Translate plan.yml tasks into XML task specs:
- Each plan.yml task becomes an XML `<task>` with `<name>`, `<files>`, `<action>`, `<verify>`, `<done>`
- Analyze dependencies between tasks (file overlap, import chains)
- Assign wave numbers based on dependency analysis

**Source C: Neither exists — create from bottleneck analysis.** This is the common path:

1. Read the bottleneck feature's code, eval gaps, failing assertions, and /eval or /taste feedback
2. Prioritize work (same as old /go):
   - **Failing assertions** — fix regressions first
   - **Tasks from /eval or /taste** — specific gaps already identified
   - **Missing assertion coverage** — <5 assertions? Add more before building
   - **Weakest sub-score dimension** — target lowest of delivery/craft
   - **Promoted todos** — founder intent from todos.yml
   - **New work** — only when all above are clear
3. Break into 2-5 atomic tasks, each with XML structure (see `references/xml-task-format.md`):

```xml
<task type="auto" id="task-01">
  <name>Action-oriented name</name>
  <files>path/to/file.ext</files>
  <read_first>path/to/reference.ext</read_first>
  <action>Specific implementation with concrete values</action>
  <verify>Command or check to prove it worked</verify>
  <acceptance_criteria>
    - Grep-verifiable condition
  </acceptance_criteria>
  <done>Measurable acceptance criteria</done>
</task>
```

4. Analyze dependencies: does task B need task A's output? Do they touch the same files?

**Cleanup:** If all remaining work is cleanup/refactor, spawn `founder-os:refactorer` in worktree instead. Hard constraint: no behavior changes, assertions must hold.

### Step 3: Wave grouping (GSD engine)

Group tasks into dependency waves:

- **Independent tasks** (no shared files, no import dependencies) → same wave (parallel)
- **Dependent tasks** (needs output of earlier task, touches same files) → later wave (sequential)

Present the wave plan:

```
## Wave Plan

Target: [feature] — [bottleneck dimension] [current] → [target]

| Wave | Tasks | What it builds |
|------|-------|----------------|
| 1 | task-01, task-02 | Error boundaries for file I/O + subprocess calls |
| 2 | task-03 | Integration test covering both paths |
```

### Step 4: Predict (founder-os)

Before executing ANY wave, log the session prediction to `~/.claude/knowledge/predictions.tsv`. See `templates/prediction.md` for format.

```
I predict: [specific outcome with numbers — e.g., "craft_score +15 (50→65)"]
Because: [cite experiment-learnings.md entry, or "Exploring — no prior data"]
I'd be wrong if: [falsification condition]
```

This prediction covers the ENTIRE wave execution, not individual tasks. Grade once after all waves complete.

### Step 5: Approval gate

| Mode | Behavior |
|------|----------|
| `mode: build` (default) | Present wave plan inline, proceed. Founder can interrupt. |
| `mode: ship` or `autonomy: supervised` | Wait for founder acknowledgment via AskUserQuestion. |
| `autonomy: autonomous`/`full-auto` | Skip. |

### Step 6: Execute waves (GSD engine + founder-os agents)

Read `references/wave-execution.md` for the full execution model.

**For each wave:**

#### 6a. Agent selection per task

The orchestrator decides which agent to spawn based on task complexity:

| Task complexity | Agent | Why |
|----------------|-------|-----|
| Simple (config, rename, single-file edit) | `gsd-executor` | Cheap, fast, fresh context |
| Standard (feature work, 1-3 files) | `gsd-executor` | Fresh context, XML-driven |
| Complex (multi-file feature, architectural) | `founder-os:builder` | Deep context, product awareness |
| Cleanup/refactor | `founder-os:refactorer` | No-behavior-change constraint |

**Complexity heuristic:** Tasks touching 1-2 files with clear `<action>` specs → gsd-executor. Tasks touching 3+ files, requiring product context, or involving architectural decisions → founder-os:builder.

#### 6b. Spawn executors

**Parallel mode** (default): spawn one agent per task in the wave, each with fresh context.

Each executor receives:
- The XML task spec (from Step 2)
- Relevant source files (from `<files>` and `<read_first>`)
- Product context: product-spec.yml, feature definition from founder.yml
- Mind files context (for founder-os:builder agents)
- NO accumulated conversation history — fresh context window

```
Agent(
  subagent_type="gsd-executor",  # or "founder-os:builder" for complex tasks
  prompt="
    <objective>
    Execute task: {task_name}
    Feature: {feature_name}
    Commit atomically after completing the task.
    </objective>

    <task_spec>
    {XML task block from Step 2}
    </task_spec>

    <context_files>
    Read these files at execution start:
    - {files from <read_first>}
    - {files from <files>}
    - config/product-spec.yml (if exists)
    - config/founder.yml features.{feature} (if exists)
    </context_files>

    <commit_protocol>
    Stage files individually (never git add . or git add -A).
    Commit message: feat({feature}): {task description}
    One intent per commit.
    {If parallel: use --no-verify to avoid hook contention.}
    </commit_protocol>

    <success_criteria>
    - [ ] All acceptance criteria from task spec met
    - [ ] Verify command passes
    - [ ] Changes committed
    </success_criteria>
  "
)
```

**Safe mode** (`--safe`): execute tasks sequentially in main context. No agent spawning. One task at a time, commit after each.

**Interactive mode** (`--interactive`): execute tasks sequentially in main context with user checkpoint between each task. Present what was done, ask to continue or redirect.

#### 6c. Wait and verify wave

Wait for all agents in the wave to complete.

**Completion verification per agent:**
- Check git log for commits mentioning the task
- Verify files from `<files>` were actually modified
- Run `<verify>` command from task spec
- Check `<acceptance_criteria>` if present

If any agent fails: report which task failed, offer retry or skip.

**Post-wave hook validation** (parallel mode only): run pre-commit hooks once after the wave since agents used `--no-verify`.

**Report wave completion:**

```
## Wave {N} Complete

**task-01: Error boundaries for file I/O** — added try/catch to 3 functions, graceful degradation on read failure
**task-02: Error boundaries for subprocess** — wrapped spawn calls with timeout and stderr capture

Assertion delta: +2 (passing: 54 → 56)
```

#### 6d. Inter-wave measurement (founder-os)

After each wave completes, before starting the next wave:

1. Run `bash scripts/assertion-gate.sh [feature]`
2. If assertions **regressed**: STOP. Revert the wave's commits. Spawn `founder-os:debugger` in background. Do not proceed to next wave.
3. If assertions **stable or improved**: proceed to next wave.

This is the key integration: GSD executes in waves, founder-os gates between waves. A wave that breaks things gets reverted before damage compounds.

### Step 7: Post-build verification (hybrid)

After all waves complete:

**GSD-style verification:**
- All task `<verify>` commands pass
- All `<acceptance_criteria>` met
- Code compiles, tests pass (if applicable)

**Founder-os measurement:**
- Run `bash scripts/assertion-gate.sh [feature]` — full assertion check
- Run `founder eval . --feature [name] --fresh` — get new sub-scores
- Compare to pre-build baseline from Step 1

**Keep or revert decision** (read `references/keep-revert-matrix.md`):

| Assertions | Score direction | Decision |
|-----------|----------------|----------|
| improved | any | **keep** |
| stable | improved or stable | **keep** |
| stable | regressed | **keep** (value > health) |
| regressed | any | **revert all wave commits** |

On regression: revert ALL commits from this /go session. Spawn `founder-os:debugger` in background with regression details.

### Step 8: Grade prediction (founder-os)

**Mandatory before anything else.** Spawn `founder-os:grader` to grade the prediction from Step 4 against actual results. Spawn `founder-os:consolidator` in background to update experiment-learnings.md.

### Step 9: Plateau detection

Every 3 build cycles (not 3 tasks — 3 full Step 1→7 cycles): if targeted sub-score delta < 2 per cycle, declare plateau. Verify with `bash scripts/plateau-check.sh`.

On plateau: STOP. Do not iterate harder.
- Suggest `/research` for the stuck dimension
- Suggest `/plan` to rethink the approach
- Report what was tried and what didn't work

### Step 10: Loop or stop

| Condition | Action |
|-----------|--------|
| Target delta achieved | Stop. Report success. |
| Improvement but not at target | Loop back to Step 2. Create new tasks for remaining gaps. |
| Plateau (3+ flat cycles) | Stop. Suggest /research or /plan rethink. |
| All assertions passing, no eval gaps | Stop. Suggest /eval full or /taste for fresh perspective. |

### Session end

Run `bash scripts/assertion-gate.sh --diff`, compare to baseline. Log with `bash scripts/build-log.sh add`. Write `.claude/sessions/YYYY-MM-DD-HH.yml` (see `templates/build-session.md`).

Report using `templates/move-format.md`:
- Waves executed, tasks completed/failed
- Assertion delta, sub-score changes
- Prediction accuracy
- New tasks generated (if any)
- Bottleneck status (changed? still the same?)

## Tier-aware behavior

| Tier | Behavior |
|------|----------|
| **fix** (<50) | Pure build, --safe mode. Fix assertions, improve health. No eval between cycles. |
| **deepen** (50-70) | Wave execution enabled. Eval after every 3 commits. |
| **strengthen** (70-85) | Wave execution + eval after every commit. Research inline for unknowns. |
| **expand** (85+, eval<70) | Check if bottleneck is "missing capability" vs "incomplete." Missing → suggest /ideate or /research. |
| **mature** (85+, eval 70+) | Shorter sessions. Every 2 cycles: is another build higher leverage than /ideate or /research? Stop when features are good. |

## Agent routing

| Step | Agent | Notes |
|------|-------|-------|
| Execute (simple task) | gsd-executor | Fresh context, XML-driven, cheap |
| Execute (complex task) | founder-os:builder | Deep context, product-aware |
| Execute (cleanup) | founder-os:refactorer | No behavior changes, worktree |
| Execute (speculative) | founder-os:builder x N | Parallel worktrees, compare scores |
| Measure | founder-os:measurer or Bash | Mechanical, cheap |
| Grade | founder-os:grader | Has memory, learns grading |
| Debug regression | founder-os:debugger (bg) | Async during revert |
| Consolidate learnings | founder-os:consolidator (bg) | Updates experiment-learnings.md |
| Verify (GSD-style) | gsd-verifier | Goal-backward verification |
| Review (beta) | founder-os:reviewer | Adversarial code review |

See `references/beta-features.md` for speculative branching and adversarial review.

## What you never do

- Skip the prediction or prediction grading
- Continue past plateau without researching
- Modify score.sh, eval.sh, taste.mjs, or skills/taste/SKILL.md (immutable eval harness)
- Speculate on trivial moves
- Let the reviewer block a keep when assertions improved
- Skip presenting the wave plan (soft-gate still shows it)
- Execute wave N+1 when wave N had assertion regressions
- Spawn agents without fresh context (no accumulated conversation garbage)
- Use `git add .` or `git add -A` in any executor

## System integration

Reads: eval-cache.json, founder.yml, plan.yml, predictions.tsv, todos.yml, beliefs.yml, product-spec.yml, preferences.yml, experiment-learnings.md, .planning/*-PLAN.md (if GSD plans exist)
Writes: code (commits), predictions.tsv, experiment-learnings.md, session YAML, build-log
Triggers: /eval (measurement), /research (plateau), /retro (prediction grading)
Triggered by: /plan (after diagnosis), founder saying "go" / "build it" / "fix everything"

## If something breaks

- `founder eval .` fails: check config/founder.yml features section
- Agent spawn fails: fall back to `--safe` (sequential inline), log failure
- Worktree fails: fall back to main worktree, sequential execution
- No plan exists: run /plan logic inline first, or create tasks from bottleneck (Step 2, Source C)
- Dirty git state: `git stash` before starting
- Missing files: create experiment-learnings.md or predictions.tsv with standard templates
- GSD plan has no wave field: treat all tasks as wave 1 (sequential)
- Task verify command fails: retry once, then mark task failed and continue wave

$ARGUMENTS
