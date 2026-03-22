# Plan Gotchas — Real Failure Modes

These are from real sessions, not hypotheticals. Read before generating moves.

## Data gathering

### Reading 14 sources sequentially
The old SKILL.md listed 14 data sources to read. Claude reads them one by one, burning 5+ minutes before proposing anything. Use `scripts/session-context.sh` instead — one script, one output, all state. If you need deeper detail on one source, read that file specifically.

### Stale eval cache
Eval cache can be days old. If `date` in the cache is >2 days old, note it. Don't plan against stale data without flagging it. The delta field is only meaningful relative to the previous eval, not absolute time.

## Diagnosis

### Sub-score vs raw score blindness
Feature at 55 overall but delivery:40 + craft:75 + viability:50. The delivery bottleneck is invisible if you only read the total. Always look at sub-scores — the weakest dimension is the actual bottleneck, not the average.

### Bottleneck stagnation
Same feature is bottleneck for 3+ sessions. Don't keep proposing the same work. Either:
- The approach is wrong — change the angle
- The feature is genuinely hard — break it into a smaller piece
- The problem is upstream — check dependencies

### Strategy-eval disconnect
strategy.yml says "first-loop" but eval says "learning:35 is worst." Are they the same thing wearing different names, or genuinely different? Name the connection or the disconnect explicitly. Don't let two sources quietly disagree.

### Thesis-task disconnection
Proposed tasks don't connect to roadmap evidence items. Every task should map to an evidence item or explicitly declare it's maintenance. If you can't connect a task to the thesis, question whether the task matters right now.

## Move generation

### Planning as procrastination
Planning feels productive but produces no value until code ships. If the bottleneck is clear after reading session-context output, propose and move. Don't read 3 more files for confirmation.

### Same plan, different words
The previous plan proposed "improve scoring delivery." This plan proposes "enhance scoring's value delivery." That's the same plan. If it didn't work last time, change the approach, not the phrasing.

### Prediction safety
"This will improve things" is ungradable. Force numbers: "raise eval/scoring from 42 to 55." Include "I'd be wrong if [specific condition]." Without falsification, the prediction is performative, not informative.

### Ungraded prediction debt
10+ ungraded predictions means the learning loop is broken. Grade predictions before making new plans — the graded results should inform the next plan. Spawn the grader agent if needed.

### Task inflation
3-5 tasks when 1-2 focused moves would cover it. More tasks = less clarity about what matters most. A move is a feature-level intent, not a checklist item.

## Startup patterns

### Over-triggering on feature sprawl
"Feature sprawl" fires when 3+ features score 30-60 simultaneously. But sometimes breadth is correct at stage one — especially when features are small and independent. Check stage before alarming.

### Under-triggering on polishing
Craft > delivery + 15 catches obvious cases, but doesn't catch the subtler pattern: spending 3 sessions on error handling for a feature that doesn't deliver its core value yet. If delivery_score hasn't moved in 2+ sessions while craft_score climbed, that's polishing by another name.

## Research integration

### Research avoidance
Unknown territory in experiment-learnings relates to the bottleneck, but /plan proposes building instead of researching. Unknown = highest learning value. If the model doesn't know WHY the score is low, one research session teaches more than three build sessions.

### Stale research override
Research from 3 days ago shouldn't silently drive today's plan. If last-research.yml is >24h old, flag it as stale. Let the founder decide whether to re-research or accept the findings.

## Scripts may fail

Scripts in the `scripts/` folder depend on `jq`, `awk`, `grep`. If a script fails:
1. Check the error — is it a missing dependency (`jq: command not found`)?
2. If dependency missing: tell the user (`brew install jq`) and continue with manual inspection
3. If script error: read the script source to understand what it checks, do the check manually
4. Never skip the step — the script output informs the next decision
