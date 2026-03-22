# Advanced Ship Modes

Secondary capabilities. Claude discovers these when the situation calls for them.

## Dry run (`/ship dry` or `/ship check`)

Pre-flight only. Run `scripts/pre-flight.sh`, show results, generate tasks for blockers. No git operations.

Useful for: checking readiness before committing, generating the task list of what blocks a ship.

## Hotfix (`/ship hotfix`)

Fast path. Skip score check. Commit, push, deploy, log.

Use when production is broken and users are affected NOW. The fix should be targeted and small. Still checks for secrets. Still logs to deploy history.

Don't use when: you're nervous about a normal ship (that's what pre-flight is for), the "fix" is actually a feature, or you haven't identified what's broken.

## Pull request (`/ship pr [base]`)

Read `templates/pr-body.md`. Fill from git log + eval-cache + roadmap. Open PR via `gh pr create`.

Maps changes to features and thesis evidence. The body answers "why this matters" not "what files changed."

Use when: changes need review, CI gates merges, or you want a permanent record of why.

## Changelog (`/ship changelog`)

Generate or update CHANGELOG.md from roadmap data + git history.

## Verify (`/ship verify <url>`)

Post-deploy check. WebFetch the URL, check: HTTP status, response time, title tag, headline, error markers. Compare to last verification.

Catches total failures but misses subtle breakage. A deploy can return 200 with a blank page. This is a starting point, not a guarantee.

## Rollback (`/ship rollback`)

Read deploy history. `git revert` last deploy commit. Push. Redeploy.

**Mandatory**: create an investigation todo. Every rollback needs one. Skipping this means the same bug returns next ship.

If revert conflicts with subsequent commits, resolve manually then re-run `/ship verify`.

## History (`/ship history`)

Read `${CLAUDE_PLUGIN_DATA}/ship-log.jsonl` (fall back to `~/.claude/cache/ship-log.jsonl`). Show recent entries + stats.

Each entry: `{timestamp, type, version, commit, score, features, target, pr, tag}`.

Compute: total ships, ships by type, last ship, score trend from last 5 entries with scores.

## Task generation for all modes

Every pre-flight blocker or warning becomes a task in /todo (tagged `source: /ship`):

**Blockers**: score regressed, block-severity assertion failing, secrets detected, eval stale >7d
**Warnings**: warn-severity assertions failing, score flat, uncommitted changes, no changelog
**Release-specific**: no GTM strategy, no customer signal, narrative stale, no release notes
**Post-ship**: verification not run, predictions not graded
**Rollback**: investigation todo (mandatory), assertions that should have caught it, prediction grading
