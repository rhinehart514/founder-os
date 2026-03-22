# /configure Reference — Output Templates

Loaded on demand. Routing and interview logic are in SKILL.md.

---

## Show output (default)

```
◆ configure — current settings
  project: founder-os  ·  stage: early  ·  mode: build

  ▾ agents
    cost: balanced (opus for hard work, sonnet for research, haiku for measurement)
    autonomy: supervised (/go requires approval before each move)

  ▾ output
    verbosity: normal

  ▾ go
    hard_gate: true (must approve each move)
    plateau_threshold: 3 (stop after 3 flat moves)

  source: ~/.claude/preferences.yml (exists)
  fallback: config/founder.yml defaults

/configure agents     change agent models
/configure go         change build loop behavior
/configure reset      restore defaults
```

## Show output (no preferences.yml)

```
◆ configure — current settings (defaults)
  project: founder-os  ·  stage: early  ·  mode: build

  ▾ agents
    cost: balanced (default — opus for hard work, sonnet for research, haiku for measurement)
    autonomy: supervised (default — /go requires approval before each move)

  ▾ output
    verbosity: normal (default)

  ▾ go
    hard_gate: true (default — must approve each move)
    plateau_threshold: 3 (default — from founder.yml)

  source: no preferences.yml — using defaults
  fallback: config/founder.yml

/configure agents     change agent models
/configure go         change build loop behavior
/configure output     change verbosity
```

## Agents confirmation

```
◆ configure — agents updated

  cost: **premium**
    builder: opus · evaluator: opus · market-analyst: opus
    explorer: opus · grader: opus · debugger: opus · refactorer: opus
    measurer: sonnet · reviewer: sonnet

  autonomy: **autonomous** (/go presents plan, builds immediately)

  written to: ~/.claude/preferences.yml

/configure show      verify all settings
/go                  build with new settings
/eval                measure current state
```

## Go confirmation

```
◆ configure — go updated

  hard_gate: **false** (/go builds without waiting for approval)
  plateau_threshold: **5** (stop after 5 flat moves)

  written to: ~/.claude/preferences.yml

/configure show      verify all settings
/go                  try the new settings
/plan                what to work on
```

## Output confirmation

```
◆ configure — output updated

  verbosity: **quiet** (headers + scores + bottom commands only)

  written to: ~/.claude/preferences.yml

/configure show      verify all settings
/eval                see quiet output in action
/go                  build with new settings
```

## Reset confirmation

```
◆ configure — reset

  ✓ deleted ~/.claude/preferences.yml
  all settings restored to defaults:
    agents.cost: balanced
    agents.autonomy: supervised
    output.verbosity: normal
    go.hard_gate: true
    go.plateau_threshold: 3

/configure show      verify defaults
/go                  build with defaults
/plan                what to work on
```

## Preferences file format

```yaml
# ~/.claude/preferences.yml — user preferences for founder-os
# Written by /configure. Project config lives in config/founder.yml.

agents:
  cost: balanced        # economy | balanced | premium
  autonomy: supervised  # supervised | autonomous | full-auto

output:
  verbosity: normal     # quiet | normal | verbose

go:
  hard_gate: true       # true | false
  plateau_threshold: 3  # 1-10
```

## Formatting rules

- Header: `◆ configure — [scope]`
- Settings grouped under `▾` section markers
- Each setting: key: **value** (explanation)
- Source line: where the settings came from
- Bottom: exactly 3 next commands
- Confirmation output: show what changed + where written
- No state bar (configure doesn't produce scores)
