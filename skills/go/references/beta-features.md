# Beta Features — Speculative Branching & Adversarial Review

Opt-in via `/go` (default) or `/go --speculate N`. Disable with `/go --safe`.

## Speculative branching

When uncertain between approaches, spawn `founder-os:builder` per approach in isolated worktrees. Compare scores, keep the winner. Fall back to safe on worktree failure.

**When to speculate:** unfamiliar territory, multiple plausible approaches, Unknown Territory entries.
**When NOT to speculate:** config changes, renames, assertion additions, anything with one obvious approach.

**Cost:** ~2x tokens per speculative move. Track `speculative_delta` = winner score minus estimated single-approach score. Kill if delta < 2 after 5+ speculative moves.

## Adversarial review

Two-stage review via `founder-os:reviewer`:
1. Spec compliance — does the code match the move's acceptance criteria?
2. Code quality — edge cases, error handling, performance.

The reviewer can recommend REVERT even when assertions pass. But assertions override: if assertions improved, keep regardless of reviewer opinion.

**Tracking:** `adversarial_catches` / total moves = catch rate. Kill if catch rate < 10% after 10+ moves. Promote if > 25%.

## Session log fields (beta-specific)

```yaml
mode: beta
speculated: N
adversarial_overrides: N   # times measurement overruled reviewer
adversarial_catches: N     # times reviewer caught problems measurement missed
```

## Agent routing (beta-specific)

| Step | Agent | Notes |
|------|-------|-------|
| Build (speculate) | founder-os:builder x N | Parallel, isolated worktrees |
| Review | founder-os:reviewer | Independent, honest, cheap (haiku) |

## Evaluating beta features after each session

**Speculative branching:** Did the winner beat what a single approach would have produced? Promote if speculative_delta > 5 consistently.

**Adversarial review:** Is it finding real problems measurement misses? Promote if catch rate > 25%.

**Mechanical prediction grading:** Compare accuracy in sessions WITH enforcement vs WITHOUT. This one probably just stays — the learning loop breaks without it.
