# Evidence Hierarchy — Ranking What You Know

Evidence is not equal. When findings conflict, higher-tier evidence wins.

## The hierarchy (strongest to weakest)

### Tier 1: Observed user behavior
What users DO, not what they say. Analytics, session recordings, A/B test results, retention data, churn patterns.
- "40% of users drop off at step 3" > any opinion about step 3
- Requires: instrumentation, real users
- Limitation: tells you WHAT happened, not WHY

### Tier 2: Direct user statements
What users SAY about their experience. Interviews, support tickets, feedback forms, NPS verbatims.
- "I couldn't find the settings" is evidence. "Users might have trouble finding settings" is speculation.
- Requires: actual conversations with real users
- Limitation: users rationalize, misremember, and are polite. Triangulate with Tier 1.

### Tier 3: Market evidence
What the market demonstrates. Competitor behavior, funding rounds, pricing changes, feature adoption patterns, job postings.
- "3 competitors added this feature in 6 months" = market signal
- Requires: systematic observation, not one-off Googling
- Limitation: competitors may be wrong too. Copying is not strategy.

### Tier 4: Expert opinion / desk research
What knowledgeable people think. Blog posts, conference talks, framework docs, community consensus.
- "The React team recommends X" is useful context, not proof that X works for YOUR users
- Requires: source quality assessment (see source-quality.sh tiers)
- Limitation: experts disagree. Consensus shifts. Context matters.

### Tier 5: Codebase signals
What the code reveals. Test coverage, error rates, complexity metrics, dependency analysis.
- "This function has 0 error handling" is a finding. "This will break" is a prediction.
- Requires: reading the code, not just measuring it
- Limitation: code quality != user value. Clean code can deliver nothing.

### Tier 6: Intuition / pattern matching
What feels right based on experience. "This feels like the auth problem we had last month."
- Valid as a STARTING POINT for research. Invalid as a CONCLUSION.
- Must be converted to a testable prediction immediately.
- Limitation: LLMs have strong priors that feel like intuition but are training data averages.

## Application rules

1. **Never cite Tier 6 as justification for a build decision.** Convert to prediction, test, then cite the test result.
2. **When Tier 1 and Tier 4 conflict, Tier 1 wins.** Users doing X matters more than experts saying Y.
3. **When you only have Tier 4-6, flag findings as low-confidence.** The research needs more evidence before it drives action.
4. **Tier 3 evidence has a half-life of ~3 months.** Market data decays fast. Date everything, refresh regularly.
5. **Mixed-tier findings are stronger than single-tier.** "Users said X (T2) AND the code shows Y (T5) AND competitors do Z (T3)" is much stronger than any one alone.
