#!/usr/bin/env node

/**
 * blind-eval.mjs — Blind agent behavioral evaluator (the val_bpb)
 *
 * The one signal that can't be gamed. A blind Claude agent (no product
 * context) attempts a task on the running product. Records pass/fail,
 * timing, clicks, and confusion points.
 *
 * Usage:
 *   node blind-eval.mjs --url <url> --task <description> [--timeout 180] [--json] [--eval]
 *
 * The agent sees:
 *   1. A screenshot of the current page state
 *   2. A list of interactive elements with indices
 *   3. The task description
 *
 * It does NOT see: product name context, documentation, or hints.
 *
 * --eval mode outputs: metric:pass|fail:detail
 *
 * Requires: playwright, claude CLI (for agent reasoning via OAuth)
 */

import { chromium } from "playwright";
import { execSync } from "child_process";
import { writeFileSync, mkdirSync, rmSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";

const BOLD = "\x1b[1m";
const GREEN = "\x1b[32m";
const RED = "\x1b[31m";
const DIM = "\x1b[2m";
const NC = "\x1b[0m";

// --- CLI args ---
const args = process.argv.slice(2);
let url = null;
let task = null;
let timeoutSec = 180;
let jsonOutput = false;
let evalOutput = false;

for (let i = 0; i < args.length; i++) {
  if (args[i] === "--url" && args[i + 1]) url = args[++i];
  else if (args[i] === "--task" && args[i + 1]) task = args[++i];
  else if (args[i] === "--timeout" && args[i + 1]) timeoutSec = parseInt(args[++i], 10);
  else if (args[i] === "--json") jsonOutput = true;
  else if (args[i] === "--eval") evalOutput = true;
}

if (!url || !task) {
  console.error("Usage: node blind-eval.mjs --url <url> --task <description> [--timeout 180] [--json] [--eval]");
  process.exit(1);
}

// --- Claude CLI helper ---
function askClaude(prompt) {
  try {
    const output = execSync(
      `CLAUDECODE= claude -p --output-format text --allowedTools Read`,
      {
        encoding: "utf-8",
        input: prompt,
        maxBuffer: 10 * 1024 * 1024,
        timeout: 60000,
        shell: true,
      }
    );
    return output.trim();
  } catch (e) {
    return JSON.stringify({ action: "stuck", reasoning: `Claude CLI error: ${e.message}` });
  }
}

// --- Get interactive elements ---
async function getElements(page) {
  return page.evaluate(() => {
    const selectors = "a, button, input, select, textarea, [role='button'], [role='link'], [tabindex], [onclick]";
    const els = [...document.querySelectorAll(selectors)];
    const result = [];
    let idx = 0;
    for (const el of els) {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 && rect.height === 0) continue;
      if (rect.top > window.innerHeight * 2) continue; // skip far off-screen
      const text = (el.textContent || "").trim().slice(0, 60);
      const tag = el.tagName.toLowerCase();
      const role = el.getAttribute("role") || tag;
      const type = el.getAttribute("type") || "";
      const placeholder = el.getAttribute("placeholder") || "";
      const ariaLabel = el.getAttribute("aria-label") || "";
      result.push({
        idx: idx++,
        tag,
        role,
        type,
        text: text || placeholder || ariaLabel || `[${tag}]`,
        x: Math.round(rect.left + rect.width / 2),
        y: Math.round(rect.top + rect.height / 2),
        width: Math.round(rect.width),
        height: Math.round(rect.height),
        visible: rect.top < window.innerHeight && rect.bottom > 0,
      });
    }
    return result;
  });
}

