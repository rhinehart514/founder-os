# Changelog Guide

## What a changelog is

A human-readable record of what changed from the USER's perspective. Not git commits. Not code diffs. What's different for the person using this.

## What to include

- Features that reached "working" or above (eval score 50+)
- Behavior changes users will notice
- Removed/deprecated capabilities
- Evidence items that were proven (translated to user language)

## What to exclude

- Internal refactors (unless they change behavior)
- Score improvements with no visible change
- Prediction/learning loop updates
- Code health improvements

## Translation table

| Internal language | Changelog language |
|---|---|
| "thesis proven" | "now supports..." |
| "feature reached 60+" | "added..." |
| "evidence item disproven" | "removed..." or "changed approach to..." |
| "Known Pattern confirmed" | (don't surface — internal) |
| "assertion added" | (don't surface — internal) |
| "score improved from X to Y" | (don't surface unless behavior changed) |

## Format rules

- Reverse chronological (newest first)
- Group by major version
- Nest patches under their parent major
- Each entry: version number, one-line theme, bullet points of changes
- One paragraph max per major version describing the thesis in user terms
- Patch entries are terse: just the fixes

## Tone

- Direct. No marketing language.
- Specific. "Plugin install mode" not "improved installation experience."
- Honest. If something was removed because it didn't work, say so.
- Numbers when possible. "80/100 on first external test" not "works well."

## Anti-slop

Ban list for changelogs: "streamline," "supercharge," "leverage," "unlock," "seamlessly," "robust," "cutting-edge," "AI-powered," "revolutionary."

If a sentence still makes sense when you replace the noun with "thing," it's too generic. Rewrite.
