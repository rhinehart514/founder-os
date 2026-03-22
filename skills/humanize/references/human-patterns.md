# Human Patterns — What Senior Engineers Actually Do

Not rules. Observations from codebases built by excellent humans.

## Architecture choices

**Flat > nested.** A human with a 200-line feature puts it in 1-2 files, not a folder tree. The folder appears when there are 5+ files that genuinely relate. Not before.

**Convention > configuration.** A human picks one way and uses it everywhere. No config file with 15 options. No environment variable for the port. It's 3000. If someone needs 3001, they'll change it.

**Copy > abstraction (at first).** Three similar handlers with slightly different logic? A human writes three handlers. The abstraction appears on the fourth, when the pattern is proven. AI abstracts on the first.

**Delete > comment out.** Git remembers. A human deletes dead code. AI comments it out "in case we need it later."

## Naming conventions

**Short in tight scope.** Loop variable: `i`. Map callback: `x => x.id`. Two-line function parameter: `s` for string. AI always writes `item`, `element`, `currentString`.

**Domain-specific.** Real codebases use jargon. `sku`, `slug`, `ttl`, `nonce`, `jwt`. AI spells everything out: `stockKeepingUnit`, `urlSlug`, `timeToLive`.

**Verbs for functions, nouns for data.** `fetch`, `parse`, `render`, `save`. Not `performDataFetching`, `executeParsingOperation`. A human would never type `executeParsingOperation` voluntarily.

**Abbreviations where obvious.** `config`, `env`, `auth`, `db`, `req`, `res`, `ctx`, `err`, `msg`, `btn`, `img`. AI writes `configuration`, `environment`, `authentication`, `database`, `request`, `response`, `context`, `error`, `message`, `button`, `image`.

## Error handling

**Crash > silent failure.** A human lets the process crash on unexpected errors. They add handling for the expected ones. AI wraps everything in try/catch and logs the error, creating zombie processes that limp along in a broken state.

**One error boundary.** The top-level handler catches unhandled exceptions. Individual functions throw. The boundary decides what to do. AI puts try/catch at every level, making error flow unreadable.

**Specific > generic.** `throw new Error('user not found: ' + id)` not `throw new Error('An error occurred while processing your request')`. A human writes errors they'd want to debug at 3am.

## Comments

**The only good comments:**
- WHY something unexpected is happening: `// Safari 17 doesn't support this yet`
- WARNING about non-obvious consequences: `// This mutates the input array`
- CONTEXT that can't live in the code: `// Business rule: free tier gets 3 retries, paid gets unlimited`
- TODO with a real reason: `// TODO(jake): migrate to v2 API before March — v1 sunset`

**Comments that reveal AI:**
- Restating the code: `// Get user by ID`
- Section headers in small files: `// --- Constants ---`
- Parameter descriptions that match the name: `@param userId - The user ID`
- Function descriptions that match the name: `/** Fetches the user profile */`

## File organization

**One concept per file.** Not one function, not one class — one concept. A concept might be 20 lines or 200. The test for splitting: "Would someone looking for this feature know which file to open?"

**Tests next to code.** `profile.ts` and `profile.test.ts` in the same directory. Not `src/components/profile.ts` and `test/unit/components/profile.test.ts`. A human wants to see the test when they change the code.

**No barrel exports without a reason.** `index.ts` that re-exports everything is AI scaffolding. A human creates an index when the public API is genuinely smaller than the internal structure.

## The meta-pattern

A human-written codebase has **variance**. Some files are short. Some are long. Some are heavily commented (the tricky ones). Most have zero comments. Some use abbreviations. Some spell things out. The inconsistency IS the signal — it means different decisions were made at different times for different reasons.

AI-written codebases are uniform. That uniformity is the biggest tell. If every file feels like it came from the same session, it probably did.
