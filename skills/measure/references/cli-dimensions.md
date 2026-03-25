# CLI Taste Dimensions

Five dimensions for evaluating CLI/terminal output quality. Each 0-100.

**2026 bar:** The ceiling is set by rustc diagnostics (error display), clack prompts (interaction flows),
Turborepo TUI (parallel task visualization), and Charm libraries (component architecture). Tools that
feel like 2024 dump plain text and hope. Tools that feel like 2026 have semantic color, three-level
hierarchy, and always end with what to do next.

## 1. Scanability

Can you get the key information in 2 seconds without reading?

| Score | Anchor |
|-------|--------|
| 90+ | One glance tells you the answer. Number, status, and next action are instantly visible. Signal first, detail second. |
| 70-89 | Key info is in the first 3 lines. Some scanning needed but structure guides the eye. |
| 50-69 | Important info is present but buried. You need to read 5+ lines to find it. |
| 30-49 | Wall of text. Important and unimportant info at the same visual weight. |
| 0-29 | Can't find the answer without reading everything. Or no useful output at all. |

**What to check:**
- Is the most important information first? (bun pattern: result + timing on first line)
- Can you skip sections and still get the key message?
- Are numbers, scores, and statuses visually prominent?
- Is signal separated from noise?
- Does default output show summary only? (`--verbose` for detail, not the other way around)
- Is output density appropriate? (clig.dev: "Commands say too much when they dump pages of debugging output")

**2026 reference patterns:**
- Ruff: `file.py:1:8: F401 [*] \`os\` imported but unused` — one line, all signal
- Bun: 3-4 lines max for installs, prominently shows `12ms` timing
- Biome: `--max-diagnostics N` to prevent output floods

## 2. Output Hierarchy

Do bold/color/position distinguish primary findings from supporting detail?

| Score | Anchor |
|-------|--------|
| 90+ | Three clear levels: primary (bold/color), secondary (normal), tertiary (dim/indented). Instantly parseable. The rustc diagnostic standard. |
| 70-89 | Two clear levels. Headers and content are distinguishable. Some visual noise. |
| 50-69 | Headers exist but content is uniform weight. Everything looks equally important. |
| 30-49 | No visual hierarchy. Plain text dump. |
| 0-29 | Actively confusing — decoration without meaning, or formatting that obscures. |

**What to check:**
- Are section headers visually distinct from content?
- Is indentation meaningful (not just random)?
- Do colors/symbols carry consistent meaning (not decoration)?
- Is there a clear primary → secondary → detail progression?
- Does color follow the semantic contract (see below)?

**The 2026 semantic color contract:**

| Color | Meaning | Never use for |
|-------|---------|--------------|
| Red (bold) | Error, failure, critical | Decoration, emphasis on non-errors |
| Yellow | Warning, caution | Info messages |
| Green | Success, pass, complete | Status that isn't definitively good |
| Cyan/Blue | Info, suggested actions | Errors |
| Dim/gray | Context, secondary info, paths | Primary content |
| Bold | Primary signal, the message itself | Everything (dilutes meaning) |

**The rustc gold standard for error display:**
```
error[E0308]: mismatched types        ← bold red signal + error code
  --> src/main.rs:4:5                  ← dim location
   |
 4 |     let x: i32 = "hello";        ← code context
   |                  ^^^^^^^ expected `i32`, found `&str`  ← underline + label
   |
help: try converting the string        ← cyan/green actionable fix
```

## 3. Voice Compliance

Consistent symbols, formatting, structure across commands. Follows the product's voice.

| Score | Anchor |
|-------|--------|
| 90+ | Every command feels like the same product. Symbols, spacing, header style, density — all consistent. The clack standard: one symbol set, one visual language. |
| 70-89 | Mostly consistent. One or two commands diverge from the pattern. |
| 50-69 | Some shared patterns but noticeable inconsistencies between commands. |
| 30-49 | Each command looks like a different product. |
| 0-29 | No discernible voice. Raw debug output. |

