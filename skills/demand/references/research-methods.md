# Research Methods — When to Use What

## Tool selection by question type

### context7 (resolve-library-id -> query-docs)
**Use when:** You have a specific library/framework question — API signatures, configuration options, migration guides, version-specific behavior.
**Signal:** T1-T2 quality. Real-time docs from maintainers.
**Noise risk:** Low. May be incomplete for obscure libraries.
**Cost:** Low (text only).
**Example:** "How does Claude Code's Agent tool work?" -> context7 anthropic/claude-code

### Codebase (Grep/Glob/Read)
**Use when:** You need to understand how something works HERE, not in theory. Implementation details, patterns in use, dependency chains.
**Signal:** T1 quality. The code is the truth.
**Noise risk:** Zero — but can mislead if you read code without understanding intent.
**Cost:** Free.
**Example:** "How does /eval calculate scores?" -> Grep for eval logic in bin/eval.sh

### WebSearch + WebFetch
**Use when:** You need external knowledge — best practices, community consensus, competitor analysis, market data. NOT for library docs (use context7).
**Signal:** T3-T5. Varies wildly. Cross-reference everything.
**Noise risk:** High. SEO content farms, outdated posts, LLM-generated slop.
**Cost:** Medium.
**Filtering rules:**
- Skip results without dates or author attribution
- Prefer recent (< 1 year) over old
- Prefer posts with code examples over advice-only
- Prefer specific over generic ("how Stripe handles X" > "best practices for X")

### Playwright (browser_navigate, browser_snapshot, browser_evaluate)
**Use when:** You need to see/interact with a live product. Visual analysis, UX patterns, structural inspection (DOM, network requests).
**Signal:** T1 for your own product, T2 for competitors (you see what they shipped).
**Noise risk:** Low — you see reality, not claims.
**Cost:** High (browser automation, screenshots).
**Example:** "How does competitor X onboard users?" -> navigate, snapshot each step

### experiment-learnings.md
**Use when:** Before ANY research. Check what you already know. Avoid re-researching known patterns.
**Signal:** Your own confirmed/uncertain patterns.
**Noise risk:** Staleness — patterns may have changed since they were recorded.
**Cost:** Free.

## Decision flowchart

```
Question about a library/API?
  YES -> context7 first, WebSearch if context7 incomplete
  NO  ->

Question about THIS codebase?
  YES -> Grep/Glob/Read first, context7 for libraries it uses
  NO  ->

Question about a live product/site?
  YES -> Playwright first, WebSearch for context
  NO  ->

Question about market/competitors/patterns?
  YES -> WebSearch + WebFetch, Playwright for competitor sites
  NO  ->

Something else?
  -> Check experiment-learnings.md, then WebSearch
```

## Signal vs noise rules

1. **One good source beats five mediocre ones.** Stop searching when you find a T1-T2 source that answers the question.
2. **Cross-reference T3+ findings.** If a blog post claims X, verify against docs or source code before treating it as fact.
3. **Date everything.** Undated findings are unreliable. A 2024 blog post about a 2026 framework is wrong.
4. **Specificity > breadth.** "React 19 Server Components require X" > "Server-side rendering best practices."
5. **After 5 sources with no finding, stop.** Reformulate the question. More sources won't fix a vague question.
