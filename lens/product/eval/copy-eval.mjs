#!/usr/bin/env node

/**
 * copy-eval.mjs — Mechanical copy & positioning evaluator
 *
 * No LLM needed. Scrapes text from a running page and runs readability,
 * headline quality, and positioning checks. Zero ML.
 *
 * Usage:
 *   node copy-eval.mjs --url <url> [--json] [--eval]
 *
 * Copy checks (copy_check type):
 *   - reading_level: Flesch-Kincaid grade level of visible text
 *   - headline_words: h1 word count
 *   - forbidden: jargon word scan
 *   - names_user: headline contains a user type
 *   - has_verb: headline contains action verb
 *   - no_abstraction: no "the future of X" patterns
 *
 * Positioning checks (positioning_check type):
 *   - specific_claim: headline makes a falsifiable claim
 *   - named_user: specific user type named (not "everyone")
 *   - no_buzzword: no "AI-powered" / "next-gen" as main claim
 *   - differentiation: product name or differentiator in headline
 *
 * Composite checks (map to belief IDs):
 *   - copy-clarity: reading_level + headline_words + forbidden
 *   - value-prop-specific: names_user + has_verb + no_abstraction
 *   - positioned-not-generic: specific_claim + named_user + no_buzzword
 *
 * --eval mode outputs one line per composite: metric:pass|fail:detail
 *
 * Requires: playwright
 */

import { chromium } from "playwright";

const BOLD = "\x1b[1m";
const GREEN = "\x1b[32m";
const RED = "\x1b[31m";
const NC = "\x1b[0m";

// --- CLI args ---
const args = process.argv.slice(2);
let url = null;
let jsonOutput = false;
let evalOutput = false;

for (let i = 0; i < args.length; i++) {
  if (args[i] === "--url" && args[i + 1]) url = args[++i];
  else if (args[i] === "--json") jsonOutput = true;
  else if (args[i] === "--eval") evalOutput = true;
  else if (!url && args[i].startsWith("http")) url = args[i];
}

if (!url) {
  console.error("Usage: node copy-eval.mjs --url <url> [--json] [--eval]");
  process.exit(1);
}

// --- Readability ---
function countSyllables(word) {
  word = word.toLowerCase().replace(/[^a-z]/g, "");
  if (word.length <= 3) return 1;
  word = word.replace(/(?:[^laeiouy]es|ed|[^laeiouy]e)$/, "");
  word = word.replace(/^y/, "");
  const matches = word.match(/[aeiouy]{1,2}/g);
  return matches ? matches.length : 1;
}

function fleschKincaidGrade(text) {
  const sentences = text.split(/[.!?]+/).filter(s => s.trim().length > 0);
  const words = text.split(/\s+/).filter(w => w.replace(/[^a-z]/gi, "").length > 0);
  if (sentences.length === 0 || words.length === 0) return 0;
  const syllables = words.reduce((sum, w) => sum + countSyllables(w), 0);
  return 0.39 * (words.length / sentences.length) + 11.8 * (syllables / words.length) - 15.59;
}

// --- Patterns ---
const JARGON = [
  "utilize", "leverage", "synergy", "paradigm", "ecosystem", "holistic",
  "disrupt", "scalable", "world-class", "best-in-class", "turnkey",
  "bleeding edge", "thought leader", "move the needle",
];

const BUZZWORDS = [
  "ai-powered", "ai powered", "next-gen", "next gen", "intelligent",
  "smart", "revolutionary", "game-changing", "cutting-edge", "cutting edge",
];

const ABSTRACTION_PATTERNS = [
  /the future of \w+/i,
  /rethinking \w+/i,
  /\w+ reimagined/i,
  /\w+ reinvented/i,
  /\w+, redefined/i,
];

const USER_TYPES = [
  "founder", "founders", "developer", "developers", "team", "teams",
  "designer", "designers", "engineer", "engineers", "creator", "creators",
  "marketer", "marketers", "startup", "startups", "freelancer", "freelancers",
  "agency", "agencies", "builder", "builders", "maker", "makers",
  "student", "students", "researcher", "researchers", "writer", "writers",
];

