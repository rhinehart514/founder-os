---
name: assert
description: "Use when the user wants to add, check, remove, or audit assertions — chat-native beliefs.yml management including coverage analysis and graduation from todos"
argument-hint: "[feature: belief text] or [list|check|remove|graduate|health|coverage|suggest|flapping] [id|feature]"
allowed-tools: Read, Write, Bash, Edit, Grep
user-invocable: false
---

<!-- INTERNAL: This skill is for founder-os self-management, not marketplace distribution. -->

# /assert

Manage assertions in `lens/product/eval/beliefs.yml`. Add, remove, audit, suggest. Does NOT run assertions — that's `/eval`.

## Skill folder structure

This skill is a **folder**, not just this file. Read on demand:

- `references/assertion-types.md` — all types with examples and when-to-use guidance
- `references/writing-guide.md` — how to write good assertions (mechanical > llm_judge, specific > vague)
- `templates/assertion-template.yml` — copy-paste template for each assertion type
- `reference.md` — output formatting templates
- `gotchas.md` — real failure modes. **Read before health/coverage/suggest modes.**

Scripts (`assertion-stats.sh`, `belief-lint.sh`, `assertion-diff.sh`) exist as verification — run to cross-check your analysis, not as the primary path.

## State

Read these directly — synthesize, don't delegate:

| File | What it tells you |
|------|-------------------|
| `lens/product/eval/beliefs.yml` | All assertions: id, feature, type, severity, expected, path/command |
| `config/founder.yml` | Features, weights, code paths — for coverage mapping |
| `config/product-spec.yml` | What the product claims — assertions should test these claims |
| `.claude/cache/eval-cache.json` | Sub-scores — which features need more assertions |
| `.claude/plans/todos.yml` | Graduation candidates (recurring todos → assertions) |
| `.claude/evals/assertion-history.tsv` | Pass/fail trends — spot flapping, regressions |

**You can read beliefs.yml directly.** Count assertions by feature and type. Check for duplicates by scanning ids. Compute mechanical-vs-llm ratio. Identify coverage gaps by cross-referencing features in founder.yml. This is YOUR analysis work — scripts verify it.

## Routing

Parse `$ARGUMENTS`:

| Pattern | Mode | Action |
|---------|------|--------|
| Contains `:` | quick-add | Parse `feature: belief text`, auto-detect type, append to beliefs.yml |
| `list [feature]` | list | Read beliefs.yml, group by feature, show type + pass/fail from eval-cache |
| `check [id]` | check | Run single assertion via `founder eval . --no-generative` |
| `remove [id]` | remove | Anti-rationalization gate if failing, then remove |
| `graduate [todo-id]` | graduate | Convert todo to assertion, show proposed, confirm |
| `health` | health | Read beliefs.yml — lint for duplicates, type distribution, mechanical-vs-llm ratio, coverage gaps per feature. Verify with `belief-lint.sh`. |
| `coverage [feature]` | coverage | Dimension matrix: value/behavior/structure/regression/edge |
| `suggest [feature]` | suggest | Read code + claims, generate 2-3 assertions for gaps |
| `flapping` | flapping | Read assertion-history.tsv, find oscillating pass/fail patterns |
| `diff` | diff | Read assertion-history.tsv, compare against beliefs.yml — what's new, newly passing, newly failing. Verify with `assertion-diff.sh`. |

### Quick-add details

1. Parse feature (before `:`) and belief text (after `:`)
2. Auto-detect type: file path mention -> `file_check`, "contains"/"has" -> `content_check`, "command"/"runs" -> `command_check`, "score"/"trend" -> `score_trend`, else -> `llm_judge`
3. Generate id from feature + key words. Check for duplicates via Grep.
4. Default severity: `warn`. Append to beliefs.yml.
5. Flag w:5 features with 0 existing assertions as high priority.

### Remove gate

If the assertion is **failing**: "This assertion is failing. Failing assertions are the signal, not the problem. Removing it hides the bug." Require explicit confirmation. If passing/stale: proceed.

### Suggest protocol

Read feature's `code:` paths + `delivers:` claims from founder.yml. Read existing assertions. Read `references/writing-guide.md`. Generate assertions that fill gaps: prefer mechanical types, target uncovered dimensions.

## Anti-rationalization checks

Flag during any mode:
- Removing a failing assertion -> warn
- All file_check for a feature -> "proves files exist, not that they work"
- 100% pass rate with <3 assertions -> "not enough coverage"
- Adding to well-covered feature when uncovered features exist -> redirect

## Task generation — the path to full assertion coverage

**/assert's job is not just managing assertions. It's generating EVERY task needed to reach comprehensive coverage.** If a feature has gaps in assertion coverage, those gaps should become tasks. The backlog drives what gets asserted next.

**For EVERY coverage gap found, generate the complete task list:**

