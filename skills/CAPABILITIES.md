# Claude Code Capabilities — What founder-os Can Build On

Research findings from deep dive into Claude Code's extension system. This is the map of what's possible — not what founder-os currently uses, but what it COULD use.

Last updated: 2026-03-20

---

## Skills

Skills are markdown-based instruction packages. Each is a directory with `SKILL.md` (required) + supporting files.

### Frontmatter Fields

```yaml
---
name: my-skill                    # becomes /slash-command
description: "What it does"       # Claude uses this to decide when to auto-load
disable-model-invocation: true    # only fires when human types it, not auto-triggered
user-invocable: false             # only Claude triggers it, hidden from / menu
allowed-tools: Read, Grep, Bash   # restrict tool access during execution
model: sonnet/opus/haiku          # override model for this skill
context: fork                     # run in isolated subagent (own context window)
agent: Explore                    # which subagent type when context: fork
argument-hint: "[feature|wild]"   # autocomplete hint in / menu
hooks: {}                         # lifecycle hooks scoped to this skill
---
```

### Key Features We're NOT Using

- **`context: fork`** — runs the skill in an isolated subagent. Protects main context from expensive operations. This is how `/batch` decomposes 30 units of work without filling the main context.
- **`allowed-tools`** — restricts what Claude can do during a skill. A readonly skill could block Write/Edit. A research skill could block code modification.
- **`model` override** — run cheap skills on haiku, expensive ones on opus. We hardcode nothing right now.
- **`!command` syntax** — shell commands in the skill body run BEFORE the prompt is sent. We use this for score/predictions, but could use it for much more dynamic context injection.
- **`${CLAUDE_SKILL_DIR}`** — path to the skill's own directory. Skills can reference their own supporting files portably.

### Skill Discovery

- Descriptions are loaded into context (budget: 2% of context window, ~16K chars) so Claude knows what's available
- Full content only loads on invocation — descriptions are the index
- Priority: Enterprise > Personal (`~/.claude/skills/`) > Project (`.claude/skills/`) > Plugin
- Automatic discovery from nested `.claude/skills/` supports monorepos

### Cross-Tool Portability