const ACTION_VERBS = [
  "build", "ship", "launch", "create", "deploy", "manage", "automate",
  "track", "monitor", "analyze", "design", "write", "test", "run",
  "grow", "scale", "optimize", "improve", "measure", "generate",
  "connect", "integrate", "simplify", "save", "earn", "find", "get",
  "make", "start", "stop", "fix", "solve", "reduce", "increase",
];

async function runChecks() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });

  try {
    await page.goto(url, { waitUntil: "networkidle", timeout: 30000 });
    await page.waitForTimeout(1000);
  } catch (e) {
    if (!evalOutput) console.error(`Failed to load ${url}: ${e.message}`);
    await browser.close();
    process.exit(1);
  }

  const pageData = await page.evaluate(() => {
    const h1 = document.querySelector("h1");
    const h2s = [...document.querySelectorAll("h2")];
    const bodyText = document.body.innerText || "";
    const title = document.title || "";
    const metaDesc = document.querySelector('meta[name="description"]')?.content || "";
    return {
      h1Text: h1 ? h1.innerText.trim() : "",
      h2Texts: h2s.map(h => h.innerText.trim()),
      bodyText: bodyText.slice(0, 5000),
      title,
      metaDesc,
    };
  });

  await browser.close();

  const headline = pageData.h1Text;
  const headlineLower = headline.toLowerCase();
  const headlineWords = headline.split(/\s+/).filter(w => w.length > 0);

  // --- Individual checks ---
  const checks = {};

  // Reading level
  const grade = fleschKincaidGrade(pageData.bodyText);
  checks.reading_level = {
    pass: grade <= 8,
    grade: Math.round(grade * 10) / 10,
  };

  // Headline word count
  checks.headline_words = {
    pass: headlineWords.length > 0 && headlineWords.length <= 12,
    count: headlineWords.length,
  };

  // Forbidden jargon in headline
  const foundJargon = JARGON.filter(j => headlineLower.includes(j));
  checks.forbidden = {
    pass: foundJargon.length === 0,
    found: foundJargon,
  };

  // Names a user type
  const foundUsers = USER_TYPES.filter(u => headlineLower.includes(u));
  checks.names_user = {
    pass: foundUsers.length > 0,
    found: foundUsers,
  };

  // Has action verb
  const foundVerbs = ACTION_VERBS.filter(v => {
    const re = new RegExp(`\\b${v}s?\\b`, "i");
    return re.test(headline);
  });
  checks.has_verb = {
    pass: foundVerbs.length > 0,
    found: foundVerbs,
  };

  // No abstraction patterns
  const foundAbstractions = ABSTRACTION_PATTERNS.filter(p => p.test(headline));
  checks.no_abstraction = {
    pass: foundAbstractions.length === 0,
    patterns: foundAbstractions.map(p => p.source),
  };

  // --- Positioning checks ---

  // Specific claim (has a number, timeframe, or concrete outcome)
  const hasNumber = /\d+/.test(headline);
  const hasTimeframe = /minute|hour|day|week|second|instant|overnight/i.test(headline);
  const hasConcrete = /auto|generat|detect|scan|deploy|install|config/i.test(headline);
  checks.specific_claim = {
    pass: hasNumber || hasTimeframe || hasConcrete,
    has_number: hasNumber,
    has_timeframe: hasTimeframe,
    has_concrete: hasConcrete,
  };

  // Named user (not generic)
  const genericUsers = ["everyone", "anybody", "anyone", "people", "users", "businesses", "companies"];
  const foundGeneric = genericUsers.filter(g => headlineLower.includes(g));
  checks.named_user = {
    pass: foundUsers.length > 0 && foundGeneric.length === 0,
    specific: foundUsers,
    generic: foundGeneric,
  };

  // No buzzword positioning
  const foundBuzz = BUZZWORDS.filter(b => headlineLower.includes(b));
  checks.no_buzzword = {
    pass: foundBuzz.length === 0,
    found: foundBuzz,
  };

  // Differentiation word (product name or unique term in headline)
  const titleWords = pageData.title.split(/[\s\-|]+/).filter(w => w.length > 2);
  const productName = titleWords[0] || "";
  const hasDifferentiator = productName && headlineLower.includes(productName.toLowerCase());
  checks.differentiation = {
    pass: hasDifferentiator,
    product_name: productName,
    in_headline: hasDifferentiator,
  };

  // --- Composite checks (map to belief IDs) ---
  const composites = {};

  composites["copy-clarity"] = {
    pass: checks.reading_level.pass && checks.headline_words.pass && checks.forbidden.pass,
    detail: `grade ${checks.reading_level.grade}, ${checks.headline_words.count} words, ${checks.forbidden.found.length} jargon`,
  };

  composites["value-prop-specific"] = {
    pass: checks.names_user.pass && checks.has_verb.pass && checks.no_abstraction.pass,
    detail: `users: [${checks.names_user.found.join(",")}], verbs: [${checks.has_verb.found.join(",")}], abstractions: ${checks.no_abstraction.pass ? "none" : "found"}`,
  };

  composites["positioned-not-generic"] = {
    pass: checks.specific_claim.pass && checks.named_user.pass && checks.no_buzzword.pass,
    detail: `claim: ${checks.specific_claim.pass ? "specific" : "vague"}, user: ${checks.named_user.pass ? "named" : "generic"}, buzzwords: ${checks.no_buzzword.found.length}`,
  };

  return { checks, composites, headline, pageData };
}

