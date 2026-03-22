# Version Guide

## Version tiers

| Tier | Example | When | Resets completion? | Evidence items |
|------|---------|------|--------------------|----------------|
| **Major** | v10.0 | New thesis. Big question. Changes what "done" means. | Yes — fully | 3-5 items, weeks to prove |
| **Minor** | v9.4 | New capability within current thesis. | Partially | 2-3 items, days to weeks |
| **Patch** | v9.3.01 | Bug fix, polish, push features higher. No new capability. | No | 0-1 items, hours to days |

## When to bump

**Major bump** — the thesis question itself changed. You're no longer asking "does X work?" — you're asking a new question entirely. The previous thesis was proven, disproven, or abandoned.

**Minor bump** — same thesis, but you found a significant sub-question worth tracking. New features emerged, or evidence items were added that change the scope.

**Patch bump** — you fixed something, improved something, but the question hasn't changed. Score improved, assertions were fixed, a regression was caught.

## Auto-detection rules

When `/roadmap bump` is called without a tier:
- Thesis text changed → major
- New features or evidence items added → minor
- Only assertions fixed / score improved → patch

## Version discipline

**Patches (X.Y.01, X.Y.02, ...) are for pushing existing features higher.** If you're fixing bugs, improving scores, adding tests, refining output — that's a patch. Most work is patches. Two-digit patches (01-99) give room for iteration.

**Minors (X.Y) are for new capabilities.** A new skill, a new agent, a new pipeline that didn't exist before. Not improvements — additions.

**Majors (X.0) are for new theses.** The question changed. Everything resets.

**The test:** If someone asks "what's new in 9.4?" and the answer is "we fixed some bugs and pushed scores higher" — that should have been 9.3.1. If the answer is "we added a product discovery pipeline" — that's a minor.

**Common mistake:** Bumping minor for every push session. A session that fixes 6 features is one patch, not six minors. Version numbers should be boring — the product completion percentage is the exciting number.

## Thesis design rules

A good thesis is a question, not a goal.

**Good theses:**
- "Someone who isn't us can complete a loop without help"
- "Score should measure value, not health"
- "The loop works on itself"

**Bad theses:**
- "Ship v2.0" — that's a deadline, not a question
- "Add 5 features" — that's a task list
- "Make it better" — not testable

## Evidence item rules

Each evidence item is a specific, falsifiable claim:
- Must have an `id` (short, hyphenated)
- Must have a `question` (one sentence, answerable yes/no or with data)
- Must have a `status` (todo, partial, proven, disproven)
- When proven, must have `evidence` (specific: a file, a test result, a number)

**Max 5 evidence items per version.** More than 5 means the thesis is too broad — split it.

## Thesis lifecycle

```
new → testing → proven | disproven | abandoned
```

- **proven**: all or most evidence items confirmed. Thesis becomes a Known Pattern in experiment-learnings.md.
- **disproven**: evidence contradicts the thesis. Becomes a Dead End. Often the most valuable outcome — it tells you what's NOT true.
- **abandoned**: external circumstances changed, thesis no longer relevant. Document why.

## When to suggest a bump

When version completion crosses ~80% (most evidence proven, features maturing), surface: "v[X] is nearing proven. `/roadmap bump` when ready."

Never auto-bump. The founder decides when a thesis is answered.
