# Maturity Ladder — What to Work On at Each Level

## The principle

As quality increases, the unit of work shrinks. Early: build whole features. Middle: shape the product. Late: tune micro-interactions.

Working at the wrong level wastes effort. Polishing micro-UX on a broken feature is cosmetic. Building new features on a polished product is sprawl.

## For code (eval-driven)

### 0-30: Features don't exist
- **Build**: entire features from scratch
- **System design**: core data flow, primary loop
- **Error handling**: none needed yet — get the happy path working
- **Tests**: 1-2 smoke assertions per feature

### 30-50: Features exist but don't connect
- **Wire**: feature A feeds feature B, state passes correctly
- **Error handling**: catch the crashes — try/catch, exit codes, null checks
- **Consistency**: same patterns across features (naming, structure)
- **Tests**: assertions on the connections, not just existence

### 50-65: It works but confuses
- **Information architecture**: restructure for user mental model
- **Output design**: what does the user see? Is it scannable in 2 seconds?
- **Dead ends**: every action leads somewhere
- **Documentation**: explain what this IS before what it does
- **Tests**: assertions on user-facing output, not just internal state

### 65-80: It works and makes sense. Make it good.
- **Progressive disclosure**: show less, reveal on demand
- **Contextual help**: inline explanations, smart defaults
- **Cross-feature consistency**: same voice, same format, same information hierarchy
- **Edge cases**: what happens with empty input? Missing config? Stale data?
- **Tests**: edge case assertions, error path assertions

### 80-90: It's good. Make it excellent.
- **Performance**: what's slow? Cache it. What's redundant? Eliminate it.
- **Graceful degradation**: missing dependencies → helpful message, not crash
- **Accessibility**: keyboard navigation, screen reader, color-blind safe
- **Feedback loops**: every action confirms what happened
- **Tests**: performance benchmarks, degradation assertions

### 90+: It's excellent. Prove it.
- **External validation**: do real humans use this and come back?
- **Instrumentation**: measure what matters to users, not what's easy to measure
- **Documentation for strangers**: can someone who didn't build this understand it?
- **Delight**: the small things that make someone smile

## For visual/UX (taste-driven)

### Layout (30-50)
- Does information hierarchy exist?
- Is the most important thing visually prominent?
- Can you find the primary action?

### Spacing + typography (50-65)
- Is content scannable in 2 seconds?
- Are headings distinguishable from body?
- Is density appropriate for the content type?
- Is there breathing room or is everything cramped?

### Color + contrast (65-80)
- Does color carry semantic meaning (good/warning/error)?
- Is there sufficient contrast for readability?
- Is the palette intentional or accidental?
- Are status indicators consistently colored across features?

### Interaction feedback (80-90)
- Does every click/action produce visible feedback?
- Are loading states present for async operations?
- Do errors explain what happened AND what to do?
- Are transitions purposeful (guide attention) or decorative?

### Delight + brand (90+)
- Does the product have a distinctive feel?
- Would a user recognize this product from its output alone?
- Are there moments that exceed expectations?
- Is the voice consistent across every touchpoint?
