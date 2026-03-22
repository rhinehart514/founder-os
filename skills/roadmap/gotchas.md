# Roadmap Gotchas

Built from real failure modes. Update this when /roadmap fails in a new way.

## Thesis failures
- **Thesis vs implementation confusion**: "Implemented assertions" is not the thesis — the thesis is what you PROVED. State what you learned, not what you built. Check: can you phrase the thesis as a question? If not, it's a task list.
- **Thesis too broad**: If a version needs 6+ evidence items, the question is too big. Split into a major + minor, or narrow the question. "Make everything better" is not a thesis.
- **Thesis as wishlist**: Future versions with no connection to current evidence are fiction. Every thesis emerges from what the previous version proved or failed to prove.

## Evidence failures
- **Evidence staleness**: Items marked "partial" weeks ago are forgotten. Run `scripts/evidence-tracker.sh` to find stale items. If evidence hasn't moved in 14+ days, either the thesis is wrong or you're avoiding it.
- **Proven without proof**: Marking evidence "proven" without citing a specific file, test result, or number. "It works" is not evidence. "commander.js init scored 80/100" is evidence.
- **Ignoring disproven**: Disproven evidence is the most valuable signal. Don't hide it — write it to experiment-learnings.md as a Dead End. It tells you what's NOT true, which narrows the search space.

## Narrative failures
- **Narrative fiction**: Marketing copy overstates what was proven. Every claim in a changelog or narrative must trace to a proven evidence item or Known Pattern. If you can't cite it, you can't claim it.
- **Stale narrative**: After a bump, the narrative still reflects the old version. Always suggest `/roadmap narrative` after a bump.
- **Slop language**: "Streamline your workflow" has no information content. Use the ban list in `references/changelog-guide.md`.

## Version management failures
- **Version inflation**: Bumping major for minor work. Major = new thesis (new question). Minor = significant improvement. Patch = fix. Read `references/version-guide.md` when unsure.
- **Premature bump**: Bumping before evidence is collected. Check `scripts/version-progress.sh` first — if completion is under 60%, the version isn't ready.
- **Missing thesis transfer**: After proving a major thesis, forgetting to write it as a Known Pattern in experiment-learnings.md. The thesis is learned knowledge — it should persist beyond the roadmap.

## Script failures
- **No roadmap.yml**: Scripts exit cleanly but produce no data. Check that the project has been initialized with `/onboard`.
- **YAML parse fragility**: The scripts use grep/awk on YAML, not a proper parser. Multiline values, unusual indentation, or comments between fields can break parsing. Keep roadmap.yml entries clean and consistent.
