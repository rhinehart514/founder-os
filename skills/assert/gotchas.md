# Assertion Gotchas

Built from real failure modes. Read this before health/coverage/suggest modes. Update when /assert fails in a new way.

## Type selection failures

- **Defaulting to llm_judge**: The lazy path. If you can grep for it, don't judge it. llm_judge produces different results across runs (~15 point variance). Check `references/writing-guide.md` for the decision tree.
- **file_check theater**: 10 file_check assertions all passing = you know files exist. You know nothing about whether they work. Mix types — run `scripts/belief-lint.sh` to check your ratio.
- **command_check on flaky commands**: Commands that depend on network, temp files, or timing will flap. Pin environment or mock dependencies. If a command_check flips 3+ times in 10 runs, it's the assertion that's broken, not the code.

## Writing failures

- **Vague beliefs**: "auth works" is not testable. "login endpoint returns 200 with valid credentials" is. The test: could two people independently agree on pass/fail? If not, rewrite.
- **Multi-claim assertions**: "score runs, outputs a number, and handles errors" — when it fails, you don't know what broke. One claim per assertion.
- **Trivially true assertions**: file_check on `config/founder.yml` will always pass. content_check for a word that appears 50 times will always pass. These are furniture, not tests.
- **Aspirational beliefs**: "users love the product" belongs in roadmap.yml as thesis evidence, not beliefs.yml as an assertion. Assertions must be evaluatable NOW.

## Coverage failures

- **Structure-only coverage**: All file_check + content_check = you tested the menu, not the meal. Every feature needs at least one command_check or llm_judge that tests behavior.
- **Piling on well-covered features**: 8 assertions on scoring, 0 on deploy. Diminishing returns. Cover uncovered features before deepening covered ones.
- **No regression assertions**: Assertions that test the happy path won't catch edge case regressions. Add command_checks for error paths: bad input, missing files, malformed config.

## Management failures

- **Removing failing assertions**: Failing assertions are the signal, not the problem. Removing hides the bug. The default is to fix the code, not delete the test.
- **Ignoring flapping**: Assertions that oscillate pass/fail waste attention every eval run. Either fix the underlying instability or tighten the assertion scope. Don't just live with it.
- **Orphaned assertions**: Assertions for killed features still count toward pass rate. Clean up after `/feature kill`. Run `scripts/assertion-stats.sh` to find coverage gaps.
- **Severity inflation**: block severity halts `/go`. Reserve it for things that would make the score meaningless (core scripts broken, config missing). Default to warn.
- **Gaming pass rate**: Adding easy-to-pass assertions to inflate the number. Pass rate with 3 real assertions beats pass rate with 20 trivial ones.

## Graduation failures

- **Graduating too early**: A todo that occurred once is not a pattern. Wait for 2+ occurrences before graduating to a permanent assertion.
- **Graduating without upgrading**: Todo says "fix score output." Graduated assertion should be a command_check that tests score output, not a vague llm_judge. Graduation is a type upgrade opportunity.