// --- Run ---
const { checks, composites, headline } = await runChecks();

if (evalOutput) {
  // Output all composites + individual checks for eval.sh
  for (const [name, c] of Object.entries(composites)) {
    console.log(`${name}:${c.pass ? "pass" : "fail"}:${c.detail}`);
  }
  // Also output individual positioning checks
  for (const name of ["specific_claim", "named_user", "no_buzzword", "differentiation"]) {
    const c = checks[name];
    const detail = c.pass ? "passed" : `failed: ${JSON.stringify(c.found || c.generic || [])}`;
    console.log(`${name}:${c.pass ? "pass" : "fail"}:${detail}`);
  }
} else if (jsonOutput) {
  console.log(JSON.stringify({ url, headline, checks, composites }, null, 2));
} else {
  console.log(`${BOLD}copy-eval${NC} — ${url}`);
  console.log(`${BOLD}Headline:${NC} "${headline}"`);
  console.log("");

  console.log(`${BOLD}Copy Quality:${NC}`);
  for (const name of ["reading_level", "headline_words", "forbidden", "names_user", "has_verb", "no_abstraction"]) {
    const c = checks[name];
    const icon = c.pass ? `${GREEN}[PASS]${NC}` : `${RED}[FAIL]${NC}`;
    let detail = "";
    if (name === "reading_level") detail = `grade ${c.grade} (target: <= 8)`;
    else if (name === "headline_words") detail = `${c.count} words (target: <= 12)`;
    else if (name === "forbidden") detail = c.found.length ? `jargon: ${c.found.join(", ")}` : "no jargon";
    else if (name === "names_user") detail = c.found.length ? `users: ${c.found.join(", ")}` : "no user type found";
    else if (name === "has_verb") detail = c.found.length ? `verbs: ${c.found.join(", ")}` : "no action verb";
    else if (name === "no_abstraction") detail = c.pass ? "no abstraction patterns" : "abstraction detected";
    console.log(`  ${icon} ${name}    ${detail}`);
  }

  console.log("");
  console.log(`${BOLD}Positioning:${NC}`);
  for (const name of ["specific_claim", "named_user", "no_buzzword", "differentiation"]) {
    const c = checks[name];
    const icon = c.pass ? `${GREEN}[PASS]${NC}` : `${RED}[FAIL]${NC}`;
    let detail = "";
    if (name === "specific_claim") detail = c.pass ? "specific claim found" : "no specific claim";
    else if (name === "named_user") detail = c.pass ? `specific: ${c.specific.join(", ")}` : "no specific user named";
    else if (name === "no_buzzword") detail = c.found.length ? `buzzwords: ${c.found.join(", ")}` : "no buzzwords";
    else if (name === "differentiation") detail = c.in_headline ? `"${c.product_name}" in headline` : "no differentiator in headline";
    console.log(`  ${icon} ${name}    ${detail}`);
  }

  console.log("");
  const allPass = Object.values(composites).every(c => c.pass);
  const passCount = Object.values(composites).filter(c => c.pass).length;
  console.log(`${passCount}/${Object.keys(composites).length} composite checks passed`);
}

const anyFail = Object.values(composites).some(c => !c.pass);
process.exit(anyFail ? 1 : 0);
