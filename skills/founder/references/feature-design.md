# Feature Design

How to define a good feature in founder-os. A feature is a named part of your product that delivers value to a specific person.

## The four required fields

Every feature in `config/founder.yml` needs these:

### delivers: (what the user gets)
One sentence. Specific. Testable.

Bad: "handles authentication"
Good: "users can sign up, log in, and reset their password"

Bad: "dashboard"
Good: "founder sees product health at a glance — score, assertion pass rate, bottleneck"

The `delivers:` field is what `/eval` judges against. Vague delivery = vague eval = useless score.

### for: (who specifically)
A named human situation. Not "users." Not "developers." Not "teams."

Bad: "users"
Good: "solo founder who just made changes and wants to know if the product improved"

Bad: "developers"
Good: "new contributor running the project for the first time"

The `for:` field determines viability scoring. Generic audience = no viability signal.

### code: (where it lives)
Array of file paths or directories. This is how `/eval` knows what code to judge, and how `/feature detect` avoids duplicates.

```yaml
code: ["bin/score.sh", "bin/eval.sh", "bin/lib/config.sh"]
code: ["src/auth/"]
```

### weight: (1-5 importance)
How important this feature is to the value hypothesis in founder.yml. Drives bottleneck detection — the lowest-scoring highest-weight feature is the bottleneck.

## Optional fields

```yaml
depends_on: [other_feature]  # what must work first
status: active               # active | proven | killed | archived
commands: ["/eval", "founder eval ."]  # CLI or slash commands
killed_reason: "why"         # required when status: killed
killed_date: 2026-03-16      # required when status: killed
```

## Common mistakes

### Solution-as-feature
"Dashboard" is not a feature. "Founder sees product health at a glance" is. Features describe value, not implementation. The implementation might change; the value shouldn't.

### Feature sprawl
More than 5 active features at once = attention fragmentation. The bottleneck detection in `/plan` only works when you have focus. If you have 8 features, 6 of them should be killed, deferred, or merged.

### Missing dependencies
If feature B can't work without feature A, declare `depends_on: [A]`. Otherwise /go might try to build B when A is broken, wasting cycles. `scripts/dependency-graph.sh` catches this.

### Weight-1 features that should be killed
A feature with weight 1 is saying "this doesn't matter much." If it doesn't matter much, why track it? Either it matters (raise the weight) or it doesn't (kill it). Weight 1 is the graveyard of features nobody wants to kill.

### Overlapping code paths
Two features pointing at the same code files create eval confusion. If `scoring` and `learning` both claim `bin/eval.sh`, which feature gets credit? Keep code paths distinct. Shared utilities belong to whichever feature they primarily serve.

## Template

See `templates/feature-template.yml` for a copy-paste template.
