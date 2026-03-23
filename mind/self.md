# Self-Model

What founder-os actually is, what works, what's broken, and what's untested.
Updated from audit data, not aspirations.

Last verified: 2026-03-22

## What It Is

A Claude Code plugin that turns Claude into an AI cofounder for serial entrepreneurs.
Two engines in one system:

- **Strategic brain** (founder-os) — decides WHAT to build via discovery, research,
  measurement, and learning across ventures
- **Execution engine** (GSD integration) — decides HOW to build it via wave-based
  parallel execution, XML task specs, fresh context per agent, atomic commits

Skills, agents, hooks, and mind files that add measurement, learning, strategy,
and industrial-grade execution on top of Claude Code's native capabilities.

## Surface Area

- **28 skills** in `skills/*/SKILL.md`
- **32 agents** in `agents/*.md` (14 founder-os + 18 GSD execution agents)
- **20 hook scripts** (15 bash + 5 JS) across `hooks/`
- **8 mind files** in `mind/` + 3 lens files in `lens/product/mind/`
- **134 GSD runtime files** in `gsd/` (workflows, references, templates, bin, scripts)
- **82 helper scripts** across skills + 5 shared utilities in `skills/shared/`
- **Plugin system** via `.claude-plugin/plugin.json` + `marketplace.json`

## Skills (28)

**Ideation (3):** /discover, /ideate, /decide
**Validation (4):** /research, /strategy, /product, /money
**Scoring (3):** /score, /eval, /taste (+/calibrate redirects to /taste)
**Build (4):** /plan, /go, /push, /quick
**Ship (3):** /ship, /roadmap, /copy
**Manage (4):** /todo, /feature, /assert, /retro
**Operations (2):** /map, /pause (includes /resume)
**Meta (4):** /founder, /onboard, /configure, /skill

## Agents (32)

### Founder-OS Agents (14) — Strategic + Measurement

| Agent | Model | Turns | Role |
|-------|-------|-------|------|
| builder | opus | 30 | Writes code in worktree isolation |
| evaluator | opus | 20 | Deep feature eval, rubric generation |
| founder-coach | opus | 10 | Startup failure mode detection |
| copywriter | opus | 20 | Positioning-aware product copy |
| market-analyst | opus | 20 | Competitive landscape, pricing |
| gtm | opus | 25 | Go-to-market strategy |
| explorer | sonnet | 25 | Research unknowns, multi-source |
| customer | sonnet | 20 | Customer signal synthesis |
| refactorer | sonnet | 20 | No-behavior-change cleanup |
| debugger | sonnet | 15 | Regression investigation |
| consolidator | sonnet | 15 | Knowledge model maintenance |
| grader | sonnet | 10 | Auto-grades predictions |
| measurer | haiku | 15 | Runs scores, cheapest |
| reviewer | haiku | 10 | UX checklist, cheapest |

### GSD Agents (18) — Execution Engine

| Agent | Role |
|-------|------|
| gsd-executor | Executes plan tasks, commits, creates SUMMARY.md |
| gsd-planner | Creates detailed plans from phase scope |
| gsd-plan-checker | Reviews plan quality before execution |
| gsd-verifier | Verifies phase completion, quality gates |
| gsd-phase-researcher | Researches technical approaches for a phase |
| gsd-project-researcher | Researches domain during project initialization |
| gsd-research-synthesizer | Synthesizes parallel research results |
| gsd-advisor-researcher | Advisory research for specific questions |
| gsd-debugger | Diagnoses and fixes issues |
| gsd-codebase-mapper | Maps project structure and dependencies |
| gsd-integration-checker | Checks cross-phase integration |
| gsd-nyquist-auditor | Validates verification coverage |
| gsd-roadmapper | Creates roadmap from requirements |
| gsd-assumptions-analyzer | Surfaces implementation assumptions |
| gsd-ui-researcher | Researches UI/UX approaches |
| gsd-ui-checker | Reviews UI implementation quality |
| gsd-ui-auditor | Audits UI against design requirements |
| gsd-user-profiler | Generates developer behavioral profile |

### Agent Selection Heuristic

