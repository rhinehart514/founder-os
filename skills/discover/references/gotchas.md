# Discovery Gotchas

Check against each one before delivering output. These are LLM behavior patterns —
things the model tends to do wrong during discovery. `mind/patterns.md` covers what
founders tend to do wrong during validation. Both matter. Check both.

---

## 1. Presenting known things as insights

The most common failure. You generate "add a search bar," "let users filter by date,"
"send a notification" — things that every product in the space already has — and
present them as discovery output.

**Fix:** Search before generating. If the first 3 results for "[product type] features"
already list your idea, it's parity, not insight. Label it as parity or don't surface it.

---

## 2. Staying at the feature tier

The user asks about a product, you return features. But the most valuable discovery
often happens one level up (what outcome are we actually after?) or two levels down
(what micro-behaviors make this feel complete?).

**Fix:** Always name what tier each idea lives at (see `references/hierarchy.md`).
Surface at least one observation above and below the requested tier.

---

## 3. Confusing outputs with outcomes

"Build a dashboard" is an output. "Help the user make faster decisions about X" is
an outcome. Discovery that starts with outputs never challenges whether the output is
the right solution.

**Fix:** Before listing ideas, name the outcome (1 sentence). If you can't name it,
ask — or flag the ambiguity explicitly.

---

## 4. Treating AI as an add-on rather than a default question

Search autocomplete, tagging, categorization, summarization, draft generation — these
aren't features anymore, they're just inference calls. If you're suggesting one of these
as a product idea, you're already behind.

The real question is the UX wrapper: how does the AI output surface, when does it
trigger, who controls it, and what happens when it's wrong?

**Fix:** For any information-processing feature, ask: is this a UI problem or an
inference problem? If it's inference, skip to the UX design question.

---

## 5. Stale reference products

Citing the same 4-5 products as design benchmarks without checking if they're still
the right reference. Benchmarks shift.

**Fix:** For any "best-in-class" claim, run a search to verify it's still true.

---

## 6. Generating "different" ideas that aren't actually different

The third band (different mechanism) often produces ideas that are just the same
feature with a different UI metaphor. "What if instead of a list, it was a kanban?"
is not a different mechanism — it's a different view.

**Fix:** A truly different mechanism changes who does the work, when it happens,
or what the trigger is — not just how it's displayed.

---

## 7. Not naming assumptions

Every product idea embeds assumptions: about user behavior, technical feasibility,
market timing, distribution. Leaving them implicit means the founder can't evaluate
the idea properly.

**Fix:** For any idea, name the 1-2 assumptions it depends on. One sentence each.
Not a risk framework — just honest flagging.

---

## 8. Flat output with no opinion

A business case with 5 equally-weighted options puts the entire cognitive burden back
on the founder. It reads as thorough but isn't useful.

**Fix:** Always end with a concrete recommendation: what you'd actually push for,
what's a sleeper pick, what to skip. Be direct. If you're uncertain, say why.

---

## 9. Skipping the kill check

When the founder is excited, the system skips the quick kill questions and jumps
straight to research. This wastes agent tokens on ideas that should die in 30 seconds.

**Fix:** Always run the 5-question kill check before any research. Excitement is
not evidence.

---

## 10. Confusing portfolio stage with evidence quality

An idea in "researching" stage for 2 weeks may have less evidence than one marked
"raw" that the founder deeply understands. Stage is a lifecycle marker, not a quality
signal.

**Fix:** Assess evidence strength directly. Don't use stage as a proxy.

---

## 11. Citing your own prediction as evidence

"I predicted X, therefore X" is circular. Predictions are hypotheses, not evidence.
Evidence is what HAPPENED.

**Fix:** Only cite outcomes, market data, user signals, or confirmed patterns as
evidence. Predictions are bets, not facts.
