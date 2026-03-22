# Keep/Revert Decision Matrix

Read this before the first keep/revert decision in a session.

## The matrix

| Assertions | Reviewer | Decision | Why |
|-----------|----------|----------|-----|
| improved | KEEP | **keep** | Best case — value gained, quality confirmed |
| improved | REVERT | **keep** | Measurement wins over opinion. Log reviewer's concern. |
| improved | no review (safe) | **keep** | Assertions are authoritative |
| stable | KEEP | **keep** | No regression, reviewer approves |
| stable | REVERT | **revert** | No value gained, reviewer found problems |
| stable | no review (safe) | **keep** | No regression, fine to keep |
| regressed | any | **revert** | Always. No exceptions. No "just this once." |

## Two-stage review (beta mode only)

**Stage 1: Spec compliance** — does code satisfy acceptance criteria?
- Spawn reviewer with ONLY acceptance criteria + diff. No session history.
- MEETS_SPEC -> proceed to stage 2
- FAILS_SPEC -> loop back to build (max 2 retries, then revert)

**Stage 2: Code quality** — is the code good?
- Spawn reviewer with ONLY diff + product-standards.md
- Check: regressions, silent failures, assertion gaming, slop, UX checklist
- KEEP / REVERT / KEEP_WITH_FIXES

## Regression debugging

Before reverting an assertion regression, spawn `founder-os:debugger` in background:
```
Agent(subagent_type: "founder-os:debugger", prompt: "Score dropped from [before] to [after] after commit [hash]. Assertion [name] regressed. Investigate root cause.", run_in_background: true)
```

The debugger's findings arrive as SendMessage with root cause + suggested fix todo. The debugger has memory — it remembers past regressions. If the same assertion regresses twice, the second analysis is sharper.

## Edge cases

**Temporary regression for bigger win**: Not allowed. Revert, then build the bigger change as a single atomic commit that never regresses mid-way.

**Reviewer REVERT on improved assertions**: Keep. But log the reviewer's concern as a todo — it might surface a real problem later.

**All assertions pass but score flat**: Assertions are too shallow. They test existence, not behavior. Deepen them before continuing.

**Score dropped but assertions held**: Keep. Value > health. The score measures health; assertions measure value.

**New assertion was added AND old one regressed**: Revert. Adding a new passing assertion doesn't cancel a regression.
