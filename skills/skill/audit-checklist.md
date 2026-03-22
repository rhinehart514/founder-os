# Skill Audit Checklist

Passed to explorer agents during `/skill audit`. Each check has a verification method and pass/fail criteria.

---

## Structural Quality

### S1: Frontmatter completeness
**Verify:** SKILL.md starts with `---` and contains all of: `name:`, `description:`, `argument-hint:`, `allowed-tools:`
**Pass:** All 4 fields present in frontmatter block
**Fail:** Any missing. Report which fields are missing.

### S2: Output format compliance
**Verify:** SKILL.md output examples (text inside ``` blocks that show sample output) contain:
1. `◆` header pattern (e.g., `◆ name — scope`)
2. Section markers using `▾` or `⎯⎯` patterns
3. At least one output example ends with 3 lines starting with `/`
**Pass:** All 3 patterns found in output examples
**Fail:** Any missing. Report which patterns are missing with line numbers.

### S3: State awareness
**Verify:** SKILL.md contains one of: "State Artifacts" table, "State to read" section, or numbered list of files to read at start
**Pass:** At least one state awareness section found
**Fail:** No state awareness. Report line number where routing section ends (state should follow).

### S4: reference.md exists and is substantial
**Verify:** `skills/<name>/reference.md` exists AND has >20 lines
**Pass:** File exists with >20 lines
**Fail:** Missing or too short. Report line count if exists.

### S5: Degraded modes documented
**Verify:** SKILL.md contains "If something breaks" or "Degraded modes" section with 2+ bullet points that each describe a failure scenario AND a recovery action
**Pass:** Section exists with 2+ failure/recovery pairs
**Fail:** Missing section or <2 documented modes. Report what's found.

---

## Capability Usage

### C1: Named agent references
**Applies to:** Skills with `Agent` in allowed-tools OR that contain `Agent(` in their body
**Verify:** All Agent() calls use `subagent_type: "founder-os:*"` format, never `"general-purpose"` or bare agent names
**Pass:** All agent refs are named (or skill doesn't spawn agents)
**Fail:** Found generic agent reference. Report line number.

### C2: Fork/Agent mutual exclusion
**Verify:** If frontmatter contains `context: fork`, the SKILL.md body does NOT contain `Agent(` calls. If body contains `Agent(` calls, frontmatter does NOT contain `context: fork`.
**Pass:** No conflict
**Fail:** Both fork and Agent() present. Report line numbers.

### C3: Tool access minimality
**Verify:** Skills that are primarily read-only (don't create/modify files as their primary function) should NOT have `Write` or `Edit` in allowed-tools
**Pass:** Tool list matches the skill's function
**Fail:** Unnecessary Write/Edit access. Report skill function vs tools.

### C4: Model override support
**Applies to:** Skills that spawn agents
**Verify:** SKILL.md mentions `~/.claude/preferences.yml` or `agents.cost` or model override in its state-read section
**Pass:** Preferences reading documented (or skill doesn't spawn agents)
**Fail:** Spawns agents but doesn't read preferences. Report which agents are spawned.

### C5: Anti-rationalization quality
**Verify:** SKILL.md contains "Anti-rationalization" or "Anti-Rationalization" section with checks that are specific to THIS skill's domain (not copy-pasted generic checks)
**Pass:** Section exists with domain-specific checks
**Fail:** Missing or generic. Report what's found.

---

## New Capabilities (recommendations, not failures)

### N1: Hook opportunities
**Check:** Could this skill benefit from pre-execution or post-execution hooks? (e.g., pre-loading context, post-execution cleanup, validation)
**Recommend if:** Skill has repeated setup/teardown patterns that could be automated

### N2: LSP integration
**Check:** Does this skill frequently navigate code by reading files to find definitions/references?
**Recommend if:** Skill reads 5+ code files or searches for function/class definitions

### N3: TaskCreate usage
**Check:** Does this skill produce multi-step work items that should persist across turns?
**Recommend if:** Skill outputs "next steps" or creates sequential work plans

### N4: Preferences reading
**Check:** Does this skill spawn agents, control output format, or have behavior that should be user-configurable?
**Recommend if:** Skill has configurable behavior (model choice, verbosity, gates)

---

## Communication Protocol

### P1: Agent output format
**Applies to:** Skills that spawn agents
**Verify:** SKILL.md documents what format it expects from spawned agents (structured output, specific sections, etc.)
**Pass:** Output format expectations documented for each agent type spawned
**Fail:** Spawns agents without specifying expected output format. Report which agents lack format docs.

### P2: Todo directive parsing
**Applies to:** Skills that collect output from multiple agents
**Verify:** SKILL.md describes how it aggregates agent results and extracts actionable items (todo directives, recommendations, etc.)
**Pass:** Aggregation logic documented (or skill doesn't aggregate)
**Fail:** Aggregates without documented parsing. Report the aggregation point.

---

## Reporting format

For each skill, report:
```
▾ audit: /[name]
  S: [pass_count]/5  C: [pass_count]/5  N: [rec_count]/4  P: [pass_count]/2
  ✗ [check_id]: [specific issue] (file:line)
  · [check_id]: [recommendation]
```
