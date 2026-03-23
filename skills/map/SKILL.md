---
name: map
description: "Parallel codebase analysis — stack, architecture, conventions, concerns. Writes structured output to .claude/cache/codebase-map.json. Used by /onboard, /plan, /go when working on an existing codebase."
argument-hint: "[refresh|update|stack|arch|quality|concerns]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent
---

# /map — Codebase Analysis

Spawns parallel agents to analyze an existing codebase and produce a structured map.
The map is consumed by other skills (/onboard, /plan, /go) to understand what they're
working with.

## What this skill changes about your default behavior

You tend to:
- Skim the codebase and guess at patterns — leading to convention violations
- Miss tech debt and fragile areas — then build on top of them
- Assume standard project structure — when the actual structure is idiosyncratic
- Read 3-4 files and extrapolate — instead of systematically surveying

## Routing

Parse `$ARGUMENTS`:

| Input | Behavior |
|-------|----------|
| (no args) | Full codebase map — all 4 analysis passes |
| `refresh` | Delete existing map, remap from scratch |
| `update` | Keep existing map, re-run only stale sections |
| `stack` | Stack and dependencies only |
| `arch` | Architecture and structure only |
| `quality` | Conventions and testing only |
| `concerns` | Tech debt and concerns only |

---

## Step 1: Check for existing map

```bash
cat .claude/cache/codebase-map.json 2>/dev/null
```

**If map exists and not `refresh`:**

```
  ◆ map  ·  existing map found
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  created    ${map.created}
  sections   ${section_count} mapped

  1. Refresh — delete and remap everything
  2. Update — keep existing, update specific sections
  3. Skip — use existing map as-is
```

Wait for user choice. If `refresh` was passed as argument, skip straight to Step 2.

**If no map exists:** proceed to Step 2.

---

## Step 2: Spawn parallel analyzers

Spawn 4 agents in parallel, each with fresh context and a focused domain:

**Agent 1: Tech Stack**
```
Agent(subagent_type: "founder-os:explorer", prompt: "
Analyze this codebase for technology stack and integrations.

Survey:
- Package files (package.json, Cargo.toml, go.mod, requirements.txt, etc.)
- Config files (tsconfig, webpack, vite, etc.)
- Framework conventions (Next.js, Rails, FastAPI, etc.)
- External integrations (APIs, databases, auth providers, webhooks)
- Dev tooling (linters, formatters, CI config)

Output as JSON:
{
  \"stack\": {
    \"languages\": [],
    \"runtime\": \"\",
    \"framework\": \"\",
    \"dependencies\": { \"production\": [], \"dev\": [] },
    \"config_files\": [],
    \"build_system\": \"\"
  },
  \"integrations\": {
    \"databases\": [],
    \"apis\": [],
    \"auth\": \"\",
    \"hosting\": \"\",
    \"ci\": \"\"
  }
}

Be thorough. Include file paths for everything you reference.
", run_in_background: true)
```

**Agent 2: Architecture**
```
Agent(subagent_type: "founder-os:explorer", prompt: "
Analyze this codebase architecture and directory structure.

Survey:
- Directory layout and organization pattern
- Entry points (main files, route handlers, CLI entry)
- Module boundaries and how they communicate
- Data flow (where data enters, transforms, exits)
- Abstraction layers (services, repos, controllers, etc.)
- Key files and their roles

Output as JSON:
{
  \"architecture\": {
    \"pattern\": \"\",
    \"layers\": [],
    \"entry_points\": [],
    \"data_flow\": \"\",
    \"module_boundaries\": []
  },
  \"structure\": {
    \"layout\": {},
    \"key_locations\": {},
    \"naming_conventions\": \"\"
  }
}

Include actual file paths. Be specific about what lives where.
", run_in_background: true)
```

**Agent 3: Code Quality**
```
Agent(subagent_type: "founder-os:explorer", prompt: "
Analyze this codebase for coding conventions and testing patterns.

Survey:
- Code style (indentation, naming, import ordering)
- Error handling patterns (try/catch, Result types, error boundaries)
- Logging and observability patterns
- Test framework and structure
- Test coverage patterns (what's tested, what's not)
- Mocking and fixture patterns

Output as JSON:
{
  \"conventions\": {
    \"style\": \"\",
    \"naming\": \"\",
    \"error_handling\": \"\",
    \"logging\": \"\",
    \"patterns\": []
  },
  \"testing\": {
    \"framework\": \"\",
    \"structure\": \"\",
    \"coverage_pattern\": \"\",
    \"mocking\": \"\",
    \"notable_gaps\": []
  }
}

Show examples from actual code. Include file paths.
", run_in_background: true)
```

