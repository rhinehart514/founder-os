# Skill Anatomy — What Makes a Good Skill

Distilled from the Anthropic skills guide + founder-os experience.

## A skill is a folder, not a file

The most common mistake: treating SKILL.md as the entire skill. The markdown file is the orchestrator. The folder is the skill.

```
skills/example/
  SKILL.md              — thin orchestrator (routes, reads state, delegates)
  gotchas.md            — failure modes from real sessions (highest-signal content)
  scripts/              — mechanical checks Claude runs via Bash (zero-hallucination)
  references/           — domain knowledge Claude reads on demand (progressive disclosure)
  templates/            — output structure templates (consistency across runs)
  reference.md          — output formatting templates
```

## SKILL.md: the thin orchestrator

Under 120 lines for most skills. It does three things:

1. **Routes** — parse arguments, decide which mode to run
2. **Reads state** — point to scripts that scan project state mechanically
3. **Delegates** — point to references/templates/scripts for the actual work

What SKILL.md is NOT:
- Not a knowledge dump (put that in references/)
- Not an output template (put that in reference.md or templates/)
- Not a script (put that in scripts/)
- Not a gotcha list (put that in gotchas.md)

## gotchas.md: the highest-signal file

Per Anthropic: "The highest-signal content in any skill is the Gotchas section." Build this from real failure modes Claude hits when using the skill. Update it every time the skill fails in a new way.

Structure each gotcha as: **what goes wrong** + **why** + **fix**. Not just "don't do X" but "X fails because Y, instead do Z."

## scripts/: mechanical grounding

Scripts eliminate hallucination. Instead of asking Claude to count files or parse JSON, run a script that does it deterministically.

Good script patterns:
- **Scan scripts** — read project state, output structured data
- **Check scripts** — validate conditions, return pass/fail
- **Log scripts** — append to persistent history files

Scripts should be fast (<2s), deterministic, and produce structured output Claude can parse. Use `${CLAUDE_PROJECT_DIR}` for paths. Use `${CLAUDE_PLUGIN_DATA}` for persistent storage.

## references/: progressive disclosure

Domain knowledge that Claude reads on demand, not on every invocation. This is the "file system as context engineering" pattern from Anthropic's guide.

Tell Claude what's in the references and when to read them. Don't dump everything into SKILL.md.

## templates/: consistent output

Output templates for structured artifacts the skill produces. Markdown templates for documents, JSON templates for data structures.

Templates give Claude the structure. Claude fills in the specifics from project state.

## The description field

The description in frontmatter is for the model, not humans. It determines when Claude triggers this skill. Write it as: "Use when [specific trigger conditions]."

## Measurement wiring (founder-os specific)

A founder-os skill is measured:
- Feature entry in `config/founder.yml` with weight
- Assertions in `beliefs.yml` that test the skill works
- Eval score tracked over time
- Maturity computed from score: planned → building → working → polished → proven

Without measurement, a skill can't prove it works. Structure without measurement is theater.
