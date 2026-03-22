# Skill Management Gotchas

Real failure modes from past sessions. Read before creating or auditing.

## Creating without evidence
The 3-question gate exists because most skill ideas die on contact with reality. If the founder can't point to 3+ sessions where the pattern appeared, it's a wish, not a skill. Push back: "Keep watching for the pattern."

## SKILL.md as the entire skill
The #1 mistake. A 500-line SKILL.md is doing the job of scripts, references, and templates. Split it: orchestrator stays thin, knowledge goes into the folder. Per Anthropic guide: "Think of the entire file system as a form of context engineering."

## Overlap blindness
Two skills that do 60% the same thing fragment intelligence instead of concentrating it. Always run overlap check before creating. The instinct is "but mine is slightly different" — resist it. Add a route to the existing skill.

## Structure without measurement
A 400-line SKILL.md with 0 assertions is theater. The skill looks thick, passes structural checks, but can't prove it works. Assertions are the difference between a skill and a prompt.

## Thick skill vanity
Not every skill needs to be thick. Low-weight, narrow-scope skills should stay thin. The problem is high-weight skills (w:4-5) that are thin or stub. Match investment to importance, not ego.

## Unmeasured survival
Skills without assertions survive indefinitely because nothing flags them. Without measurement, nobody notices when they drift. Flag at 30 days. Kill or measure at 60.

## Folder over-engineering
Adding scripts/references/templates to a skill that runs once a month is waste. Match folder investment to usage frequency. A monthly skill with a gotchas.md is better than one with empty folders.

## Route keyword collision
"analyze" and "evaluate" and "check" all overlap semantically. Route overlap detection needs to catch these synonyms, not just exact keyword matches. When routing is ambiguous, the user gets the wrong skill.

## Description field as summary
The description in frontmatter is for model routing, not human reading. "A skill for managing skills" tells Claude nothing about when to trigger. Write triggers: "Use when creating, auditing, or managing skills."

## Scripts that require missing tools
Scripts that shell out to `python3` or `jq` fail silently on machines without them. Every script should degrade gracefully or check for dependencies at the top.
