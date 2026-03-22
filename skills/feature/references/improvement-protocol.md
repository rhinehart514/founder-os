# Feature Improvement Protocol

Loaded on demand when `/feature [name] ideate` is triggered. This is the full method for producing specific, evidence-backed improvement prescriptions for an existing feature.

## Phase 1: See the product (mandatory)

Before prescribing anything, you must SEE what exists:

1. **Run `scripts/feature-ideate.sh`** — gathers eval sub-scores, taste data, flow issues, backlog items, predictions, assertions, and git history for this feature. Zero context cost.
2. **Run `skills/plan/scripts/intelligence-query.sh`** — checks accumulated intelligence: past research, market context, customer intel, past ideation for this feature.
3. **Read the code** — from the feature's `code:` field in founder.yml. Components, scripts, routes, data flow. You need to SEE the product surface to prescribe improvements.
4. **Read rubric** — `.claude/cache/rubrics/[feature].json` if it exists. The rubric names the specific gaps the evaluator found.
5. **Read market context** — `.claude/cache/market-context.json`, `.claude/cache/feature-research-[name].json`, or `documents/` folder. What do best-in-class products do for this type of feature?

## Phase 2: Diagnose the gap

Name the gap between what this feature IS and what it SHOULD be:

- **Delivery gap (d: low)** — the feature doesn't fully work. Missing functionality, broken flows, dead ends. Fix these FIRST.
- **Craft gap (c: low)** — the feature works but it's rough. Poor output quality, confusing interactions, no delight. Fix after delivery.
- **Viability gap (v: low)** — the feature works and is well-made, but does anyone care? Wrong audience, unclear value, no return trigger.

Cite the specific sub-scores. "Craft at 40 while delivery is 65 — the feature works but the output quality is dragging."

## Phase 3: Generate improvement prescriptions

3-5 prescriptions, each with this structure:

```
▸ **[Improvement Name]** — [element being changed]

  see: [What exists right now. Name the element, current state, user experience.]

  problem: [Why this is a problem. Cite score, taste dimension, flow issue, dead end.
  "empty state shows nothing" not "UX could be better."]

  rx: [The prescription. 2+ options when possible.]
      Option 1: [approach] — [tradeoff] → [sub-score] +[N]pts
      Option 2: [approach] — [tradeoff] → [sub-score] +[N]pts

  reference: [Best-in-class products. Name the product, the specific pattern.]

  impact: [Which sub-score moves? By how much? Which assertion passes or gets created?]

  cost: [Rough effort. "2 hours — new component" or "1 session — refactor needed."]

  builds on: [Existing backlog items, past prescriptions, partial work this connects to.]
```

### Quality checks
- If `see` is empty → you haven't looked at the feature
- If `problem` doesn't cite a score or evidence → you're guessing
- If `rx` says "improve" or "better" without specifics → too vague
- If `reference` is empty → check competitor products first
- If `impact` has no number → not measurable
- If `builds on` is empty → check backlog and past evals first

## Phase 4: Prioritize by leverage

Order by: (impact on weakest sub-score) x (evidence strength) / (implementation cost).

1. First: fixes that unblock the core loop (delivery gaps, dead ends, blockers)
2. Second: improvements that make the feature memorable (craft gaps, delight)
3. Third: polish that compounds (consistency, edge cases, performance)

## Phase 5: Kill list (mandatory)

Feature improvement isn't just adding — it's removing:
- What interactions are confusing and should be simplified?
- What config options should become smart defaults?
- What edge cases are handled that nobody hits?
- What code complexity exists for hypothetical future needs?

## Phase 6: Present + materialize

Present prescriptions + kill list via AskUserQuestion. When founder picks:

**For each committed improvement:**
- Write todo with `source: /feature ideate`, feature name, specific element + change
- Log prediction: "[improvement] will raise [feature] [sub-score] from X to Y"
- If improvement builds on existing todo → close or update that todo

**For each kill decision:**
- Write todo to remove/simplify the element
- Log why it was killed

## Anti-patterns

- **"Improve the UX"** — too vague. Name the element, the change, the impact.
- **Prescribing without seeing** — if you haven't read the code and scores, you're guessing.
- **Copying competitors blindly** — "Linear does it" isn't a reason. "Linear does it because [mechanism] and our users have the same need" is.
- **All polish, no delivery** — if the feature doesn't work end-to-end, don't suggest animations.
- **Ignoring what's already there** — check the backlog and past taste prescriptions before generating new ideas.
- **Duplicating /ideate** — `/feature ideate` is for improving THIS feature. For new feature ideas, use `/ideate`. For broader product direction, use `/product`.
