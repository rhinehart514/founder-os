# Ship Gotchas

Real failure modes from past sessions. Read before shipping, updating the roadmap, or generating copy.

## Deploy

- **Block vs warn confusion**: Pre-flight exits 1 on blocks, 0 on warns. Treat warnings as blocks = nothing ships. Ignore blocks = broken code deploys. Parse the verdict line.

- **Stale eval cache**: Pre-flight reads eval-cache.json but doesn't re-run `/eval`. Warns at >60min but doesn't block. Re-run `/eval` if significant changes since last eval.

- **Deploy confidence is naive**: `assertion_pass_rate x last_3_deploy_success_rate`. Doesn't account for change scope. A 2-line fix and a 500-line rewrite get the same confidence. Use judgment.

- **Verification false positives**: WebFetch checking 200 OK catches total failures but misses subtle breakage. A deploy can return 200 with a blank page or broken JS. `/ship verify` is a starting point, not a guarantee.

- **Rollback without investigation**: Every rollback must produce an investigation todo. Reverting is fast, understanding why is slow.

- **Deploy history fragility**: Local deploy-history.json lives in `.claude/cache/` (can be deleted). Persistent ship-log in `${CLAUDE_PLUGIN_DATA}` survives. Use both.

## Secrets

- **Pattern matching, not entropy**: Secrets check greps the diff with patterns. A variable named `my_secret_sauce = "tomato"` flags. A base64-encoded key without "key" in the name won't.

- **Forced-add .env**: `.env` in .gitignore doesn't help if someone ran `git add -f .env`. Check `git ls-files | grep -i env`.

## Release notes

- **Changelog fiction**: Notes generated from roadmap.yml assume the roadmap is current. If not updated in weeks, notes describe what you planned, not what you built. Cross-reference `git log`.

- **Slop leakage**: Every bullet must trace to a commit, eval delta, or thesis item. If you can't cite evidence, delete the bullet.

- **Version tag mismatch**: `release-notes.sh` reads version from roadmap.yml. If roadmap says v9.0 but you tag v8.4, notes will be wrong. Always pass explicit tag.

## Git operations

- **Force push to main**: Never. Three layers block it. The temptation is real.

- **Revert conflicts**: `git revert` can conflict if reverted commit's files were modified since. Real fix: smaller, more frequent ships.

- **Uncommitted changes during ship**: The flow stages and commits, but unrelated changes can get swept in. Review what's being staged.

## PR creation

- **Feature mapping staleness**: PR body maps changed files to features via founder.yml code paths. Outdated paths = wrong mapping.

- **Empty evidence section**: A PR with "assertions: no data" looks worse than no evidence section. If eval hasn't run, delete the Evidence section.

## Thesis / Roadmap

- **Thesis vs implementation confusion**: "Implemented assertions" is not the thesis. The thesis is what you PROVED. Can you phrase it as a question? If not, it's a task list.

- **Thesis too broad**: 6+ evidence items = question too big. Split or narrow.

- **Thesis as wishlist**: Future versions with no connection to current evidence are fiction. Every thesis emerges from what the previous version proved or failed to prove.

- **Evidence staleness**: Items marked "partial" weeks ago are forgotten. Run `scripts/evidence-tracker.sh`. No movement in 14+ days = wrong thesis or avoidance.

- **Proven without proof**: "It works" is not evidence. "commander.js init scored 80/100" is evidence.

- **Ignoring disproven**: Disproven evidence is the most valuable signal. Write it as a Dead End.

- **Narrative fiction**: Marketing copy overstates what was proven. Every claim traces to a proven evidence item or Known Pattern. Can't cite it? Can't claim it.

- **Version inflation**: Major = new thesis. Minor = significant improvement. Patch = fix. Read `references/version-guide.md`.

- **Premature bump**: If version-progress.sh shows <60% completion, the version isn't ready.

- **Missing thesis transfer**: After proving a major thesis, write it as a Known Pattern in experiment-learnings.md.

- **YAML parse fragility**: Scripts use grep/awk on YAML, not a proper parser. Keep roadmap.yml clean.

## Copy

- **The adjective problem**: LLMs reach for adjectives when they lack specifics. Replace every adjective with the specific thing it claims.

- **Generic value props**: If the copy works with a competitor's name, it's not differentiated. Do the swap test.

- **Feature-listing as copy**: Spec sheets aren't copy. Each feature becomes a benefit sentence for the named person.

- **Aspirational claims**: Only claim what the eval score supports. Features scoring <50 are not claims.

- **Missing person**: Copy that never names who uses it. Start from `founder.yml value.user` or demand-cache.json packages.

- **Hollow differentiation**: "Unlike other tools, we focus on quality" — they all say that. Name the specific competitor and difference.

- **The slop relapse**: LLMs sneak banned words back on revision. Run `slop-check.sh` after every revision, not just the first draft.

- **Marketer voice vs customer voice**: "Boost your productivity" vs what founders actually say: "I can't tell if my product is good." Read `references/customer-language.md` first.

- **AI fatigue blindness**: Founders are burned out on AI promises. Frame around judgment, not speed. Never lead with "AI-powered."

- **The 70% problem**: AI tools solve 70% but leave founders on the hard 30%. If your product addresses the judgment layer, contrast explicitly.

- **Context amnesia**: Forgetting market context mid-generation. Re-read market-context.json before the quality gate, not just at start.
