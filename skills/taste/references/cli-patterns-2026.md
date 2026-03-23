# CLI/Terminal UX Patterns — 2026 Reference

Best-in-class patterns from verified research. Read on demand during /taste cli evaluations
or when building CLI output for any skill.

## The Reference Tools (what sets the bar)

| Tool | What it does best | Pattern to learn |
|------|-------------------|------------------|
| rustc | Error display | Three-level hierarchy: signal → location → context → fix |
| clack | Interactive prompts | `│`-bordered flows with `◆◇▲■` symbol set |
| Turborepo | Parallel task display | Split-screen TUI: task list left, output right |
| Charm (Bubble Tea) | Full TUI apps | Elm architecture, component model, physics-based animation |
| ruff | Dense diagnostic output | One line per finding, all signal, `[*]` for fixable |
| bun | Speed as UX | 3-4 lines max, timing prominently shown |
| biome | Output control | `--max-diagnostics N`, human→stderr, machine→stdout |

## Interaction Patterns

### The clack visual language (semi-standard in 2026)
```
┌  create-my-app
│
◆  What is your project name?
│  my-project
│
◇  Which template?
│  TypeScript
│
└  Done!
```

Symbols: `│` border, `◆` active step, `◇` completed, `▲` error, `■` cancelled.
Dozens of Node.js CLIs adopted this. It's the Material Design of terminal interactions.

### Autocomplete (the Fig legacy)
- Inline ghost text (dim, Tab to accept)
- Floating popup anchored to cursor (5-8 options, descriptions)
- Context-aware: reads git state, directory, available subcommands
- Zero-latency or don't bother — server round-trips break the illusion

### Help text (the jq model)
- `-h` for concise (what to run next), `--help` for full reference
- Lead with examples — users learn by example faster than option lists
- Most common flags first, not alphabetical
- Pointer to web docs for deep reference

### Subcommand discovery
The kubectl pattern: consistent verb-noun structure lets users guess commands.
`get pods` → `get deployments` → `describe pods`. The pattern teaches itself.

## When to Build a TUI vs. Plain CLI

**Build a TUI when:**
- User navigates N items and takes actions on them (k9s, lazygit)
- Real-time state needs watching across multiple dimensions (htop)
- Workflow has undo/redo that benefits from seeing state before acting
- Operation takes minutes with monitoring needed

**Don't build a TUI when:**
- Command runs and exits in under 5 seconds
- Output is consumed by scripts or CI
- User runs it once and moves on

The test: would a user leave this running and interact with it for 30+ seconds?

## The stdout/stderr Split (AI-native pattern)

```
stdout = the product output (JSON, structured data, the result)
stderr = progress, spinners, status lines, warnings (human-readable, not contractual)
```

This means `mytool | jq .` works cleanly. Spinners go to stderr, JSON stays clean on stdout.
This is the emerging standard for AI-native CLIs.

## Score/Evaluation Display Pattern

```
  Score: 73/100

    Delivery    ████████░░  78
    Craft       ███████░░░  68
    Viability   ██████████  82

    Bottleneck: Craft (68) — 3 issues found
    → Run /eval craft for details
```

Pattern: lead with the number → visual bars for relative position → named breakdown → actionable next step.

## Plan-Before-Execute Pattern (Warp, 2026)

For any CLI that takes destructive or multi-step actions: show the plan, get confirmation, execute.
Warp's `/plan` command is the reference. This prevents accidents without the anti-pattern of
"Are you sure? (y/n)" on every action.

The plan IS the preview. Not a confirmation dialog — a full preview of what will happen.

## Sources

- clig.dev — Command Line Interface Guidelines
- Evil Martians — CLI UX progress display patterns
- BetterCLI.org — Colors and formatting
- InfoQ — AI Agent CLI patterns
- Charm libraries (charm.land/libs)
- Clack (clack.cc)
- Turborepo TUI (ratatui-based)
- Warp 2.0 Agentic Development Environment
- rustc diagnostic design guide
