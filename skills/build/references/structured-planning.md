# Structured Planning — XML Task Format and Wave Grouping

How /plan decomposes strategic moves into executable, parallel-safe task plans.

## Why structured plans

Freeform task descriptions produce shallow execution. "Improve scoring delivery" gives an executor no actionable path. Structured plans give executors:

1. **Exact files** to read and modify
2. **Concrete actions** with real values, not references
3. **Verifiable acceptance criteria** that can be checked mechanically
4. **Dependency ordering** so independent work runs in parallel

The cost of verbose plans is far less than the cost of re-doing shallow execution.

## The XML task format

Every task in a plan uses this structure:

```xml
<task type="implementation">
  <name>Action-oriented name — what this task accomplishes</name>
  <files>path/to/file.ext, another/file.ext</files>
  <read_first>path/to/reference.ext, path/to/source-of-truth.ext</read_first>
  <action>
    Precise instructions. What to change. Why.
    Include CONCRETE values: exact identifiers, parameters, expected outputs,
    file paths, command arguments.
    The executor should complete the task from this text alone.
  </action>
  <verify>Command or check to prove it worked (e.g., "npm test exits 0")</verify>
  <acceptance_criteria>
    - Grep-verifiable: "file.ext contains 'exact string'"
    - Measurable: "command exits 0" or "output includes X"
  </acceptance_criteria>
  <done>Observable outcome — what's different when this task is complete</done>
</task>
```

### Field rules

| Field | Required | Rules |
|-------|----------|-------|
| `name` | Yes | Action-oriented. "Add pool config to database.ts", not "Database stuff" |
| `files` | Yes | Every file this task creates or modifies |
| `read_first` | Yes | Files the executor MUST read before touching anything. Always includes the file being modified + any source-of-truth files (schemas, configs, reference implementations) |
| `action` | Yes | Contains CONCRETE values. Never "align X with Y" — specify the exact target state. Never "update config" — list the exact keys and values |
| `verify` | Yes | A command or check. "npm test", "grep 'pattern' file.ext", "curl localhost:3000/health returns 200" |
| `acceptance_criteria` | Yes | Grep-verifiable conditions. Never subjective ("looks correct", "properly configured"). Always exact: "file.ext contains 'def verify_token('" |
| `done` | Yes | The observable outcome. What changed in the world |

### Task types

| Type | Use for |
|------|---------|
| `implementation` | Code changes, config updates, file creation |
| `verification` | Running tests, checking behavior, validating integration |
| `research` | Reading code, investigating approaches (output: decision, not code) |

## Wave grouping — parallel execution model

Tasks are grouped into dependency waves. All tasks in the same wave can execute in parallel. Tasks in Wave N+1 depend on Wave N completing first.

```
Wave 1 (parallel — no dependencies):
  Task A: Create user model      [src/models/user.ts]
  Task B: Create product model   [src/models/product.ts]

Wave 2 (depends on Wave 1):
  Task C: API endpoints using both models [src/api/routes.ts]

Wave 3 (depends on Wave 2):
  Task D: Integration test for full flow  [tests/integration.test.ts]
```

### When tasks are in the same wave (parallel)

- No shared files — they modify different files
- No type/export dependencies — neither needs the other's output
- No ordering requirement — either could complete first

### When tasks need separate waves (sequential)

- **File overlap**: both modify `src/config/database.ts` — Wave 2 sees Wave 1's changes
- **Type dependency**: Task B imports a type that Task A creates
- **Behavioral dependency**: Task B tests behavior that Task A implements

### Anti-pattern: reflexive chaining

```
BAD:
  Wave 1: Task A (no real dependency)
  Wave 2: Task B (depends on A... but why?)
  Wave 3: Task C (depends on B... but why?)

GOOD:
  Wave 1: Task A, Task B, Task C (all independent, run in parallel)
```

Don't chain waves unless there's a genuine dependency. The default is parallel.

## Plan structure

A complete plan wraps tasks in a plan element:

```xml
<plan name="improve-scoring-delivery" feature="scoring" wave="1">
  <task type="implementation">
    <name>Add score breakdown to CLI output</name>
    <files>bin/score.sh, lib/format.sh</files>
    <read_first>bin/score.sh, lib/format.sh, templates/plan-output.md</read_first>
    <action>
      In bin/score.sh after line "echo $TOTAL_SCORE", add a breakdown section:
      - Sub-scores: health, eval, taste (read from cache files)
      - Format: "  health: NN  eval: NN  taste: NN"
      - Use lib/format.sh:format_score_bar() for visual bars
      - Color: green >= 70, yellow >= 40, red < 40
    </action>
    <verify>bash bin/score.sh . --json | jq '.breakdown' returns object with 3 keys</verify>
    <acceptance_criteria>
      - bin/score.sh contains "breakdown" section after total score
      - Output includes "health:" and "eval:" and "taste:" labels
      - lib/format.sh contains function format_score_bar
    </acceptance_criteria>
    <done>Score command shows sub-score breakdown alongside total</done>
  </task>

  <task type="verification">
    <name>Verify score output matches format spec</name>
    <files>tests/score-output.test.sh</files>
    <read_first>templates/plan-output.md, bin/score.sh</read_first>
    <action>
      Create test that runs bin/score.sh on a fixture project and checks:
      - Exit code 0
      - Output contains total score line
      - Output contains breakdown with 3 sub-scores
      - No error output on stderr
    </action>
    <verify>bash tests/score-output.test.sh exits 0</verify>
    <acceptance_criteria>
      - tests/score-output.test.sh exists and is executable
      - Test checks for "health:", "eval:", "taste:" in output
    </acceptance_criteria>
    <done>Score output has automated regression test</done>
  </task>
</plan>
```

## Connecting to founder-os moves

Each /plan move maps to one or more XML plans:

```
Move (strategic layer — templates/move-brief.md):
  feature, dimension, prediction, evidence, acceptance

  -> Plan 1 (execution layer — XML tasks in waves):
       Wave 1: foundation tasks
       Wave 2: dependent tasks

  -> Plan 2 (if move is complex):
       Wave 1: separate vertical slice
```

**Sizing guide:**
- 2-3 tasks per plan, not 5-10
- Complex moves = multiple plans, not one large plan
- Prefer vertical slices (model + API + UI for one feature) over horizontal layers (all models, then all APIs)

## Quality checklist

Before presenting a structured plan, verify:

- [ ] Every task has `<read_first>` with at least the file being modified
- [ ] Every `<action>` contains concrete values (no "align X with Y" without the target state)
- [ ] Every `<acceptance_criteria>` is grep-verifiable (no "looks correct")
- [ ] Wave assignments reflect real dependencies, not reflexive ordering
- [ ] Independent tasks are in the same wave (parallel by default)
- [ ] Task count per plan is 2-3 (split if more)
- [ ] The plan connects to the move's prediction — if the tasks succeed, the prediction should come true