### Coverage gap tasks (from health/coverage modes)
- Each feature with 0 assertions → task: "Feature [X] has zero assertions — add 3 (1 file_check, 1 content_check, 1 command_check)"
- Each feature with <3 assertions → task: "Feature [X] has only [N] assertions — add [3-N] more"
- Each feature with only file_check assertions → task: "Feature [X] only proves files exist — upgrade to content_check or command_check"
- Each feature with only llm_judge assertions → task: "Feature [X] relies on LLM judgment — add mechanical assertions"

### Type distribution tasks
- No command_check assertions for a feature with CLI/scripts → task: "Feature [X] has scripts but no command_check — add one"
- No content_check for a feature with config/output files → task: "Feature [X] has output files but no content_check — add one"
- >50% llm_judge for any feature → task: "Feature [X] is [N]% llm_judge — replace weakest with mechanical"
- No score_trend assertions for scored features → task: "Feature [X] is scored but has no score_trend assertion — add floor"

### Signal quality tasks
- Each always-passing assertion that tests existence not behavior → task: "Assertion [id] always passes — strengthen to test behavior"
- Each flapping assertion → task: "Assertion [id] is flapping — investigate root cause and stabilize or rewrite"
- Each assertion with vague expected value → task: "Assertion [id] has vague expectation — make specific"
- Each newly failing assertion → task: "Assertion [id] newly failing — fix the code or update the belief"

### Graduation tasks (from todo candidates)
- Each todo that's been done 3+ times → task: "Todo [id] recurs — graduate to assertion via /assert graduate"
- Each todo that matches a belief pattern → task: "Todo [id] should be an assertion — graduate it"

### High-weight feature tasks
- Each w:5 feature with <5 assertions → urgent task: "Critical feature [X] has thin coverage — add assertions"
- Each w:4+ feature with no block-severity assertions → task: "High-weight feature [X] has no blockers — add block assertion on core behavior"

**Write ALL tasks to /todo.** Tag with `source: /assert`, feature name, and gap type (coverage/type/signal/graduation). Priority: highest-weight features with lowest coverage first.

**There is no cap on task count.** A project with 7 features and thin coverage might need 25 assertion tasks. Generate all of them.

After writing tasks, show: "Generated N assertion tasks across M features. Worst coverage: [feature] with [N] assertions needs [X] more."

## Self-evaluation

The skill worked if:
- **Quick-add**: assertion was appended to beliefs.yml with no duplicate ids and correct type detection
- **Suggest**: generated assertions that fill actual coverage gaps (not duplicates of existing assertions)
- **Health/coverage**: dimension matrix was rendered AND tasks were generated for every gap
- **All modes**: anti-rationalization checks fired when applicable (failing removal, weak coverage)

## llm_judge confidence

When auto-detecting type, `llm_judge` is the fallback for beliefs that can't be mechanically verified. It has lower confidence than mechanical types: LLM judges produce ~15-point variance across runs. Prefer `file_check`, `content_check`, `command_check`, or `score_trend` whenever possible. If a quick-add defaults to `llm_judge`, flag it: "This belief will be LLM-judged (variable confidence). Can it be rewritten as a mechanical check?"

## What you never do

- Add duplicate ids
- Default to `block` severity (use `warn`)
- Remove failing beliefs without the anti-rationalization warning
- Modify eval.sh or score.sh (immutable eval harness)
- Graduate a todo without showing proposed assertion first
- Suggest assertions for features not in founder.yml

## System integration

**Reads:** beliefs.yml, founder.yml, product-spec.yml, eval-cache.json, todos.yml, assertion-history.tsv
**Writes:** `lens/product/eval/beliefs.yml` (add/remove/graduate)
**Triggers:** /eval (after adding assertions), /todo (graduation candidates), /go (coverage tasks)
**Triggered by:** "add a test", "assert", /plan coverage gaps, /eval weak features, /feature coverage analysis

## Error handling

- **No beliefs.yml**: Create at `lens/product/eval/beliefs.yml` with header
- **Feature not in founder.yml**: Still add for quick-add; skip in health/coverage/suggest
- **Ambiguous type**: Default to `llm_judge`
- **Id collision**: Append number (e.g., `auth-login-2`)
- **No history data**: Note "Run `/eval` twice for trend data"

For output templates, see [reference.md](reference.md).

## If something breaks

- beliefs.yml parse error: check YAML indentation, run `python3 -c 'import yaml; yaml.safe_load(open("lens/product/eval/beliefs.yml"))'`
- "Feature not found" on suggest/coverage: feature name must match a key in `config/founder.yml` features section
- Duplicate id collision on quick-add: check existing ids with `grep '^  id:' lens/product/eval/beliefs.yml`, append a number to disambiguate
- assertion-stats.sh returns empty: beliefs.yml may be missing or empty, run `/assert health` to diagnose

$ARGUMENTS
