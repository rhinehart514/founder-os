# XML Task Format

The structure that executor agents receive. Each task is a self-contained unit of work with everything the executor needs to complete it.

## Full task structure

```xml
<task type="auto" id="task-01">
  <name>Task 1: Create error boundaries for file I/O operations</name>
  <files>src/lib/file-ops.ts, src/lib/config-reader.ts</files>
  <read_first>src/lib/file-ops.ts, src/lib/config-reader.ts, src/types/errors.ts</read_first>
  <action>
    Wrap all fs.readFileSync and fs.writeFileSync calls in try/catch blocks.
    On read failure: return { ok: false, error: "File not found: {path}" } instead of throwing.
    On write failure: return { ok: false, error: "Write failed: {path} — {err.message}" }.
    Use the FileResult type from src/types/errors.ts for return values.
    Do NOT change function signatures — callers already expect the return type.
  </action>
  <verify>npx tsc --noEmit && grep -c "try {" src/lib/file-ops.ts | test $(cat) -ge 3</verify>
  <acceptance_criteria>
    - file-ops.ts contains at least 3 try/catch blocks
    - file-ops.ts imports FileResult from src/types/errors.ts
    - config-reader.ts returns { ok: false } on missing config (not throw)
    - npx tsc --noEmit passes with zero errors
  </acceptance_criteria>
  <done>All file I/O operations have error boundaries, type-checks pass</done>
</task>
```

## Field reference

| Field | Required | Purpose |
|-------|----------|---------|
| `type` | yes | `auto` (autonomous) or `checkpoint:*` (needs human) |
| `id` | yes | Unique identifier within the task set (e.g., `task-01`) |
| `name` | yes | Action-oriented name. Starts with verb. |
| `files` | yes | Files this task creates or modifies. |
| `read_first` | recommended | Files the executor MUST read before editing. Establishes ground truth. |
| `action` | yes | Specific implementation instructions with concrete values. |
| `verify` | yes | Command or check to prove the task worked. |
| `acceptance_criteria` | recommended | Grep-verifiable conditions. Each must be mechanically checkable. |
| `done` | yes | Measurable completion criteria (one sentence). |

## Writing good task specs

### Action field — be specific

**Bad:**
```xml
<action>Add error handling to the file operations</action>
```

**Good:**
```xml
<action>
  Wrap fs.readFileSync calls in try/catch. On ENOENT: return { ok: false, error: "not found" }.
  On EACCES: return { ok: false, error: "permission denied" }. On other errors: rethrow.
  Use the ErrorResult type from src/types.ts.
</action>
```

The executor has fresh context and no conversation history. It only knows what you put in the spec. Concrete values (exact type names, exact error messages, exact function signatures) prevent ambiguity.

### read_first — always include

The executor has NO knowledge of your codebase. Without `read_first`, it will:
- Guess at existing patterns and conventions
- Miss type definitions it needs to import
- Duplicate existing utilities
- Break implicit contracts

`read_first` files should include:
- Files being modified (to see current state)
- Type definition files (to use correct types)
- Adjacent files (to match conventions)
- Config files (to respect existing patterns)

### acceptance_criteria — grep-verifiable

Each criterion should be checkable with grep, wc, or a similar mechanical tool. No subjective judgment.

**Bad:**
```xml
<acceptance_criteria>
  - Error handling is comprehensive
  - Code follows best practices
</acceptance_criteria>
```

**Good:**
```xml
<acceptance_criteria>
  - file-ops.ts contains "catch (err)" at least 3 times
  - file-ops.ts does NOT contain "console.log" (use structured errors)
  - config-reader.ts contains "FileResult" import
</acceptance_criteria>
```

### verify — one command

The verify field should be a single command (or short pipeline) that returns exit code 0 on success:

```xml
<!-- Type check -->
<verify>npx tsc --noEmit</verify>

<!-- Test suite -->
<verify>npx jest src/lib/file-ops.test.ts --passWithNoTests</verify>

<!-- Pattern check -->
<verify>grep -q "try {" src/lib/file-ops.ts</verify>

<!-- Build check -->
<verify>npm run build 2>&1 | tail -1 | grep -q "success"</verify>

<!-- Combined -->
<verify>npx tsc --noEmit && npx jest --passWithNoTests -q</verify>
```

## Task types

### auto (95% of tasks)

