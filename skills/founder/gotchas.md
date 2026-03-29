# /founder Gotchas

Merged from: founder, onboard, feature, todo, assert, configure, skill, money. Update when any mode fails in a new way.

## Dashboard

- **Missing jq**: system-pulse.sh needs jq. Check `command -v jq` and warn.
- **Stale score-cache**: only updated when `founder score .` runs. Note cache age.
- **eval-cache without weights**: missing weights default to 1, making bottleneck wrong for weighted projects.
- **predictions.tsv fallback**: project-local shadows `~/.claude/knowledge/`. Correct but surprising.
- **Portfolio file location**: `~/.founder-os/portfolio.yml` is global. `config/portfolio.yml` is local. Dashboard reads global.
- **Dashboard addiction**: /founder 3+ times without a commit between = avoidance, not progress.
- **Opinion over-scripting**: decision tree is a starting point. Override when judgment says so.
- **Zombie zones**: data weeks old looks active but is dead. Check modification times.
- **Bar width rounding**: scores 3, 7, 13 round to same bar. Always show the number.
- **Portfolio zone bloat**: cap at 5 active ideas. Note "[N] more" if exceeded.
- **Snapshot bloat**: keep last 20, trim older.
- **Pattern detection false positives**: not every bottleneck stall is wrong. Check if score is moving slowly.
- **Score-product divergence**: score improves while product doesn't (gaming) or vice versa (formula lag).
- **Health grade inflation**: zero predictions is worse than 30% accuracy. Weight learning loop heavily.

## Onboard

- **Monorepo blindness**: detect-project.sh finds root package.json, misses apps/. Check for workspaces, turborepo.json.
- **Framework false negatives**: custom frameworks match nothing. If src/ has 50+ files, ask.
- **CLI-as-web mistake**: check bin/ in package.json before assuming web.
- **Placeholder generation**: "TODO" or vague text defeats the purpose. Every field needs real content.
- **Value hypothesis vagueness**: must be testable: "[person] can [action] without [pain]."
- **Missing value.user**: "developers" is not a person. Name the situation.
- **Stage mis-assessment**: code polish != maturity. Check git history, tests, deploy config.
- **Feature over-detection**: modules != features. Features deliver user value.
- **Weight inflation**: every feature at w:5 means nothing is prioritized.
- **llm_judge overuse**: mechanical assertions have zero variance. Use them first.
- **Assertions that always pass**: test something that could fail and would matter.
- **Skipping strategy.yml**: without it, /plan has no bottleneck context.

## Hierarchy

- **Feature without system assignment**: every feature needs a `system:` field. Orphan features create invisible coupling because nobody owns the boundary. On `feature new`, always require system assignment.
- **All work at feature level**: if the dashboard hierarchy widget shows ✗ at outcome, opportunity, and system — you're executing a backlog, not building a product. Surface it.
- **System as afterthought**: system boundaries set during onboard become load-bearing architecture. Getting them wrong early compounds. Review on every `bundle` invocation.
- **Decide without checking level**: outcome-level decisions need [observed] or [stated] evidence. Feature-level decisions can proceed with [market] or [inferred]. Applying the wrong threshold wastes time or ships bad ideas.

## Feature

- **Generic "for" field**: "developers" makes viability scoring meaningless. Name the situation.
- **Solution-as-delivers**: "dashboard" is implementation, not value.
- **Zombie weight-1**: if it barely matters, kill it.
- **Overlapping code paths**: two features claiming same file confuses eval.
- **Maturity wishful thinking**: maturity is COMPUTED from eval scores, never manual.
- **Kill avoidance**: 3+ sessions with no score movement = kill or rethink.
- **Undeclared dependencies**: check dependency-graph.sh before building.
- **Prescribing without seeing**: read the actual code before generating ideas.
- **Wrong sub-score focus**: fix delivery before craft. Always check which sub-score is lowest.

## Todo

- **Todo as procrastination**: growing backlog with nothing done = avoidance.
- **Vague titles**: "fix auth" is not actionable. Describe the done state.
- **Never running decay**: stale items accumulate. Default view must include decay.
- **Promoting without capacity**: 5+ active = nothing is active. Cap at 1-3.
- **Source-blind promotion**: regression todos deserve faster promotion than speculative ones.
- **Never killing**: 60+ days with nobody caring = delete.

## Assert

- **Defaulting to llm_judge**: if you can grep for it, don't judge it. ~15 point variance.
- **file_check theater**: 10 file_checks all passing = you know files exist, not that they work.
- **command_check on flaky commands**: network/timing deps will flap. Pin or mock.
- **Vague beliefs**: "auth works" is not testable. One claim per assertion.
- **Removing failing assertions**: failing = signal, not problem. Removing hides bugs.
- **Piling on well-covered features**: cover uncovered features before deepening.
- **Severity inflation**: default to warn. Reserve block for things that break scoring.

## Configure

- **Economy when quality matters**: economy is for exploration, not core features.
- **Config-as-fix antipattern**: scores are low because the product needs work, not config.
- **Overwriting preferences.yml**: always read-modify-write, never truncate.
- **Editing founder.yml**: /configure writes ONLY to preferences.yml.

## Skill

- **Creating without evidence**: 3+ sessions of the pattern recurring, or push back.
- **SKILL.md as the entire skill**: split into scripts, references, templates.
- **Overlap blindness**: add a route to existing skill instead of creating a new one.
- **Structure without measurement**: 400-line SKILL.md with 0 assertions = theater.
- **Unmeasured survival**: flag at 30 days, kill or measure at 60.
- **Route keyword collision**: catch semantic synonyms, not just exact matches.

## Money

- **Anchoring to cost, not value**: price is about value to user, not infrastructure cost.
- **Free tier too generous**: free should create desire for paid, not satisfy it.
- **Assuming zero churn**: use 5% monthly as default. Zero churn = fantasy.
- **CAC = $0 because "organic"**: founder time has opportunity cost.
- **LTV fantasy**: without retention data, use 12 months conservative.
- **Ignoring per-user API costs**: AI products especially. Margin = revenue minus ALL costs.
- **Over-modeling with no data**: at stage one, the only question is "will one person pay?"