**Agent 4: Concerns**
```
Agent(subagent_type: "founder-os:explorer", prompt: "
Analyze this codebase for technical debt, known issues, and areas of concern.

Survey:
- TODO/FIXME/HACK comments and their locations
- Known fragile areas (complex functions, deeply nested logic)
- Security patterns (input validation, auth checks, secrets handling)
- Performance concerns (N+1 queries, large bundles, missing indexes)
- Dependency health (outdated deps, known vulnerabilities, abandoned packages)
- Dead code and unused exports

Output as JSON:
{
  \"concerns\": {
    \"tech_debt\": [],
    \"security\": [],
    \"performance\": [],
    \"fragile_areas\": [],
    \"dead_code\": [],
    \"dependency_health\": \"\"
  }
}

Include file paths and line numbers where possible. Rate severity: high/medium/low.
", run_in_background: true)
```

If a single section was requested (e.g., `/map stack`), spawn only the relevant agent.

---

## Step 3: Collect and synthesize

Wait for all agents to complete. Merge their JSON outputs into a single map:

```json
{
  "created": "YYYY-MM-DD",
  "project_root": "${pwd}",
  "stack": { ... },
  "integrations": { ... },
  "architecture": { ... },
  "structure": { ... },
  "conventions": { ... },
  "testing": { ... },
  "concerns": { ... }
}
```

Write to `.claude/cache/codebase-map.json`.

If any agent failed, note which section is missing and continue with what succeeded.

---

## Step 4: Output

```
  ◆ map  ·  complete
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  stack          ${framework} · ${language} · ${runtime}
  architecture   ${pattern} · ${layer_count} layers
  conventions    ${style_summary}
  testing        ${framework} · ${coverage_pattern}
  concerns       ${concern_count} flagged (${high_count} high)

  → .claude/cache/codebase-map.json

  ${concern_count > 0 ? '⚠ ' + high_severity_concerns : ''}
  → ${next_action}
```

Next action should be context-aware:
- If concerns are high-severity → "address concerns before building"
- If onboarding a new project → "/onboard to set up founder.yml"
- If map was requested during planning → "continuing with /plan"

---

## State Reads

| File | What it tells you |
|------|-------------------|
| `.claude/cache/codebase-map.json` | Existing map (for refresh/update decisions) |
| `config/founder.yml` | Project context (optional) |

## State Writes

- `.claude/cache/codebase-map.json` — the codebase map

## Agent usage

- **founder-os:explorer** x4 — parallel analysis (tech, arch, quality, concerns)
- Single agent for targeted section mapping

All four spawn in parallel for full map. Single section requests spawn one agent.

## System integration

**Triggers:** /plan (codebase context needed), /go (understanding conventions), /eval (knowing test patterns)
**Triggered by:** /onboard (new project setup), /plan (when no map exists), "map the codebase", "what's in this repo"

## Self-evaluation

/map succeeded if:
- All 4 sections have data (or failures are clearly noted)
- Output includes actual file paths, not guesses
- JSON is valid and written to .claude/cache/codebase-map.json
- Concerns are rated by severity
- Output summary is scannable in 5 seconds

## Cost note

- Full map: 4 explorer agents in parallel (~80k tokens total)
- Single section: 1 explorer agent (~20k tokens)
- Update mode: only re-runs stale sections

## What you never do

- Guess at project structure without reading files
- Skip concerns analysis — tech debt awareness prevents building on sand
- Write the map without file paths — the map is a reference, paths are required
- Run sequentially when parallel is possible — 4 agents in parallel is the point
- Include secrets, API keys, or credentials in the map output

## If something breaks

- Agent timeout → note which section is missing, write partial map
- No package manager files → infer stack from file extensions and imports
- Empty repository → report "no code to map" instead of generating empty JSON
- `.claude/cache/` doesn't exist → create it
- One agent returns garbage → exclude that section, note it in output

$ARGUMENTS
