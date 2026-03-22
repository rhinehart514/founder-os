# AI Smells — Detection Rules

Seven patterns that reveal AI-generated code. Each includes what to look for, why it's a tell, and what a human would do instead.

## 1. Over-abstraction

**The tell:** More files than logic. `types.ts`, `constants.ts`, `utils.ts`, `helpers.ts`, `index.ts` — five files for thirty lines of actual work. Interface with one implementation. Abstract class with one subclass. Factory that creates one thing.

**Detection:**
- File <30 lines with name matching `utils|helpers|constants|types|index`
- `interface` + single `implements` in the codebase
- `abstract class` with one concrete subclass
- Folder with 5+ files, <200 total lines
- Re-exports: `export { default } from './Component'` as the only content of index.ts

**Human version:** One file. Put types at the top of the file that uses them. Constants next to the code that references them. "Utils" is a code smell — if a function is useful, it belongs near its caller.

**The line:** Abstractions earn their existence by having 2+ implementations or being genuinely reusable across 3+ files. Below that threshold, inline it.

---

## 2. Defensive paranoia

**The tell:** Code that doesn't trust itself. Every function validates its inputs even when the caller is 5 lines above. Try/catch around pure computation. `if (!result) return` after a function that always returns a value.

**Detection:**
- Try/catch ratio: >1 per 20 lines of code
- Null checks on function return values that can't be null (non-nullable types, required params)
- `typeof x !== 'undefined'` on variables you just declared
- `.catch(() => {})` — swallowing errors silently
- Input validation repeated at multiple layers for the same data

**Human version:** Validate at the boundary — user input, API responses, file reads. Inside the system, trust the types. If a function says it returns `string`, don't check for null. If something truly can fail, handle it. If it can't, don't waste lines pretending it might.

**The line:** Would a senior engineer reading this say "why are you checking for that?" If yes, delete the check.

---

## 3. Documentation theater

**The tell:** Comments that describe what the code does, not why. JSDoc on a function called `getName` that says "Gets the name and returns it as a string." README with 8 badges, a table of contents, and Contributing guidelines for a solo project.

**Detection:**
- Comment/code ratio >25%
- Comments starting with "This function...", "This method...", "Get the...", "Set the..."
- `@param name - The name` (restating the parameter name)
- `@returns {string} The result` (restating the return type)
- `// Loop through items` above a for loop
- `// Check if valid` above an if statement

**Human version:** Zero comments on self-explanatory code. Comments only when the WHY isn't obvious: "We use setTimeout(0) here because React batches state updates and we need this to run after the render." That comment earns its existence. "// Update the state" does not.

**The line:** Delete the comment. Can you still understand the code? If yes, the comment was theater.

---

## 4. Uniform voice

**The tell:** Every file reads like it was written by the same person in the same mood on the same day. Same patterns, same structure, same rhythm. Real codebases have geological layers — code from different periods, different contexts, different urgencies.

**Detection (requires LLM, not mechanical):**
- Read 5 files from different parts of the codebase. Do they all feel identical?
- Same error handling pattern in every file (always try/catch, or always .catch, or always Result type)
- Same variable naming style everywhere (always camelCase descriptive, never abbreviations)
- Same function structure (always early return, or always single return point)

**Human version:** The auth module is paranoid and verbose — written by someone who's seen breaches. The data pipeline is terse and functional — written by someone who thinks in transforms. The UI components are chatty with descriptive props — written by someone who thinks in component APIs. Different domains, different voices.

**The line:** This is the hardest to fix mechanically. It requires re-reading code through the lens of "who would have written this part?" and adjusting the voice to match.

---

## 5. Premature completeness

**The tell:** Every edge case handled before any edge case exists. Config with 20 options when the product needs 3. Switch statement with 12 cases when 4 are possible today. Error messages for scenarios that can't happen yet.

**Detection:**
- Switch/match with >10 cases
- Config/options objects with >8 keys
- Error handling for HTTP status codes the API doesn't return
- Feature flags for features that don't exist
- `// TODO: handle this case` — the case was so premature they couldn't even write the handler

**Human version:** Handle what exists. `default: throw new Error('unexpected')` for the rest. When a new case appears, add it then. Three similar lines of code is better than a premature abstraction that handles four cases when only two exist.

**The line:** If you're handling a case that has never happened in production, delete it. Add it when it happens.

---

## 6. Template structure

**The tell:** Every file follows the same visible skeleton. Imports → types → constants → helpers → main → exports. Every React component: props type → component → styles → export default. The files are organized for the AI's training data, not for the problem.

**Detection (requires LLM, not mechanical):**
- Read 5 component files. Are they structurally identical?
- Every file begins with the same import block ordering
- Types always above the code, never inline
- Consistent section comments (`// --- Types ---`, `// --- Helpers ---`)

**Human version:** The structure serves the content. A file that's one big function doesn't need sections. A complex module might have a different organization than a simple utility. Some files are 15 lines. Some are 200. The length is dictated by the problem, not the template.

**The line:** If you can describe the file structure without reading the content, it's a template.

---

## 7. Name anxiety

**The tell:** Names that concatenate every noun in scope. `UserProfileDashboardContainer`. `handleUserProfileFormSubmission`. `isValidUserEmailAddress`. The AI is afraid of ambiguity, so it over-qualifies everything.

**Detection:**
- CamelCase identifiers with 4+ words (>25 characters)
- `handle*` prefix on >5 functions in one file
- Hungarian notation remnants (`strName`, `numCount`, `bIsValid`)
- Redundant prefixes matching the file/module name (`UserProfile` in `user-profile.ts`)
- `I` prefix on interfaces (`IUser`, `IConfig`)

**Human version:** Shortest name that's unambiguous in context. Inside `user/profile.ts`, it's `Profile`, not `UserProfile`. A click handler is `submit`, not `handleFormSubmission`. A boolean is `valid`, not `isCurrentlyValid`. Context does the work that AI makes the name do.

**The line:** Read the name out loud. If you sound like a lawyer, shorten it.
