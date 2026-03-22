# Tier Routing — What to Recommend at Each Maturity Level

Determine the tier from eval-cache scores. Verify with `bash ../../bin/maturity-tier.sh` if uncertain.

## Tier table

| Tier | Score range | /plan behavior |
|------|-------------|---------------|
| **fix** (<50) | Only propose fix tasks. No ideation, no research, no strategy. |
| **deepen** (50-70) | Propose tasks from eval gaps. Run /eval inline if stale. |
| **strengthen** (70-85) | Target weakest sub-scores on highest-weight features. Suggest /research for unknowns. |
| **expand** (85+ score, <70 eval avg) | Structure solid, features shallow. Deep eval tasks. Only /ideate if bottleneck needs new capabilities. |
| **mature** (85+ score, 70+ eval avg) | Shift from "fix" to "what's next." Suggest /ideate, /research, /strategy, /taste, /product. Building new code is secondary. |

## Tier behavior details

**At fix/deepen:** stay focused on assertions and health. No ideation, no strategy deep-dives.

**At strengthen:** research becomes valuable. If the bottleneck feature has entries in Unknown Territory (experiment-learnings.md), recommend /research before building. Exception: if the unknown is cheap to test by building (<1 hour), skip research and build the experiment directly.

**At expand/mature:** surface unknown territory as primary opportunities. Check if /ideate, /research, /strategy have been run recently — recommend them if not. The bottleneck is no longer "what's broken" — it's "what's missing."

**Mature tier priorities:**
1. Unknown territory experiments (highest learning value)
2. Skills the founder hasn't used (/ideate, /strategy, /product, /money)
3. Feature gaps identified by /ideate or /research
4. Visual quality (/taste) if web-facing

**The tier gates ideation.** Don't suggest /ideate at fix or deepen. It's earned by getting features to a solid state first.
