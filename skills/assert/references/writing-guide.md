# Writing Good Assertions

Assertions are the north star metric. A bad assertion is worse than no assertion — it gives false confidence. This guide covers what makes an assertion good.

## The hierarchy: mechanical > llm_judge

Every assertion should be as mechanical as possible. The decision ladder:

1. **Can you check a file exists?** -> `file_check` (weakest but deterministic)
2. **Can you grep for specific content?** -> `content_check` (stronger, still deterministic)
3. **Can you run a command and check the output?** -> `command_check` (strongest mechanical)
4. **None of the above work?** -> `llm_judge` (powerful but noisy)

Target ratio: 80% mechanical, 20% llm_judge. If your beliefs.yml is >30% llm_judge, you're leaving too much to variance.

## Specific > vague

Bad: `"score works"` — what does "works" mean?
Good: `"score.sh exits 0 and outputs a number between 0 and 100"`

Bad: `"docs are good"` — good how?
Good: `"README.md contains a ## Quick Start section with at least one code block"`

Bad: `"auth is secure"` — unmeasurable
Good: `"login endpoint returns 401 for invalid credentials"`

The test: could two different people independently agree on whether this assertion passes or fails? If not, it's too vague.

## Testable > aspirational

Bad: `"the product delights users"` — can't be mechanically tested
Good: `"the onboarding flow completes in under 5 clicks"` — measurable

Bad: `"code quality is high"` — means nothing
Good: `"zero TypeScript 'any' types in src/"` — grepable

Aspirational beliefs belong in `roadmap.yml` as thesis evidence, not in `beliefs.yml` as assertions.

## One claim per assertion

Bad:
```yaml
- id: scoring-works
  belief: "score.sh runs, produces a number, handles errors, and is fast"
```

This tests 4 things. When it fails, you don't know which one broke.

Good:
```yaml
- id: score-runs
  belief: "score.sh exits 0"
  type: command_check
  command: "bash bin/score.sh . 2>&1"
  expect_exit: 0

- id: score-outputs-number
  belief: "score.sh outputs a number"
  type: command_check
  command: "bash bin/score.sh . 2>&1 | grep -E '^[0-9]+$'"
  expect_exit: 0
```

## Severity guidelines

- **block** — If this fails, the product is broken. Score should be 0. Use for: core scripts run, config exists, build succeeds.
- **warn** — If this fails, something is wrong but the product still works. Use for: most assertions. Content checks, behavior checks, quality checks.
- **info** — If this fails, it's a signal but not urgent. Use for: nice-to-haves, aspirational checks, trend assertions on young projects.

Default to `warn`. Only use `block` for things that would make the score meaningless if broken.

## Coverage dimensions

Every feature should have assertions across multiple dimensions:

| Dimension | Question | Type |
|-----------|----------|------|
| **Value** | Does it deliver what it claims? | llm_judge on delivers claim |
| **Behavior** | Does it work end-to-end? | command_check |
| **Structure** | Do the right files exist? | file_check, content_check |
| **Regression** | Would a breaking change be caught? | command_check on edge cases |
| **Edge cases** | Does it handle errors gracefully? | command_check on error paths |

The trap: covering only structure (file_check) and calling it "tested." That's testing the menu, not the meal.

## Common mistakes

**Testing the test, not the product:**
```yaml
# Bad — tests that beliefs.yml has entries, not that the product works
- id: has-assertions
  belief: "beliefs.yml has at least 10 assertions"
  type: content_check
```

**Trivially true assertions:**
```yaml
# Bad — this file will always exist, this assertion will never fail
- id: config-exists
  belief: "founder.yml exists"
  type: file_check
  path: config/founder.yml
```

**Fragile path assertions:**
```yaml
# Bad — breaks if the file moves, which is a refactor not a regression
- id: util-exists
  belief: "utils.ts is at src/lib/utils.ts"
  type: file_check
  path: src/lib/utils.ts
```

**Duplicate coverage:**
```yaml
# Bad — both test that score.sh runs, one is redundant
- id: score-runs
  type: command_check
  command: "bash bin/score.sh ."

- id: score-exits-zero
  type: command_check
  command: "bash bin/score.sh . && echo ok"
```

## The upgrade path

When reviewing existing assertions, look for upgrade opportunities:

1. `file_check` on a script -> upgrade to `command_check` that runs it
2. `content_check` for a function name -> upgrade to `command_check` that calls the function
3. Vague `llm_judge` -> split into specific `content_check` + focused `llm_judge`
4. Multiple `file_check` on same feature -> replace with one `command_check` that tests the feature end-to-end
