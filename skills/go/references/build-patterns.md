# Build Patterns

Read this before building. Patterns that work vs anti-patterns, learned from real sessions.

## Patterns that work

### One intent per commit
A commit does one thing. "Add error boundary" or "Fix assertion regression" — not both. This makes revert mechanical: if the commit is bad, revert it. No surgical reversal needed.

### Assertion-first building
Before writing the feature, write the assertion that would prove it works. Then build until the assertion passes. This prevents the common failure mode of building something that "looks right" but doesn't actually deliver value.

### Score check after every change
Run `bash scripts/assertion-gate.sh [feature]` after every commit. Not after every 3 commits. Every commit. Regressions caught immediately are 10x cheaper to fix than regressions found 3 commits later.

### Sub-score targeting
Before building, name the sub-score you're targeting (delivery, craft, viability). After building, check THAT specific sub-score. If it didn't move, the approach isn't working — even if the total score went up from a different dimension.

### Mechanical before generative
Prefer changes that can be verified mechanically (assertion passes, error count drops, file exists) over changes that need LLM judgment to evaluate. Mechanical verification is deterministic; LLM judgment has 15pt variance.

### Smallest useful change
Build the smallest thing that moves the target metric. Not the smallest possible change (that's cosmetic gaming), but the smallest change that a user would notice or a metric would register. This maximizes learning per commit.

### Stash before starting
If git state is dirty, stash. A dirty worktree makes revert impossible and diff comparison meaningless.

## Anti-patterns

### Score chasing
Changing code to move the score without changing user behavior. Classic signs: renaming variables to avoid lint hits, adding comments to reduce "sparse documentation" penalties, restructuring files to improve "code organization" scores. The score is a thermometer, not a thermostat.

### Cosmetic-first building
Starting with fonts, spacing, and colors before the core value loop works. Craft matters, but craft ON TOP OF value. Craft without value is furniture.

### Multi-intent commits
"Add feature X and fix bug Y and refactor Z" — when this needs to be reverted, everything goes. One intent per commit means clean revert boundaries.

### Assertion gaming
Making assertions pass by testing the wrong thing. Checking that a file exists instead of checking that it works. Checking the happy path while ignoring edge cases. The reviewer catches this in beta mode, but it's better to write honest assertions from the start.

### Building past plateau
3 flat moves and you're still going. The approach is exhausted. More of the same won't break through. Research, rethink, or ask for help — don't iterate harder on a dead approach.

### Ignoring sub-score direction
Total score went up, but the dimension you were targeting went DOWN. This means you accidentally improved something else. The targeted dimension still needs work, and now you have a false sense of progress.

### Silent changes
Making changes that produce no visible feedback. No score change, no assertion change, no output change. If measurement can't see it, it didn't happen. Either the change is too small to matter or the measurement is too coarse — figure out which.
