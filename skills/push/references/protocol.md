# Push Protocol — Full 7-Step Loop

## 1. Determine maturity level

Read `.claude/cache/eval-cache.json`. Compute weighted average score. Map to maturity ladder (see `maturity-ladder.md`). This determines WHAT you look for and HOW you ideate.

Read `config/founder.yml` stage field as a cross-check — early stage at 85+ is suspicious.

## 2. Extract (Level 1: Mechanical)

Run `bash scripts/extract-gaps.sh .` — get every known gap from:
- `.claude/cache/eval-cache.json` — per-feature gaps with file:line evidence
- `.claude/evals/reports/taste-*.json` — visual dimensions scoring below threshold
- `.claude/evals/reports/flows-*.json` — unfixed behavioral issues

Cross-reference `git log --oneline -20` to filter out gaps that were already fixed (stale eval cache). Mark stale gaps as `[fixed]`.

## 3. Diagnose deeper (Level 2: Analytical)

For each feature, go beyond what eval found:
- Read ALL code in the feature's `code:` paths from founder.yml
- Look for gaps appropriate to the current maturity level (see maturity ladder)
- Check for things eval typically misses: silent error swallowing, inconsistent patterns between files, fragile parsing, missing validation on boundaries

Add diagnosed gaps to the task list with `source: /push:diagnosis`.

## 4. Ideate across five rings (Level 3: Creative)

See `five-rings.md` for the full framework. Weight shifts with maturity:
- Score 40: mostly code + feature rings
- Score 70: mostly product + market rings
- Score 90: mostly vision ring

Tag ideated tasks by ring: `source: /push:code`, `/push:feature`, `/push:product`, `/push:market`, `/push:vision`.

Read `.claude/cache/wrong-prediction-areas.txt` to avoid re-proposing failed approaches.
Read `~/.claude/knowledge/experiment-learnings.md` for patterns that work.

## 5. Display the attack surface

Present using voice.md table format, grouped by maturity level:

```
push  level: polish (67/100)
      N mechanical · N diagnosed · N ideated

                            score  weight  gaps
scoring      69 █████████░░░  ●●●●●    3 + 2 ideated
  · [eval] health gate first-run edge case
  · [diagnosed] three YAML parsers still in eval.sh
  · [ideation] inline sparkline in score output

N tasks total · build? (y/feature/n)
```

If `extract` mode: stop here. Otherwise, ask which features to build (or "all").

## 6. Build

For each feature the founder approved:

1. **Batch by feature.** Work all gaps for one feature before moving to the next.
2. **Mechanical first, ideation last.** Fix known gaps before building new improvements.
3. **Predict every fix.** "I predict [gap fix] moves [feature] [dimension] from X to Y."
4. **Verify after every fix.** `bash bin/eval.sh . --no-llm` — assertions must hold.
5. **Parallel when safe.** Spawn `founder-os:builder` agents for features with non-overlapping code paths.

Stop when:
- Target score reached (if `/push N` was used)
- All tasks in the approved set are done
- Score plateau (3 consecutive fixes with no improvement)

## 7. Measure

After each feature batch:
- Run `bash bin/eval.sh . --no-llm` for mechanical check
- Show before/after per feature
- Grade predictions
- If score improved: continue to next feature
- If plateau: stop, suggest `/eval` for fresh scores
