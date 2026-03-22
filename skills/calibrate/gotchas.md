# Calibrate Gotchas

Real failure modes. Read before running calibration.

## Founder gives vibes instead of specifics

"I like clean design" is not calibration data. It's noise. If the founder can't name a specific product and a specific element they admire, the interview hasn't worked yet. Push harder — show them screenshots of 3 products and ask which they prefer and why. Specifics or nothing.

## Design system extracted from defaults

If the codebase uses shadcn/Tailwind with zero customization, the "design system" is just framework defaults. That's still useful information — it means the product has no design system, and taste should penalize accordingly. Don't pretend defaults are intentional choices.

## Anti-slop profile is too broad

"Gradient heroes are slop" is true for most products but wrong for a creative tool or a gaming site. The anti-slop profile must be category-specific. A productivity SaaS and a social platform have completely different slop signals. Always check the product category before writing rules.

## Market research finds 2024 articles

Search results for "design trends" return content from 1-2 years ago. Add the current year to every search query. Verify article dates before citing them. A trend article from 2024 is historical context, not current intelligence.

## Playwright can't reach competitor sites

Some sites block headless browsers, require auth, or have aggressive bot detection. If Playwright can't screenshot a competitor, fall back to WebSearch for their design analysis. Don't skip the competitor entirely — note it as "screenshot failed, analyzed from web results."

## Calibration inflates scores

If founder preferences are "I love lots of whitespace" and the product has lots of whitespace, calibration makes breathing_room score higher. But the product might still have bad whitespace — too much in the wrong places. Calibration weights dimensions, it doesn't override evidence. A high-weight dimension with bad execution should still score low.

## Stale calibration is worse than no calibration

A 60-day-old anti-slop profile references patterns that are no longer generic (or misses new ones that are). A 90-day-old market snapshot describes a competitive landscape that's shifted. Stale calibration creates false confidence. The freshness-check.sh script exists for this reason — respect its warnings.

## Over-calibrating after every eval

Calibration is meant to be stable for weeks. If someone runs `/calibrate` after every `/taste` eval, they're trying to game the score. Calibration should change when: the founder's taste changes, the market shifts, or the product pivots. Not because the score was "wrong."
