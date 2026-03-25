# Build Gotchas — Real Failure Modes

Read before any mode. Every entry is from a real session or confirmed pattern.

## Data & measurement

### Stale eval cache
Eval cache can be days old. Check `date` field — if >2 days, flag it. After fixing 5 gaps, eval-cache still shows OLD gaps. Before generating tasks from eval gaps, check `git log --oneline -10` for commits that clearly address a gap.

### No baseline, no comparison
You make a change, it "looks good," you move on. Next /eval shows a 10-point drop and you don't know which task caused it. Always snapshot before. This applies to QUICK mode especially.

### Eval variance
LLM judge scores vary ~15 points across runs. Delta <5 might be noise. Run `--fresh --samples 2` for reliable signal. Don't celebrate or revert on noise.

### Ignoring sub-score direction
Total score went up but targeted dimension went down. You improved something else by accident. Always check the specific sub-score you were targeting.

### Sub-score vs raw score blindness
Feature at 55 overall but delivery:40 + craft:75. The delivery bottleneck is invisible if you only read the total. Always look at sub-scores — weakest dimension is the actual bottleneck.

## Planning failures

### Reading 14 sources sequentially
Don't read data sources one by one, burning 5+ minutes. Use `scripts/session-context.sh` — one script, one output. Read specific files only when you need deeper detail.

### Planning as procrastination
Planning feels productive but ships no value. If the bottleneck is clear after session-context output, propose and move. Don't read 3 more files for confirmation.

### Same plan, different words
Previous plan: "improve scoring delivery." New plan: "enhance scoring's value delivery." That's the same plan. If it didn't work last time, change the approach, not the phrasing.

### Task inflation
3-5 tasks when 1-2 focused moves would cover it. More tasks = less clarity. In QUICK mode, if you have 4+ tasks or 3+ features, route to GO instead.

### Thesis-task disconnection
Every task should map to a roadmap evidence item or explicitly declare it's maintenance. If you can't connect a task to the thesis, question whether it matters now.

### Strategy-eval disconnect
strategy.yml and eval-cache may use different names for the same thing. Name the connection or disconnect explicitly. Don't let two sources quietly disagree.

## Prediction failures

### Ungradable predictions
"Improve error handling" cannot be graded. Force numbers: "raise craft_score from 50 to 65." Include "I'd be wrong if [specific condition]." Without falsification, the prediction is performative.

### Grading gets skipped
Most common loop break. You build, measure, move on — forgetting to grade. Grade BEFORE picking the next move. Spawn the grader agent if needed.

### Trivially true predictions
"I predict the file will exist after I create it." Predict the EFFECT on user or metric, not the implementation artifact. Even in QUICK mode, "I predict this takes 1 commit" counts.

### Ungraded prediction debt
10+ ungraded predictions = broken learning loop. Grade before making new plans.

## Build loop failures

### Plateau blindness
3 flat moves and still iterating. Run `scripts/plateau-check.sh` mechanically — don't trust judgment here. If approach didn't move the score in 3 commits, commit #4 won't either.

### Multi-intent commits
"Add feature + fix bug + clean up formatting." When this needs reverting, everything goes. One intent per commit. Two features = two commits.

### Building outside the bottleneck
Check pre-build scan output — the bottleneck is there for a reason. Building outside it without founder redirect is a red flag.

### Dirty git state at start
Uncommitted changes make revert impossible and diffs meaningless. Always stash before entering the loop.

### Bottleneck stagnation
Same feature is bottleneck for 3+ sessions. Either the approach is wrong, the feature is too big, or the problem is upstream.

## Assertion failures

### Assertion gaming
Making assertions pass by testing the wrong thing — existence instead of behavior, happy path instead of edge cases. Write assertions with falsification conditions.

### Temporary regression rationalization
"This assertion regressed but it'll pass after the next commit." No. Revert now.

### Shallow assertions masking plateau
All assertions pass, score is flat. Assertions test existence not quality. Deepen them before continuing.

## Agent & execution failures

### Speculating on trivial moves
Config changes and file renames don't need parallel builders. Speculation costs 2x tokens. Save for genuinely uncertain approaches.

### Worktree agent limitation
Builder agents in worktrees can't spawn sub-agents. Builds are slower than expected. Don't set aggressive expectations.

### Cost tier mismatch
Using opus for config changes, haiku for complex features. Match agent model to task complexity.

### Session log not written
If interrupted, session YAML never gets written. Log to build-log.sh after each move incrementally.

## Push-specific failures

### Score gaming
Adding comments that explain code can improve "delivery" scores without delivering anything. The eval is a thermometer. Fix the product, not the score.

### Duplicate tasks
If /push runs twice without clearing backlog, you get duplicate todos. Deduplicate against existing todos.yml. Match on first 5 words of title.

### Taste and flows are expensive
Don't trigger /taste from /push. Use cached data. Flag if stale.

### Turn budget
Full /push on 20+ gaps can consume 50+ turns. Scope to one feature when overwhelmed.

## Startup patterns

### Over-triggering on feature sprawl
3+ features scoring 30-60 fires "feature sprawl" but breadth may be correct at stage one with small independent features. Check stage before alarming.

### Under-triggering on polishing
Craft > delivery + 15 is obvious, but 3 sessions of error handling on a feature that doesn't deliver core value is polishing by another name.

### Research avoidance
Unknown territory relates to bottleneck but you propose building instead of researching. One research session teaches more than three build sessions.

## Scripts may fail

Scripts depend on `jq`, `awk`, `grep`. If a script fails:
1. Check the error — missing dependency (`jq: command not found`)?
2. If missing: tell user (`brew install jq`), continue with manual inspection
3. If script error: read the source, do the check manually
4. Never skip the step — script output informs the next decision