Skills follow the [AgentSkills.io](https://agentskills.io) open standard. SKILL.md files work across Claude Code, Cursor, Gemini CLI, and others. founder-os skills could theoretically run outside Claude Code.

---

## Agents (Subagents)

Specialized AI assistants with their own context window, custom prompts, specific tool access, and independent permissions.

### Agent Frontmatter

```yaml
---
name: code-reviewer
description: "When to delegate to this agent"
tools: Read, Glob, Grep, Bash            # tool allowlist
disallowedTools: Write, Edit              # tool denylist
model: sonnet/opus/haiku/inherit          # model selection
permissionMode: default/acceptEdits/dontAsk/bypassPermissions/plan
maxTurns: 20                              # max agentic turns
skills: [api-conventions, error-handling] # preloaded skills
memory: user/project/local               # persistent cross-session memory
background: true/false                    # run as background task
isolation: worktree                       # isolated git worktree
mcpServers:                               # scoped MCP servers
  - playwright:
      type: stdio
      command: npx
      args: ["-y", "@playwright/mcp@latest"]
hooks: {}                                 # lifecycle hooks
---
```

### Key Features We're NOT Using

- **`permissionMode: bypassPermissions`** — fully autonomous agents that don't ask for permission. Dangerous but powerful for trusted loops.

**Now in use:** `memory: user` (all 14 agents), `isolation: worktree` (builder, refactorer via /go), `maxTurns` (all agents). Background execution controlled per-call by spawning skill, not in agent definitions. All agents have `skills: []` (empty arrays).

### Agent Locations (priority)

1. `--agents` CLI flag (session-only)
2. `.claude/agents/` (project-level, check into VCS)
3. `~/.claude/agents/` (user-level, all projects)
4. Plugin's `agents/` directory

### Limitations

- Subagents CANNOT spawn other subagents (no nesting)
- Main agents can restrict which subagents they spawn: `tools: Agent(worker, researcher)`
- Auto-compaction at ~95% context capacity

### Agent Teams (Experimental)

The most powerful orchestration primitive. Multiple named agents coordinating:

- **Shared task lists** — agents see and claim tasks
- **Inter-agent messaging** — `SendMessage({to: "reviewer"})` while running
- **Task dependencies** — agent B waits until agent A completes its task
- **Plan approval gates** — human reviews before execution proceeds
- **Named agents** — addressable by name for targeted communication

Anthropic built a 100K-line C compiler with 16 agents across 2,000 sessions using this.

---

## Hooks (22 Events)

Shell commands, HTTP endpoints, LLM prompts, or agents that execute at lifecycle points.

### All Available Events

| Event | Blockable | When | founder-os uses? |
|-------|-----------|------|----------------|
| `SessionStart` | No | Session begins/resumes | YES |
| `InstructionsLoaded` | No | CLAUDE.md or rules loaded | no |
| `UserPromptSubmit` | Yes | User submits prompt | YES |
| `PreToolUse` | Yes | Before tool execution | YES |
| `PermissionRequest` | Yes | Permission dialog appears | no |
| `PostToolUse` | No | After tool succeeds | YES |
| `PostToolUseFailure` | No | After tool fails | no |
| `Notification` | No | Notification sent | no |
| `SubagentStart` | No | Subagent spawned | YES |
| `SubagentStop` | Yes | Subagent finishes | YES |
| `Stop` | Yes | Claude finishes responding | YES |
| `TeammateIdle` | Yes | Agent team teammate about to idle | no |
| `TaskCompleted` | Yes | Task marked complete | YES |
| `ConfigChange` | Yes | Config file changes | no |
| `WorktreeCreate` | Yes | Worktree created | no |
| `WorktreeRemove` | No | Worktree removed | no |
| `PreCompact` | No | Before context compaction | YES |
| `PostCompact` | No | After compaction | YES |
| `Elicitation` | Yes | MCP server requests user input | no |
| `ElicitationResult` | Yes | User responds to MCP elicitation | no |
| `SessionEnd` | No | Session terminates | YES |

**We use 11 of 22 events.** 14 hooks registered, 15 scripts. 11 events untapped.

### Four Hook Handler Types

1. **`command`** — shell scripts, receives JSON on stdin
2. **`http`** — POST requests to endpoints, supports auth headers
3. **`prompt`** — single-turn LLM evaluation
4. **`agent`** — multi-turn agentic verification with tool access

### Powerful Patterns We're NOT Using

- **`TeammateIdle`** — in agent teams, can redirect idle agents to new work or send feedback.

**Now in use:** `SessionStart`, `PreCompact`, `PostCompact`, `SessionEnd`, `TaskCompleted`, `SubagentStart`, `SubagentStop`, `UserPromptSubmit`, `PostToolUse` (3 matchers), `PreToolUse`, `Stop`.

### Environment Variables

- `CLAUDE_PROJECT_DIR` — project root
- `CLAUDE_PLUGIN_ROOT` — plugin directory
- `CLAUDE_ENV_FILE` — SessionStart ONLY: write vars here to persist them for the session

---

## Plugin System

### Structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # manifest (required)
├── skills/                  # SKILL.md files
├── agents/                  # agent .md files
├── hooks/
│   └── hooks.json           # hook definitions
└── .mcp.json                # MCP server config
```

### Marketplace

- Marketplace = git repo with `.claude-plugin/marketplace.json`
- Sources: GitHub repos, git URLs, git subdirs (sparse clone), npm/pip packages
- Version pinning via `ref` (branch/tag) and `sha` (exact commit)
- Release channels (stable/latest) via separate marketplaces pointing to different refs
- Anthropic has official directory at `plugins.claude.ai`
- Enterprise: `strictKnownMarketplaces` restricts sources, `extraKnownMarketplaces` auto-prompts team install

---

## Ecosystem Patterns (What People Are Building)

### The Ralph Wiggum Pattern (dominant)

Named by Geoffrey Huntley. Continuously run an agent until success criteria are met:
```
test → fail → retry with error context → loop until green
```
Multiple implementations: ralph-claude-code, ralph-orchestrator, multi-agent-ralph-loop. This is `/go` but formalized.

### Orchestration Tools

- **Claude Squad** — terminal app managing multiple Claude Code instances in parallel
- **TSK** — Rust CLI delegating tasks to agents in sandboxed Docker, returning git branches
- **HCOM** — real-time multi-agent communication via hooks with @-mention targeting
- **Gas Town** — high-throughput orchestration with "Mayor" and "Deacon" roles

### Massive Skill Libraries

- **anthropics/skills** — Anthropic's official public skill repository
- **VoltAgent/awesome-agent-skills** — 500+ skills, cross-tool compatible (Claude Code, Codex, Gemini CLI, Cursor)
- **alirezarezvani/claude-skills** — 180+ production-ready skills
- **Anthropic's frontend-design skill** — 277K+ installs

### The `/batch` Pattern (canonical composite)

Ships with Claude Code. The reference for composite skills:
1. Decompose work into 5-30 units
2. Spawn one agent per unit in isolated git worktree
3. Each agent works independently
4. Each opens a PR when done
5. Human reviews and merges

This is the pattern — not sequential command chaining, but **parallel agent orchestration with worktree isolation**.

---

## What This Means for founder-os

### Critical Constraint: `context: fork` and Agent Spawning Are Mutually Exclusive

A forked skill runs AS a subagent. Subagents CANNOT spawn sub-subagents. This means:
- **Architecture A (Inline Orchestrator)**: No fork, CAN spawn agents. Use for skills that coordinate agents: /go, /eval, /research, /strategy, /discover, /ideate, /product, /taste, /retro, /roadmap, /ship, /copy, /money
- **Architecture B (Forked Task)**: Fork, CANNOT spawn agents. Use for isolated work: /configure

Skills MUST choose one architecture. Having both `context: fork` AND `Agent` in allowed-tools is a bug.

### Done (v8.3)

- ~~`context: fork` on expensive skills~~ — /product uses fork. /research, /strategy removed fork (need agents).
- ~~`model: haiku` on cheap skills~~ — measurer→haiku, reviewer→haiku.
- ~~`memory: user` on agents~~ — all 14 agents have `memory: user`.
- ~~`background: true` on agents~~ — explorer and market-analyst always run in background.
- ~~`/batch` pattern for /go~~ — builder + refactorer agents use worktree isolation.
- ~~Parallel evaluator spawning~~ — /eval spawns evaluator per feature in parallel.
- ~~Named agent references~~ — all skills use `founder-os:<agent>`, never `"general-purpose"`.
- ~~`skills` preloading on agents~~ — NOT IMPLEMENTED. All agents have `skills: []`. Skills preloading is available but unused.
- ~~`maxTurns` on agents~~ — all 14 agents have safety valves (10-30 turns).
- ~~/calibrate merged into /taste~~ — taste owns visual intelligence + calibration.

### Done (v9.0 — Startup Agent Layer)

- ~~5 new agents~~ — customer (sonnet, bg), founder-coach (opus), consolidator (sonnet), gtm (opus, bg), copywriter (opus). All with `memory: user` + `maxTurns`.
- ~~`mind/startup-patterns.md`~~ — 8 failure mode detection rules loaded via `.claude/rules/` symlink. Makes all agents startup-aware.
- ~~`/product` converted Architecture A~~ — removed `context: fork`, now spawns customer + founder-coach agents inline.
- ~~`/discover` enhanced~~ — spawns customer agent alongside explorer + market-analyst.
- ~~`/retro` enhanced~~ — spawns consolidator agent after grading for knowledge model maintenance.
- ~~`/strategy` enhanced~~ — spawns gtm agent for `gtm` and `price` modes.
- ~~`/go` soft discovery gate~~ — informational warning when building without customer signal.
- ~~`/ship` launch readiness~~ — checks for GTM strategy, customer signal, narrative freshness on release ships.
- ~~`/eval` customer-aware viability~~ — reads customer-intel.json for viability dimension scoring.
- ~~`/plan` startup pattern check~~ — runs failure mode detection before bottleneck diagnosis.
- ~~`/ideate` customer signal~~ — spawns customer agent for signal-weighted ideation.
- ~~2 new skills~~ — `/money` (pricing, runway, unit economics, channels) and `/copy` (landing pages, pitch, outreach, release notes). Both are rich folder skills with references + templates.
- Agent count: 9 → 14. Skill count: 25 (after audit killed humanize, build, portfolio; calibrate vestigial).

### Priority 1: Highest Leverage (would change behavior)

1. **Plugin `settings.json` with `agent` key.** A plugin can make Claude boot into a persona. One agent definition could replace the entire `.claude/rules/` symlink architecture. founder-os ships a default agent config that gives every session measurement awareness + prediction discipline without symlinks.

2. **Agent SDK for eval (rewrite bin/eval.sh).** The 15pt variance in LLM-judged feature scores is the #1 measurement problem. Fix: rewrite the judge as Python/TypeScript using the Anthropic API with temperature=0, structured output schema, rubric-anchored prompts. Directly eliminates JSON parsing bugs and non-determinism. Cost: ~$0.03/eval run on Haiku.

3. ~~**`UserPromptSubmit` hook for intent routing.**~~ Done — hook registered.

4. ~~**`TaskCompleted` hook as quality gate.**~~ Done — hook registered.

5. ~~**`SessionEnd` hook for auto session logging.**~~ Done — hook registered.

6. **`prompt` hook handler on `SubagentStop`.** founder-os uses `command` hooks (shell scripts). A `prompt` hook is a lightweight LLM evaluation — "did this agent follow founder-os standards?" Free quality enforcement on every agent completion. Zero shell scripts needed.

### Priority 2: Medium-Term (extend what works)

7. **LSP tool on evaluator agent.** 50ms go-to-definition vs 30-60s grep. Add LSP to evaluator's allowed-tools for dramatically better code navigation during /eval. Supports 11+ languages.
8. ~~**`PostCompact` hook for context rebuild.**~~ Done — hook registered.
9. **`InstructionsLoaded` hook.** Validate mind files actually loaded (currently no way to know if identity.md/thinking.md failed to inject).
10. **CronCreate for periodic monitoring.** /go could schedule periodic score checks during build loops instead of manual check-ins. Session-scoped, up to 50 tasks.
11. **Auto-memory unification.** Claude Code has native `~/.claude/memory/`. All 9 agents have `memory: user`. Does this overlap with experiment-learnings.md? If agent memory captures the same patterns, the manual knowledge model becomes redundant.
12. **MCP elicitation for interactive /eval.** /eval could ask the founder structured quality questions during scoring instead of pure LLM judgment. Blends human signal with mechanical measurement.
13. **Skill-scoped hooks.** /go could have an on-complete hook that runs assertions. Skills can have their own lifecycle hooks — not just global ones.
14. **`allowed-tools` on readonly skills.** /eval analysis phase, /retro shouldn't be able to Write files.

### Priority 3: Big Bets (new product surface)

15. **Cross-tool portability via AgentSkills.io.** founder-os skills working in Cursor and Gemini CLI. Massively expands TAM.
16. **Marketplace distribution with version pinning.** `claude plugin install founder-os@v8.0.3` with guaranteed compatibility.
17. **Agent teams for composite skills.** Experimental in Claude Code. /audit spawns taste + eval + product agents that communicate directly with each other — not just report back to the orchestrating skill.
