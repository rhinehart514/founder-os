# Flows Protocol — Frontend Delivery Audit

Read this when running `/taste <url> flows`. This is the detailed protocol.

## Philosophy

Flows mode is a **Product Verification** skill. It tests whether the frontend works, not whether it looks good. The output is an issue list grouped by severity, not scores.

The JS check scripts in `scripts/checks/` are composable tools. Read each file, pass its contents to `browser_evaluate`, collect the structured result. Adapt as needed — these are starting points, not rigid templates.

## Step 1: Discover what to test

Read in parallel (skip missing silently):
- `config/product-spec.yml` — core loop, first experience
- `config/founder.yml` features — what claims does the product make?
- Navigate to URL + `browser_snapshot` — what actions exist on the page?

Identify:
1. **Core flow** — the primary task (e.g., "sign up and create a project")
2. **1-2 secondary flows** — other important paths
3. **Edge case URLs** — empty state page, deep link to inner page

If no product-spec exists, derive the core flow from the page: what's the primary CTA? Where does it lead?

## Step 2: Mechanical audit

Run the JS checks from `scripts/checks/`. For each check file:
1. Read the file contents
2. Pass to `browser_evaluate`
3. Collect the structured result

**Checks to run:**
- `checks/click-targets.js` — interactive elements < 44px
- `checks/form-labels.js` — inputs without labels
- `checks/heading-hierarchy.js` — h1 > h2 > h3 size order
- `checks/aria-landmarks.js` — main, nav, header, footer present
- `checks/images-alt.js` — images without alt text

**Also check via MCP tools:**
- `browser_console_messages` — JS errors and warnings
- `browser_network_requests` — failed API calls (4xx/5xx)

Collect all mechanical results before proceeding. These are the ungameable foundation.

**Optional fast path:** If `node` and `playwright` are available, run `node lens/product/eval/dom-eval.mjs --url <url> --json` for a more comprehensive mechanical audit (includes axe-core WCAG contrast checking). Merge results with the MCP-based checks.

## Step 3: First contact

As a first-time visitor with zero context:
1. `browser_snapshot` + `browser_take_screenshot`
2. Evaluate: value prop visible? Primary CTA obvious? Nav present? Placeholder content?

This is judgment, not mechanical. Use the snapshot and screenshot to answer: would a stranger understand what this is in 5 seconds?

## Step 4: Core flow

Walk the core flow from Step 1. For each step:
1. Identify the next action from `browser_snapshot`
2. Perform it: `browser_click`, `browser_fill_form`, `browser_press_key`
3. `browser_wait_for` — wait for response
4. `browser_snapshot` — did the UI respond? Is there feedback?

**Check at each step:**
- Did something visible change?
- Is there a loading/success/error indicator?
- Do I know where I am and what happened?
- Can I go back? (`browser_navigate_back`)

**Form testing (if forms exist):**
- Submit empty → check for validation messages
- Submit valid → check for success feedback

**After completing:** Is there a next step, or a dead end?

## Step 5: Edge cases

1. **Empty state**: Navigate to a data page with no data. Run `checks/empty-state.js`.
2. **Dead ends**: After completing the core flow, is there a next action?
3. **Deep link**: Navigate directly to an inner page URL. Does it work without context?

## Step 6: Responsive

1. `browser_resize` to 390x844
2. `browser_take_screenshot`
3. Run `checks/responsive-scroll.js` — horizontal overflow?
4. Run `checks/click-targets.js` again — targets still adequate at mobile?
5. `browser_snapshot` — is nav accessible (visible or hamburger)?

## Step 7: Report

Run `scripts/flows-summary.sh` to check past results for trends.

Group findings by severity:
- **blocker**: Can't complete core task
- **major**: Experience is broken (no empty state, dead ends, broken mobile)
- **minor**: Noticeable but workable (small targets, missing labels, heading hierarchy)
- **polish**: Professional gap (missing loading states, focus rings)

Write structured report to `.claude/evals/reports/flows-{YYYY-MM-DD}.json`.
Use the flows template from `templates/taste-report.md`.

**Cap at 10 issues.** Prioritize ruthlessly — the top 3 fixes matter more than a complete inventory.

## What to adapt

This protocol is a starting point. Adapt based on what you find:
- **Auth-gated?** Test public pages only, note auth boundary.
- **SPA slow to hydrate?** Wait longer before running checks.
- **No obvious CTA?** That's a finding (Layer 2 failure).
- **Single-page app?** Deep link testing may not apply.

The checks/ JS files are also starting points. If a page has unusual structure (shadow DOM, iframes, web components), adapt the JS to match.