/go and /plan choose between agent pools based on task:
- **Simple implementation** → gsd-executor (cheap, fast, fresh context)
- **Complex product work** → founder-os:builder (product-aware, opus)
- **Cleanup** → founder-os:refactorer (no-behavior-change)
- **Research** → gsd-phase-researcher (technical) or founder-os:explorer (market)
- **Verification** → gsd-verifier (code works?) + founder-os:reviewer (UX checklist)

## Execution Architecture

### Wave-Based Parallel Execution (/go)

```
Step 1: Measure baseline (founder-os: score-cache, assertions)
Step 2: Create XML task plans with dependency analysis
Step 3: Group tasks into waves
        Wave 1: [Task A, Task B] — parallel, no dependencies
        Wave 2: [Task C] — depends on A
        Wave 3: [Task D, Task E] — depend on C
Step 4: Execute each wave
        - Spawn gsd-executor per task (fresh 200k context each)
        - Atomic commit per task
        - Inter-wave assertion gate (founder-os: revert if regression)
Step 5: Verify (GSD: code works + founder-os: score improved?)
Step 6: Grade prediction, update model (founder-os)
Step 7: Loop or stop
```

**Key innovation:** Inter-wave assertion gates. Between every wave, founder-os
checks assertions. Regression = revert entire wave and stop. This prevents
damage from compounding across waves. GSD doesn't have this — founder-os adds it.

### Structured Planning (/plan)

Plans use XML task format for precision:
```xml
<task type="auto">
  <name>Descriptive task name</name>
  <read_first>specific/files/to/read.ts</read_first>
  <action>Precise instructions with concrete values</action>
  <acceptance_criteria>grep-verifiable condition</acceptance_criteria>
</task>
```

Tasks are grouped into dependency waves. Independent tasks run in parallel.
Dependent tasks wait for their prerequisites.

## Hooks (20 scripts)

Founder-os hooks (15 bash):
| Event | Script | Purpose |
|-------|--------|---------|
| SessionStart | session_start.sh | Boot card with portfolio + project state |
| PreCompact | pre_compact.sh | Save critical state before compression |
| PostCompact | post_compact.sh | Re-inject state after compression |
| SessionEnd | session_end.sh | Session summary to .claude/sessions/ |
| TaskCompleted | task_completed.sh | Quality gate (blocks on assertion regression) |
| SubagentStart | subagent_start.sh | Inject role-specific context |
| SubagentStop | subagent_stop.sh | Log agent activity |
| UserPromptSubmit | user_prompt_submit.sh | Deterministic intent routing |
| PostToolUse (Edit/Write) | post_edit.sh | Fast post-edit checks |
| PostToolUse (Edit/Write) | post_edit_slow.sh | Slow checks, async |
| PostToolUse (Edit/Write) | post_skill.sh | Validate .claude/plans/ schema |
| PostToolUse (Edit/Write) | config_change.sh | Validate founder.yml edits |
| PostToolUse (Bash) | post_commit.sh | Score diff after git commit |
| PreToolUse (Bash) | pre_commit_check.sh | Safety gate before commit |
| Stop | stop.sh | Remind about ungraded predictions |

GSD hooks (5 JS — not yet wired into hooks.json):
| Script | Purpose |
|--------|---------|
| gsd-context-monitor.js | Context window usage warnings |
| gsd-workflow-guard.js | Workflow state validation |
| gsd-prompt-guard.js | Prompt injection detection |
| gsd-statusline.js | Status line display |
| gsd-check-update.js | Version update check |

## State — What Actually Exists

**Files that exist and are actively used:**