async function runBlindEval() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });

  const tmpDir = join(tmpdir(), `blind-eval-${Date.now()}`);
  mkdirSync(tmpDir, { recursive: true });

  try {
    await page.goto(url, { waitUntil: "networkidle", timeout: 30000 });
    await page.waitForTimeout(1000);
  } catch (e) {
    await browser.close();
    return { pass: false, time_seconds: 0, click_count: 0, error: `Failed to load: ${e.message}` };
  }

  const startTime = Date.now();
  const timeoutMs = timeoutSec * 1000;
  const maxSteps = 15;
  let clicks = 0;
  let stepsUsed = 0;
  let lastUrl = url;
  const confusionNotes = [];
  let completed = false;

  // Capture initial page text for value-visible comparison
  let initialText = "";
  try {
    initialText = await page.evaluate(() => document.body.innerText.slice(0, 1000));
  } catch {}

  for (let step = 0; step < maxSteps; step++) {
    stepsUsed = step + 1;
    if (Date.now() - startTime > timeoutMs) break;

    // Get current state
    const screenshotPath = join(tmpDir, `step-${step}.png`);
    await page.screenshot({ path: screenshotPath, type: "png" });
    const elements = await getElements(page);
    const currentUrl = page.url();

    // Build element list for Claude
    const elementList = elements
      .filter(e => e.visible)
      .map(e => `  [${e.idx}] ${e.role}${e.type ? `(${e.type})` : ""}: "${e.text}" at (${e.x},${e.y})`)
      .join("\n");

    const prompt = `You are a first-time user testing a web product. You know NOTHING about this product — no documentation, no context, no brand knowledge.

Your task: ${task}

Current page URL: ${currentUrl}
Step ${step + 1} of ${maxSteps}.

Read the screenshot at ${screenshotPath} to see the current page.

Interactive elements on the page:
${elementList || "  (no interactive elements found)"}

Based on what you see, decide your next action. Respond with ONLY a JSON object (no markdown, no explanation):
{"action": "click|type|scroll|done|stuck", "element": <index>, "text": "<text to type if action is type>", "reasoning": "<1 sentence>"}

Rules:
- "click": click element at given index
- "type": type text into element at given index
- "scroll": scroll down to see more
- "done": you completed the task successfully
- "stuck": you cannot figure out what to do

If the task seems complete based on what you see, use "done".
If you've been going in circles or can't proceed, use "stuck".`;

    const response = askClaude(prompt);

    // Parse response
    let action;
    try {
      const jsonMatch = response.match(/\{[\s\S]*\}/);
      action = jsonMatch ? JSON.parse(jsonMatch[0]) : { action: "stuck", reasoning: "Could not parse response" };
    } catch {
      action = { action: "stuck", reasoning: "Could not parse response" };
    }

    if (!evalOutput && !jsonOutput) {
      process.stderr.write(`${DIM}  step ${step + 1}: ${action.action}${action.element !== undefined ? ` [${action.element}]` : ""} — ${action.reasoning || ""}${NC}\n`);
    }

    if (action.action === "done") {
      completed = true;
      break;
    }

    if (action.action === "stuck") {
      confusionNotes.push(action.reasoning || "stuck");
      if (confusionNotes.length >= 3) break;
      // Try scrolling as fallback
      await page.evaluate(() => window.scrollBy(0, 400));
      continue;
    }

    if (action.action === "scroll") {
      await page.evaluate(() => window.scrollBy(0, 400));
      continue;
    }

    const targetIdx = action.element;
    const targetEl = elements.find(e => e.idx === targetIdx);

    if (!targetEl) {
      confusionNotes.push(`element [${targetIdx}] not found`);
      continue;
    }

    try {
      if (action.action === "click") {
        await page.mouse.click(targetEl.x, targetEl.y);
        clicks++;
        await page.waitForTimeout(1000);
      } else if (action.action === "type" && action.text) {
        await page.mouse.click(targetEl.x, targetEl.y);
        await page.keyboard.type(action.text);
        clicks++;
        await page.waitForTimeout(500);
      }
    } catch (e) {
      confusionNotes.push(`interaction failed: ${e.message}`);
    }

    lastUrl = page.url();
  }

  const elapsed = Math.round((Date.now() - startTime) / 1000);

  // Check if page changed (value visible)
  let pageChanged = false;
  try {
    pageChanged = page.url() !== url;
    if (!pageChanged) {
      const finalText = await page.evaluate(() => document.body.innerText.slice(0, 1000));
      // Compare initial vs final text — value is visible if content actually changed
      pageChanged = initialText !== finalText && finalText.length > 0;
    }
  } catch {}

  await browser.close();

  // Cleanup temp screenshots
  try { rmSync(tmpDir, { recursive: true }); } catch {}

  return {
    pass: completed,
    time_seconds: elapsed,
    click_count: clicks,
    steps_used: stepsUsed,
    confusion_notes: confusionNotes,
    last_page: lastUrl,
    value_visible: pageChanged,
  };
}

// --- Run ---
const result = await runBlindEval();

if (evalOutput) {
  const passStr = result.pass ? "pass" : "fail";
  console.log(`first-action-works:${passStr}:${result.pass ? "completed" : "failed"} in ${result.time_seconds}s, ${result.click_count} clicks`);
  console.log(`value-visible:${result.value_visible ? "pass" : "fail"}:${result.value_visible ? "page changed after action" : "no visible change"}`);
} else if (jsonOutput) {
  console.log(JSON.stringify({ url, task, result }, null, 2));
} else {
  console.log(`${BOLD}blind-eval${NC} — ${url}`);
  console.log(`${BOLD}Task:${NC} "${task}"`);
  console.log("");
  const icon = result.pass ? `${GREEN}[PASS]${NC}` : `${RED}[FAIL]${NC}`;
  console.log(`  ${icon} Task ${result.pass ? "completed" : "failed"} in ${result.time_seconds}s`);
  console.log(`  Clicks: ${result.click_count}`);
  if (result.confusion_notes.length > 0) {
    console.log(`  Confusion points:`);
    for (const note of result.confusion_notes) {
      console.log(`    - ${note}`);
    }
  }
  console.log(`  Last page: ${result.last_page}`);
  console.log(`  Value visible: ${result.value_visible ? "yes" : "no"}`);
}

process.exit(result.pass ? 0 : 1);
