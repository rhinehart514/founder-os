# /founder feature — Feature Management

Define, view, detect, and improve features. Every feature lives inside a system and serves a job.

## Routing

| Input | Action |
|-------|--------|
| `feature` (no args) | List all features with scores, weights, systems |
| `feature [name]` | Show feature detail — scores, assertions, system, jobs served |
| `feature new` | Define a new feature (guided) |
| `feature detect` | Auto-detect features from codebase |
| `feature improve [name]` | Route to `/ideate [feature]` |
| `feature kill [name]` | Archive feature, update founder.yml |

## Feature contract

Every feature in `config/founder.yml` must have:

```yaml
features:
  feature-name:
    delivers: "[what value — outcome, not implementation]"
    for: "[specific person in a specific situation]"
    code: ["path/to/main/files"]
    weight: 1-5
    system: "[owning system name]"  # REQUIRED — which product domain owns this
```

## `feature new` protocol

1. **Name**: short, kebab-case
2. **Delivers**: what changes for the user (outcome, not implementation)
3. **For**: named person in a situation ("solo founder who just got a new idea"), not "users"
4. **Code**: primary file paths
5. **Weight**: 1 (nice-to-have) to 5 (core to thesis)
6. **System assignment** (REQUIRED): which system owns this feature?
   - Read `skills/shared/system-thinking.md` for system identification
   - Check existing systems in `config/founder.yml` — does this feature belong to one?
   - If no system fits: either the feature is misscoped OR a new system is needed. Ask via AskUserQuestion.
   - If feature spans multiple systems: coupling smell. Either split the feature into system-scoped pieces, or the system boundaries are wrong. Flag it.
7. **Job mapping**: which functional/emotional/social job does this serve? Check `demand-cache.json` jobs.
8. Write to `config/founder.yml`
9. Log prediction: "I predict [feature] will score [X] on first eval because [Y]"

## Feature listing

Show features grouped by system:

```
◆ features

  SYSTEM: measurement
    scoring     78 (d:82 c:70) w:5  ██████████
    evaluation  64 (d:68 c:58) w:4  ████████░░

  SYSTEM: discovery
    demand      52 (d:55 c:48) w:4  ██████░░░░
    ideation    45 (d:50 c:38) w:2  █████░░░░░

  ORPHAN (no system):
    ⚠ dashboard  58 (d:62 c:50) w:3  — needs system assignment
```

## System assignment validation

On every `feature` invocation (list or detail), check:
- Features with no `system:` field → flag as orphan
- Features whose `system:` names a system with no other features → flag as potentially over-decomposed
- Features that span code paths in multiple systems → flag as coupling smell

## Scripts

- `scripts/feature-map.sh` — list features with scores
- `scripts/feature-health.sh` — per-feature health check
- `scripts/dependency-graph.sh` — feature dependency visualization

## Self-evaluation

- `feature new`: all 7 fields populated (including system), prediction logged
- `feature list`: grouped by system, orphans flagged
- `feature [name]`: shows scores, system, jobs served, assertions

## What you never do

- Accept "users" as the `for` field — name the person
- Accept implementation as `delivers` — name the outcome
- Skip system assignment — every feature needs a home
- Set weight to 5 for everything — that means nothing is prioritized
