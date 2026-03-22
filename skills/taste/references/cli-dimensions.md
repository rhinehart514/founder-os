# CLI Taste Dimensions

Five dimensions for evaluating CLI/terminal output quality. Each 0-100.

## 1. Scanability

Can you get the key information in 2 seconds without reading?

| Score | Anchor |
|-------|--------|
| 90+ | One glance tells you the answer. Number, status, and next action are instantly visible. |
| 70-89 | Key info is in the first 3 lines. Some scanning needed but structure guides the eye. |
| 50-69 | Important info is present but buried. You need to read 5+ lines to find it. |
| 30-49 | Wall of text. Important and unimportant info at the same visual weight. |
| 0-29 | Can't find the answer without reading everything. Or no useful output at all. |

**What to check:**
- Is the most important information first?
- Can you skip sections and still get the key message?
- Are numbers, scores, and statuses visually prominent?
- Is signal separated from noise?

## 2. Output Hierarchy

Do bold/color/position distinguish primary findings from supporting detail?

| Score | Anchor |
|-------|--------|
| 90+ | Three clear levels: primary (bold/color), secondary (normal), tertiary (dim/indented). Instantly parseable. |
| 70-89 | Two clear levels. Headers and content are distinguishable. Some visual noise. |
| 50-69 | Headers exist but content is uniform weight. Everything looks equally important. |
| 30-49 | No visual hierarchy. Plain text dump. |
| 0-29 | Actively confusing — decoration without meaning, or formatting that obscures. |

**What to check:**
- Are section headers visually distinct from content?
- Is indentation meaningful (not just random)?
- Do colors/symbols carry consistent meaning (not decoration)?
- Is there a clear primary → secondary → detail progression?

## 3. Voice Compliance

Consistent symbols, formatting, structure across commands. Follows the product's voice.

| Score | Anchor |
|-------|--------|
| 90+ | Every command feels like the same product. Symbols, spacing, header style, density — all consistent. |
| 70-89 | Mostly consistent. One or two commands diverge from the pattern. |
| 50-69 | Some shared patterns but noticeable inconsistencies between commands. |
| 30-49 | Each command looks like a different product. |
| 0-29 | No discernible voice. Raw debug output. |

**What to check:**
- Do all commands use the same section header style?
- Are status indicators consistent (✓/✗/· vs pass/fail vs YES/NO)?
- Is spacing/indentation consistent across commands?
- Does the tone match (terse vs. verbose, formal vs. casual)?

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
