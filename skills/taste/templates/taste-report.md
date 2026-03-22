# Taste Output Templates

Use these templates for all taste output modes. Copy the structure exactly — the formatting is the product surface.

---

## Full evaluation

```
◆ taste — <url>                              <category>
  calibrated against: <refs or "uncalibrated — cap 70">
  [DEGRADED: uncalibrated eval — run /calibrate for honest scores]

  ▸ slop check
    verdict: <crafted|mixed|slop>  [cap: <none|40>]
    evidence: <what was found>

  ▸ gestalt (3 sentences, before any scoring)
    see:  <what your eyes land on>
    feel: <emotional/instinctive response>
    wrong: <the first thing that bothers you>

  overall   **<score>**/100  ████████████████░░░░  [+/-delta]
  [caps applied: <list of active caps>]
  [FIRST EVAL: -5 penalty applied to all dimensions]

  ▸ gates
    layout_coherence         <score>/100  [+/-delta]  <evidence>
    information_architecture <score>/100  [+/-delta]  <evidence>
    [CAPPED AT 30 — fix the skeleton before decorating]

  ▸ dimensions (weakest first)
    <dim>   <score>/100  [+/-delta]  <evidence>
                          rx: <prescription>
    <dim>   <score>/100  [+/-delta]  <evidence>
                          rx: <prescription>

  ▸ product intelligence (does the surface serve the user?)
    context: delivers "<delivers>" for "<for>"
    · [<signal_strength>] <type>: <element>
      <finding>
      → <opportunity>
    · [<signal_strength>] <type>: <element>
      <finding>
      → <opportunity>
    mental model: <assessment>
    pi verdict: <one sentence — does the surface serve the right user?>
    [skip: no user model — add delivers:/for: to founder.yml features]

  ▸ top 3 fixes
    1. <element> → <change> → <dim> +<N>pts
    2. <element> → <change> → <dim> +<N>pts
    3. <element> → <change> → <dim> +<N>pts

  ▸ trend (if past data exists)
    improving: <dims going up>
    stuck: <dims unchanged 3+ evals>
    regressing: <dims going down>

  ▸ past prescriptions (if past data exists)
    followed: <what was fixed>
    ignored: <what wasn't — and the cost>

  verdict: <would_return + one_thing>

/taste <url>          re-evaluate after changes
/calibrate            ground evals in founder preferences
/go [feature]         build the top fix
```

## Report JSON structure

Write to `.claude/evals/reports/taste-{YYYY-MM-DD}.json`:

```json
{
  "url": "<URL>",
  "timestamp": "<ISO>",
  "overall": 0,
  "dimensions": {
    "<name>": {
      "score": 0,
      "previous": null,
      "delta": null,
      "evidence": "<first-person>",
      "prescription": "<fix or null>"
    }
  },
  "gates": { "layout_coherence": 0, "information_architecture": 0, "capped": false },
  "slop": { "verdict": "crafted|mixed|slop", "signals": 0, "evidence": [], "cap_applied": null },
  "gestalt": { "see": "", "feel": "", "wrong": "" },
  "caps_applied": ["<list of active scoring caps>"],
  "first_eval_penalty": false,
  "product_intelligence": {
    "feature_context": { "delivers": "", "for": "", "stage": "" },
    "opportunities": [
      {
        "type": "surface_mismatch|missing_micro|cognitive_load|revelation_order|mental_model_gap",
        "element": "<specific element>",
        "finding": "<what was observed>",
        "user_impact": "<how this affects the user>",
        "opportunity": "<what to do about it>",
        "signal_strength": "strong|moderate|weak",
        "source": "phase_4.5"
      }
    ],
    "mental_model_assessment": "",
    "revelation_order": "",
    "verdict": ""
  },
  "strongest": "<dimension + why>",
  "weakest": "<dimension + why>",
  "would_return": "<yes/no + reason>",
  "one_thing": "<highest-impact change>",
  "top_3_fixes": [{ "element": "", "change": "", "impact": "" }],
  "routes_evaluated": 0,
  "meta": {
    "mode": "standard",
    "calibration": "full|partial|none",
    "calibration_cap": null,
    "has_past_eval": false,
    "stage": "early|growth|mature"
  }
}
```

## TSV append format

Append to `.claude/evals/taste-history.tsv` (create with header if missing):

```
date	url	overall	hierarchy	breathing_room	contrast	polish	emotional_tone	information_density	wayfinding	distinctiveness	scroll_experience	layout_coherence	information_architecture
```

---

## Trend

```
◆ taste trend

  overall: 42 → 48 → 55 ████████████░░░░░░░░ **improving**
  evals: [N] total · last: [date]

  ▸ improving
    hierarchy          32 → 45 → 58  ↑26
    contrast           40 → 52 → 55  ↑15

  ▸ stuck (3+ evals, <5pt change)
    breathing_room     38 → 40 → 41  — current approach exhausted

  ▸ regressing
    polish             55 → 52 → 48  ↓7

  ▸ prescription effectiveness
    followed: 4 of 6 prescriptions · avg impact: +8pts
    ignored: 2 prescriptions · cost: stuck dimensions

/taste <url>          re-evaluate
/go [feature]         fix stuck dimensions
/research [dim]       new approach for stuck
```

---

## Comparative (`/taste vs`)

