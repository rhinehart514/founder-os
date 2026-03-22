# UX Checklist (Craft Layer)

After every feature or significant change, check your own work against these.
LLMs consistently miss them. You will too unless you explicitly check.

## Universal (every product surface)

1. **5-second test** — A stranger encounters this for the first time. Do they understand what it does and what to do in 5 seconds? If not, the product surface has failed before the code even runs.
2. **Empty state** — What does a new user with zero data see? Blank screen / empty output / null response = bug. Add guidance, a CTA, sample content, or a helpful error.
3. **Dead ends** — After the user completes the action, where do they go? Every screen/output/response leads somewhere. No action should strand the user.
4. **First-time experience** — Pretend you've never seen the product. Is it obvious what to do? If it requires prior context, explain it.
5. **User feedback** — After every action, does something visible change? Silent actions feel broken. This applies to CLI (print confirmation), API (return meaningful response), web (visual state change).
6. **Error communication** — When something goes wrong, does the user understand what happened AND how to fix it? "Error" is not a message. "File not found: config/founder.yml — run `founder init` to create it" is.
7. **Next action clarity** — Does every output/screen/response make the next step obvious? One action, not a menu. Not "you could do A or B or C" but "do X."
8. **Information density** — Too much? Progressive disclosure. Too little? More context. Match density to task and expertise level.
9. **Consistency** — Does this feel like the same product across every touchpoint? Same tone, same formatting patterns, same information hierarchy.
10. **Return trigger** — Is there a reason to come back? If the user got value once, what pulls them back tomorrow?

## Web-specific

11. **Visual hierarchy** — What's the first thing the eye hits? One primary action per screen. Secondary elements recede.
12. **Loading states** — Every async operation: loading, success, error. Skeleton > spinner > nothing.
13. **Mobile** — Does it work at 390px? Tables readable? Touch targets 44px? No horizontal scroll.
14. **Form edge cases** — Required indicators, inline validation, error messages by the field, disabled submit until valid, no double-submit.
15. **Navigation coherence** — Can the user get back? Can they find this page from main nav?

## CLI-specific

11. **Scanability** — Can you get the key information in 2 seconds without reading? Signal first, detail second.
12. **Output hierarchy** — Bold/color/position distinguish primary findings from supporting detail. Not everything at the same visual weight.
13. **Voice compliance** — Follows the product's output standards (voice.md). Consistent symbols, formatting, structure across all commands.
14. **Actionable output** — Every command ends with what to do next. Not just data — direction.
15. **Graceful degradation** — Missing dependencies, missing config, missing data — each has a helpful message, not a stack trace.

## API-specific

11. **Response shape** — Consistent structure across endpoints. Predictable field names. No surprises.
12. **Error format** — Errors include: what went wrong, why, and how to fix it. Status codes are correct.
13. **Documentation match** — What the docs say matches what the API returns. Drift = broken trust.
14. **Progressive complexity** — Simple use case is simple. Advanced use case is possible. Not everything requires understanding everything.
15. **SDK ergonomics** — If there's a client library, is the common case a one-liner?

These aren't polish. They're the gap between "code that works" and "product users love."
