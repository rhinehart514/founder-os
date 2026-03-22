# Product Lens

Extends founder-os with product-development-specific tools:

- **taste.mjs** — Visual eval via Claude Vision (11 dimensions)
- **DOM/copy/blind evals** — Mechanical UX assertions (contrast, click targets, copy clarity, blind task completion)
- **beliefs.yml** — Product-specific assertions (dom_check, copy_check, positioning_check, playwright_task)
- **UX checklist** — 10-point craft layer checklist loaded as a mind file
- **Score extensions** — Dead end detection, empty state auditing, `:any` type counting, lint override penalties
- **Corpus** — Taste reference database for calibrating visual eval

## What it adds to scoring

`score.sh` sources `scoring/score-product.sh` automatically when present. This adds:
- Web dead ends (pages with no outbound links)
- Empty states without CTAs
- IA audit (orphan routes, dead ends)
- `:any` types, console.log in production TSX, unused imports, lint overrides

## Commands

`/ship` — available via `skills/ship/SKILL.md`. Product-specific eval types (dom_check, copy_check, playwright_task) are available through `beliefs.yml`.

## Disabling

To run founder-os without the product lens:
```bash
mv lens/product lens/_disabled
```
Score and eval will still run — just without web-specific checks.
