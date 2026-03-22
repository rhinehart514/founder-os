# Shipping Gotchas

Real failure modes from past sessions. Read before every ship.

## Pre-flight

- **Block vs warn confusion**: Some checks block, some warn. If you treat warnings as blocks, nothing ships. If you ignore blocks, broken code deploys. The script exits 1 on blocks, 0 on warns. Parse the verdict line.

- **Stale eval cache**: Pre-flight reads eval-cache.json but doesn't re-run `/eval`. If the cache is hours old, the assertions may have changed. The script warns at >60min but doesn't block. Re-run `/eval` if you've made significant changes since last eval.

- **Deploy confidence is naive**: Computed from `assertion_pass_rate x last_3_deploy_success_rate`. Doesn't account for change scope — a 2-line typo fix and a 500-line rewrite get the same confidence. Use judgment alongside the number.

## Secrets

- **Secrets in existing files**: The check greps the diff, not just filenames. But it uses pattern matching, not entropy detection. A variable named `my_secret_sauce = "tomato"` will flag. A base64-encoded API key without "key" in the name won't. When in doubt, review the diff yourself.

- **Environment files**: `.env` in .gitignore doesn't help if someone ran `git add -f .env` previously. Check `git ls-files | grep -i env` if you're paranoid.

## Release notes

- **Changelog fiction**: Release notes generated from roadmap.yml assume the roadmap is current. If the roadmap hasn't been updated in weeks, the notes describe what you planned, not what you built. Cross-reference with `git log`.

- **Slop leakage**: "Improved performance" and "enhanced user experience" are the release notes equivalent of filler. The template has a ban list. Every bullet must trace to a specific commit, eval delta, or thesis item. If you can't point to evidence, delete the bullet.

- **Version tag mismatch**: `scripts/release-notes.sh` reads the version from roadmap.yml. If roadmap says v9.0 but you're tagging v8.4, the notes will be wrong. Always pass the explicit tag: `/ship release v8.4`.

## Git operations

- **Force push to main**: Never. The skill refuses, the pre-commit hook should catch it, and git itself should block it if branch protection is on. Three layers exist because the temptation is real.

- **Revert conflicts on rollback**: `git revert` can conflict if the reverted commit touched files that have been modified since. The skill asks for resolution approach, but the real fix is smaller, more frequent ships.

- **Uncommitted changes during ship**: The full flow stages and commits, but if you have unrelated uncommitted changes mixed in, you'll ship more than intended. `git status` check warns, but review what's being staged.

## Deploy

- **Verification false positives**: WebFetch checking for 200 OK and title tag catches total failures but misses subtle breakage. A deploy can return 200 with a blank page, a missing feature, or broken JS. If the product is user-facing, `/ship verify` is a starting point, not a guarantee.

- **Rollback without investigation**: Reverting is fast, understanding why is slow. Every rollback must produce an investigation todo. Skipping this means the same bug returns next ship.

- **Deploy history in .claude/cache**: The local deploy-history.json lives in `.claude/cache/` which can be gitignored or deleted. The persistent ship-log in `${CLAUDE_PLUGIN_DATA}` survives plugin upgrades and cache clears. Use both — local for session context, persistent for cross-session trends.

## PR creation

- **Feature mapping staleness**: PR body maps changed files to features via `config/founder.yml` code paths. If those paths are outdated, the mapping is wrong. Features will show as "unaffected" when they're actually the whole point of the PR.

- **Empty evidence section**: A PR body with "assertions: no data" and "score: no data" looks worse than no evidence section at all. If eval hasn't been run, delete the Evidence section rather than showing blanks.
