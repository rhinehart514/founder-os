# Ship Checklist

The full pre-ship checklist. `scripts/pre-flight.sh` automates most of these, but understanding what each check does helps you know when to override.

## Hard stops (BLOCK)

These prevent shipping. Fix them or explicitly downgrade severity.

### Score below 30
The product health is critically low. Something fundamental is broken — build errors, missing structure, severe hygiene issues. Shipping in this state deploys a broken product.

### Block-severity assertions failing
Assertions marked as block severity exist because their failure means the core value proposition is broken. If the assertion is wrong, delete it. If it's right, fix the code.

### Secrets in diff
API keys, passwords, tokens, or credentials detected in the staged diff. Once pushed, secrets are in git history forever. Remove them, rotate the credential, add to .gitignore.

### Deploy confidence below 50%
Computed as `assertion_pass_rate x last_3_deploy_success_rate x 100`. Below 50% means either assertions are failing or recent deploys have been unstable. Both are reasons to pause.

## Warnings (WARN)

These don't block but should be acknowledged before shipping.

### Warn-severity assertions failing
Less critical than block, but still tracked beliefs about the product. Acknowledge which are failing and why you're shipping anyway.

### Features scoring below 50
The eval says these features aren't delivering value yet. Shipping them is fine if this deploy is about something else, but don't pretend they're ready.

### Score regression since last deploy
Current score is lower than the score recorded at last deploy. Something got worse. Maybe intentionally (refactor in progress), maybe not.

### Eval cache stale (>1 hour)
The eval data is old. The product may have changed since the last eval. Re-running `/eval` takes a minute and gives you current data.

### Large changeset (>20 files)
Big changesets are harder to reason about and harder to rollback cleanly. Consider splitting into multiple ships.

### No changelog
No CHANGELOG.md or cached changelog exists. Run `/ship changelog` to generate one. Not critical for deploys, but important for releases.

### Multiple warnings (>3)
Any single warning is fine. Three or more warnings together suggest the ship isn't as ready as it feels. Review the full list before proceeding.

## Informational (release ships only)

These are surfaced for release-type ships but never block.

### GTM strategy
Does `.claude/cache/gtm-strategy.json` exist? If you're doing a public release, having a distribution plan helps. Run `/money gtm` to create one.

### Customer signal
Does `.claude/cache/customer-intel.json` exist? Releases informed by customer feedback land better. Run `/research customer` to gather signal.

### Narrative freshness
Is `.claude/cache/narrative.yml` current? Stale narrative means release notes may not reflect the current product story. Run `/roadmap narrative` to refresh.

## When to override

- **Hotfix path**: Score check is skipped. You're fixing something broken in production — speed matters more than ceremony.
- **First deploy**: No deploy history exists. Confidence can't be computed. Ship it and start building history.
- **Intentional regression**: Refactoring sometimes temporarily lowers scores. If you know why, acknowledge and ship.
