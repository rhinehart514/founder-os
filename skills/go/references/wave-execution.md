# Wave-Based Parallel Execution

How /go executes tasks in dependency-grouped waves. Adapted from GSD's execute-phase engine, wrapped with founder-os measurement gates.

## Core concept

Tasks are grouped into waves by dependency analysis. Tasks within a wave have no dependencies on each other and can execute in parallel. Waves execute sequentially — wave 2 waits for wave 1 to complete and pass the assertion gate.

```
Wave 1: [task-01] [task-02] [task-03]   ← parallel, independent
           ↓          ↓          ↓
        assertion gate (founder-os)      ← regression = revert wave, stop
           ↓
Wave 2: [task-04] [task-05]             ← parallel, depend on wave 1
           ↓          ↓
        assertion gate (founder-os)
           ↓
Wave 3: [task-06]                        ← depends on wave 2
           ↓
        final measurement (founder-os)
```

## Wave assignment

Tasks get wave numbers through dependency analysis:

**Wave 1:** Tasks with no dependencies on other tasks. They touch independent files and don't need each other's output.

**Wave N+1:** Tasks that depend on any task in wave N. Dependencies come from:
- File overlap: task B modifies a file that task A creates or modifies
- Import chains: task B imports types/functions that task A defines
- Explicit dependency: task B's `<read_first>` references task A's output
- Logical ordering: task B only makes sense after task A (e.g., "add tests" after "add feature")

**Pre-computed vs runtime:** If using GSD-style PLAN.md files, wave numbers are pre-computed in frontmatter (`wave: N`). If creating tasks from bottleneck analysis, /go computes waves at runtime from file overlap and logical dependencies.

## Parallel execution model

Each executor agent gets a **fresh context window**. This is the critical design choice — no accumulated conversation garbage, no context bleed between tasks.

### What the orchestrator sends

The orchestrator sends **paths and specs**, not file contents. Executors read files themselves with their full context budget. This keeps the orchestrator lean (~10-15% context usage for 200k windows, more flexible for 1M+ windows).

```
Orchestrator context budget:
- Step 1 (measure): ~5% — read caches, run scripts
- Step 2 (plan): ~5% — analyze features, create XML tasks
- Step 3-6 (waves): ~5% — spawn agents, verify results
- Total: ~15% orchestrator, 100% fresh per executor
```

### What each executor receives

1. **The XML task spec** — what to build, which files, how to verify
2. **File paths to read** — from `<files>` and `<read_first>` fields
3. **Product context paths** — product-spec.yml, feature definition
4. **Commit protocol** — how to stage and commit (including --no-verify for parallel)
5. **Success criteria** — what "done" looks like

The executor reads these files itself, with its full context window. This means:
- A 200k-context executor gets 200k of fresh space for the task
- No context pollution from other tasks or orchestrator reasoning
- Each task gets the agent's best work, not its tired-after-5-tasks work

### Parallel safety

When multiple agents commit simultaneously:
- Each agent uses `--no-verify` to avoid pre-commit hook contention
- The orchestrator runs hooks once after the wave completes
- Agents work on different files (enforced by wave grouping)
- If two tasks unexpectedly touch the same file, git merge handles it (or fails, triggering manual resolution)

## Inter-wave assertion gate

This is what makes /go's wave execution different from raw GSD execution. Between every wave, founder-os checks:

```
Wave N completes
    ↓
bash scripts/assertion-gate.sh [feature]
    ↓
┌─────────────────────────────┐
│ Assertions improved?        │ → proceed to wave N+1
│ Assertions stable?          │ → proceed to wave N+1
│ Assertions REGRESSED?       │ → STOP. Revert wave N. Spawn debugger.
└─────────────────────────────┘
```

**Why gate between waves:** GSD executes all waves and checks at the end. This works for greenfield projects but is dangerous for existing products — a wave 1 regression compounds through waves 2-3. The inter-wave gate catches regressions early, before they propagate.

**Revert granularity:** On regression, revert ALL commits from the failing wave. Not surgical — the whole wave goes. This is simpler and safer than trying to identify which specific task caused the regression.

## Agent type selection

The orchestrator picks the right agent for each task:

### gsd-executor (default)

Best for: well-specified tasks with clear XML specs, 1-2 files, mechanical implementation.

Characteristics:
- Follows XML task spec precisely
- Fresh context, no product knowledge beyond what's in the spec
- Cheap (uses configured executor model, often sonnet)
- Fast — no loading of mind files or product context
- Commits atomically after task completion

### founder-os:builder (complex tasks)

Best for: multi-file features, tasks requiring product context, architectural decisions.

Characteristics:
- Loads founder-os mind files (product-spec, standards, identity)
- Understands product context and feature definitions
- More expensive (opus model)
- Can make judgment calls about implementation approach
- Better for tasks where "how" isn't fully specified

### Selection heuristic

```
if task.files.count <= 2 AND task.action is specific AND no architectural decisions:
    → gsd-executor
elif task is cleanup/refactor:
    → founder-os:refactorer (worktree, no behavior changes)
elif task.files.count >= 3 OR task requires product judgment:
    → founder-os:builder
```

## Completion verification

After each executor completes, the orchestrator verifies:

1. **Git commits exist** — `git log --oneline --grep="{task identifier}" --since="1 hour ago"`
2. **Files modified** — files from `<files>` appear in `git diff --name-only`
3. **Verify command passes** — run the `<verify>` command from the task spec
4. **Acceptance criteria** — if `<acceptance_criteria>` exist, check each one

If verification fails for a task:
- Retry once with the same agent type
- If retry fails, mark task as failed
- Report to orchestrator for human decision: retry with different approach, skip, or stop

## Mode-specific behavior

### Default mode (parallel waves)

Full wave execution as described above. Multiple agents per wave when tasks are independent.

### Safe mode (`--safe`)

Sequential execution in main context. No agent spawning. Tasks execute one at a time in the main conversation:
- Wave grouping still computed (for ordering)
- But tasks execute sequentially regardless of wave assignment
- Assertion gate runs after every task (not just every wave)
- Best for: small task sets, debugging, when agents are unreliable

### Interactive mode (`--interactive`)

Like safe mode but with user checkpoints:
- Execute one task at a time in main context
- After each task: present what was done, pause for user input
- User can: approve and continue, redirect, modify, or stop
- Best for: learning, high-risk changes, when the founder wants control

### Speculative mode (`--speculate N`)

For genuinely uncertain approaches:
- Spawn N `founder-os:builder` agents in isolated worktrees
- Each tries a different approach to the same task
- Compare assertion results and scores
- Keep the winner, discard the rest
- Only for tasks where multiple plausible approaches exist

## Failure handling

| Failure | Response |
|---------|----------|
| Agent spawn fails | Fall back to --safe (inline execution) |
| Agent times out | Kill, report, offer retry or skip |
| Agent produces no commits | Treat as failed, offer retry |
| Verify command fails | Retry task once, then report |
| Wave assertion regression | Revert wave, spawn debugger, stop |
| All agents in wave fail | Stop, report for investigation |
| Merge conflict (rare) | Fall back to sequential for conflicting tasks |

## Context efficiency

The wave model is more context-efficient than sequential single-agent building:

- **Old /go:** One agent accumulates context across all tasks. By task 5, context is 60%+ full of previous reasoning.
- **Wave /go:** Each task gets 100% fresh context. The orchestrator stays at ~15%. Total tokens may be similar, but quality-per-task is higher.

The tradeoff: more agent spawn overhead, less shared context between related tasks. Wave grouping mitigates this — tasks that need shared context go in the same wave or the later task reads the earlier task's output files.
