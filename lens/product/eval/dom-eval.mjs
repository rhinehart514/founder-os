#!/usr/bin/env node

/**
 * dom-eval.mjs — Tier 1 mechanical DOM evaluator
 *
 * No LLM needed. Uses axe-core for accessibility + page.evaluate() for
 * layout metrics. The ungameable UX foundation.
 *
 * Usage:
 *   node dom-eval.mjs --url <url> [--json] [--eval]
 *
 * Checks:
 *   - contrast: WCAG AA pass/fail count (via axe-core)
 *   - hierarchy: h1 > h2 > body font-size verified
 *   - targets: click targets < 44px count
 *   - density: interactive elements per viewport
 *   - whitespace: content area / viewport ratio (layout-based)
 *   - distinctiveness: non-default styling check
 *
 * --eval mode outputs one line per check: metric:pass|fail:detail
 * --json mode outputs full JSON
 *
 * Requires:
 *   - playwright (npx playwright install chromium)
 *   - @axe-core/playwright
 */

import { chromium } from "playwright";
import AxeBuilder from "@axe-core/playwright";

// --- Display ---
const DIM = "\x1b[2m";
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
  console.error("Usage: node dom-eval.mjs --url <url> [--json] [--eval]");
  process.exit(1);
}

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

  const results = {};

  // 1. Contrast — WCAG AA via axe-core
  try {
    const axeResults = await new AxeBuilder({ page })
      .withRules(["color-contrast"])
      .analyze();
    const violation = axeResults.violations.find(v => v.id === "color-contrast");
    const count = violation ? violation.nodes.length : 0;
    results.contrast = {
      pass: count === 0,
      violations: count,
      detail: violation
        ? violation.nodes.slice(0, 5).map(n => ({
            html: n.html.slice(0, 100),
            message: n.any?.[0]?.message || "",
          }))
        : [],
    };
  } catch (e) {
    results.contrast = { pass: false, violations: -1, error: e.message };
  }

  // 2. Hierarchy — h1 > h2 > body font-size
  try {
    const h = await page.evaluate(() => {
      const body = document.body;
      const h1s = [...document.querySelectorAll("h1")];
      const h2s = [...document.querySelectorAll("h2")];
      const bodySize = parseFloat(getComputedStyle(body).fontSize);
      const h1Sizes = h1s.map(el => parseFloat(getComputedStyle(el).fontSize));
      const h2Sizes = h2s.map(el => parseFloat(getComputedStyle(el).fontSize));
      const maxH1 = h1Sizes.length ? Math.max(...h1Sizes) : 0;
      const maxH2 = h2Sizes.length ? Math.max(...h2Sizes) : 0;
      return { bodySize, maxH1, maxH2, h1Count: h1s.length, h2Count: h2s.length };
    });
    const valid = h.h1Count > 0 && h.maxH1 > h.maxH2 && (h.h2Count === 0 || h.maxH2 > h.bodySize);
    results.hierarchy = {
      pass: valid,
      h1_max: h.maxH1,
      h2_max: h.maxH2,
      body_size: h.bodySize,
      h1_count: h.h1Count,
      h2_count: h.h2Count,
    };
  } catch (e) {
    results.hierarchy = { pass: false, error: e.message };
  }

  // 3. Click targets — elements < 44px
  try {
    const t = await page.evaluate(() => {
      const els = document.querySelectorAll(
        "a, button, input, select, textarea, [role='button'], [role='link'], [tabindex]"
      );
      const small = [];
      let total = 0;
      for (const el of els) {
        const rect = el.getBoundingClientRect();
        if (rect.width === 0 && rect.height === 0) continue;
        total++;
        if (rect.width < 44 || rect.height < 44) {
          small.push({
            tag: el.tagName.toLowerCase(),
            text: (el.textContent || "").trim().slice(0, 50),
            width: Math.round(rect.width),
            height: Math.round(rect.height),
          });
        }
      }
      return { total, smallCount: small.length, small: small.slice(0, 10) };
    });
    results.targets = {
      pass: t.smallCount === 0,
      total_interactive: t.total,
      undersized: t.smallCount,
      examples: t.small,
    };
  } catch (e) {
    results.targets = { pass: false, error: e.message };
  }

  // 4. Density — interactive elements per viewport
  try {
    const d = await page.evaluate(() => {
      const els = document.querySelectorAll(
        "a, button, input, select, textarea, [role='button'], [role='link']"
      );
      let inViewport = 0;
      for (const el of els) {
        const rect = el.getBoundingClientRect();
        if (
          rect.top < window.innerHeight && rect.bottom > 0 &&
          rect.left < window.innerWidth && rect.right > 0
        ) {
          inViewport++;
        }
      }
      return { inViewport };
    });
    results.density = {
      pass: d.inViewport >= 1 && d.inViewport <= 50,
      interactive_in_viewport: d.inViewport,
    };
  } catch (e) {
    results.density = { pass: false, error: e.message };
  }

  // 5. Whitespace — content area vs viewport (layout-based)
  try {
    const w = await page.evaluate(() => {
      const vw = window.innerWidth;
      const vh = window.innerHeight;
      const vArea = vw * vh;
      let contentArea = 0;
      for (const el of document.querySelectorAll("*")) {
        const style = getComputedStyle(el);
        if (style.display === "none" || style.visibility === "hidden") continue;
        if (el.children.length > 0) continue; // leaf nodes only
        const rect = el.getBoundingClientRect();
        if (rect.width === 0 || rect.height === 0) continue;
        if (rect.bottom < 0 || rect.top > vh) continue;
        const top = Math.max(0, rect.top);
        const bottom = Math.min(vh, rect.bottom);
        const left = Math.max(0, rect.left);
        const right = Math.min(vw, rect.right);
        contentArea += (right - left) * (bottom - top);
      }
      const ratio = Math.min(contentArea / vArea, 1);
      return { contentRatio: ratio, whitespaceRatio: 1 - ratio };
    });
    results.whitespace = {
      pass: w.whitespaceRatio >= 0.15 && w.whitespaceRatio <= 0.75,
      content_ratio: Math.round(w.contentRatio * 100) / 100,
      whitespace_ratio: Math.round(w.whitespaceRatio * 100) / 100,
    };
  } catch (e) {
    results.whitespace = { pass: false, error: e.message };
  }

  // 6. Distinctiveness — non-default styling
  try {
    const ds = await page.evaluate(() => {
      const bodyStyle = getComputedStyle(document.body);
      const bgColor = bodyStyle.backgroundColor;
      const fontFamily = bodyStyle.fontFamily.toLowerCase();
      const isDefaultBg =
        bgColor === "rgb(255, 255, 255)" ||
        bgColor === "rgba(0, 0, 0, 0)" ||
        bgColor === "white";
      const isInterFont = fontFamily.includes("inter");
      let hasCustomColor = false;
      for (const el of document.querySelectorAll("*")) {
        const bg = getComputedStyle(el).backgroundColor;
        if (
          bg &&
          bg !== "rgba(0, 0, 0, 0)" &&
          bg !== "rgb(255, 255, 255)" &&
          bg !== "rgb(0, 0, 0)"
        ) {
          hasCustomColor = true;
          break;
        }
      }
      return {
        fontFamily: bodyStyle.fontFamily.slice(0, 100),
        bgColor,
        isDefaultBg,
        isInterFont,
        hasCustomColor,
        distinct: !isInterFont || !isDefaultBg || hasCustomColor,
      };
    });
    results.distinctiveness = {
      pass: ds.distinct,
      font_family: ds.fontFamily,
      bg_color: ds.bgColor,
      has_custom_color: ds.hasCustomColor,
    };
  } catch (e) {
    results.distinctiveness = { pass: false, error: e.message };
  }

  await browser.close();
  return results;
}

