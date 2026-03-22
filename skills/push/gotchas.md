# Push Gotchas

## Stale eval cache

The biggest failure mode. After you fix 5 gaps, the eval-cache.json still shows the OLD gaps. Extract-gaps.sh pulls from the cache as-is. Before generating tasks from eval gaps, check `git log --oneline -10` — if recent commits clearly address a gap, mark it as already-fixed.

## Duplicate tasks

If /push runs twice without clearing the backlog, you get duplicate todos. Always deduplicate against existing todos.yml before writing. Match on first 5 words of title.

## Score gaming

It's possible to move eval scores by changing the code that eval reads without actually improving the product. For example: adding comments that explain what code does can improve "delivery" scores without delivering anything new. The eval isn't a test to game — it's a thermometer. Fix the product, not the score.

## Taste and flows are expensive

Don't trigger /taste or /taste flows from /push. Use whatever cached data exists. If it's stale, flag it but don't spawn Playwright sessions — that's /taste's job.

## Turn budget

A full /push loop on 20+ gaps can consume 50+ turns. Consider scoping to one feature (`/push scoring`) when the full list is overwhelming. Or use `extract` mode to see the gap list without building.
