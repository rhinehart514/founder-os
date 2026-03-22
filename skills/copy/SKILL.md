---
name: copy
description: "Use when the user needs product copy — landing pages, pitch, onboarding text, release notes, or empty-state guidance. Positioning-aware and customer-grounded."
argument-hint: "[landing|pitch|outreach|release|onboard|empty-states|\"write copy for...\"]"
allowed-tools: Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, Agent, AskUserQuestion
---

# /copy

Positioning-aware product copy. Names a specific person, states what changes for them, differentiates from every alternative. Reads market context, customer signal, and design system to produce copy grounded in evidence, not adjectives.

## Skill folder structure

This skill is a **folder**. Read these on demand:

- `scripts/slop-check.sh <file>` — mechanical slop detector. **Standalone utility** — run `bash scripts/slop-check.sh <file>` independently to check any text for slop patterns, outside of /copy.
- `scripts/copy-log.sh` — persistent copy history (add, list, stats). Uses `${CLAUDE_PLUGIN_DATA}`
- `scripts/copy-diff.sh [type]` — shows copy iteration history
- `references/voice-guide.md` — how to write in the product's voice (optional — read when voice alignment matters, Claude has good defaults)
- `references/slop-words.md` — the banned word list with why each is banned
- `references/positioning-frameworks.md` — category creation, competitor wedge framing
- `references/copy-patterns.md` — headline formulas, CTA patterns
- `templates/landing-page.md` — hero + problem + solution + proof + CTA structure
- `templates/release-announcement.md` — release announcement template (user-facing, not changelog)
- `templates/pitch-narrative.md` — elevator/tweet/paragraph narrative
- `templates/cold-outreach.md` — email + DM templates
- `templates/release-notes.md` — user-facing changelog structure
- `reference.md` — output templates for all modes
- `gotchas.md` — LLM copy failure modes. **Read before generating any copy.**

## Routing

| Input | Mode | Agent? |
|-------|------|--------|
| (none) | Ask what copy is needed via AskUserQuestion | — |
| `landing` | Landing page: hero, problem, solution, CTA | copywriter + market-analyst |
| `pitch` | Elevator (10s), tweet (280c), paragraph (50w) | copywriter + market-analyst |
| `outreach` | Cold email/DM with specific targeting | copywriter |
| `release` | Release notes from roadmap data | no agent — review draft via quality gate |
| `onboard` | First-screen + success moment copy | no agent — review draft via quality gate |
| `empty-states` | Copy for every empty state in the product | no agent — review draft via quality gate |
| `review` | Check existing copy for quality | no agent — quality verdict + specific fixes only |
| `[any text]` | Custom copy brief | copywriter |

## How it works

**Read state first** (parallel): `config/founder.yml` (user, features), `.claude/cache/market-context.json`, `.claude/cache/customer-intel.json`, `.claude/cache/narrative.yml`, `.claude/design-system.md`. Then read `gotchas.md` and `references/slop-words.md`. For landing/pitch: also `references/positioning-frameworks.md` and `references/voice-guide.md`.

**Agent spawning** — only for modes that need it:
- `landing`, `pitch`, `outreach`, custom briefs → spawn `founder-os:copywriter` with full context from state reads. For `landing` and `pitch`, also spawn `founder-os:market-analyst` in background for competitive messaging.
- `release`, `onboard`, `empty-states` → write the draft yourself, then run it through the quality gate. These are simpler modes that don't justify agent cost.
- `review` → no draft generation. Run the quality gate on the founder's existing copy. Output: verdict (pass/fail per check) + specific line-level fixes. Not a full rewrite.

**Quality gate (mandatory)** — before presenting ANY copy:
1. Names a person? (not "developers" — a specific situation)
2. States what changes? (not "improve your workflow" — tangible outcome)
3. Differentiates? (names a specific alternative)
4. Slop-free? Run `echo "[copy]" | bash ${CLAUDE_SKILL_DIR}/scripts/slop-check.sh`
Any failure = rewrite before presenting.

**Present and log** — via AskUserQuestion. Log via `bash ${CLAUDE_SKILL_DIR}/scripts/copy-log.sh add "[type]" "[headline]" "[preview]"`.

## System integration

Reads: `config/founder.yml`, `.claude/cache/market-context.json`, `.claude/cache/customer-intel.json`, `.claude/cache/narrative.yml`, `.claude/design-system.md`
Writes: `${CLAUDE_PLUGIN_DATA}/copy-log.json`, copy files in project
Triggers: `/taste` (check copy visually), `/ship release` (use copy in release notes)
Triggered by: `/onboard` (empty-states), `/ship` (release notes), `/ideate` (positioning), manual

## Output format

See `reference.md` for mode-specific templates.

For **review mode**: quality verdict per check (pass/fail) + specific fixes. Not a full rewrite.

For **generation modes**: draft + quality gate results.

## Self-evaluation

The skill worked if:
- Copy names a specific person (not "developers" or "teams")
- Copy states a tangible outcome (not "improve your workflow")
- `slop-check.sh` returned 0 slop words
- Review mode: specific fixes were provided, not a full rewrite

## What you never do

- Use slop words — the ban list is absolute (see `references/slop-words.md`)
- Claim features that score <50 — only claim what's delivered
- Skip the quality gate — every piece of copy gets checked
- Generate copy for a product with no user defined — flag and help define
- Spawn agents for simple modes (release, onboard, empty-states) — write the draft yourself

## If something breaks

- No value.user in founder.yml: "Who is this for? Define the user before writing copy."
- No market-context.json: degrade to un-positioned copy, flag it
- No customer-intel.json: use founder language from founder.yml
- No design-system.md: use neutral tone, suggest creating one

$ARGUMENTS
