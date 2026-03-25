# Build Session Log Template

Use this structure when logging to `.claude/sessions/YYYY-MM-DD-HH.yml` and `build-log.sh add`.

## Session YAML (written to .claude/sessions/)

```yaml
date: YYYY-MM-DDTHH:MM:SSZ
scope: [feature name or "bottleneck"]
mode: beta|safe
moves: N
kept: N
reverted: N
speculated: N          # moves using speculative branching (beta only)
adversarial_overrides: N  # times reviewer overruled by measurement (beta only)
score_before: N
score_after: N
delta: +/-N
prediction_accuracy: "N/M correct (P%)"
predictions:
  - text: "[specific prediction with numbers]"
    correct: yes|no|partial
    model_update: "[what changed about the model — empty if prediction was right]"
features_changed:
  feature_name:
    before: N
    after: N
    delivery: [before, after]
    craft: [before, after]
    viability: [before, after]
learnings:
  - "[one line per insight gained]"
```

## Build-log JSON (for scripts/build-log.sh add)

```json
{"scope":"feature","mode":"safe","moves":3,"kept":2,"reverted":1,"score_before":58,"score_after":66,"prediction_accuracy":"2/3"}
```

Pipe to build-log.sh:
```bash
echo '{"scope":"scoring","mode":"safe","moves":3,"kept":2,"reverted":1,"score_before":58,"score_after":66,"prediction_accuracy":"2/3"}' | bash scripts/build-log.sh add
```
