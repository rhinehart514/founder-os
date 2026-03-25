# Release Announcement Template

Different from release notes. An announcement is for people who don't use the product yet. Release notes are for current users.

## Structure

```
[HEADLINE — what's new in 7 words or fewer]

[One paragraph: who this is for and what changed for them. Not what code shipped — what's different in their world now.]

What's new:
- [Change 1 — user-facing, specific, measurable if possible]
- [Change 2 — same rules]
- [Change 3 — same rules]

[If applicable: One sentence on what's coming next. Not a promise — a direction.]

[CTA — one action. "Try it" or "See the changelog" or a link. Not multiple options.]
```

## Rules

- **One theme.** Even if the release has 10 changes, the announcement has one story. Find the narrative that ties changes together.
- **User-facing only.** "Refactored the state management layer" is not an announcement. "Dashboard loads 3x faster" is.
- **No version numbers in the headline.** Nobody cares that it's v2.3.1. They care what changed.
- **No slop.** Same banned word list applies. No "excited to announce" (nobody cares about your excitement). No "we've been working hard" (every company works hard).
- **Evidence over claims.** "Scores are 3x faster" beats "significantly improved performance."
- **Honest limitations.** If something isn't done, it's better to say "not yet" than to omit it and have users discover the gap.

## Anti-patterns

- "We're excited to announce..." — start with what changed, not how you feel
- Listing every PR merged — this is a changelog, not an announcement
- "Bug fixes and improvements" — name the bugs, name the improvements
- Announcing features that don't work yet — only announce what scores 50+
- Multiple CTAs — one announcement, one action
- Screenshot of code — users don't care about code. Show the result.

## Tone

Match the product's voice (see `references/voice-guide.md`). If no voice guide exists, default to: direct, specific, short sentences, no hype.
