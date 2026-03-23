# Product Hierarchy

A decomposition model for navigating between levels of abstraction during discovery.
Use this to anchor every business case to an outcome and opportunity before discussing
features.

**In /discover:** Every business case must name its outcome and opportunity (top 2 tiers)
before the portfolio.yml spec is generated. The wedge should be labeled by its tier.

---

## The stack

```
OUTCOME          What metric or behavior moves if this works?
                 (user retention, activation rate, time-to-value, revenue)

OPPORTUNITY      What pain, unmet need, or desire makes this worth addressing?
                 Distinct from the solution. Stable over time even as solutions change.

SYSTEM           A coherent product domain with its own data model and ownership.
                 You can't prioritize systems against each other — they all need to exist.
                 Examples: auth, payments, notifications, search, permissions

FEATURE          A discrete, shippable unit. Has a clear user goal it serves.
                 Can be scoped, estimated, shipped independently.
                 Examples: saved searches, digest email, bulk export, role management

MICRO-FEATURE    The behaviors that make a feature feel complete rather than 80% done.
                 Most teams never explicitly plan these. They show up as "polish" work.
                 Examples: empty states, undo/redo, inline validation, smart defaults,
                 keyboard shortcuts, optimistic UI, bulk actions, progressive disclosure

INTERACTION      Atomic UI moments. Invisible until absent.
                 Examples: button press feedback, skeleton loaders, error copy,
                 hover states, transition timing, haptic response
```

---

## How to use this during discovery

**Anchor check:** Before generating ideas, name the outcome and opportunity in 1-2
sentences. If you can't, flag the ambiguity. Everything below is a hypothesis about
how to address the opportunity.

**Level labeling:** Tag each idea you generate with its tier. Don't mix levels in
the same list without labeling — a "notification badge" (interaction) and a
"notification system" (system) are not comparable ideas.

**The micro-feature gap:** For the most important feature in any session, explicitly
ask what micro-features it needs to feel complete. This is where most product
quality debt accumulates — not in missing features, but in features that shipped
without their supporting behaviors.

**Temporal decay:** What was a surprising capability 2 years ago is probably
table stakes now. Check the current tier of any idea before presenting it as
a differentiator.

---

## The AI question (ask this at every tier)

For any information-processing feature, ask: is this a UI problem or an inference problem?
A lot of "features" are now just prompts with a surface. Before scoping, name which it is.

- At the system level: is this rule-based or should it be model-driven?
- At the feature level: does building this still require shipping code, or is it a
  well-prompted LLM call with the right context?
- At the micro-feature level: what behaviors can now be generated from context rather
  than hardcoded? (smart defaults, inline suggestions, predictive states)

This isn't a special consideration — it's the default question now.
