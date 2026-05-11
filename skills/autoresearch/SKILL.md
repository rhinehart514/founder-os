---
name: autoresearch
description: TRIGGER when user explicitly invokes optimization with a numeric automatable metric — "optimize the lighthouse score", "shrink the bundle", "reduce build time", "cut p99 latency", "hill climb the eval accuracy", "/autoresearch", "make X faster" where X is measurable. Drops a working hill-climb harness into the project, generates project-specific mutations by reading the codebase, runs the loop. SKIP when there's no numeric metric, when changes need design/UX/copy judgment, or for one-off manual tuning. SKIP requests like "make this cleaner/better/smaller" that have no measurement command.
when_to_use: Any optimization with a numeric automatable metric — Lighthouse, bundle bytes, build seconds, p99 ms, coverage %, eval accuracy. If you can't write a one-line shell command that prints the metric, this skill is wrong.
---

# autoresearch

Autonomous hill-climb. Read code → generate mutations → measure → keep-or-revert → repeat. The runner ships ready-made; the model fills in the project-specific bits and lets the loop run.

## State machine

```
TRIGGERED
  ↓
GATE: is the metric numeric + automatable? (no → bail, suggest alternative skill)
  ↓
READ_CODEBASE         (package.json, entry file, build config — parallel reads)
  ↓
INFER + CONFIRM       (one line: metric / measureCmd / targetFiles. NOT a Q&A round.)
  ↓
SCAFFOLD              (cp templates/* into .autoresearch/)
  ↓
WRITE_CONFIG          (fill config.js from inference; set buildCmd if compiled)
  ↓
WRITE_MUTATIONS       (read target files, write 15-30 mutations whose patterns
                       you have GREPPED for in the actual file)
  ↓
RUN                   (node .autoresearch/server.js & node .autoresearch/runner.js)
  ↓
runner exits with one of:
  - "exhausted"         → REGENERATE_BATCH → RUN
  - "plateau"           → STOP, report
  - "target"            → STOP, report
  - "interrupted"       → STOP, report
  - "preflight-failed"  → re-read target files, REWRITE mutations, RUN
  - "error"             → DIAGNOSE → fix → RUN
```

## What the templates do

`~/.claude/skills/autoresearch/templates/`:

| file | purpose |
|---|---|
| `runner.js` | Hill-climb loop. Dedupes by content hash, not name. Snapshots `bestState + score` to `.autoresearch/best/` after each keep. Resume restores `bestScore` from kept-only experiments and `consecutiveDiscards` from trailing tail. Pre-flight aborts if all dryable mutations are no-ops. Stops on plateau / target / SIGINT. |
| `server.js` | Static server. Default :3456. |
| `dashboard.html` | Live dashboard, polls every 500ms. Adapts to whatever metric is configured. |
| `config.example.js` | Schema. Required: `metric`, `maximize`, `targetFiles`, `measureCmd`. Recommended: `minImprovement`, `samples`, `buildCmd` (compiled), `plateauLimit`, `targetScore`. |
| `mutations.example.js` | Two shapes: `{ name, apply(state) }` for JS regex, or `{ name, applyCmd: "shell..." }` for Python/Rust/Go or any language-fragile target. |

## Procedure

### TRIGGERED → GATE

If the user's request has no numeric automatable metric, bail. Examples that should NOT trigger this skill:
- "make this copy better" → no metric
- "make this component cleaner" → judgment, not measurement
- "improve error handling" → no metric (suggest manual review)
- "make the nav smaller" → if "smaller" is bytes, OK; if it's px, no metric

### READ_CODEBASE

In parallel: read `package.json`, the main entry file, any obvious build config. Don't ask the user anything yet.

### INFER + CONFIRM (one line, not a form)

Emit one line stating what you'll do. The user can correct or stay silent.

> "Optimizing **performance** in `index.html` via `npx lighthouse http://localhost:3000`. Running baseline now."

If a project doesn't surface enough signal (bare directory, no entry file), then ask. Otherwise proceed.

### SCAFFOLD

```bash
mkdir -p .autoresearch
cp ~/.claude/skills/autoresearch/templates/runner.js          .autoresearch/runner.js
cp ~/.claude/skills/autoresearch/templates/server.js          .autoresearch/server.js
cp ~/.claude/skills/autoresearch/templates/dashboard.html     .autoresearch/dashboard.html
cp ~/.claude/skills/autoresearch/templates/config.example.js  .autoresearch/config.js
cp ~/.claude/skills/autoresearch/templates/mutations.example.js .autoresearch/mutations.js
echo '/results.json' >> .autoresearch/.gitignore
echo '/best/' >> .autoresearch/.gitignore
```

### WRITE_CONFIG

Fill `.autoresearch/config.js` from inference. Common shapes:

