# /money Output Templates

## Full model

```
◆ money — full model

  stage: [stage] · [N] features at 50+
  user: "[from founder.yml]"

⎯⎯ pricing ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  recommend: [model] at $[price]/[period] per [metric]
  competitors: $[low]-$[high]/[period]
  value anchor: "[what the user pays for alternatives]"

  options:
    A. [model] at $[price] — [tradeoff]
    B. [model] at $[price] — [tradeoff]
    C. [model] at $[price] — [tradeoff]

⎯⎯ unit economics ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  revenue/user: $[N]/mo
  est. CAC:     $[range] ([channel])
  est. LTV:     $[range] ([retention] × [revenue])
  payback:      [N] months
  confidence:   [low|medium|high]

⎯⎯ channels ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  1. [channel] — score [N] — [evidence]
     experiment: [specific first action]
  2. [channel] — score [N] — [evidence]
     experiment: [specific first action]
  3. [channel] — score [N] — [evidence]

⎯⎯ runway ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  monthly burn: ~$[N]
  breakeven:    [N] users at $[price]

  conservative: breakeven in [N] months
  expected:     breakeven in [N] months
  optimistic:   breakeven in [N] months

⎯⎯ verdict ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  "[one paragraph honest assessment]"

/money price          dig deeper on pricing
/money channels       channel experiments
/strategy honest      reality check
```

## Price mode

```
◆ money — pricing

  current: [model at price, or "none"]
  competitors: [N] analyzed

  landscape:
    [competitor] — $[price]/[period] — [model] — [evidence source]
    [competitor] — $[price]/[period] — [model] — [evidence source]

  recommend: [model] at $[price]/[period] per [metric]
  why: [one sentence grounded in evidence]
  risk: [what could make this wrong]
```

## Runway mode

```
◆ money — runway

  monthly burn: ~$[N] ([breakdown])
  revenue:      $[N]/mo ([N] users × $[price])

            conservative   expected    optimistic
  month 3:  $[N]          $[N]        $[N]
  month 6:  $[N]          $[N]        $[N]
  month 12: $[N]          $[N]        $[N]

  breakeven: [N] users · [N] months (expected)

  decision points:
    · [N] months: if <[N] users, [what to do]
    · [N] months: if <[N] revenue, [what to do]
```
