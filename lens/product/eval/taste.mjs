#!/usr/bin/env node

/**
 * taste.mjs — Visual taste evaluator. Your eval loss for product quality.
 *
 * The 2026 approach: don't grep the code, LOOK at the product.
 * 1. Starts dev server (or uses running one)
 * 2. Screenshots every route with Playwright
 * 3. Sends screenshots to Claude vision with taste rubric
 * 4. Returns scored breakdown with cited visual evidence
 *
 * This is the expensive eval — run on demand, not every commit.
 * score.sh is the cheap proxy (training loss). This is eval loss.
 *
 * Auth support: Add an 'auth' section to .claude/taste.yml:
 *   Login flow: login_url + email + password → Playwright logs in automatically
 *   Manual: cookies/localStorage injection (fallback for non-standard auth)
 * This lets taste eval see authenticated pages (dashboard, profile, etc.)
 *
 * Usage:
 *   node taste.mjs [project-dir] [--json] [--port 3000] [--url http://localhost:3000]
 *
 * Requires:
 *   - playwright (npx playwright install chromium)
 *   - claude CLI (for evaluation via OAuth — no API key needed)
 */

import { chromium } from "playwright";
import { readFileSync, existsSync, writeFileSync, appendFileSync, readdirSync, statSync, mkdirSync } from "fs";
import { join, resolve } from "path";
import { execSync, spawn } from "child_process";

