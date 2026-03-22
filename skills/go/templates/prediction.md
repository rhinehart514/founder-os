# Prediction Template

Every move in the /go loop requires a prediction. No exceptions.

## Format

```
I predict: [specific outcome with numbers]
Because: [cite experiment-learnings.md entry, or declare "Exploring — no prior data"]
I'd be wrong if: [the one thing that would disprove this]
```

## TSV format (for predictions.tsv)

```
date	prediction	evidence	result	correct	model_update
2026-03-17	scoring craft_score +15 (50→65) from error boundary hardening	Known Pattern: error handling is mechanical, high keep rate	craft +8, subprocess paths still open	partial	file I/O and subprocess error handling are different patterns
```

Tab-separated. Fields:
1. `date` — YYYY-MM-DD
2. `prediction` — specific, with numbers. "Improve error handling" is ungradable. "Raise craft_score from 50 to 65" is gradable.
3. `evidence` — cite a Known/Uncertain/Unknown pattern, or "Exploring"
4. `result` — what actually happened (filled by grader after build)
5. `correct` — yes/no/partial (filled by grader)
6. `model_update` — what changed about the mental model (filled by grader, required when wrong)

## Quality checks

- If prediction has no number -> ungradable. Add a number.
- If evidence says "I think" -> that's guessing. Cite or declare exploring.
- If "I'd be wrong if" is missing -> you haven't thought about failure modes.
- If the prediction is trivially true ("the file will be created") -> too safe. Predict the EFFECT.
