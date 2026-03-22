# Push Patterns

## Three levels of work

Every /push session operates at three levels. The ratio shifts with maturity.

### Level 1: Mechanical (fix what eval found)
- Gap has file:line evidence → go to that exact line, fix that exact thing
- Fastest, most predictable, lowest risk
- At score 30: this is 90% of the work
- At score 80: this is 20% of the work

### Level 2: Diagnostic (find what eval missed)
- Read the code deeper than eval did — eval skims, you read
- Look for: silent error swallowing, inconsistent patterns, fragile parsing, missing validation
- Medium speed, medium risk — you might find nothing, or you might find the real problem
- At score 30: skip this — features barely exist
- At score 65+: this is where the real gains are

### Level 3: Creative (ideate what would make it great)
- Not fixing bugs — inventing improvements
- Grounded in measurement data: "scoring craft is 65 because output buries the number → what if we added inline sparklines?"
- Highest impact, highest risk — might not work, might be wrong level
- At score 30: skip entirely
- At score 70+: this is the only way to break through plateaus

## Batch strategy

- **Batch by feature, not by level.** Work all three levels for scoring before moving to learning.
- **Mechanical first within each feature.** Known bugs before speculative improvements.
- **Verify between levels.** Run assertions after mechanical fixes before starting diagnostic work.

## What works at each maturity

| Score | Focus on... | Skip... |
|-------|------------|---------|
| 0-30 | Building features that don't exist | Polish, micro-UX, edge cases |
| 30-50 | Wiring features together, error handling | Visual design, performance, delight |
| 50-65 | User understanding, output clarity, dead ends | Micro-interactions, accessibility |
| 65-80 | Craft, consistency, progressive disclosure | New features, architecture rewrites |
| 80-90 | Edge cases, performance, graceful degradation | Feature additions, scope expansion |
| 90+ | External validation, instrumentation | Everything internal — the product works |

## Anti-patterns

- **Fixing at the wrong level.** Score is 45 but you're tweaking output formatting → you're polishing a skeleton. Build the feature first.
- **All mechanical, no ideation.** Closing every eval gap but never asking "what would actually make this great?" → diminishing returns. The eval only catches what it knows to look for.
- **All ideation, no mechanical.** Creative improvements while known bugs exist → building on a cracked foundation.
- **Parallelizing overlapping files.** Two builders editing the same script → merge conflict, wasted work. Check code paths before spawning parallel agents.
- **Ignoring the wrong-prediction cache.** `.claude/cache/wrong-prediction-areas.txt` lists where predictions failed. Don't repeat failed approaches — ideate differently.