| File | Written by | Read by |
|------|-----------|---------|
| config/founder.yml | /onboard, manual | /plan, /eval, /score, /founder, many |
| config/portfolio.yml | /discover, /ideate | /ideate, /decide |
| .claude/cache/score-cache.json | /score | /plan, /go, /founder |
| .claude/cache/codebase-map.json | /map | /plan, /go, /onboard |
| .claude/cache/HANDOFF.json | /pause | /pause resume |
| ~/.claude/knowledge/predictions.tsv | many skills | /retro, /plan |
| ~/.claude/knowledge/experiment-learnings.md | /retro | /plan, /ideate, /strategy |
| ~/.claude/cache/market-context.json | /research | /strategy, /ideate, /product |
| ~/.claude/cache/customer-intel.json | /product, /research | /eval, /ideate, /copy |
| ~/.claude/cache/last-research.yml | /research | /plan |
| ~/.claude/cache/last-retro.yml | /retro | /plan |
| ~/.claude/knowledge/founder-taste.md | /taste calibrate | /taste |
| ~/.claude/plans/*.md | /plan | /go, /plan |
| .planning/ | /go, /plan (GSD format) | /go, /quick, gsd agents |

**Files that SHOULD exist but DON'T:**

| File | Should be written by | Impact |
|------|---------------------|--------|
| .claude/cache/eval-cache.json | /eval | **CRITICAL** — 10+ skills need feature scores |
| config/product-spec.yml | /onboard, /discover | Product claims unavailable |
| config/beliefs.yml | /assert | Assertion scoring broken |

## Agent Wiring

| Skill | Agents spawned |
|-------|---------------|
| /go | gsd-executor (wave parallel), builder (complex), measurer, grader, debugger (bg), refactorer |
| /plan | gsd-plan-checker (verify), gsd-phase-researcher (research), explorer |
| /eval | evaluator (parallel per feature), measurer |
| /research | explorer, market-analyst (parallel) |
| /strategy | explorer, market-analyst (parallel), gtm (for gtm/price modes) |
| /discover | explorer, market-analyst, customer (parallel) |
| /retro | grader (batch), consolidator (post-grading) |
| /product | customer (bg), founder-coach |
| /ideate | explorer, customer (bg) |
| /copy | copywriter, market-analyst (for landing/pitch) |
| /money | gtm, market-analyst (parallel) |
| /quick | gsd-executor, explorer (--research flag) |
| /map | explorer (4 parallel: stack, architecture, quality, concerns) |

## Known Weaknesses (confirmed)

- **eval-cache.json never generated.** The entire measurement tier downstream of /eval
  is degraded. This is the #1 infrastructure problem.
- **GSD hooks not wired.** 5 JS hooks copied but not registered in hooks.json.
- **GSD runtime paths.** GSD workflows reference `~/.claude/get-shit-done/` paths
  that need updating to `gsd/` relative paths for plugin mode.
- **/decide is a stub.** The go/kill/pivot gate has SKILL.md but no supporting files.
- **Wave execution untested.** The new /go with parallel waves has never been run.
  First real execution will be the highest-information test.

## Untested (Highest Information Value)

- Does wave-based parallel execution actually produce better results than sequential?
- Do inter-wave assertion gates catch regressions that single-pass misses?
- Can the full ideate→validate→decide→build→measure→learn loop complete in one session?
- Does the GSD executor with fresh 200k context produce higher quality than the
  accumulated-context builder agent?
- Can someone who isn't us install and use founder-os from scratch?
- Does portfolio context actually improve build decisions?
- Do agents with `memory: user` accumulate useful cross-session context, or noise?

## Architecture Decisions

**Two engines, one system.** Founder-os brain (strategy, measurement, learning) +
GSD engine (execution, context engineering, parallelism). Neither is complete alone.

**Skills are the product surface.** Founders interact with /slash commands.
Workflows, scripts, and agents are internal plumbing.

**Measurement hierarchy:** value > craft > health.

**Learning loop:** predict → act → measure → grade → update model → repeat.

**Execution model:** Wave-based parallel with fresh context per agent.
Orchestrator stays at ~15% context. Each executor gets 100% fresh.

**Plugin mode:** `.claude-plugin/plugin.json` with 32 agents, auto-discovered skills,
hooks via `hooks/hooks.json`.

**Mind files:** Loaded every session. identity.md (who), thinking.md (how),
standards.md (quality), patterns.md (failure modes), world.md (2026 context),
voice.md (communication), self.md (this file).

## Reference Codebases

`projects/` contains full codebases for reference and learning:
- `projects/rhino-os/` — predecessor system, original measurement + learning architecture
- `projects/get-shit-done/` — GSD source, reference for execution engine patterns
