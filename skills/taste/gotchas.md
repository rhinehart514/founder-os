# Taste Gotchas

Real failure modes from past sessions. Read before every `/taste` run.

## Screenshot captures a loading state, not the product

Playwright screenshots fire after `wait_for(time: 3)` but some SPAs take longer. If the screenshot shows a spinner, skeleton, or blank page — that's not the product. Re-navigate with a longer wait or check network requests for pending fetches. Do NOT score a loading state as the actual product.

## Scoring the framework, not the product

shadcn/Tailwind defaults describe half the internet. Penalize *undifferentiated* defaults, not defaults themselves. A card grid that serves the content well is fine. The slop rule asks: "could AI generate this by prompting 'build me a [category] page'?" — not "does it use rounded corners?"

**The 80+ bar is now enforced.** If the product uses only framework defaults with no custom layout, motion, or interaction craft — hard cap at 79 on layout_coherence, polish, and distinctiveness. This isn't about using fancy libraries for the sake of it. It's about whether the builder made intentional choices beyond what a framework provides. 80+ means craft that's visible, psychologically grounded, and technically sophisticated. Read the "The 80+ Bar" section in `references/dimensions.md` before scoring any dimension above 79.

## Static pages cap at 75 for polish and scroll

No motion library (Framer Motion, GSAP, react-spring, etc.) in the codebase → polish and scroll_experience cap at 75. A static page can be clean, well-organized, properly spaced. It cannot be exceptional. Exceptional means the interface responds, breathes, guides — and that requires motion. Check `package.json` or imports before scoring these dimensions above 75.

## Dimension subjectivity produces session variance

"Emotional tone" and "distinctiveness" vary 10-15 points across sessions. Without `founder-taste.md`, these dimensions are noise. When calibration exists, anchor to it. When it doesn't, weight these lower mentally and note "uncalibrated — variance expected" in the report.

## Generous scoring on first eval

First eval has no baseline to compare against. LLMs default to polite — "this is pretty good, 65/100." Actively look for the weakest dimension and score it honestly. If avg > 60 on an early-stage product, re-check each dimension against the anchors in `references/dimensions.md`.

## Slop check false positives on intentional template use

The slop check flags shadcn/Tailwind defaults, but some products intentionally use these as a foundation and add craft on top. The mechanical check (slop-check.sh) looks at package.json and source patterns — it can't see whether the defaults were used as a starting point that was then customized. If the mechanical verdict is "slop" but visual inspection shows genuine craft, override the mechanical verdict in the gestalt and note why. The override must be specific: "slop-check flagged shadcn defaults, but the custom color system and motion choreography demonstrate intentional choices."

## Uncalibrated eval variance

Without founder preferences and competitive context, subjective dimensions (emotional_tone, distinctiveness) show 15-20 point variance across sessions. When uncalibrated, note "No calibration: moderate confidence" in the report and weight subjective dimensions lower mentally. Don't gate the eval — just be honest about confidence.

## Mobile scoring is texture, not detail

At 390px, small details disappear. Scoring becomes texture-based. Don't penalize mobile views for lacking detail that physically can't fit. Score for appropriate density and touch target sizing at that viewport. A mobile view that reorganizes content well can score higher than desktop on information_density.

## Market calibration is aspirational without a corpus

"Market-calibrated" requires a scored corpus of products in the same category. Without `taste-market.json`, scores are anchored to generic best-in-class (Linear, Stripe, Notion). Be honest: note "uncalibrated against market" in the report. Don't pretend generic anchors are specific.

## Gate rule punishes intentional unconventionality

layout_coherence < 30 caps overall at 30. But some products — editorial, art, experimental — break grids intentionally. If the product is deliberately unconventional and the "incoherence" is a design choice, note the cap as potentially inappropriate. Still enforce it — but flag the tension.

## Anti-inflation over-correction flattens real strengths

Flagging avg > 70 at early stage is correct, but don't force genuinely strong dimensions down. If hierarchy is legitimately 82 because of excellent typography choices, that's real — don't cap it because the product is "early." Flag the tension between stage and score, don't resolve it by lying.

## Prescriptions that say "add more whitespace" every time

Generic prescriptions are useless. "Add more whitespace" is always technically correct and never actionable. Prescriptions must reference a specific DOM element, a specific CSS property, and a specific target value. "`.hero-section` padding: 24px → 48px" is a prescription. "Improve spacing" is not.

## Code reading misses dynamic content

System dimensions (wayfinding, information_architecture) rely on code reading, but code shows potential routes — not what users actually encounter. A route that exists in the router but has no nav link scores differently than one with prominent navigation. Score what the user sees, not what the code can do.

## Comparing across different URLs without noting the context

When past evals exist for a different URL, deltas are misleading. "Overall went from 55 to 42" sounds like regression, but if the first was a marketing site and the second is an app dashboard, they're different products. Always check URL matches before computing deltas.

---

## Flows mode gotchas

### Auth-gated pages kill the flow audit

If the product requires login, Playwright can't test the authenticated experience without credentials. Options: test only the public-facing pages (landing, signup, docs), or ask the founder for a test URL/token. Don't score "empty page after redirect" as a real finding — it's an auth boundary, not a bug.

### Mechanical checks produce false positives on SPAs

Single-page apps may show zero interactive elements in the initial DOM snapshot because content renders client-side. If `browser_evaluate` returns suspiciously few elements, wait longer (`browser_wait_for` with a content selector) and re-run the checks. Don't report "no interactive elements" on a React app that hasn't hydrated.

### Core flow testing assumes you know the core flow

If product-spec.yml doesn't exist and the page doesn't have an obvious CTA, the flow audit will guess wrong about what to test. When unsure, test the most prominent action on the page. If there's truly no clear action — that's a finding (Layer 2 failure: no primary CTA).

### Empty state testing requires knowing the empty URL

"Navigate with no data" requires knowing which URL to hit. For authenticated apps, this might be impossible without a fresh account. For public apps, try the main content page without any query params. If you can't test empty state, note it as "untested" rather than guessing.

### Mobile responsive checks miss CSS media query bugs

`browser_resize` triggers viewport changes but some CSS issues only appear on actual mobile devices (touch events, iOS Safari quirks, etc.). Report responsive findings as "viewport-based" not "mobile-verified." The definitive mobile test requires a real device.

### Don't mix flows and visual findings

Flows mode reports functionality issues. If you notice a visual problem during flow testing, note it for the visual eval but don't include it in the flows report. Mixing "button doesn't work" with "button has wrong border-radius" dilutes the severity signal.
