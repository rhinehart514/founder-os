# Failure Patterns

Mechanically checkable from portfolio AND project state. Loaded every session.
When you see one, name it immediately — don't wait for the founder to ask.

## Validation Patterns (Portfolio State)

### 1. Building for Nobody
**Signal:** Idea has no named person (not segment — PERSON) as the customer.
**Check:** `portfolio.yml` → idea.customer is empty, generic ("SMBs"), or a segment without a name. Also: `config/founder.yml` → `value.user` field.
**Say:** "Who specifically wants this? Not 'restaurants' — a person. What's their name, role, and why do they care?"

### 2. Solution Before Problem
**Signal:** Idea starts with technology or feature, not a pain point.
**Check:** Idea description leads with "an app that..." or "AI-powered..." instead of "people who struggle with..."
**Say:** "You described what you'd build, not who's in pain. What's the problem that exists WITHOUT your product?"

### 3. Wedge Confusion
**Signal:** The initial product tries to do too much. No clear smallest-valuable-thing.
**Check:** Idea has >3 core features or the MVP description is >2 sentences.
**Say:** "What's the ONE thing that gets you in the door? Everything else is v2."

### 4. Why-Now Vacuum
**Signal:** Idea could have been built 5 years ago. No timing catalyst.
**Check:** `why_now` field is empty or generic ("AI is getting better").
**Say:** "Why didn't someone build this in 2021? What changed? If nothing changed, you're competing with incumbents who had a head start."

### 5. Revenue Avoidance
**Signal:** Idea has features but no pricing model. Founder deflects pricing questions.
**Check (validation):** Idea has >2 validated hypotheses but pricing section is empty.
**Check (build):** `founder.yml` → no `pricing` section AND `eval-cache.json` → 3+ features scoring 50+.
**Say:** "You've validated demand but haven't named a price. That's avoidance. What would you charge, and would they pay it?"

### 6. Research Addiction
**Signal:** Idea has been in "researching" stage for >2 weeks with no go/kill decision.
**Check:** Idea stage is "researching" and `last_updated` is >14 days ago.
**Say:** "You have enough to decide. More research is procrastination. Go or kill?"

### 7. Portfolio Sprawl
**Signal:** >3 ideas in active validation simultaneously.
**Check:** Count of ideas with stage not in [killed, parked, shipped].
**Say:** "You're spreading attention across N ideas. A serial entrepreneur runs them SERIALLY. Pick one, kill or commit, then move to the next."

### 8. Pattern Blindness
**Signal:** Current idea resembles a past dead end but founder hasn't acknowledged it.
**Check:** Similarity between current idea and entries in Dead Ends section of experiment-learnings.md.
**Say:** "This looks like [past dead end]. That failed because [mechanism]. What's different this time?"

### 9. Confirmation Bias
**Signal:** All research findings support the idea. No disconfirming evidence sought.
**Check:** All hypotheses for an idea are status: "confirmed" with no "disproved" or "uncertain."
**Say:** "Every signal says yes? That means you haven't looked for the no. What would kill this idea?"

### 10. Audience of One
**Signal:** The founder is the only person who wants this.
**Check:** Customer evidence comes only from founder's own experience, no external validation.
**Say:** "You want this. Do 5 other people? Have you talked to them?"

## Build Patterns (Project State)

### 11. Polishing Before Delivering
**Signal:** Craft score exceeds delivery score significantly.
**Check:** `eval-cache.json` → any feature where `craft_score > delivery_score + 15`.
**Say:** "Feature [name] has craft [C] but delivery [D]. You're polishing something that doesn't work yet. Ship the value, then polish."

### 12. Feature Sprawl
**Signal:** Too many features half-built simultaneously.
**Check:** `eval-cache.json` → count features where score is 30-60. If >3, triggered.
**Say:** "You have [N] features half-built. Pick one. Finish it. Kill or defer the rest."

### 13. Prediction Starvation
**Signal:** The learning loop is starving.
**Check:** `predictions.tsv` → count predictions in last 7 days. If <3, triggered.
**Say:** "Only [N] predictions in 7 days. The learning loop is starving. Every move needs a prediction."

### 14. Strategy Avoidance
**Signal:** Building without strategic context.
**Check:** `strategy.yml` → missing OR `last_updated` field >14 days old.
**Say:** "No strategy in [N] days. You're building without knowing if it matters. Run `/strategy honest`."

## Stage-Appropriate Expectations

| Stage | Duration | Key Question | Output |
|-------|----------|-------------|--------|
| Raw idea | Hours | Is this worth 2 hours of research? | Quick kill or research plan |
| Researching | 1-2 weeks | Is there a market? | Evidence for/against, customer profile |
| Validating | 2-4 weeks | Will they pay? | Pricing data, LOIs, waitlist |
| Committing | Days | Go or kill? | Decision with explicit confidence |
| Building (stage one) | Weeks | First value loop | Score 30-60, delivery over craft |
| Building (stage some) | Weeks-months | Do they come back? | Score 50-75, retention focus |
| Building (stage many) | Months | Distribution | Score 65-85, growth features |
| Killed | — | What did we learn? | Model update, pattern logged |

## Anti-Pattern Rationalizations

| What They Say | What's Actually Happening |
|---------------|--------------------------|
| "I need more data" | Research addiction (pattern 6) |
| "It's for everyone" | Building for nobody (pattern 1) |
| "We'll figure out pricing later" | Revenue avoidance (pattern 5) |
| "This is different from last time" | Maybe. Check pattern blindness (pattern 8) |
| "I just need to build it and they'll see" | Solution before problem (pattern 2) |
| "The market is huge" | Wedge confusion (pattern 3) |
| "I'm exploring multiple options" | Portfolio sprawl (pattern 7) at >3 |
| "I need variety to stay motivated" | Avoiding the hard part of a feature |
| "First impressions matter" | Polishing before delivering (pattern 11) |
| "Predictions slow me down" | Prediction starvation (pattern 13) |
| "Tech debt will slow us down" | Zero users → debt to whom? |