**What to check:**
- Do all commands use the same section header style?
- Are status indicators consistent (✓/✗/· vs pass/fail vs YES/NO)?
- Is spacing/indentation consistent across commands?
- Does the tone match (terse vs. verbose, formal vs. casual)?
- Is there one symbol set used everywhere? (clack uses `◆◇▲■◯◉☐☑` consistently)

**2026 reference:** Clack established a visual language that dozens of Node.js CLIs adopted.
The test: could you identify which product made this output without seeing the name?

## 4. Actionable Output

Every command ends with what to do next. Not just data — direction.

| Score | Anchor |
|-------|--------|
| 90+ | Clear single next action. "Run X to fix this." No menu, no ambiguity. |
| 70-89 | Next action present but among 2-3 options. Still clear which is primary. |
| 50-69 | Data is shown but "what do I do with this?" requires interpretation. |
| 30-49 | Output dumps data and stops. User must know the system to decide next step. |
| 0-29 | No indication of what to do. Terminates without guidance. |

**What to check:**
- Does the output end with a recommended next command?
- Is one action primary and others secondary?
- Does the output answer "what should I do?" not just "what happened?"
- Are error messages paired with fix instructions?

**The three-part error rule (2026 standard):**
1. **What happened**: specific, not generic. Not "Error" — "Can't write to config.yml"
2. **Why**: "You don't have write permission"
3. **How to fix**: "Run `chmod +w config.yml` or check file ownership"

Bonus (rustc pattern): error code with `--explain` support for full docs.

## 5. Graceful Degradation

Missing dependencies, missing config, missing data — each gets a helpful message, not a stack trace.

| Score | Anchor |
|-------|--------|
| 90+ | Every failure state produces a specific, actionable message. "Missing X — run Y to fix." |
| 70-89 | Most failures handled. One or two edge cases produce unclear errors. |
| 50-69 | Common failures handled, uncommon ones produce raw errors or stack traces. |
| 30-49 | Errors are caught but messages are generic ("Error occurred"). |
| 0-29 | Stack traces, silent failures, or crashes on missing dependencies. |

**What to check:**
- Run the command with missing config — what happens?
- Run with missing dependencies — what happens?
- Run with empty/corrupt data — what happens?
- Are error messages specific enough to act on without reading source code?
- Does it respect TTY detection? (no spinners/colors when piped)
- Does it respect NO_COLOR env var?
- Does `Ctrl-C` exit cleanly with a message, not a stack trace?

**2026 non-negotiables for graceful degradation:**
- `NO_COLOR` env var → strip all ANSI codes (no-color.org standard)
- TTY detection → disable spinners, progress bars, interactive prompts when piped
- `TERM=dumb` → disable all formatting
- Machine output mode → `--json` flag for structured stdout
- Cancellation → `Ctrl-C` shows `Cancelled.` not a traceback

## Anti-Patterns (what drops the score)

These are confirmed bad patterns from 2026 CLI UX research:

- **Logging noise at default verbosity**: "Starting process..." and "Process started." on every action
- **Timestamps on every line** when user didn't ask for timing
- **Stack traces on expected errors**: file not found → stack trace is wrong
- **Progress bars in CI logs**: becomes "Christmas tree" of partial lines. Suppress when not TTY.
- **Silent success that looks like a hang**: no output for 10 seconds with no spinner
- **Everything colored**: color loses signal value when every line is a different color
- **Red for non-errors**: using red because it "looks cool"
- **Colors that break on light terminals**: dark gray text vanishing on white background
- **Emoji spam**: one meaningful symbol per output type is fine. Sparkle + checkmark + party popper = noise.
- **Confirmation prompts for non-destructive actions**: "Are you sure? (y/n)" when nothing can go wrong
- **Required flags with no reasonable default**: forcing `--format json` when json is the only option