// --- Run ---
const results = await runChecks();
const passCount = Object.values(results).filter(r => r.pass).length;
const failCount = Object.values(results).filter(r => !r.pass).length;
const total = passCount + failCount;

if (evalOutput) {
  // Machine-readable for eval.sh: metric:pass|fail:detail
  for (const [name, r] of Object.entries(results)) {
    const status = r.pass ? "pass" : "fail";
    let detail = "";
    if (name === "contrast") detail = `${r.violations} WCAG AA violations`;
    else if (name === "hierarchy") detail = `h1=${r.h1_max || 0}px h2=${r.h2_max || 0}px body=${r.body_size || 0}px`;
    else if (name === "targets") detail = `${r.undersized || 0}/${r.total_interactive || 0} undersized`;
    else if (name === "density") detail = `${r.interactive_in_viewport || 0} interactive in viewport`;
    else if (name === "whitespace") detail = `${Math.round((r.whitespace_ratio || 0) * 100)}% whitespace`;
    else if (name === "distinctiveness") detail = r.pass ? "custom styling detected" : "default/generic styling";
    console.log(`${name}:${status}:${detail}`);
  }
} else if (jsonOutput) {
  console.log(JSON.stringify({ url, checks: results, summary: { pass: passCount, fail: failCount, total } }, null, 2));
} else {
  console.log(`${BOLD}dom-eval${NC} — ${url}`);
  console.log("");
  for (const [name, r] of Object.entries(results)) {
    const icon = r.pass ? `${GREEN}[PASS]${NC}` : `${RED}[FAIL]${NC}`;
    let detail = "";
    if (name === "contrast") detail = `${r.violations} WCAG AA violations`;
    else if (name === "hierarchy") detail = `h1:${r.h1_max || 0}px h2:${r.h2_max || 0}px body:${r.body_size || 0}px`;
    else if (name === "targets") detail = `${r.undersized || 0}/${r.total_interactive || 0} undersized (<44px)`;
    else if (name === "density") detail = `${r.interactive_in_viewport || 0} interactive elements in viewport`;
    else if (name === "whitespace") detail = `${Math.round((r.whitespace_ratio || 0) * 100)}% whitespace`;
    else if (name === "distinctiveness") detail = r.pass ? "custom styling detected" : "default/generic styling";
    console.log(`  ${icon} ${name}    ${detail}`);
  }
  console.log("");
  console.log(`${passCount}/${total} checks passed`);
}

process.exit(failCount > 0 ? 1 : 0);
