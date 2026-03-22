# Todo Sources

Todos enter the backlog from multiple skills and agents. Each source carries different priority implications.

## Skill sources

| Skill | When it writes todos | Priority signal |
|-------|---------------------|-----------------|
| `/todo add` | Founder captures directly | Explicit intent — high |
| `/plan` | Quick capture during planning | Session-relevant — medium |
| `/eval` | Regressions, new gaps discovered | Measurement-backed — high |
| `/go` | Plateau detection, kept-but-warned moves | Build loop exhaust — medium |
| `/retro` | Wrong predictions that need action | Learning loop — medium |
| `/ideate` | Committed ideas that need implementation | Strategic — varies |
| `/taste` | Visual quality issues found during eval | Craft signal — medium |

## Agent sources

Agents write todos via `todo:` prefixed lines in SendMessage. The lead agent (or `/go` loop) reads these and writes to `todos.yml`. Agents never write directly.

| Agent | Protocol | What it captures |
|-------|----------|-----------------|
| builder | `todo:done`, `todo:add` | Auto-closes matched active todos, captures new problems and regression guards |
| measurer | `todo:add` | Regressions, stuck features, uncovered gaps |
| reviewer | `todo:add`, `todo:graduate` | Unfixed warnings from kept moves, recurring patterns |
| evaluator | `todo:add`, `todo:graduate` | Uncovered gaps from deep eval, rubric-informed assertions |
| explorer | `todo:add`, `todo:kill` | Research findings → tasks, dead-end kills |

## Agent todo protocol

```
todo:add "[title]" feature:[name] source:[origin]
todo:done [id]
todo:kill [id]
todo:graduate "[pattern] → assertion" feature:[name]
```

## Priority boost rules

Some sources get automatic priority boost when displayed:

- `/go plateau` — the build loop hit a wall. High signal.
- `/eval measurer` regression — something got worse. Urgent.
- `/go reviewer` — known issues in kept code. Technical debt with a name.
- Recurring `todo:add` on same feature from different agents — convergent signal.

## Source field format

All todos include `source:` for traceability:

```yaml
source: /todo           # founder direct capture
source: /go builder     # builder agent during /go
source: /eval measurer  # measurer during /eval
source: /research explorer  # explorer during /research
source: /ideate         # committed idea materialization
```
