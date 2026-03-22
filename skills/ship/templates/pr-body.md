# PR Body Template

Fill from git log, eval-cache, and roadmap.yml. The PR description answers "why this matters" not just "what changed."

---

## What this does
[1-2 sentences — what changed for the user, not what code changed. If there's no user-facing change, say what developer experience changed.]

## Why
[Which thesis evidence item, bottleneck, or assertion failure this addresses. Link to the roadmap thesis if applicable.]

## Features affected
- [feature name] (eval: [score]) — [what changed: new capability, score improvement, bug fix]

## Evidence
- assertions: [N passing, M failing — any changes from before this PR]
- score: [before → after, or "no change"]
- eval delta: [feature scores that moved]

## What's NOT in this PR
- [Honest scope boundary — what this doesn't address]
- [Known follow-up work, if any]

---

## Filling instructions

1. Run `git log [base]..HEAD --oneline` for commit list
2. Run `git diff [base]...HEAD --stat` for files changed
3. Map files to features via `config/founder.yml` code paths
4. Read `.claude/cache/eval-cache.json` for feature scores
5. Read `.claude/plans/roadmap.yml` for thesis context
6. Delete any section that has nothing meaningful to say — an empty "Evidence" section is worse than no section
