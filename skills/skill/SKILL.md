---
name: skill
description: "Use when the user wants to create, inspect, audit, or remove skills — the skill lifecycle manager including quality tiers and overlap detection"
argument-hint: "[list|create <name>|install <url>|remove <name>|info <name>|health|audit|overlap <name>]"
allowed-tools: Read, Bash, Grep, Glob, Edit, Write, AskUserQuestion
user-invocable: false
---

<!-- INTERNAL: This skill is for founder-os self-management, not marketplace distribution. -->

# /skill

Manages the skill lifecycle: create, inspect, audit, remove. A founder-os skill is a **measured folder** — prompt + scripts + references + assertions. Not just a markdown file.

## Skill folder structure

This skill is a **folder**. Read these on demand:

- `scripts/skill-scan.sh` — lists all skills with file counts, descriptions, last modified
- `scripts/skill-quality.sh` — grades each skill for completeness (gotchas, scripts, references, templates)
- `references/skill-anatomy.md` — what makes a good skill per Anthropic guide
- `reference.md` — output templates for all modes
- `audit-checklist.md` — 16-check quality audit matrix
- `gotchas.md` — real failure modes. **Read before creating or auditing.**

## Routing

| Input | Action |
|-------|--------|
| `list` or (none) | Run `skill-scan.sh` then show all skills with maturity + pass rates |
| `create <name>` | Evidence check → overlap check → create measured skill |
| `install <url>` | Install external skill, wire into measurement |
| `remove <name>` | Remove skill, mark killed in founder.yml |
| `info <name>` | Show skill details, assertions, sub-scores |
| `health` | Run `skill-scan.sh` + `skill-quality.sh` → tier classification dashboard |
| `audit` | Full 16-check quality audit — spawn explorer agents in parallel batches |
| `overlap <name>` | Check proposed name against existing skills for route overlap |

## The protocol

### Step 1: Mechanical scan (always first)

Run `bash ${CLAUDE_SKILL_DIR}/scripts/skill-scan.sh` for the skill inventory. For `health` or `audit`, also run `bash ${CLAUDE_SKILL_DIR}/scripts/skill-quality.sh` for completeness grades.

### Step 2: Read gotchas

Read `gotchas.md` before creating or auditing.

### Step 3: Route-specific logic

- **create**: 3-question evidence gate → overlap check → write SKILL.md + wire into founder.yml + seed assertions. See `references/skill-anatomy.md` for folder structure guidance.
- **audit**: Spawn explorer agents in parallel batches per `audit-checklist.md`. Write results to `.claude/cache/skill-audit.json`.
- **health**: Classify each skill into thick/thin/stub/dead tiers. Write to `.claude/cache/skill-health.json`.
- **info/list/overlap/install/remove**: See `reference.md` for output templates.

### Step 4: Output

Use templates from `reference.md`. Every output ends with 3 next commands.

## Task generation — the path to skill excellence

**/skill's job is not just auditing. It's generating EVERY task needed to bring skills to full quality.** Every missing gotchas.md, every skill without scripts, every unmeasured skill is a task. The skill system is only as good as its weakest skill.

**For EVERY quality gap found, generate the complete task list:**

### Completeness tasks (from skill-quality.sh)
- Each skill missing `gotchas.md` → task: "Skill [X] has no gotchas — add from observed failure modes"
- Each skill missing `scripts/` → task: "Skill [X] has no scripts — add mechanical helpers"
- Each skill missing `references/` → task: "Skill [X] has no references — add domain knowledge"
- Each skill missing `templates/` → task: "Skill [X] has no templates — add output structure"
- Each skill missing `reference.md` → task: "Skill [X] has no output format guide — add reference.md"

### Measurement tasks
- Each skill with no feature in founder.yml → task: "Skill [X] not tracked as feature — add to founder.yml"
- Each skill with no assertions → task: "Skill [X] has no assertions — add via /assert"
- Each skill never evaluated → task: "Skill [X] never scored — run /eval [X]"
- Skill assertions all passing but quality is low → task: "Skill [X] assertions too weak — strengthen"

### Tier progression tasks
- Each `stub` skill (SKILL.md only) → task: "Skill [X] is a stub — add scripts and references to reach thin"
- Each `thin` skill → task: "Skill [X] is thin — add gotchas, templates, more scripts to reach thick"
- Each `dead` skill (>30d no changes, no assertions) → task: "Skill [X] appears dead — kill or revive"

### Overlap tasks
- Skills with overlapping routes → task: "Skills [X] and [Y] overlap on route [Z] — clarify boundaries"
- Skills with duplicate functionality → task: "Skills [X] and [Y] do similar things — merge or differentiate"

### Architecture tasks
- Skills using wrong architecture (fork when they should spawn, or vice versa) → task: "Skill [X] architecture mismatch — evaluate A vs B"
- Skills not using named agents → task: "Skill [X] spawns generic agents — use named agent refs"

**Write ALL tasks to /todo.** Tag with `source: /skill`, skill name, and gap type (completeness/measurement/tier/overlap/architecture). Priority: stub skills on high-weight features first.

**There is no cap on task count.** An audit of 21 skills might generate 50+ tasks. Generate all of them.

After writing tasks, show: "Generated N tasks across M skills. [X] stubs, [Y] thin, [Z] thick. Worst: [skill] needs [N] tasks."

## Self-evaluation

The skill worked if:
- **Create**: skill folder was created with SKILL.md + reference.md + gotchas.md, wired into founder.yml, and baseline assertions were seeded
- **Audit**: every skill got a quality grade AND tasks were generated for every gap
- **Health**: tier classification (thick/thin/stub/dead) was computed for all skills
- **All modes**: tasks were written to /todo for every quality gap found

## System integration

Reads: `skills/*/SKILL.md` (all skill definitions), `config/founder.yml` (feature wiring), `config/beliefs.yml` (skill assertions), `.claude/cache/eval-cache.json` (skill scores), `.claude/cache/skill-health.json`, `.claude/cache/skill-audit.json`
Writes: `skills/<name>/SKILL.md` (create), `config/founder.yml` (feature wiring), `.claude/cache/skill-health.json`, `.claude/cache/skill-audit.json`
Triggers: `/eval` (score new skill), `/assert` (seed assertions), `/todo` (quality gap tasks)
Triggered by: manual, `/plan` (when skill quality is the bottleneck)

## What you never do

- Create skills without evidence (3+ sessions of the pattern recurring)
- Create skills without overlap check
- Create skills without measurement wiring (feature + assertions + baseline)
- Classify "thick" without assertions — structure without measurement is theater
- Let unmeasured skills survive 30+ days without flagging

## If something breaks

- No beliefs.yml: all skills unmeasured, suggest `/onboard`
- No eval-cache.json: show structural health only, skip scores
- No founder.yml features: show scan data only, no maturity/weight
- skill-health.json stale >7 days: regenerate from filesystem

$ARGUMENTS
