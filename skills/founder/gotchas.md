# /founder Gotchas

Built from real failure modes across sessions. Update this when /founder fails in a new way.

## Data failures
- **Missing jq**: system-pulse.sh needs jq for JSON parsing. If jq is missing, score/eval/bottleneck sections silently fail. Check `command -v jq` at the top and warn.
- **Stale score-cache**: score-cache.json is only updated when `founder score .` runs. The dashboard shows the cached score, not the real one. If last commit changed code, the cached score may be wrong. Note the cache age.
- **eval-cache without founder.yml weights**: eval-cache has scores but bottleneck computation needs weights from founder.yml. Missing weights default to 1, which makes the bottleneck wrong for any project with intentional weighting.
- **predictions.tsv fallback path**: The script checks project-local first, then `~/.claude/knowledge/`. If both exist, it reads the project-local one. This is correct but surprising — a project can shadow the global predictions file.
- **Portfolio file location**: `~/.founder-os/portfolio.yml` is global (cross-project). `config/portfolio.yml` is local. The dashboard reads the global file for the portfolio summary zone. If only the local file exists, no portfolio zone renders.

## Rendering failures
- **Dashboard addiction**: Checking /founder repeatedly without building. The dashboard shows state, it doesn't change state. If someone runs /founder 3+ times in a session without a commit between them, note it.
- **Opinion over-scripting**: The decision tree produces mechanical advice. The tree is a starting point — override it when judgment says otherwise. A feature at eval 31 that just jumped from 20 is momentum, not "needs work."
- **Zombie zones**: Rendering a zone with data that's weeks old looks active but is actually dead. Check modification times. A plan from 5 days ago is not "active."
- **Bar width rounding**: Score bars use 20-char width. Scores like 3, 7, 13 round to the same bar width. Don't rely on bar visual for small differences — always show the number.
- **Portfolio zone bloat**: With many ideas, the portfolio summary can dominate the dashboard. Cap at 5 active ideas shown. If more exist, show top 5 by recency and note "[N] more active ideas."

## Snapshot failures
- **Snapshot bloat**: founder-snapshots.json grows unbounded if you forget to trim. Keep last 20, prune older. The script doesn't auto-trim — you must enforce this.
- **Snapshot-less compare**: `/founder compare` with 0 snapshots should say "First snapshot" and stop. Don't try to diff against nothing.
- **Pattern detection false positives**: "Bottleneck stagnation" fires when working on a hard problem that legitimately takes multiple sessions. Not every stall is wrong. Check if the bottleneck score is actually moving (even slowly).

## Anti-rationalization failures
- **Score-product divergence**: Score improves while product doesn't (assertion gaming) or product improves while score doesn't (formula lag). Both are real. Flag both.
- **Health grade inflation**: The A-F grade can show A when the learning loop is broken (predictions ungraded for weeks). Weight the learning loop subsystem heavily — a system that doesn't learn is grade C at best regardless of other subsystems.
- **Prediction avoidance masking**: If there are zero predictions, accuracy shows "--" which looks neutral. Zero predictions is worse than 30% accuracy — the system is blind.

## Script failures
- **skill-catalog.sh on non-standard layouts**: The script expects `skills/*/SKILL.md` convention. Skills installed in non-standard paths (nested, different naming) won't appear. This is by design but confusing when a skill exists but doesn't show in help.
- **compute-bottleneck.sh missing**: If the shared bin script isn't executable or doesn't exist, bottleneck falls back to "none computed." The opinion then has no bottleneck to act on — it should fall through to plan-based or thesis-based opinions instead.
