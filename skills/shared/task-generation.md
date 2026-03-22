# Task Generation Protocol

Shared reference for all skills that generate tasks. Skills reference this file instead of duplicating the protocol.

## First-run mode

Run `bash skills/shared/first-run-detect.sh [project-dir]` before generating tasks.
If result is "first_run", simplify output:
- Show only 3-5 highest-priority tasks (not the full list)
- Skip maturity tier explanations
- Focus on: "run /plan to find what to work on" or "run /score to see where you are"
- Do not reference eval-cache internals, sub-scores, or feature weights
- Use plain language: "Define your features" not "populate eval-cache.json"

## The rule

**Every signal a skill surfaces becomes a task in /todo.** Observations without tasks are reports that sit on shelves. If a skill found something — a gap, a regression, a stale metric, an opportunity — someone needs to do something about it.

## How to generate tasks

1. **Be specific.** "Fix feature X" is not a task. "Feature X delivery gap: /plan returns generic advice when eval-cache is missing — add fallback in plan/SKILL.md line 45" is a task.
2. **Tag the source.** Every task gets `source: /[skill-name]` so the backlog shows where work came from.
3. **Tag the category.** Each skill defines its own task categories (see the skill's "generates tasks for" list). Tag tasks with the category so /todo can filter and prioritize.
4. **Priority follows weight.** Tasks on high-weight features go first. Within a feature, regressions before gaps before polish.
5. **No cap on task count.** A skill that surfaces 15 gaps generates 15 tasks. /plan picks which to work on — the generating skill's job is to ensure nothing is missing.

## How to write tasks to /todo

Write ALL tasks to /todo via the todo system. Each task needs:
- `title`: specific, actionable, includes the target
- `source`: `/[skill-name]`
- `feature`: which feature this affects (if applicable)
- `category`: the task type from the skill's category list
- `priority`: derived from feature weight + severity

## After generating tasks

Show a summary line: "Surfaced N [signals/gaps/findings] -> N tasks added to backlog."

Include the worst/highest-priority item explicitly so the founder sees it without digging.

## What makes a bad task

- Vague ("improve scoring") — no target, no file, no metric
- Duplicate — check /todo before generating; don't pile on
- Cosmetic masquerading as delivery — if the user can't see the difference, it's not a delivery task
- Process tasks ("run /eval") without a WHY — always include what prompted the task
