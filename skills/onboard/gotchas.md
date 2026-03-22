# Onboarding Gotchas

Built from real failure modes. Update this when /onboard fails in a new way.

## Detection failures
- **Monorepo blindness**: detect-project.sh finds the root package.json but misses the actual app in packages/web/ or apps/frontend/. Always check for workspaces, turborepo.json, nx.json, or lerna.json.
- **Framework false negatives**: Custom frameworks won't match any detection rule. If no framework detected but src/ has 50+ files, ask — don't default to "no framework."
- **CLI-as-web mistake**: Projects with package.json but no framework are often CLI tools, not web apps. Check for bin/ entries in package.json before assuming web.

## Config generation failures
- **Placeholder generation**: Writing `delivers: "TODO"` or `for: "users"` defeats the purpose. Every field needs real content from reading the code. If you can't determine it, say so explicitly rather than filling with vague text.
- **Value hypothesis vagueness**: "Makes things better" is not a hypothesis. It must be testable: "[specific person] can [specific action] without [specific pain]." If you can't make it specific, ask the user.
- **Missing value.user**: The most common miss. If founder.yml doesn't name a specific person, every downstream command suffers. "Developers" is not a person. "A React developer adding auth to a side project" is.
- **Stage mis-assessment**: Code polish doesn't indicate maturity. A beautiful MVP with zero users is still stage one. Check git history recency, test coverage, and whether there's a deploy config — not just code quality.

## Feature detection failures
- **Feature over-detection**: Finding 10+ features in a small codebase means you're finding modules, not features. Features deliver user value — a utils/ directory is not a feature.
- **Feature under-detection**: Missing features that live in non-obvious places. A Makefile target that runs the whole deploy pipeline is a feature. A GitHub Action that generates reports is a feature.
- **Weight inflation**: Every feature at weight 5 means nothing is prioritized. The value hypothesis should make weights obvious — what's closest to the core claim gets the highest weight.

## Assertion failures
- **Assertion over-seeding**: Starting with 20 assertions when 5 good ones would build signal faster. Quality over quantity — each assertion should test something that matters.
- **llm_judge overuse**: Starting with llm_judge assertions when a file_check or command_check would be more reliable. Mechanical assertions have zero variance. Use them first.
- **Assertions that always pass**: `file_check: package.json exists` is true for every node project. Test something that could fail and would mean something if it did.

## Learning loop failures
- **Skipping strategy.yml**: Without it, /plan doesn't know the stage or bottleneck. Every onboard must write strategy.yml even if the stage is "unknown."
- **Template roadmap**: Writing a roadmap thesis that's just the value hypothesis copy-pasted. The thesis should be a QUESTION: "Can [hypothesis] be proven by [evidence]?"
