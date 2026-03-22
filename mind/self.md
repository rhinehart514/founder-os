# Self-Model

What founder-os can do, where it's weak, and what's untested.

## What It Does (Features)

**Ideation** — Generate ideas, improve existing ones, kill bad ones fast.
- `/discover` takes "I want to build X" → validated business case
- `/ideate` generates evidence-weighted ideas with 11+ creative techniques
- `/decide` forces go/kill/pivot with explicit evidence and confidence

**Validation** — Research before you build. Evidence, not opinions.
- `/research` gathers market intelligence, competitor teardowns, customer signals
- `/strategy` produces honest diagnoses — positioning, timing, competitive response
- `/product` pressure-tests whether you're building something anyone wants
- `/money` models pricing, unit economics, runway

**Portfolio** — Track ideas across ventures. The serial entrepreneur's compound advantage.
- `/portfolio` shows all ideas, stages, patterns, accuracy
- `~/.founder-os/portfolio.yml` persists across projects
- Pattern detection catches sprawl, research addiction, confirmation bias

**Scoring** — One honest number: is your product good?
- `/score` synthesizes health + features + design + market into one number
- `/eval` judges each feature: does the code deliver what it claims?
- `/taste` evaluates visual quality and whether core flows actually work

**Build Loop** — Plan the bottleneck, build it, measure improvement.
- `/plan` finds the weakest feature and proposes work
- `/go` builds autonomously — code, measure, learn, repeat
- `/push` targets a specific score for a specific feature

**World Awareness** — Proactive market intelligence. Checks the outside world before acting.
- `/plan` WebSearches the market before proposing work — surfaces competitor launches, pricing changes
- `/strategy` visits competitor sites with Playwright — real screenshots, real pricing, not guesses
- `/retro audit` checks if each feature still matters — timing windows close, markets shift
- `/money` checks actual competitor pricing pages before modeling
- `mind/world.md` provides 2026 context: AI capabilities, outcome-based pricing, platform risk, regulation

**Skills** — 27 commands that route intent to the right action.
- `/founder` is the home screen — portfolio first, then project status
- `/onboard` bootstraps any project with real features from code analysis
- `/ship` deploys, `/roadmap` tracks versions, `/copy` writes product text
- `/todo` manages backlog, `/retro` closes the learning loop

**Learning** — Gets smarter every session. Predictions compound across ventures.
- Every action has a prediction logged to `predictions.tsv`
- `/retro` grades predictions, updates the knowledge model
- Wrong predictions are the most valuable — they update the model
- `experiment-learnings.md` is the causal model that compounds

**Install** — Two steps: `install.sh` + `/onboard`.
- Plugin mode via `.claude-plugin/plugin.json` (14 agents)
- Creates `~/.founder-os/` for global state, initializes knowledge files

## Known Weaknesses

- Fresh port from rhino-os. Untested on external projects end-to-end.
- Portfolio integration into build features is additive, not deeply wired.
- Lens (visual eval) requires `npm install` — not auto-installed.
- No README yet for new users.

## Untested (Highest Information Value)

- Can the full ideate→validate→decide→build→measure→learn loop complete in one session?
- Does portfolio context actually improve build decisions?
- Can someone who isn't us install and use this from scratch?
- Do the merged skills (research, strategy, ideate, retro) work without mode confusion?
- Does killing an idea in the portfolio actually update experiment-learnings.md?