Fully autonomous. Executor reads spec, implements, verifies, commits.

```xml
<task type="auto" id="task-01">
  <name>Task 1: Add validation to user input</name>
  <files>src/api/users.ts</files>
  <read_first>src/api/users.ts, src/types/user.ts</read_first>
  <action>Add zod schema validation to POST /users endpoint...</action>
  <verify>npx tsc --noEmit</verify>
  <done>Input validation with zod schema on user creation endpoint</done>
</task>
```

### checkpoint:human-verify (4% of tasks)

Executor builds, then pauses for human verification. Used for visual/interactive features.

```xml
<task type="checkpoint:human-verify" id="task-03" gate="blocking">
  <what-built>Dashboard layout — server running at http://localhost:3000</what-built>
  <how-to-verify>Visit localhost:3000/dashboard. Check: grid layout, responsive on mobile, no scroll issues.</how-to-verify>
  <resume-signal>Type "approved" or describe issues</resume-signal>
</task>
```

### checkpoint:decision (1% of tasks)

Executor reaches a decision point that requires founder input.

```xml
<task type="checkpoint:decision" id="task-02" gate="blocking">
  <decision>Authentication strategy for API endpoints</decision>
  <context>Both JWT and session-based auth are viable. JWT is simpler but session gives us revocation.</context>
  <options>
    <option id="jwt"><name>JWT tokens</name><pros>Stateless, simple</pros><cons>No revocation</cons></option>
    <option id="session"><name>Session-based</name><pros>Revocable</pros><cons>Requires session store</cons></option>
  </options>
  <resume-signal>Select: jwt or session</resume-signal>
</task>
```

## Dependency and wave assignment

Tasks declare dependencies implicitly through file overlap and explicitly through read_first chains.

### Implicit dependencies (file overlap)

```xml
<!-- Wave 1: creates the type -->
<task type="auto" id="task-01">
  <files>src/types/errors.ts</files>
  ...
</task>

<!-- Wave 2: uses the type (same file in read_first) -->
<task type="auto" id="task-02">
  <read_first>src/types/errors.ts</read_first>
  <files>src/lib/file-ops.ts</files>
  ...
</task>
```

task-02 depends on task-01 because task-01 creates/modifies `src/types/errors.ts` and task-02 reads it.

### Wave assignment rules

1. Tasks with no dependencies on other tasks → wave 1
2. Tasks depending on any wave-N task → wave N+1
3. Tasks with file conflicts (both modify same file) → sequential waves even without logical dependency
4. Minimize wave count — push tasks to the earliest possible wave

### Example wave grouping

```
Tasks:
  task-01: create ErrorResult type       → files: src/types/errors.ts
  task-02: error boundaries for file-ops → files: src/lib/file-ops.ts, read_first: src/types/errors.ts
  task-03: error boundaries for config   → files: src/lib/config.ts, read_first: src/types/errors.ts
  task-04: integration tests             → files: src/tests/errors.test.ts, read_first: src/lib/file-ops.ts, src/lib/config.ts

Wave assignment:
  Wave 1: [task-01]              — no dependencies
  Wave 2: [task-02, task-03]     — both depend on task-01, independent of each other
  Wave 3: [task-04]              — depends on task-02 and task-03
```

## Commit protocol for executors

Each executor commits atomically after completing its task:

```bash
# Stage files individually (NEVER git add . or git add -A)
git add src/types/errors.ts

# Commit with descriptive message
git commit -m "feat(scoring): create ErrorResult type for structured error handling

- Added ErrorResult<T> union type with ok/error discriminator
- Added specific error types: FileNotFound, PermissionDenied, ParseError"

# If parallel execution: use --no-verify
git commit --no-verify -m "feat(scoring): create ErrorResult type..."
```

Commit message format: `{type}({feature}): {description}`

Types: `feat` (new), `fix` (bug), `test` (tests only), `refactor` (no behavior change), `docs`, `chore`

## Anti-patterns

**Vague action:** "Improve the error handling" — executor doesn't know what to do.
**Missing read_first:** Executor guesses at existing patterns, creates inconsistencies.
**Unverifiable criteria:** "Code is well-structured" — not grep-able.
**Oversized tasks:** 5+ files, multiple concerns — split into smaller tasks.
**Redundant reads:** Don't put the same file in both `<files>` and `<read_first>` — `<files>` implies the executor will read it.