```js
// Lighthouse (noisy — needs samples + minImprovement)
{ metric: 'performance', maximize: true,
  targetFiles: ['index.html'], samples: 3, minImprovement: 3, targetScore: 99,
  measureCmd: 'npx -y lighthouse $URL --output=json --quiet --only-categories=performance',
  parse: (s) => ({ score: Math.round(JSON.parse(s).categories.performance.score * 100) }) }

// Bundle size (deterministic — minImprovement: 0, samples: 1, buildCmd separate)
{ metric: 'bundle_kb', maximize: false,
  targetFiles: ['vite.config.ts', 'src/index.tsx'], minImprovement: 0,
  buildCmd: 'npm run build',
  measureCmd: 'du -sk dist | cut -f1' }

// Build time (slightly noisy — samples: 3, no buildCmd because measure IS the build)
{ metric: 'build_s', maximize: false,
  targetFiles: ['vite.config.ts', 'tsconfig.json'], samples: 3, minImprovement: 0.5,
  measureCmd: '/usr/bin/time -p npm run build 2>&1 | awk \'/real/ {print $2}\'' }

// API p99 (very noisy — samples: 5)
{ metric: 'p99_ms', maximize: false,
  targetFiles: ['src/server.ts'], samples: 5, minImprovement: 5,
  buildCmd: 'npm run build && pm2 restart api',
  measureCmd: 'hey -n 1000 -q 50 $URL | awk \'/99%/ {print $NF*1000}\'' }

// Python eval accuracy
{ metric: 'accuracy', maximize: true,
  targetFiles: ['prompts/system.md'], samples: 1, minImprovement: 0.01,
  measureCmd: 'python eval.py --json | jq .accuracy' }
```

**Verify the measure command runs once by hand before the loop starts.** If baseline fails, runner exits with status `"error"` immediately — debug the command, don't grind.

### WRITE_MUTATIONS

Read every file in `targetFiles`. Write 15–30 mutations into `.autoresearch/mutations.js`.

**Two shapes.** Pick per mutation:

```js
// JS apply — for HTML/CSS/JS/JSON/YAML, anything string-replaceable
{ name: 'lazy load all images',
  apply: (state) => {
    state['index.html'] = state['index.html'].replace(/<img(?![^>]*loading)/g, '<img loading="lazy"');
    return state;
  } }

// applyCmd — for Python, Rust, Go, AST transforms, formatters, patches
{ name: 'remove unused imports via ruff',
  applyCmd: 'ruff check --select F401 --fix src/' }
```

**Rules** (these are why generic checklists lose):
- One change per mutation. Compound diffs hide what worked.
- **Grep the pattern before writing the mutation.** A regex that matches nothing is a no-op skip — and the runner's pre-flight will abort the whole batch if every dryable mutation is a no-op.
- Specific to what you read, not what you imagine. The Lighthouse run kept "use system font stack only" because the HTML had a Google Fonts link. That mutation only existed because somebody read the file.
- Cheap before exotic. Solid ground state first.

**Idea ladder** (apply only entries that match the code you read):

| domain | cheap | medium | expensive |
|---|---|---|---|
| performance | `loading=lazy`, `fetchpriority`, `preload` | remove animations, system fonts, simplify gradients | swap libs, drop deps |
| bundle | tree-shake imports, drop polyfills | code-split routes, dynamic imports | swap heavy deps |
| build time | skip type-check on watch, lighter sourcemaps | parallelize, swc/esbuild | cache layers, incremental |
| latency | cache headers, dedupe DB calls | batch queries, denormalize | move work async, CDN |
| accuracy | tighten instructions, examples | restructure prompt, CoT | swap model |

### RUN

Two background commands:

```bash
node .autoresearch/server.js &       # dashboard
node .autoresearch/runner.js         # the loop
```

Open `http://localhost:3456/dashboard.html`. Stream progress inline:

```
[1/24] lazy load all images
  performance: 94
  ✓ keep (86 → 94)
```

### REGENERATE_BATCH (when runner exits "exhausted")

Don't ask the user. Read `results.json`, identify what kept and what near-missed, write a new `mutations.js`. The runner dedupes by content hash, so:
- A reworded name with identical code → skipped (correctly).
- An identical name with different code → runs (correctly — it's a new mutation).
- A different name with identical code → skipped (correctly).

The runner reloads `bestState` and `bestScore` from the `.autoresearch/best/` snapshot, so you don't lose ground.

Stop regenerating when:
- runner exits `"plateau"` — 5 consecutive non-improvements
- runner exits `"target"` — `targetScore` hit
- you've genuinely run out of ideas after re-reading the code

### Final report

```
=== autoresearch: <metric> (status: plateau|target|interrupted) ===
baseline:   77      final: 99      gain: +29%

kept (7):
  +8  lazy load all images
  +3  fetchpriority on hero
  +1  reduce image quality in URLs
  ...

discarded:  33    crashed: 0    skipped: 5
```

Point them at `.autoresearch/dashboard.html` and `.autoresearch/results.json`.

## Hard rules

1. **One mutation, one measurement.** No compounding.
2. **Set `minImprovement` to noise floor.** Without it, jitter wins compound into a phony best.
3. **Grep patterns before writing mutations.** If the regex doesn't match the actual file, it's a no-op skip.
4. **Run baseline first.** If it fails, fix the measure command before generating mutations.
5. **Don't track `results.json` or `best/` in git.** Working files.
6. **Side-effect-free measurement.** No prod, no billing, no destructive ops in `measureCmd`.
7. **One-line confirmation, not a Q&A.** The skill is triggered to act — read first, infer, state assumptions, run. Block only on genuine ambiguity.

## When NOT to use

- No automatable numeric metric (use a regular task, not this skill).
- One measurement >5 min (loop becomes unusable — use `/loop` instead).
- Changes need design/UX/copy judgment (use `/product-design`, `/pencil-dev`).
- Side effects are dangerous (production, billing, external services).

## Reference run

A representative Lighthouse optimization run improved from 77 to 99 over 45 experiments. The included templates use a noise floor, content-hash deduplication, a build-aware loop, an `applyCmd` escape hatch, and crash-safe resume.