// --- Progress display ---
const DIM = "\x1b[2m";
const BOLD = "\x1b[1m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const NC = "\x1b[0m";
const spinChars = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏";
let spinInterval = null;

function startSpinner(msg) {
  let i = 0;
  process.stderr.write(DIM);
  spinInterval = setInterval(() => {
    process.stderr.write(`\r  ${spinChars[i % spinChars.length]} ${msg}`);
    i++;
  }, 100);
}

function stopSpinner(msg) {
  if (spinInterval) {
    clearInterval(spinInterval);
    spinInterval = null;
  }
  process.stderr.write(`\r  ${GREEN}✓${NC} ${msg}\n`);
}

// --- founder.yml config reader ---
function loadFounderConfig() {
  const configPath = join(import.meta.dirname, "..", "config", "founder.yml");
  if (!existsSync(configPath)) return {};
  const content = readFileSync(configPath, "utf-8");
  // Simple flat YAML parser — reads dotted paths
  const values = {};
  const stack = [];
  for (const line of content.split("\n")) {
    if (/^\s*#/.test(line) || !line.trim()) continue;
    const indent = line.length - line.trimStart().length;
    const match = line.trimStart().match(/^([a-zA-Z_][\w-]*):\s*(.*)/);
    if (!match) continue;
    const [, key, rawVal] = match;
    const val = rawVal.replace(/#.*/, "").trim();
    // Maintain indent stack for nesting
    while (stack.length > 0 && stack[stack.length - 1].indent >= indent) stack.pop();
    stack.push({ key, indent });
    if (val && val !== "~") {
      const fullKey = stack.map(s => s.key).join(".");
      values[fullKey] = val;
    }
  }
  return values;
}

const founderCfg = loadFounderConfig();
function cfg(key, defaultVal) {
  const v = founderCfg[key];
  if (v === undefined || v === "~") return defaultVal;
  const num = Number(v);
  return isNaN(num) ? v : num;
}

// --- Config ---
const args = process.argv.slice(2);
let projectDir = ".";
let outputMode = "breakdown";
let baseUrl = null;
let port = null;
let skipServer = false;
let force = false;
let featureFilter = null;
let researchFirst = false;
let openScreenshots = false;

for (let i = 0; i < args.length; i++) {
  if (args[i] === "--json") outputMode = "json";
  else if (args[i] === "--score") outputMode = "score";
  else if (args[i] === "--port") port = parseInt(args[i + 1]), i++;
  else if (args[i] === "--url") baseUrl = args[i + 1], skipServer = true, i++;
  else if (args[i] === "--force") force = true;
  else if (args[i] === "--feature") featureFilter = args[i + 1], i++;
  else if (args[i] === "--research") researchFirst = true;
  else if (args[i] === "--open") openScreenshots = true;
  else if (args[i] === "--help" || args[i] === "-h") {
    console.log(`Usage: node taste.mjs [project-dir] [options]`);
    console.log(`\nEvaluates product taste by screenshotting every route and judging with Claude vision.`);
    console.log(`\nOptions:`);
    console.log(`  --json             Output JSON`);
    console.log(`  --score            Output score only`);
    console.log(`  --port <port>      Dev server port`);
    console.log(`  --url <url>        Use running server (skip auto-start)`);
    console.log(`  --force            Re-run even if recent eval exists`);
    console.log(`  --feature <name>   Evaluate a single feature (requires .claude/features.yml)`);
    console.log(`  --research         Remind to run /research-taste before eval for grounded scoring`);
    console.log(`  --open             Open screenshots in Preview after capture (see what Claude sees)`);
    console.log(`\nAuth: Add an 'auth' section to .claude/taste.yml:`);
    console.log(`  Login flow (recommended):`);
    console.log(`    auth:`);
    console.log(`      login_url: /login`);
    console.log(`      email: test@example.com`);
    console.log(`      password: testpass123`);
    console.log(`      wait_for: "[data-testid=dashboard]"  # selector or networkidle`);
    console.log(`  Manual cookies/localStorage also supported (see docs).`);
    console.log(`\nRequires: claude CLI (OAuth), playwright (npx playwright install chromium)`);
    process.exit(0);
  }
  else if (!args[i].startsWith("-")) projectDir = args[i];
}

projectDir = resolve(projectDir);

// --- Load taste.yml config (route selection + auth) ---
function loadTasteConfig() {
  const configPaths = [
    join(projectDir, ".claude", "taste.yml"),
    join(projectDir, ".claude", "taste.yaml"),
  ];

  for (const p of configPaths) {
    if (existsSync(p)) {
      try {
        const content = readFileSync(p, "utf-8");
        // Simple YAML parser for our flat structure
        const config = { routes: [], mobile: [], auth: null };
        let currentKey = null;
        let authSection = null;
        let inCookies = false;
        let inLocalStorage = false;
        let currentCookie = null;

        for (const line of content.split("\n")) {
          const trimmed = line.trim();
          if (trimmed.startsWith("#") || !trimmed) continue;

          // Top-level sections
          if (trimmed === "routes:") { currentKey = "routes"; authSection = null; continue; }
          if (trimmed === "mobile:") { currentKey = "mobile"; authSection = null; continue; }
          if (trimmed === "auth:") { currentKey = null; authSection = {}; config.auth = authSection; inCookies = false; inLocalStorage = false; continue; }

          // Route/mobile list items
          if (currentKey && trimmed.startsWith("- ")) {
            const val = trimmed.slice(2).trim().replace(/#.*/, "").trim();
            if (val) config[currentKey].push(val);
            continue;
          }

          // Auth sub-sections
          if (authSection !== null) {
            if (trimmed === "cookies:") { inCookies = true; inLocalStorage = false; authSection.cookies = authSection.cookies || []; continue; }
            if (trimmed === "localStorage:") { inLocalStorage = true; inCookies = false; authSection.localStorage = authSection.localStorage || {}; continue; }
            if (trimmed.startsWith("login_url:")) { authSection.login_url = trimmed.split(":").slice(1).join(":").trim().replace(/["']/g, ""); continue; }
            if (trimmed.startsWith("email:")) { authSection.email = trimmed.slice(6).trim().replace(/["']/g, ""); continue; }
            if (trimmed.startsWith("password:")) { authSection.password = trimmed.slice(9).trim().replace(/["']/g, ""); continue; }
            if (trimmed.startsWith("email_selector:")) { authSection.email_selector = trimmed.slice(15).trim().replace(/["']/g, ""); continue; }
            if (trimmed.startsWith("password_selector:")) { authSection.password_selector = trimmed.slice(18).trim().replace(/["']/g, ""); continue; }
            if (trimmed.startsWith("submit_selector:")) { authSection.submit_selector = trimmed.slice(16).trim().replace(/["']/g, ""); continue; }
            if (trimmed.startsWith("wait_for:")) { authSection.wait_for = trimmed.slice(9).trim().replace(/["']/g, ""); continue; }

            // Cookie entries (list of objects with name, value, domain, path)
            if (inCookies) {
              if (trimmed.startsWith("- name:")) {
                currentCookie = { name: trimmed.slice(7).trim().replace(/["']/g, "") };
                authSection.cookies.push(currentCookie);
              } else if (currentCookie && trimmed.startsWith("value:")) {
                currentCookie.value = trimmed.slice(6).trim().replace(/["']/g, "");
              } else if (currentCookie && trimmed.startsWith("domain:")) {
                currentCookie.domain = trimmed.slice(7).trim().replace(/["']/g, "");
              } else if (currentCookie && trimmed.startsWith("path:")) {
                currentCookie.path = trimmed.slice(5).trim().replace(/["']/g, "");
              }
              continue;
            }

            // localStorage entries (key: value pairs)
            if (inLocalStorage) {
              const kvMatch = trimmed.match(/^([^:]+):\s*(.+)/);
              if (kvMatch) {
                authSection.localStorage[kvMatch[1].trim().replace(/["']/g, "")] = kvMatch[2].trim().replace(/["']/g, "");
              }
              continue;
            }
          }
        }
        if (config.routes.length > 0 || config.auth) return config;
      } catch {}
    }
  }
  return null;
}

// --- Load features.yml config (feature-to-route mapping) ---
function loadFeatures() {
  const configPaths = [
    join(projectDir, ".claude", "features.yml"),
    join(projectDir, ".claude", "features.yaml"),
  ];

  for (const p of configPaths) {
    if (existsSync(p)) {
      try {
        const content = readFileSync(p, "utf-8");
        const features = {};
        let currentFeature = null;
        let inFeatures = false;
        let inRoutes = false;
        let featuresIndent = -1;
        let featureIndent = -1;

        for (const line of content.split("\n")) {
          const trimmed = line.trim();
          if (trimmed.startsWith("#") || !trimmed) continue;
          const indent = line.length - line.trimStart().length;

          if (trimmed === "features:") {
            inFeatures = true;
            featuresIndent = indent;
            continue;
          }

          if (!inFeatures) continue;

          // A key at features indent + 2 is a feature name
          if (indent > featuresIndent && !trimmed.startsWith("-") && trimmed.endsWith(":") && !trimmed.startsWith("routes:")) {
            currentFeature = trimmed.slice(0, -1).trim();
            featureIndent = indent;
            features[currentFeature] = { routes: [] };
            inRoutes = false;
            continue;
          }

          if (currentFeature && trimmed === "routes:") {
            inRoutes = true;
            continue;
          }

          // Back to a higher or same indent as features section — stop
          if (indent <= featuresIndent && trimmed && !trimmed.startsWith("-")) {
            inFeatures = false;
            continue;
          }

          if (inRoutes && currentFeature && trimmed.startsWith("- ")) {
            const val = trimmed.slice(2).trim().replace(/["']/g, "").replace(/#.*/, "").trim();
            if (val) features[currentFeature].routes.push(val);
          }
        }

        if (Object.keys(features).length > 0) return features;
      } catch {}
    }
  }
  return null;
}

// --- Discover routes by browsing the app like a user ---
// No filesystem assumptions. Works with any framework, any data layer.
// BFS from root: find links, follow them, screenshot each unique page.
async function discoverRoutes(browser, url, authConfig) {
  const maxRoutes = cfg("taste.max_routes", 8);
  const visited = new Set();
  const queue = ["/"];
  const discovered = []; // { path, title }
  const origin = new URL(url).origin;

  const context = await browser.newContext();
  const page = await context.newPage();

  // Auth first — so we see authenticated pages
  await injectAuth(context, page, authConfig, url);

  while (queue.length > 0 && discovered.length < maxRoutes) {
    const path = queue.shift();
    const normalized = normalizePath(path);
    if (visited.has(normalized)) continue;
    visited.add(normalized);

    try {
      await page.goto(`${url}${path}`, {
        waitUntil: "networkidle",
        timeout: cfg("taste.timeouts.page_load", 30000),
      });
      await page.waitForTimeout(cfg("taste.timeouts.post_load_wait", 1000));

      // Skip error pages (4xx/5xx responses render but aren't useful to evaluate)
      const pageTitle = await page.title().catch(() => "");
      const bodyText = await page.evaluate(() => document.body?.innerText?.slice(0, 200) || "").catch(() => "");
      const is404 = /404|not found/i.test(pageTitle) || /404|not found|page doesn.t exist/i.test(bodyText);
      if (is404) continue;

      discovered.push({ path: normalized, title: pageTitle });

      // Extract all internal links from this page
      const links = await page.evaluate((originStr) => {
        const anchors = Array.from(document.querySelectorAll("a[href]"));
        const navLinks = Array.from(document.querySelectorAll("[role=link][href], [data-href]"));
        const allElements = [...anchors, ...navLinks];

        return allElements
          .map(el => {
            const href = el.getAttribute("href") || el.getAttribute("data-href") || "";
            return href;
          })
          .filter(href => {
            if (!href) return false;
            // Skip anchors, mailto, tel, javascript
            if (href.startsWith("#") || href.startsWith("mailto:") || href.startsWith("tel:") || href.startsWith("javascript:")) return false;
            // Skip external links
            if (href.startsWith("http") && !href.startsWith(originStr)) return false;
            // Skip static assets
            if (/\.(png|jpg|jpeg|gif|svg|css|js|ico|woff|ttf|pdf)$/i.test(href)) return false;
            return true;
          })
          .map(href => {
            // Normalize to path-only
            if (href.startsWith("http")) {
              try { return new URL(href).pathname; } catch { return null; }
            }
            // Strip query params and hash
            return href.split("?")[0].split("#")[0];
          })
          .filter(Boolean);
      }, origin);

      // Add new links to the queue
      for (const link of links) {
        const norm = normalizePath(link);
        if (!visited.has(norm) && !queue.includes(norm)) {
          queue.push(norm);
        }
      }
    } catch (err) {
      console.error(`  ${DIM}skip ${path}: ${err.message}${NC}`);
    }
  }

  await page.close();
  await context.close();

  // Always include root
  if (!discovered.find(d => d.path === "/")) {
    discovered.unshift({ path: "/", title: "" });
  }

  return discovered.map(d => d.path);
}

function normalizePath(path) {
  // Strip trailing slash (except root), normalize double slashes
  let p = path.replace(/\/+/g, "/");
  if (p.length > 1 && p.endsWith("/")) p = p.slice(0, -1);
  return p || "/";
}

// --- Detect routes (taste.yml override OR filesystem fallback) ---
function detectConfiguredRoutes() {
  const config = loadTasteConfig();
  if (config && config.routes.length > 0) {
    return { routes: config.routes, mobileOnly: config.mobile || [] };
  }
  return null;
}

// --- Inject auth state into browser context ---
async function injectAuth(context, page, authConfig, url) {
  if (!authConfig) return;

  // Login flow: navigate to login page, fill credentials, submit
  if (authConfig.login_url && authConfig.email && authConfig.password) {
    const loginUrl = authConfig.login_url.startsWith("http")
      ? authConfig.login_url
      : `${url}${authConfig.login_url}`;

    console.error(`  ${DIM}logging in via ${loginUrl}...${NC}`);
    await page.goto(loginUrl, { waitUntil: "networkidle", timeout: cfg("taste.timeouts.page_load", 30000) });

    // Fill email — try custom selector, then common patterns
    const emailSelector = authConfig.email_selector
      || 'input[type="email"], input[name="email"], input[name="username"], input[id="email"], input[autocomplete="email"], input[autocomplete="username"]';
    try {
      await page.waitForSelector(emailSelector, { timeout: 5000 });
      await page.fill(emailSelector, authConfig.email);
    } catch {
      console.error(`  ${YELLOW}could not find email field (tried: ${emailSelector})${NC}`);
    }

    // Fill password
    const passwordSelector = authConfig.password_selector
      || 'input[type="password"], input[name="password"], input[id="password"]';
    try {
      await page.fill(passwordSelector, authConfig.password);
    } catch {
      console.error(`  ${YELLOW}could not find password field${NC}`);
    }

    // Submit — try custom selector, then common patterns, then Enter key
    const submitSelector = authConfig.submit_selector
      || 'button[type="submit"], input[type="submit"], button:has-text("Sign in"), button:has-text("Log in"), button:has-text("Login"), button:has-text("Continue")';
    try {
      const submitBtn = await page.$(submitSelector);
      if (submitBtn) {
        await submitBtn.click();
      } else {
        // Fallback: press Enter in the password field
        await page.press(passwordSelector, "Enter");
      }
    } catch {
      // Last resort: Enter key
      await page.keyboard.press("Enter");
    }

    // Wait for auth to complete
    const waitFor = authConfig.wait_for || "networkidle";
    try {
      if (waitFor === "networkidle" || waitFor === "domcontentloaded" || waitFor === "load") {
        await page.waitForLoadState(waitFor, { timeout: 15000 });
      } else {
        // waitFor is a selector — wait for it to appear (indicates successful login)
        await page.waitForSelector(waitFor, { timeout: 15000 });
      }
      // Extra settle time for SPAs that redirect after auth
      await page.waitForTimeout(2000);
      console.error(`  ${GREEN}✓${NC} logged in successfully`);
    } catch {
      console.error(`  ${YELLOW}login may have failed — continuing anyway${NC}`);
    }

    return; // Login flow handles everything, skip cookie/localStorage injection
  }

  // Inject cookies (manual fallback)
  if (authConfig.cookies?.length) {
    const parsedUrl = new URL(url);
    const cookies = authConfig.cookies.map(c => ({
      name: c.name,
      value: c.value,
      domain: c.domain || parsedUrl.hostname,
      path: c.path || "/",
    }));
    await context.addCookies(cookies);
    console.error(`  ${DIM}injected ${cookies.length} auth cookie(s)${NC}`);
  }

  // Inject localStorage (requires navigating first, then setting values)
  if (authConfig.localStorage && Object.keys(authConfig.localStorage).length > 0) {
    // Navigate to base URL to set localStorage on the correct origin
    await page.goto(url, { waitUntil: "domcontentloaded", timeout: cfg("taste.timeouts.page_load", 30000) });
    await page.evaluate((items) => {
      for (const [key, value] of Object.entries(items)) {
        localStorage.setItem(key, value);
      }
    }, authConfig.localStorage);
    console.error(`  ${DIM}injected ${Object.keys(authConfig.localStorage).length} localStorage item(s)${NC}`);
  }
}

// --- Screenshot routes ---
async function screenshotRoutes(browser, url, routeConfig, authConfig) {
  const screenshots = [];
  const context = await browser.newContext();
  const page = await context.newPage();

  // Inject auth before screenshotting
  await injectAuth(context, page, authConfig, url);

  const desktopVp = { width: cfg("taste.viewports.desktop.width", 1440), height: cfg("taste.viewports.desktop.height", 900), name: "desktop" };
  const mobileVp = { width: cfg("taste.viewports.mobile.width", 390), height: cfg("taste.viewports.mobile.height", 844), name: "mobile" };
  const { routes, mobileOnly = [] } = routeConfig;

  for (const route of routes) {
    // Desktop for all routes
    await page.setViewportSize({ width: desktopVp.width, height: desktopVp.height });
    try {
      await page.goto(`${url}${route}`, { waitUntil: "networkidle", timeout: cfg("taste.timeouts.page_load", 30000) });
      await page.waitForTimeout(cfg("taste.timeouts.post_load_wait", 1000));
      const buffer = await page.screenshot({ fullPage: true, type: "png" });
      screenshots.push({ route, viewport: "desktop", dimensions: `${desktopVp.width}x${desktopVp.height}`, base64: buffer.toString("base64") });
    } catch (err) {
      console.error(`  Failed: ${route} (desktop): ${err.message}`);
    }

    // Mobile only for specified routes
    if (mobileOnly.includes(route)) {
      await page.setViewportSize({ width: mobileVp.width, height: mobileVp.height });
      try {
        await page.goto(`${url}${route}`, { waitUntil: "networkidle", timeout: cfg("taste.timeouts.page_load", 30000) });
        await page.waitForTimeout(cfg("taste.timeouts.post_load_wait", 1000));
        const buffer = await page.screenshot({ fullPage: true, type: "png" });
        screenshots.push({ route, viewport: "mobile", dimensions: `${mobileVp.width}x${mobileVp.height}`, base64: buffer.toString("base64") });
      } catch (err) {
        console.error(`  Failed: ${route} (mobile): ${err.message}`);
      }
    }
  }

  await page.close();
  await context.close();
  return screenshots;
}

// --- Load intelligence layers ---
function loadContext() {
  const ctx = { landscape: null, taste: null, product: null, dimensionKnowledge: {}, founderTaste: null, designSystem: null };

  // Landscape positions (from scout)
  const landscapePath = join(process.env.HOME, ".claude", "knowledge", "landscape.json");
  if (existsSync(landscapePath)) {
    try {
      const data = JSON.parse(readFileSync(landscapePath, "utf-8"));
      ctx.landscape = data.positions
        ?.filter(p => p.confidence === "strong")
        .map(p => p.position)
        .join("\n- ") || null;
    } catch {}
  }

  // Taste profile (accumulated preferences)
  const tastePath = join(process.env.HOME, ".claude", "knowledge", "taste.jsonl");
  if (existsSync(tastePath)) {
    try {
      const lines = readFileSync(tastePath, "utf-8").trim().split("\n").slice(-20);
      const signals = lines.map(l => {
        try { const j = JSON.parse(l); return `[${j.strength}] ${j.signal}`; } catch { return null; }
      }).filter(Boolean);
      if (signals.length) ctx.taste = signals.join("\n- ");
    } catch {}
  }

  // Per-dimension taste knowledge (from /research-taste)
  const knowledgeDir = join(process.env.HOME, ".claude", "knowledge", "taste-knowledge");
  const dimensions = [
    "hierarchy", "breathing_room", "contrast", "polish", "emotional_tone",
    "information_density", "wayfinding", "distinctiveness", "scroll_experience",
    "layout_coherence", "information_architecture"
  ];
  ctx.dimensionKnowledge = {};
  for (const dim of dimensions) {
    const dimPath = join(knowledgeDir, `${dim}.md`);
    if (existsSync(dimPath)) {
      try {
        const content = readFileSync(dimPath, "utf-8");
        // Extract Patterns and Anti-Patterns sections (most useful for rubric)
        const patterns = content.match(/## Patterns[\s\S]*?(?=## |$)/)?.[0]?.trim() || "";
        const antiPatterns = content.match(/## Anti-Patterns[\s\S]*?(?=## |$)/)?.[0]?.trim() || "";
        const scoringGuide = content.match(/## Scoring Guide[\s\S]*?(?=## |$)/)?.[0]?.trim() || "";
        if (patterns || antiPatterns || scoringGuide) {
          ctx.dimensionKnowledge[dim] = { patterns, antiPatterns, scoringGuide };
        }
      } catch {}
    }
  }

  // Founder taste profile (structured preferences)
  const founderTastePath = join(process.env.HOME, ".claude", "knowledge", "founder-taste.md");
  if (existsSync(founderTastePath)) {
    try {
      const content = readFileSync(founderTastePath, "utf-8");
      // Extract the Preferences section
      const prefs = content.match(/## Preferences[\s\S]*/)?.[0]?.trim() || "";
      if (prefs && !prefs.includes("No preferences recorded yet")) {
        ctx.founderTaste = prefs;
      }
    } catch {}
  }

  // Design system document (project-specific visual rules)
  for (const p of [
    join(projectDir, ".claude", "design-system.md"),
    join(projectDir, "design-system.md"),
  ]) {
    if (existsSync(p)) {
      try {
        ctx.designSystem = readFileSync(p, "utf-8");
      } catch {}
      break;
    }
  }

  // Project CLAUDE.md (product context)
  for (const p of [
    join(projectDir, "CLAUDE.md"),
    join(projectDir, ".claude", "CLAUDE.md"),
  ]) {
    if (existsSync(p)) {
      try {
        const content = readFileSync(p, "utf-8");
        // Extract product section (first ~50 lines or until ## that isn't Product)
        const lines = content.split("\n").slice(0, 80);
        ctx.product = lines.join("\n");
      } catch {}
      break;
    }
  }

  return ctx;
}

// --- Build taste rubric prompt ---
function buildRubricPrompt(routes) {
  const ctx = loadContext();

  let marketSection = "";
  if (ctx.landscape) {
    marketSection = `\n## Market Context (from landscape intelligence)
You know these things about the market. Use them to calibrate your judgment:
- ${ctx.landscape}
`;
  }

  let tasteSection = "";
  if (ctx.taste) {
    tasteSection = `\n## Founder's Taste Profile (accumulated preferences)
This founder has shown these preferences. Weight your evaluation accordingly:
- ${ctx.taste}
`;
  }

  let productSection = "";
  if (ctx.product) {
    productSection = `\n## Product Context
${ctx.product}
`;
  }

  let knowledgeSection = "";
  if (ctx.dimensionKnowledge && Object.keys(ctx.dimensionKnowledge).length > 0) {
    knowledgeSection = `\n## Researched Taste Knowledge (use this to ground your evaluation)
The following dimensions have been researched with specific patterns, anti-patterns, and exemplars. Use this knowledge to make your evaluation SPECIFIC and GROUNDED rather than generic. When you score a dimension that has research, cite the specific pattern or anti-pattern you observed.\n`;
    for (const [dim, knowledge] of Object.entries(ctx.dimensionKnowledge)) {
      knowledgeSection += `\n### ${dim.toUpperCase()}\n`;
      if (knowledge.patterns) knowledgeSection += `${knowledge.patterns}\n`;
      if (knowledge.antiPatterns) knowledgeSection += `${knowledge.antiPatterns}\n`;
      if (knowledge.scoringGuide) knowledgeSection += `${knowledge.scoringGuide}\n`;
    }
  }

  let founderSection = "";
  if (ctx.founderTaste) {
    founderSection = `\n## Founder Taste Calibration (weight these preferences in your scoring)
${ctx.founderTaste}
`;
  }

  let designSystemSection = "";
  if (ctx.designSystem) {
    designSystemSection = `\n## Design System (THIS product's visual rules — use for slop detection)
The following design system has been documented for this specific product. When evaluating DISTINCTIVENESS and POLISH, check whether the screenshots follow these rules. Deviations from the design system are BUGS, not style choices. Components that look like framework defaults instead of matching the design system below should be flagged.

${ctx.designSystem}

**Slop detection upgrade**: Instead of asking "could AI have generated this?", ask "does this match the design system above?" Components that match = intentional. Components that don't = slop or regression.
`;
  }

  return `You are a first-time user who just landed on this product. You have never seen it before. You don't know what it does. You don't care about the code, the architecture, or the design system. You care about ONE thing: does this thing give you value fast enough that you'd come back?

You have the attention span of someone with 40 browser tabs open. You will leave in 5 seconds if you don't understand what this is and what to do next.
${productSection}${designSystemSection}${marketSection}${tasteSection}${knowledgeSection}${founderSection}
You are looking at screenshots of this application. Score each dimension 1-5 based on your EXPERIENCE as a real user seeing this cold — calibrated against products you actually use daily (Instagram, Discord, Notion, Linear, Arc). Those are the bar. Not "good for a student project." Not "good for an early product."

## STRUCTURAL AUDIT — Do This FIRST (before scoring anything else)

Before you score ANY of the experiential dimensions below, you must complete this structural audit. These two dimensions are GATES — if either scores 1-2, it caps the overall score at 2 regardless of how good individual screens feel. A product with broken layout or incoherent IA cannot score well overall. Pretty screens on a broken skeleton are lipstick on a pig.

### GATE 1: LAYOUT_COHERENCE (does the spatial system make sense?)

Look at ALL the screenshots together. Compare them side by side in your mind. Answer these questions BEFORE assigning a score:

1. **Grid consistency**: Do all pages share the same max-width? Same column structure? Or does one page use a centered narrow column while another goes full-width for no reason?
2. **Spacing system**: Are gaps between sections consistent across pages? Or does page A have tight spacing while page B is drowning in whitespace?
3. **Component sizing**: Are cards, buttons, inputs the same size across routes? Or does a card on one page look completely different from a card on another?
4. **Sidebar/nav dimensions**: If there's a sidebar or top nav, is it the same width/height on every page? Do content margins match?
5. **Mobile adaptation**: Does the mobile layout RETHINK content for thumb reach and small screens? Or does it just squeeze the desktop layout until it breaks?
6. **Proportions**: Do hero sections, content areas, and footers have intentional proportional relationships? Or are heights/widths arbitrary?

Score:
   5 = Airtight spatial system — I can see the same grid DNA on every page. Proportions are intentional. Mobile is rethought, not squeezed.
   3 = Mostly coherent but I spotted inconsistencies — a section that's wider than it should be, spacing that shifts between pages, mobile that just shrinks.
   1 = No layout system. Every page looks like it was built independently. Columns don't align, widths are random, gutters shift. This is spatial chaos.

### GATE 2: INFORMATION_ARCHITECTURE (can I build a mental model of this product?)

Look at the navigation, labels, and page structure across ALL screenshots. Answer these questions BEFORE assigning a score:

1. **Mental model**: Can you describe this product's organizing principle in one sentence? (e.g., "organized by: spaces → channels → messages" or "organized by: projects → tasks → subtasks") If you can't articulate it, the IA is broken.
2. **Navigation coverage**: Does the main nav reach all key destinations? Or are important features buried 3 clicks deep, behind modals, or hidden in hamburger menus?
3. **Grouping logic**: Are related features near each other? Or is "Create" in the sidebar but "Edit" in a completely different section?
4. **Label clarity**: Can you predict what's behind each nav item from the label alone? Or are there vague labels like "More", "Hub", "Explore" that could mean anything?
5. **Depth sanity**: Is the most important functionality at the top level? Or do trivial settings get prime nav real estate while core features are buried?
6. **Consistency**: Does the same concept appear in multiple places under different names? Are there redundant paths to the same destination?

Score:
   5 = Crystal clear mental model — I can predict where everything lives. Navigation maps directly to what the product does. Labels are self-explanatory. Depth matches importance.
   3 = I can navigate but the logic is fuzzy — some features are in unexpected places, labels require guessing, I have to remember paths rather than predict them.
   1 = No mental model possible. Features scattered randomly. Navigation doesn't map to the product's purpose. I would have to search/guess to find basic functionality.

**GATE RULE**: If EITHER layout_coherence or information_architecture scores ≤ 2, the overall score is CAPPED at 2. Rationale: a product with broken spatial structure or incoherent IA will confuse users no matter how polished individual screens are. Fix the skeleton before decorating.

---

## Experiential Dimensions (score these AFTER the structural audit)

1. **HIERARCHY** (do I know what this is and where to look?)
   5 = I understood what this product does and what to do first within 3 seconds
   3 = I can figure it out but had to scan around — nothing grabbed me
   1 = I have no idea what I'm looking at or what to do

2. **BREATHING_ROOM** (does this feel calm or chaotic?)
   5 = I feel relaxed looking at this — content is grouped, nothing is fighting for space
   3 = It's fine but feels a bit crowded or a bit empty — no rhythm
   1 = Overwhelming wall of stuff, or so empty I wonder if it's broken

3. **CONTRAST** (can I tell what's clickable?)
   5 = The main action is obvious, I know exactly what to tap/click without thinking
   3 = I can probably figure out what's interactive but nothing is pulling me toward it
   1 = Everything looks the same — I'd have to hover/tap randomly to discover what's clickable

4. **POLISH** (does this feel like someone cared?)
   5 = Smooth, responsive, things move intentionally — feels like a real product people use
   3 = Works but feels a bit lifeless or inconsistent — some parts polished, some rough
   1 = Feels broken or unfinished — jarring transitions, dead clicks, layout jumps

5. **EMOTIONAL_TONE** (would I tell a friend about this?)
   5 = This has personality — I can feel who it's for and it makes me want to explore
   3 = Neutral — competent but forgettable, I wouldn't mention it to anyone
   1 = Actively off-putting — feels corporate when it should be fun, or chaotic when it should be trustworthy

6. **INFORMATION_DENSITY** (do I feel informed or overwhelmed?)
   5 = I see exactly what I need, nothing I don't — content earns its space
   3 = Some useful info but also clutter, or too sparse to be useful without clicking deeper
   1 = Either drowning in data or staring at a near-empty screen wondering "where's the content?"

7. **WAYFINDING** (do I know what to do next?)
   5 = At every point I know where I am, what I can do, and how to get back — zero dead ends
   3 = I can navigate but hit a moment where I wasn't sure what to do or how to go back
   1 = I'm lost — no breadcrumbs, no obvious next step, I'd close the tab

8. **DISTINCTIVENESS** (would I recognize this tomorrow?)
   5 = This looks like ITSELF — I'd recognize it with the logo hidden
   3 = Competent but I've seen this template before — it's every shadcn/tailwind app
   1 = Pure framework defaults — literally indistinguishable from a tutorial project

9. **SCROLL_EXPERIENCE** (does scrolling feel intentional or accidental?)
   5 = Scrolling reveals content in a rhythm that keeps me engaged — sections arrive at the right pace, nothing feels too long or too short, sticky elements help me stay oriented
   3 = Scrolling works but nothing is designed around it — content just stacks vertically with no pacing, I lose track of where I am on long pages
   1 = Scrolling feels broken — endless empty space, sections that don't end, no landmarks, I'd stop scrolling and leave

## Research-Grounded Evaluation (CRITICAL)

Before scoring, you must establish an EXTERNAL reference frame. You are not judging against your own sense of "good" — you are comparing against the best real products that solve similar problems.

For each feature/route you evaluate:
1. Identify what category this screen is (profile page, feed, creation tool, community hub, settings, etc.)
2. Name the 2-3 BEST real products that have this same type of screen (e.g., profile → Discord, TikTok, BeReal; feed → TikTok, Instagram, Reddit; creation → Notion, Figma, Canva)
3. Compare what you see against those specific products — not abstract "good design"
4. Score based on how this holds up against those references

## Slop Check (MANDATORY for every screen)

For each route, answer: "Could this screen have been generated by prompting an AI with 'build me a [feature type] page'?"

If YES → the DISTINCTIVENESS score is capped at 2/5 regardless of polish.

What you are checking:
- Generic card grids with rounded corners and shadows → slop
- "Welcome back, [name]!" with a generic dashboard → slop
- Settings page that looks like every other settings page → slop
- A layout that could belong to ANY product if you hid the logo → slop

What breaks the slop pattern:
- A specific visual element that only makes sense for THIS product
- Copy/microcopy with personality (not "Get started" / "No items yet")
- An interaction pattern that serves THIS product's core loop
- Information displayed in a way that is unique to this domain

Cite the specific element that makes each screen NOT slop, or say "nothing — this is template energy."

## Rules
- You are a USER, not a designer. Score based on your gut reaction, not design theory.
- "I felt confused" beats "the visual hierarchy could be improved" — use first-person experience language.
- Cite what you FELT at specific moments: "I landed on the homepage and didn't know if this was a social app or a tool"
- Calibrate against your daily-use apps — that's the bar. Users don't grade on a curve.
- A score of 3 means "I wouldn't uninstall it but I wouldn't recommend it." 5 means "I'd show someone." 1 means "I'd close the tab."
- Be brutally honest. Most AI-generated UIs score 2-3. Most MVPs score 2-3. Say so.
- The product context tells you WHO this is for — judge whether the UI actually serves THOSE people, not abstract "users."

## Score Integrity (CRITICAL)
- Your scores are a diagnostic instrument, not a reward signal. Inflated scores are WORSE than harsh scores because they hide real problems.
- DO NOT be generous. DO NOT give benefit of the doubt. DO NOT round up. If you're unsure between 2 and 3, pick 2.
- A 5 on ANY dimension means this product is INDISTINGUISHABLE from the best consumer apps you use daily on that specific axis. This is extremely rare for any product, let alone an early-stage one.
- A 4 means "genuinely good — I noticed something intentional and well-executed." Most products don't earn this on most dimensions.
- Expected distribution for a typical product: mostly 2s and 3s, maybe one 4 if something is genuinely strong, 5s are exceptional.
- If you give an overall score of 4+, you must justify why this product stands alongside Notion/Linear/Discord on EACH high-scoring dimension. If you can't, lower the score.
- Previous scores should NOT anchor you. If a prior eval scored hierarchy 4/5 but the screenshots show confusion, score it honestly now. Scores can go DOWN.

## Output Format (strict JSON)
{
  "overall": <number 1-5>,
  "dimensions": {
    "hierarchy": { "score": <1-5>, "evidence": "<what you experienced — first person>" },
    "breathing_room": { "score": <1-5>, "evidence": "<what you experienced>" },
    "contrast": { "score": <1-5>, "evidence": "<what you experienced>" },
    "polish": { "score": <1-5>, "evidence": "<what you experienced>" },
    "emotional_tone": { "score": <1-5>, "evidence": "<what you experienced>" },
    "information_density": { "score": <1-5>, "evidence": "<what you experienced>" },
    "wayfinding": { "score": <1-5>, "evidence": "<what you experienced>" },
    "distinctiveness": { "score": <1-5>, "evidence": "<what you experienced>" },
    "scroll_experience": { "score": <1-5>, "evidence": "<what you experienced scrolling through — section pacing, sticky headers, parallax, content reveal>" },
    "layout_coherence": { "score": <1-5>, "evidence": "<what you observed about grid, alignment, spacing consistency across pages — cite specific mismatches>" },
    "information_architecture": { "score": <1-5>, "evidence": "<what you observed about nav structure, content grouping, label clarity, mental model — cite where you got lost or where things don't belong>" }
  },
  "strongest": "<which dimension and why — as a user>",
  "weakest": "<which dimension and the specific moment you felt it fail>",
  "would_return": "<yes/no and the honest reason — what would bring you back or what's missing>",
  "would_recommend": "<yes/no and who you'd tell or why you wouldn't>",
  "one_thing": "<the single change that would make you come back — be specific, not generic>"
}

Routes screenshotted: ${routes.join(", ")}
Respond with ONLY the JSON object, no markdown fences.`;
}

// --- Call Claude via CLI (uses OAuth, no API key needed) ---
async function evaluateWithClaude(screenshots, routes, screenshotDir) {
  // Save screenshots to disk so claude CLI can read them
  const savedPaths = [];
  const maxScreenshots = cfg("taste.max_screenshots", 12);
  const selected = screenshots.slice(0, maxScreenshots);

  for (const ss of selected) {
    const filename = `${ss.route.replace(/\//g, "_") || "root"}-${ss.viewport}.png`;
    const filepath = join(screenshotDir, filename);
    writeFileSync(filepath, Buffer.from(ss.base64, "base64"));
    savedPaths.push({ path: filepath, route: ss.route, viewport: ss.viewport, dimensions: ss.dimensions });
  }

  // Build prompt — tell Claude to read the screenshot files
  let prompt = buildRubricPrompt(routes);
  prompt += "\n\nRead each screenshot file below using the Read tool, then evaluate what you see.\n";
  for (const s of savedPaths) {
    prompt += `\n- ${s.path} (${s.route} — ${s.viewport} ${s.dimensions || ""})`;
  }
  prompt += "\n\nAfter reading ALL screenshots, respond with ONLY the JSON object.";

  // Build claude args array (no shell interpolation — safe from injection)
  const claudeArgs = ["-p", "--output-format", "text", "--allowedTools", "Read"];

  try {
    const output = execSync(`CLAUDECODE= claude ${claudeArgs.map(a => `'${a.replace(/'/g, "'\\''")}'`).join(" ")}`, {
      encoding: "utf-8",
      input: prompt,
      maxBuffer: 10 * 1024 * 1024,
      timeout: cfg("taste.timeouts.eval_timeout", 180000),
      shell: true,
    });

    // Parse JSON response
    const text = output.trim();
    try {
      return JSON.parse(text);
    } catch {
      const match = text.match(/\{[\s\S]*\}/);
      if (match) return JSON.parse(match[0]);
      throw new Error(`Failed to parse Claude response as JSON:\n${text}`);
    }
  } catch (err) {
    if (err.status) {
      throw new Error(`claude CLI failed (exit ${err.status}). Is claude installed and authenticated?\n${err.stderr || ""}`);
    }
    throw err;
  }
}

// --- Check if server is already running on a port ---
async function isPortActive(portNum) {
  const check = async () => {
    try {
      const resp = await fetch(`http://localhost:${portNum}`, { signal: AbortSignal.timeout(cfg("taste.timeouts.port_check", 5000)) });
      return resp.ok || resp.status < 500;
    } catch {
      return false;
    }
  };
  // Double-check with a gap to avoid false positives (e.g. server shutting down)
  if (!await check()) return false;
  await new Promise(r => setTimeout(r, 500));
  return check();
}

// --- Start dev server ---
async function startDevServer(dir) {
  const pkgPath = join(dir, "package.json");
  if (!existsSync(pkgPath)) {
    throw new Error("No package.json found. Provide --url instead.");
  }

  const pkg = JSON.parse(readFileSync(pkgPath, "utf-8"));
  const scripts = pkg.scripts || {};

  // Determine dev command and port
  let devCmd = "dev";
  let detectedPort = 3000;

  if (scripts.dev) {
    const portMatch = scripts.dev.match(/-p\s*(\d+)|--port\s*(\d+)|PORT=(\d+)/);
    if (portMatch) detectedPort = parseInt(portMatch[1] || portMatch[2] || portMatch[3]);
  }

  if (port) detectedPort = port;

  // Check if server is already running
  if (await isPortActive(detectedPort)) {
    const serverUrl = `http://localhost:${detectedPort}`;
    stopSpinner(`dev server already running at ${serverUrl}`);
    return { url: serverUrl, process: null, port: detectedPort };
  }

  startSpinner(`starting dev server on port ${detectedPort}...`);

  const child = spawn("npm", ["run", devCmd], {
    cwd: dir,
    stdio: "pipe",
    env: { ...process.env, PORT: String(detectedPort) },
  });

  // Wait for server to be ready
  const serverUrl = `http://localhost:${detectedPort}`;
  let ready = false;
  let attempts = 0;

  while (!ready && attempts < 60) {
    attempts++;
    try {
      await fetch(serverUrl, { signal: AbortSignal.timeout(cfg("taste.timeouts.server_startup", 3000)) });
      ready = true;
    } catch {
      await new Promise(r => setTimeout(r, 1000));
    }
  }

  if (!ready) {
    child.kill();
    throw new Error(`Dev server failed to start on port ${detectedPort} after 60s`);
  }

  stopSpinner(`dev server ready at ${serverUrl}`);
  return { url: serverUrl, process: child, port: detectedPort };
}

// --- Main ---
async function main() {
  // Check for claude CLI
  try {
    execSync("which claude", { stdio: "pipe" });
  } catch {
    console.error("Error: claude CLI not found. Install Claude Code first.");
    process.exit(1);
  }

  console.error(`${BOLD}=== founder taste — visual product evaluation ===${NC}\n`);

  if (researchFirst) {
    console.error(`${YELLOW}--research flag: run /research-taste before taste eval for grounded scoring${NC}`);
    console.error(`${DIM}  Skipping auto-research (requires interactive Claude session)${NC}`);
    console.error(`${DIM}  Run: /research-taste all${NC}`);
  }

  // --- Freshness check ---
  const reportDir = join(projectDir, ".claude", "evals", "reports");
  const CACHE_MAX_AGE = cfg("taste.cache_ttl", 7200) * 1000;

  if (!force && existsSync(reportDir)) {
    const today = new Date().toISOString().slice(0, 10);
    const todayReport = join(reportDir, `taste-${today}.json`);
    if (existsSync(todayReport)) {
      const age = Date.now() - statSync(todayReport).mtimeMs;
      if (age < CACHE_MAX_AGE) {
        const cached = JSON.parse(readFileSync(todayReport, "utf-8"));
        const ageMin = Math.round(age / 60000);
        console.error(`${YELLOW}  Eval already ran ${ageMin}m ago. Use --force to re-run.${NC}\n`);

        // Show the cached result
        switch (outputMode) {
          case "json": console.log(JSON.stringify(cached)); break;
          case "score": console.log(cached.score_100); break;
          default:
            console.log(`=== Taste Score: ${cached.score_100}/100 (${cached.overall}/5) ===\n`);
            for (const [dim, data] of Object.entries(cached.dimensions)) {
              const bar = "█".repeat(data.score) + "░".repeat(5 - data.score);
              console.log(`  ${dim.padEnd(20)} ${bar} ${data.score}/5`);
              console.log(`  ${"".padEnd(20)} ${data.evidence}\n`);
            }
            console.log(`  Strongest: ${cached.strongest}`);
            console.log(`  Weakest:   ${cached.weakest}`);
            if (cached.would_return) console.log(`\n  Return?    ${cached.would_return}`);
            if (cached.would_recommend) console.log(`  Recommend? ${cached.would_recommend}`);
            console.log(`\n  → ${cached.one_thing}`);
        }
        return;
      }
    }
  }

  // Load features map (optional)
  const features = loadFeatures();

  // If --feature flag, validate it exists
  if (featureFilter && features) {
    if (!features[featureFilter]) {
      console.error(`Error: feature "${featureFilter}" not found in .claude/features.yml`);
      console.error(`Available features: ${Object.keys(features).join(", ")}`);
      process.exit(1);
    }
  } else if (featureFilter && !features) {
    console.error(`Error: --feature requires .claude/features.yml to exist`);
    process.exit(1);
  }

  // Start or connect to dev server
  let server = null;
  let url = baseUrl;

  if (!url) {
    startSpinner("checking dev server...");
    server = await startDevServer(projectDir);
    url = server.url;
  }

  try {
    // Launch Playwright
    startSpinner("launching browser...");
    const browser = await chromium.launch({ headless: true });
    stopSpinner("browser ready");

    // Load auth config from taste.yml
    const tasteConfig = loadTasteConfig();
    const authConfig = tasteConfig?.auth || null;
    if (authConfig) {
      console.error(`  ${GREEN}✓${NC} auth config loaded (${authConfig.cookies?.length || 0} cookies, ${Object.keys(authConfig.localStorage || {}).length} localStorage items)`);
    }

    // Determine routes: explicit config > feature filter > browse-and-discover
    let routes;
    let mobileOnly = ["/"];
    const featureLabel = featureFilter ? ` [feature: ${featureFilter}]` : "";

    if (featureFilter && features) {
      routes = features[featureFilter].routes;
      console.error(`  ${GREEN}✓${NC} feature routes: ${routes.join(", ")}`);
    } else {
      const configured = detectConfiguredRoutes();
      if (configured) {
        routes = configured.routes;
        mobileOnly = configured.mobileOnly;
        console.error(`  ${GREEN}✓${NC} routes from taste.yml: ${routes.join(", ")}`);
      } else {
        // Browse the app like a user — discover routes by following links
        startSpinner("browsing app to discover routes...");
        routes = await discoverRoutes(browser, url, authConfig);
        stopSpinner(`discovered ${routes.length} routes${featureLabel}: ${routes.join(", ")}`);
      }
    }

    // Screenshot discovered routes
    const routeConfig = { routes, mobileOnly };
    const mobileCount = routes.filter(r => mobileOnly.includes(r)).length;
    const totalShots = routes.length + mobileCount;
    startSpinner(`screenshotting ${totalShots} views (${routes.length} desktop + ${mobileCount} mobile)...`);
    const screenshots = await screenshotRoutes(browser, url, routeConfig, authConfig);
    stopSpinner(`captured ${screenshots.length} screenshots`);

    await browser.close();

    if (screenshots.length === 0) {
      throw new Error("No screenshots captured — dev server may have died. Check that `npm run dev` works and try again.");
    }

    // Save screenshots and evaluate with Claude via CLI (OAuth)
    const screenshotDir = join(projectDir, ".claude", "evals", "screenshots");
    mkdirSync(screenshotDir, { recursive: true });

    startSpinner("evaluating with Claude vision (this takes ~30s)...");
    const result = await evaluateWithClaude(screenshots, routes, screenshotDir);
    stopSpinner("evaluation complete");

    // Open screenshots for founder to see (--open flag or TASTE_OPEN env)
    if (openScreenshots || process.env.TASTE_OPEN === "1") {
      try {
        const pngs = readdirSync(screenshotDir).filter(f => f.endsWith(".png")).map(f => join(screenshotDir, f));
        if (pngs.length > 0) {
          execSync(`open ${pngs.map(p => `"${p}"`).join(" ")}`, { stdio: "ignore" });
          console.error(`\n  ${GREEN}Opened ${pngs.length} screenshots in Preview — see what Claude sees${NC}`);
        }
      } catch { /* non-fatal — Preview might not be available */ }
    }

    // --- Integrity checks on evaluator output ---
    // taste.mjs must validate its own output, just like score.sh does.
    // The rubric tells Claude to be honest. This code VERIFIES it was.
    const integrityWarnings = [];

    if (result.dimensions) {
      const scores = Object.values(result.dimensions).map(d => d.score);
      const avg = scores.reduce((a, b) => a + b, 0) / scores.length;
      const min = Math.min(...scores);
      const max = Math.max(...scores);
      const allSame = new Set(scores).size === 1;

      // Check 1: Suspiciously generous (avg > 3.5 for non-mature products)
      const stage = cfg("project.stage", "mvp");
      const generousThreshold = stage === "mature" ? 4.0 : 3.5;
      if (avg > generousThreshold) {
        integrityWarnings.push(`GENEROUS: avg ${avg.toFixed(1)}/5 exceeds ${generousThreshold} threshold for ${stage} stage. Expected mostly 2s and 3s.`);
      }

      // Check 2: No weakness found (every product has weaknesses)
      if (min >= 4) {
        integrityWarnings.push(`NO_WEAKNESS: lowest dimension is ${min}/5. Every product has at least one dimension below 4. Evaluator may be inflating.`);
      }

      // Check 3: No discrimination (all scores the same = bad evaluation)
      if (allSame && scores.length > 3) {
        integrityWarnings.push(`FLAT_EVAL: all ${scores.length} dimensions scored ${scores[0]}/5. No discrimination between dimensions = unreliable evaluation.`);
      }

      // Check 4: Structural gate — layout_coherence and information_architecture cap overall
      const layoutScore = result.dimensions.layout_coherence?.score;
      const iaScore = result.dimensions.information_architecture?.score;
      const gateMin = Math.min(layoutScore || 5, iaScore || 5);
      if (gateMin <= 2 && result.overall > 2) {
        const gateLabel = (layoutScore <= 2 && iaScore <= 2) ? "layout_coherence AND information_architecture"
          : layoutScore <= 2 ? "layout_coherence" : "information_architecture";
        integrityWarnings.push(`STRUCTURAL_GATE: ${gateLabel} scored ${gateMin}/5. Overall capped from ${result.overall} to 2. Fix the skeleton before decorating.`);
        result.overall_uncapped = result.overall;
        result.overall = 2;
      }

      // Check 5: Score jump vs previous eval (if taste-history.tsv exists)
      const historyPath = join(projectDir, ".claude", "evals", "taste-history.tsv");
      if (existsSync(historyPath)) {
        const lines = readFileSync(historyPath, "utf-8").trim().split("\n");
        if (lines.length >= 2) { // header + at least one prior entry
          const lastLine = lines[lines.length - 1].split("\t");
          const prevOverall = parseFloat(lastLine[1]);
          if (!isNaN(prevOverall) && result.overall) {
            const delta = result.overall - prevOverall;
            if (delta > 1.5) {
              integrityWarnings.push(`JUMP: overall ${prevOverall.toFixed(1)} → ${result.overall}/5 (+${delta.toFixed(1)}). Jumps >1.5 between evals are suspicious without major changes.`);
            }
          }
        }
      }
    }

    if (integrityWarnings.length > 0) {
      result.integrity_warnings = integrityWarnings;
      console.error(`\n  ${YELLOW}⚠ Taste Integrity Warnings:${NC}`);
      for (const w of integrityWarnings) {
        console.error(`    ${YELLOW}· ${w}${NC}`);
      }
      console.error("");
    }

    // Add metadata
    result.meta = {
      project: projectDir,
      routes: routes.length,
      screenshots: screenshots.length,
      timestamp: new Date().toISOString(),
      evaluator: "claude-vision",
    };

    // Convert 1-5 to 0-100 for consistency with score.sh
    result.score_100 = Math.round((result.overall / 5) * 100);

    // Add structured weakest_dimension for builder handoff (taste → builder)
    if (result.dimensions) {
      let minScore = 6, minDim = "";
      for (const [dim, data] of Object.entries(result.dimensions)) {
        if (data.score < minScore) { minScore = data.score; minDim = dim; }
      }
      if (minDim) result.weakest_dimension = minDim;
    }

    // Add feature info if features.yml exists
    if (featureFilter) {
      result.feature = featureFilter;
    } else if (features && result.dimensions) {
      // Group dimensions by feature — identify weakest dimension per feature based on its routes
      result.features = {};
      for (const [fname, fdata] of Object.entries(features)) {
        let minScore = 6, minDim = "";
        for (const [dim, ddata] of Object.entries(result.dimensions)) {
          if (ddata.score < minScore) { minScore = ddata.score; minDim = dim; }
        }
        result.features[fname] = { routes: fdata.routes, weakest_dimension: minDim };
      }
    }

    // Save result
    mkdirSync(reportDir, { recursive: true });
    const reportPath = join(reportDir, `taste-${new Date().toISOString().slice(0, 10)}.json`);
    writeFileSync(reportPath, JSON.stringify(result, null, 2));
    console.error(`\n  ${GREEN}Report saved: ${reportPath}${NC}\n`);

    // Append to taste history TSV for trend tracking
    const historyPath = join(projectDir, ".claude", "evals", "taste-history.tsv");
    const historyDir = join(projectDir, ".claude", "evals");
    mkdirSync(historyDir, { recursive: true });
    if (!existsSync(historyPath)) {
      writeFileSync(historyPath, "timestamp\toverall\tweakest_dimension\tone_thing\tfeature\n");
    }
    const historyLine = [
      new Date().toISOString(),
      result.overall || "",
      result.weakest_dimension || "",
      (result.one_thing || "").replace(/\t/g, " ").replace(/\n/g, " "),
      featureFilter || "all",
    ].join("\t") + "\n";
    appendFileSync(historyPath, historyLine);

    // Output
    switch (outputMode) {
      case "json":
        console.log(JSON.stringify(result));
        break;
      case "score":
        console.log(result.score_100);
        break;
      case "breakdown":
      default:
        console.log(`=== Taste Score: ${result.score_100}/100 (${result.overall}/5) ===\n`);
        for (const [dim, data] of Object.entries(result.dimensions)) {
          const bar = "█".repeat(data.score) + "░".repeat(5 - data.score);
          console.log(`  ${dim.padEnd(20)} ${bar} ${data.score}/5`);
          console.log(`  ${"".padEnd(20)} ${data.evidence}\n`);
        }
        console.log(`  Strongest: ${result.strongest}`);
        console.log(`  Weakest:   ${result.weakest}`);
        if (result.would_return) console.log(`\n  Return?    ${result.would_return}`);
        if (result.would_recommend) console.log(`  Recommend? ${result.would_recommend}`);
        console.log(`\n  → ${result.one_thing}`);
        break;
    }
  } finally {
    if (server?.process) {
      server.process.kill();
      console.error("\n  Dev server stopped.");
    }
  }
}

main().catch(err => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});
