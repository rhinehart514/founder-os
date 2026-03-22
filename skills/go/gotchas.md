# Go Gotchas — Real Failure Modes

Read this before entering the loop. Every entry is from a real session or confirmed pattern.

## Prediction failures

**Ungradable predictions.** "Improve error handling" cannot be graded. The grader agent needs a number to compare against. Always: "raise craft_score from 50 to 65" or "make assertion X pass." If you can't put a number on it, you don't understand what you're building.

**Grading gets skipped.** The most common loop break. You build, measure, move on — forgetting to grade. The prediction taught nothing. The grader agent exists for this reason, but you have to actually spawn it. Grade BEFORE picking the next move, not "later."

**Trivially true predictions.** "I predict the file will exist after I create it." That's not a prediction, it's a tautology. Predict the EFFECT on the user or the metric, not the implementation artifact.

## Build loop failures

**Plateau blindness.** 3 flat moves and you're still iterating on the same approach. The rule is stop, but the temptation is "one more try." If the approach didn't move the score in 3 commits, commit #4 won't either. Run `bash scripts/plateau-check.sh` mechanically — don't trust your judgment here.

**Multi-intent commits.** "Add feature + fix bug + clean up formatting." When this needs reverting, everything goes. One intent per commit. If you're touching 2 features, that's 2 commits.

**Building outside the bottleneck.** You picked a fun feature instead of the one that matters. Check the pre-build scan output — the bottleneck is there for a reason. Building outside it without founder redirect is a red flag.

**Dirty git state at start.** Uncommitted changes make revert impossible and diffs meaningless. Always stash before entering the loop. The pre-build-scan.sh warns about this, but you have to act on the warning.

## Assertion failures

**Assertion gaming.** The builder can make assertions pass by testing the wrong thing — checking file existence instead of behavior, testing the happy path while ignoring edge cases. In beta mode the reviewer catches this. In safe mode, you're on your own. Write assertions with falsification conditions.

**Temporary regression rationalization.** "This assertion regressed but it'll pass after the next commit." No. Revert now, build the bigger change as a single atomic commit that never regresses at any intermediate point.

**Shallow assertions masking plateau.** All assertions pass, score is flat. The assertions test existence ("file has error handling") not quality ("error handling covers all code paths"). Deepen assertions before continuing to build.

## Speculation failures

**Speculating on trivial moves.** Config changes, file renames, assertion additions — these don't need 2 parallel builders. Speculation costs 2x tokens. Save it for genuinely uncertain approaches where you can articulate 2 meaningfully different paths.

**Worktree agent limitation.** Builder agents in worktrees can't spawn sub-agents (fork + Agent are mutually exclusive). They do all work themselves. This is correct but means worktree builds are slower than you'd expect. Don't set aggressive completion expectations for worktree builders.

**Both branches fail.** When both speculative approaches produce assertion regressions, fall back to safe mode with a completely different approach. Don't retry the same approaches without new information.

## Session management failures

**Session log not written.** If /go crashes or gets interrupted, the session YAML never gets written. Lost learning. Write session state incrementally — log to build-log.sh after each move, not just at the end. The session YAML is the final summary, but build-log.sh is the incremental backup.

**Hard gate fatigue.** The founder approves move 1 carefully, rubber-stamps moves 2-5. Front-load risky or uncertain moves when attention is highest. Save the mechanical moves for later in the session.

**Cost tier mismatch.** Using opus builders for config changes, or haiku for complex feature work. Check `~/.claude/preferences.yml` for the cost tier, and match agent models to task complexity. Don't use premium tokens on mechanical work.

## Measurement failures

**Ignoring sub-score direction.** Total score went up but your targeted dimension went down. You accidentally improved something else. The targeted dimension still needs work and you have a false sense of progress. Always check the specific sub-score you were targeting.

**Eval variance.** LLM judge scores vary ~15 points across runs. One eval showing +3 might be noise. If the delta is <5, run `--fresh --samples 2` for a more reliable signal. Don't celebrate or revert on noise.

## Scripts may fail

Scripts in the `scripts/` folder depend on `jq`, `awk`, `grep`. If a script fails:
1. Check the error — is it a missing dependency (`jq: command not found`)?
2. If dependency missing: tell the user (`brew install jq`) and continue with manual inspection
3. If script error: read the script source to understand what it checks, do the check manually
4. Never skip the step — the script output informs the next decision
