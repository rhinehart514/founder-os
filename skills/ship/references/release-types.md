# Release Types — When to Use Each

Four ways to get code out. Pick the right one for the situation.

## Commit + Push (`/ship`)

**When**: Normal work is done and measured. The default.

What happens: pre-flight checks → stage → commit → push → deploy (if auto-deploy configured) → verify → log.

Use when:
- Work has been built and evaluated
- Assertions are passing
- Score hasn't regressed
- You want the code deployed

Don't use when:
- You need review from others (use PR)
- You want a versioned milestone (use release)
- Something is broken in production (use hotfix)

## Pull Request (`/ship pr [base]`)

**When**: You want review, CI, or a record of the change before it merges.

What happens: generates a PR description from git log + eval-cache + roadmap → opens PR via `gh pr create`.

Use when:
- Working on a team and changes need review
- CI pipeline gates merges
- The change is significant enough to discuss
- You want a permanent record of why a change was made

The PR body maps changes to features and thesis evidence — not just "what files changed" but "why this matters."

## GitHub Release (`/ship release [tag]`)

**When**: A version thesis is proven and you want to mark the milestone publicly.

What happens: generates release notes from roadmap.yml + git log + eval-cache → creates a GitHub release with `gh release create`.

Use when:
- A roadmap version thesis has enough evidence
- You want to communicate externally what changed
- You're distributing the product (plugin marketplace, npm, etc.)
- Version completion is high enough to graduate

Release notes are generated from evidence, not vibes. Every bullet traces to a proven thesis item, a feature score improvement, or a confirmed prediction. The slop filter catches "improved performance" and "enhanced user experience."

## Hotfix (`/ship hotfix`)

**When**: Something is broken in production and speed matters more than ceremony.

What happens: skips score check → fast-path commit → push → deploy → log.

Use when:
- Production is broken
- Users are affected right now
- The fix is targeted and small
- You've already identified the root cause

Don't use when:
- You're nervous about a normal ship (that's what pre-flight is for)
- The "fix" is actually a feature
- You haven't identified what's broken (investigate first)

Hotfixes still log to deploy history and still check for secrets. They skip the score gate because a broken production is worse than a temporarily lower score.

## Decision flow

```
Is production broken right now?
  yes → /ship hotfix
  no  →
    Do others need to review this?
      yes → /ship pr
      no  →
        Is this a version milestone?
          yes → /ship release [tag]
          no  → /ship
```