```
◆ taste vs — <url1> vs <url2>

  dimension                 [site1]   [site2]   delta
  layout_coherence             62        78     -16  ↓
  hierarchy                    55        60      -5  ↓
  breathing_room               48        72     -24  ↓
  contrast                     70        65      +5  ↑
  polish                       42        88     -46  ↓

  ▸ steal list
    from [site2]: [specific element/pattern] → [dimension] +[N]pts
    from [site1]: [specific element/pattern] → [dimension] +[N]pts

  verdict: [site2] wins on craft, [site1] wins on [specific thing].
  Biggest gap: **polish** (-46pts) — [what to steal].

/taste <url>          re-evaluate after stealing
/clone <url>          clone the winning patterns
/go [feature]         build the improvements
```

---

## Calibrate (redirects to /calibrate)

Calibration is now a separate skill. Run `/calibrate` for:
- `/calibrate profile` — founder taste interview
- `/calibrate design-system` — extract tokens from code
- `/calibrate anti-slop` — build category-specific slop profile
- `/calibrate market` — competitive landscape + 2026 trends
- `/calibrate verify` — check calibration accuracy
- `/calibrate drift` — detect preference/market drift

---

## Flows (`/taste <url> flows`)

```
◆ taste flows — <url>

  ▸ mechanical
    ✓ no console errors
    ✓ no failed network requests
    ✗ MAJOR  <N> click targets under 44px: <element list>
    ✗ MINOR  <N> inputs missing labels: <element list>
    ✓ heading hierarchy valid (h1: <size>px > h2: <size>px)
    ✗ MINOR  missing ARIA landmarks: <list>
    ✓ all images have alt text

  ▸ first contact
    ✓ value prop visible: "<headline text>"
    ✓ primary CTA clear: "<button text>"
    ✗ MAJOR  <finding>

  ▸ core flow: "<description>"
    step 1: <action> → ✓ <result>
    step 2: <action> → ✗ BLOCKER  <what went wrong>
    step 3: <action> → ✓ <result>
    result: <COMPLETE|INCOMPLETE — reason>

  ▸ edge cases
    ✗ MAJOR  empty state: <page> shows blank
    ✗ MAJOR  dead end after <action>
    ✓ deep link to <path> works

  ▸ responsive
    ✗ MAJOR  horizontal scroll at 390px
    ✗ MINOR  nav hidden on mobile, no toggle
    ✓ text readable (body: <size>px)

  ── summary ──
  blockers: <N>  major: <N>  minor: <N>  polish: <N>
  core flow: <COMPLETE|INCOMPLETE>
  verdict: <one sentence — is this ready for users?>

  ▸ fix priority
    1. [<severity>] <element> — <problem> → <fix>
    2. [<severity>] <element> — <problem> → <fix>
    3. [<severity>] <element> — <problem> → <fix>

/taste <url>            visual eval (after flows pass)
/go [feature]           fix the blockers
/taste <url> flows      re-run after fixes
```

## Flows report JSON structure

Write to `.claude/evals/reports/flows-{YYYY-MM-DD}.json`:

```json
{
  "url": "<URL>",
  "timestamp": "<ISO>",
  "mechanical": {
    "console_errors": 0,
    "failed_requests": 0,
    "undersized_targets": 0,
    "unlabeled_inputs": 0,
    "heading_hierarchy_valid": true,
    "aria_landmarks": { "main": true, "nav": true, "header": true, "footer": false },
    "images_without_alt": 0
  },
  "first_contact": {
    "value_prop_visible": true,
    "primary_cta_clear": true,
    "navigation_present": true,
    "placeholder_content": false
  },
  "core_flow": {
    "description": "<what was tested>",
    "steps": [
      { "action": "<what>", "pass": true, "feedback": true, "detail": "<what happened>" }
    ],
    "complete": false,
    "blocked_at": "<step description or null>"
  },
  "edge_cases": {
    "empty_state": { "tested": true, "pass": false, "detail": "<what showed>" },
    "dead_ends": { "tested": true, "pass": false, "detail": "<where stranded>" },
    "deep_links": { "tested": true, "pass": true },
    "long_content": { "tested": false }
  },
  "responsive": {
    "mobile_390": { "horizontal_scroll": true, "nav_accessible": false, "text_readable": true },
    "tablet_768": { "layout_reasonable": true }
  },
  "summary": {
    "blockers": 1,
    "major": 4,
    "minor": 3,
    "polish": 0,
    "core_flow_complete": false,
    "verdict": "<one sentence>"
  },
  "fix_priority": [
    { "severity": "blocker", "element": "<what>", "problem": "<description>", "fix": "<recommendation>" }
  ]
}
```

---

## Formatting rules

- Header: `◆ taste — <url>` with category suffix
- Gate dimensions shown first — if either <30, cap message shown
- Dimensions sorted weakest-first, each with evidence + prescription
- Prescriptions: `rx:` prefix, specific and actionable
- Top 3 fixes: numbered, element → change → dimension impact
- Trend: grouped by improving/stuck/regressing
- Comparative: column-aligned comparison table with deltas
- Calibrate: labeled dividers for profile, design system, dimensions
- Verify: alignment table with expected/actual/gap/status
- Verdict: one-sentence, would the user return + one thing to fix
- Bottom: exactly 3 next commands
