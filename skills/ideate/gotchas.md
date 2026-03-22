# Ideation Gotchas

Built from real failure modes across sessions. Update this when /ideate fails in a new way.

## Evidence failures
- **"Wouldn't it be cool if..."**: Ideas without evidence are wishes. Every idea needs a cite from eval-cache, predictions.tsv, customer-intel, or market data. If you can't cite, say "exploring unknown territory" explicitly.
- **Stale evidence**: market-context.json from 2 weeks ago is not evidence. Check dates. Run `scripts/evidence-scan.sh` for fresh data.
- **Citing your own prediction as evidence**: "I predicted X, therefore X" is circular. Predictions are hypotheses, not evidence. Evidence is what HAPPENED.

## Generation failures
- **Quadrant filling**: Innovation matrices tempt you to fill every cell. Some cells should be empty. 2 good ideas beats a full matrix of mediocre ones.
- **Feature-as-idea**: "Add a dashboard" is a solution, not an idea. Ideas are about problems: "Users can't see their progress over time." The solution might be a dashboard, or a weekly email, or a CLI sparkline.
- **Incremental only**: If every idea is "+5 to a sub-score," you're optimizing, not ideating. Include at least one idea that changes the shape of the product.
- **Ignoring the backlog**: 3+ todos on the same topic IS an idea. The backlog is telling you something. Don't duplicate it — promote it.

## Kill list failures
- **Kill list avoidance**: "I can't find anything to kill" means you're not looking hard enough. Run `scripts/kill-audit.sh` for candidates.
- **Killing the easy thing**: Killing a stale todo is free. Killing a feature you spent 3 sessions on is hard. The hard kills are the ones that matter.
- **Re-proposing killed ideas**: Check founder.yml for `status: killed` features before proposing. If an idea was killed, you need NEW evidence to revive it.

## Technique failures
- **One technique only**: If you always use evidence-weighted generation, you'll always get the same type of ideas. Rotate techniques from `techniques/` folder.
- **Technique as theater**: Running through SCAMPER mechanically produces mechanical ideas. The technique is a starting point, not a formula.
- **Divergent without convergent**: 30 raw ideas are useless without the killer pass. Always pair divergent generation with `techniques/killer.md`.

## Feature improvement failures
- **Prescribing without seeing**: If you haven't read the code AND the scores, you're guessing. "Add a video board" is meaningless if the feature doesn't have video data. Look first.
- **"Improve the UX"**: Too vague. Name the element ("the data table header"), the change ("add thumbnail previews in the first column"), and the impact ("hierarchy +10pts"). If you can't be this specific, you haven't looked closely enough.
- **All polish, no delivery**: If the feature doesn't work end-to-end (delivery < craft), fix the core loop before suggesting animations or visual improvements.
- **Ignoring existing prescriptions**: Check taste history and past improvements before generating new ones. Don't duplicate what's already been identified — build on it or escalate.
- **Copying competitors blindly**: "Linear does it" isn't a reason. "Linear does it because users need to see project status at a glance, and our users have the same need because [evidence]" is a reason.
- **Missing the simplification pass**: Feature improvement isn't just adding things. Every improvement session should remove or simplify at least one thing. Attention is finite, screen space is finite.
- **Abstract options instead of concrete ones**: "Option 1: simple approach. Option 2: complex approach." is lazy. "Option 1: static thumbnail grid with lazy load (2hrs, hierarchy +10pts). Option 2: hover-to-preview with video playback (1 session, hierarchy +15pts, distinctiveness +12pts)." is useful.

## Materialization failures
- **Idea without assertion**: If you can't write 2 mechanical assertions for an idea, it's not testable. Not testable = not buildable.
- **Committing without killing**: Every commit should pair with a kill. Attention is finite. You can't add without removing.
- **Skipping the prediction**: Every committed idea needs a logged prediction. "I predict this will raise [feature] from X to Y because Z." No prediction = no learning.
