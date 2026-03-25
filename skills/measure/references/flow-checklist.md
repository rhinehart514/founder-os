# Flow Checklist — Frontend Delivery Audit

What makes a frontend flawless. Six layers, each builds on the previous.
Used by `/taste <url> flows` mode. Check every layer in order — a failure in Layer 1 makes Layer 4 irrelevant.

---

## Layer 1: Does it load?

Mechanical checks. No judgment needed.

| Check | How to test | Pass | Fail |
|-------|-----------|------|------|
| Page loads | `browser_navigate` completes without timeout | Content visible | Timeout, blank page, error page |
| No JS errors | `browser_console_messages` — filter for errors | 0 errors | Any error |
| No failed requests | `browser_network_requests` — filter 4xx/5xx | 0 failures | Any failed API call |
| No layout shift | Screenshot at 1s vs 3s — same layout | Stable | Content jumps after load |
| Loads in <3s | `browser_wait_for` with content selector | Content appears fast | Blank screen persists |

**If Layer 1 fails: stop. Fix the broken foundation before evaluating anything else.**

---

## Layer 2: Can I understand it?

First 5 seconds. What does a stranger with zero context see?

| Check | How to test | Pass | Fail |
|-------|-----------|------|------|
| Value prop visible | `browser_snapshot` — is there a headline that says what this does? | Clear statement above fold | No headline, generic text, or jargon |
| Primary action obvious | `browser_snapshot` — one clear CTA above fold | One button/link stands out | Multiple competing CTAs, or none |
| Heading hierarchy | `browser_evaluate` — h1 > h2 > h3 font sizes | Descending sizes | Same size, wrong order, missing h1 |
| No placeholder content | `browser_snapshot` — search for lorem, TODO, example.com | Real content | Placeholder text visible |
| Navigation present | `browser_snapshot` — nav element with links | Nav with reachable destinations | No nav, or nav with dead links |

---

## Layer 3: Can I use it?

Interact with the product. Attempt the core flow.

| Check | How to test | Pass | Fail |
|-------|-----------|------|------|
| Primary CTA works | `browser_click` on primary CTA → page changes or content updates | Visible response | Nothing happens, or error |
| Forms submit | `browser_fill_form` + submit → feedback | Success/error message | Silent failure, no feedback |
| Form validation | Submit empty required fields → inline errors | Field-level messages | Page-level error or nothing |
| Loading states | Trigger async action → observe | Skeleton, spinner, or progress | Blank wait, then content appears |
| Success feedback | Complete an action → confirmation | Clear "done" signal | Silent completion |
| Error feedback | Trigger an error → message | Actionable error message | Generic error or nothing |
| Navigation works | `browser_click` nav links → pages load | All nav items lead somewhere | Dead links, 404s |
| Back button works | Navigate forward, then `browser_navigate_back` | Returns to previous state | Broken state, or doesn't go back |

---

## Layer 4: Does it handle edges?

What happens when things aren't perfect?

| Check | How to test | Pass | Fail |
|-------|-----------|------|------|
| Empty state | Navigate with no data / new account | Guidance, CTA, sample content | Blank page, "no data" |
| Dead ends | Complete a flow → where next? | Clear next step or return | Stranded, no next action |
| Long content | Test with long text in inputs/displays | Truncates or wraps gracefully | Overflow, broken layout |
| Deep links | Navigate directly to inner page URL | Works with context | Broken without auth, or missing context |
| Auth boundary | Access protected route without auth | Redirect to login with return URL | Error, blank page, or data leak |

---

## Layer 5: Is it accessible?

Mechanical accessibility checks.

| Check | How to test | Pass | Fail |
|-------|-----------|------|------|
| Contrast ratios | `browser_evaluate` — check WCAG AA (4.5:1 text, 3:1 large) | All text passes | Low contrast text |
| Click targets | `browser_evaluate` — interactive elements >= 44x44px | All targets adequate | Elements < 44px |
| Form labels | `browser_evaluate` — inputs have associated labels | All inputs labeled | Inputs without labels |
| Focus visible | `browser_press_key` Tab → focus indicator visible | Ring or outline on focused element | No visible focus |
| Keyboard nav | `browser_press_key` Tab through page → all interactive elements reachable | Can reach all actions | Elements skipped or trapped |
| ARIA landmarks | `browser_snapshot` — check for main, nav, header roles | Key landmarks present | No semantic structure |
| Alt text | `browser_evaluate` — images have alt attributes | All images have alt | Images without alt |

---

## Layer 6: Is it responsive?

Test at multiple viewports.

| Check | How to test | Pass | Fail |
|-------|-----------|------|------|
| Mobile layout (390px) | `browser_resize` 390x844 → screenshot | Content reflows, no overflow | Horizontal scroll, overlapping elements |
| Touch targets mobile | `browser_evaluate` at 390px — interactive >= 44px | Adequate targets | Tiny buttons/links |
| Nav accessible mobile | `browser_snapshot` at 390px — nav visible or hamburger works | Can access all nav | Nav hidden with no toggle |
| Text readable mobile | `browser_evaluate` at 390px — body font >= 14px | Readable without zoom | Tiny text |
| Tablet layout (768px) | `browser_resize` 768x1024 → screenshot | Reasonable layout | Broken between mobile and desktop |

---

## Severity Classification

| Severity | Meaning | Examples |
|----------|---------|---------|
| **blocker** | User cannot complete the core task | JS error breaks page, primary CTA doesn't work, form submission fails |
| **major** | User can complete task but experience is broken | No empty state, dead ends after actions, no error messages, broken mobile |
| **minor** | User notices but can work around | Missing hover states, small click targets, heading hierarchy off, contrast warnings |
| **polish** | Professional quality gap | Missing loading states, inconsistent focus rings, minor layout shift |

---

## How This Differs From Visual Eval

| | Visual eval (`/taste <url>`) | Flow eval (`/taste <url> flows`) |
|---|---|---|
| **Question** | Is this well-designed? | Does this work? |
| **Method** | Screenshot + snapshot + code read | Navigate + click + fill + check |
| **Output** | 11 dimension scores 0-100 | Issue list by severity |
| **Time** | 5-10 minutes | 3-5 minutes |
| **LLM cost** | High (scoring judgment) | Low (mostly mechanical checks) |
| **When to use** | After the product works, to polish | Before polishing, to ensure it works |
| **Catches** | Poor visual design, bad IA, weak tone | Broken flows, missing states, a11y gaps, dead ends |

The right order: **flows first, then visual.** A beautiful product that doesn't work is a decorated corpse.
