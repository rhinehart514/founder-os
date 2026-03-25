# Onboarding Flow

Step-by-step reference for what /onboard does and why. Read on demand — SKILL.md has the protocol.

## The flow

### 1. Detect + Check (parallel)

**detect-project.sh** discovers:
- Language (node/python/rust/go/ruby/java/etc.)
- Framework (next.js/nuxt/sveltekit/astro/remix/vite/django/rails/etc.)
- Styling (tailwind/css-in-js/sass)
- Package manager (npm/yarn/pnpm/bun)
- Key files present/missing
- Source structure and file counts
- Git state (commits, branch, recency)

**onboard-checklist.sh** discovers:
- What founder-os artifacts already exist
- Whether they have real content or are templates
- Setup completion score (N/8)
- Whether this is fresh, partial, or fully initialized

### 2. Understand the product

Read the actual code. Form an opinion about:
- **What is this?** One specific sentence. Not "a web app" — "a campus infrastructure platform that generates course schedules for UB students."
- **Who uses it?** A person. "A first-year CS student trying to avoid 8am classes" not "students."
- **What value?** What changes after they use it. "They get a conflict-free schedule in 30 seconds instead of 2 hours of manual planning."
- **Current state?** Working, broken, half-built, polished. Be honest.

### 3. Write config

`config/founder.yml` must have zero placeholders. Every field filled from code analysis:
- `value.hypothesis` — one testable sentence: "X can Y without Z"
- `value.user` — the named person from step 2
- `project.stage` — mvp/early/growth/mature based on evidence
- Features with real delivers, for, code paths, weights

### 4. Generate features

Detection heuristic:
- Route directories (app/dashboard/) = feature
- Major source modules (src/auth/) = feature
- CLI commands (bin/score.sh) = feature
- Package scripts ("test") = feature
- NOT utilities, configs, or infrastructure

Each feature: delivers (from code), for (who benefits), code (file paths), weight (1-5 importance), maturity (planned/building/working/polished)

### 5. Generate assertions

2-3 per feature, mechanical first:
- `file_check` — does the core file exist?
- `command_check` — does something run/return expected output?
- `content_check` — does a file contain expected content?
- `llm_judge` — LAST RESORT only when mechanical checks can't cover it

### 6. Start learning loop

Create these so every command works from session one:
- `.claude/knowledge/predictions.tsv` — header row
- `.claude/knowledge/experiment-learnings.md` — standard template
- `.claude/plans/strategy.yml` — stage + bottleneck placeholder
- `.claude/plans/roadmap.yml` — version thesis from value hypothesis

### 7. First score

Run `scripts/first-score.sh` which:
- Executes `founder score .`
- Explains what each number means (new user context)
- Sets expectations (30-50 is normal for fresh onboard)

Also run `founder eval .` and cache to `.claude/cache/eval-cache.json`.

### 8. Present

Output template:

```
◆ onboard — [project name]

  [project name] — [one sentence description]
  for: [who]
  hypothesis: "[testable sentence]"
  stage: [stage] · mode: build

  ✓ config/founder.yml — value hypothesis + [N] features defined
  ✓ beliefs.yml — [N] assertions across [N] features
  ✓ learning loop — predictions.tsv, experiment-learnings.md, strategy.yml, roadmap.yml
  ✓ first eval complete

▾ features detected
  ▸ [name]     w:[N]  [maturity]  [score]/100
    "[delivers]"

  eval: [N] passing · [N] failing · [N] warn
  bottleneck: **[worst feature]** — [why]

▾ what's next
  Your product has a score now. Here's how to make it better:

/plan              find the bottleneck and plan a fix
/go [feature]      autonomous build loop on the worst feature
/eval              re-measure after changes
```

## Time target

Under 2 minutes from `/onboard` to seeing the full output. This is a first impression — speed matters.
