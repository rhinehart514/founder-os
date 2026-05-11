#!/usr/bin/env node
// Autoresearch runner — generic hill-climb loop.
// Reads ./config.js and ./mutations.js, writes ./results.json.
//
// Resume-safe:
//   - bestScore is recomputed from kept experiments only (not all scored ones)
//   - consecutiveDiscards is restored by counting trailing non-keeps
//   - bestState + bestScore stored together in ./best/{files,score.json}
//
// Crash-safe: bestState snapshot persists after every keep.
// Noise-safe: minImprovement gate prevents jitter wins from compounding.
// Plateau-safe: auto-stop after consecutive discards >= plateauLimit.
// Mutation-safe: dedup by content hash, not name. Pre-flight check warns on dead batches.
// Language-agnostic: mutations may use { apply(state) } OR { applyCmd: "shell..." }.
// Build-aware: optional config.buildCmd runs between writeState and measure.

const { execSync } = require('child_process');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const config = require('./config.js');
const mutations = require('./mutations.js');

const RUNNER_DIR = __dirname;
const RESULTS_PATH = path.join(RUNNER_DIR, 'results.json');
const BEST_DIR = path.join(RUNNER_DIR, 'best');
const BEST_SCORE_PATH = path.join(BEST_DIR, 'score.json');
const PROJECT_ROOT = path.resolve(RUNNER_DIR, config.projectRoot || '..');
const PLATEAU_LIMIT = config.plateauLimit ?? 5;
const MIN_IMPROVEMENT = config.minImprovement ?? 0;
const BUILD_TIMEOUT = config.buildTimeoutMs ?? 60000;

let experiments = [];
let bestScore = null;
let bestState = null;
let consecutiveDiscards = 0;

function resolveFile(rel) {
  return path.join(PROJECT_ROOT, rel);
}

function readState() {
  const state = {};
  for (const f of config.targetFiles) {
    state[f] = fs.readFileSync(resolveFile(f), 'utf8');
  }
  return state;
}

function writeState(state) {
  for (const [f, content] of Object.entries(state)) {
    fs.writeFileSync(resolveFile(f), content);
  }
}

function snapshotBest(state, score) {
  fs.mkdirSync(BEST_DIR, { recursive: true });
  for (const [f, content] of Object.entries(state)) {
    const out = path.join(BEST_DIR, f);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    fs.writeFileSync(out, content);
  }
  fs.writeFileSync(BEST_SCORE_PATH, JSON.stringify({ score }));
}

function loadBestSnapshot() {
  if (!fs.existsSync(BEST_DIR)) return null;
  const state = {};
  for (const f of config.targetFiles) {
    const p = path.join(BEST_DIR, f);
    if (!fs.existsSync(p)) return null;
    state[f] = fs.readFileSync(p, 'utf8');
  }
  let score = null;
  try {
    score = JSON.parse(fs.readFileSync(BEST_SCORE_PATH, 'utf8')).score;
  } catch {}
  return { state, score };
}

function statesEqual(a, b) {
  for (const k of Object.keys(a)) if (a[k] !== b[k]) return false;
  return true;
}

function mutationHash(mut) {
  const src = mut.applyCmd || (typeof mut.apply === 'function' ? mut.apply.toString() : '');
  return crypto.createHash('sha256').update(src).digest('hex').slice(0, 12);
}

function loadExisting() {
  try {
    const data = JSON.parse(fs.readFileSync(RESULTS_PATH, 'utf8'));
    if (Array.isArray(data.experiments)) {
      experiments = data.experiments;
      // bestScore from KEPT experiments only — discards must not inflate the baseline.
      const kept = experiments.filter(
        (e) => e.status === 'keep' && e.score !== null && e.score !== undefined
      );
      if (kept.length) {
        bestScore = config.maximize
          ? Math.max(...kept.map((e) => e.score))
          : Math.min(...kept.map((e) => e.score));
      }
      // Restore consecutiveDiscards by counting trailing discards since last keep.
      let trailing = 0;
      for (let i = experiments.length - 1; i >= 0; i--) {
        if (experiments[i].status === 'keep') break;
        if (experiments[i].status === 'discard') trailing++;
      }
      consecutiveDiscards = trailing;
    }
  } catch {}
}

function save(status, current = null) {
  fs.writeFileSync(
    RESULTS_PATH,
    JSON.stringify(
      {
        config: {
          metric: config.metric,
          maximize: !!config.maximize,
          subMetrics: config.subMetrics || [],
          minImprovement: MIN_IMPROVEMENT,
          plateauLimit: PLATEAU_LIMIT,
        },
        experiments,
        current,
        status,
        consecutiveDiscards,
      },
      null,
      2
    )
  );
}

function runShell(cmd, opts = {}) {
  // Capture stderr alongside stdout when no parse() — many tools (time, pytest) emit on stderr.
  const wrapped = opts.captureStderr ? `(${cmd}) 2>&1` : cmd;
  return execSync(wrapped, {
    encoding: 'utf8',
    timeout: opts.timeout ?? config.timeoutMs ?? 120000,
    cwd: opts.cwd || PROJECT_ROOT,
    stdio: ['ignore', 'pipe', opts.captureStderr ? 'pipe' : 'pipe'],
    shell: '/bin/sh',
  });
}

function runMeasureOnce() {
  try {
    const captureStderr = typeof config.parse !== 'function';
    const out = runShell(config.measureCmd, { captureStderr });
    if (typeof config.parse === 'function') return config.parse(out);
    const lastNumeric = out.trim().split('\n').reverse().find((l) => Number.isFinite(parseFloat(l)));
    const n = lastNumeric ? parseFloat(lastNumeric) : NaN;
    return Number.isFinite(n) ? { score: n } : null;
  } catch (e) {
    console.error('  measure error:', e.message.split('\n')[0]);
    return null;
  }
}

function median(nums) {
  const sorted = [...nums].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

function measure() {
  const samples = config.samples || 1;
  if (samples === 1) return runMeasureOnce();
  const results = [];
  for (let i = 0; i < samples; i++) {
    const r = runMeasureOnce();
    if (r && r.score !== null && r.score !== undefined) results.push(r);
  }
  if (!results.length) return null;
  const merged = { score: median(results.map((r) => r.score)) };
  for (const k of Object.keys(results[0])) {
    if (k === 'score') continue;
    const vals = results.map((r) => r[k]).filter((v) => typeof v === 'number');
    if (vals.length) merged[k] = median(vals);
  }
  return merged;
}

function isBetter(score) {
  if (bestScore === null) return true;
  const delta = config.maximize ? score - bestScore : bestScore - score;
  return delta > MIN_IMPROVEMENT;
}

function runBuild() {
  if (!config.buildCmd) return true;
  try {
    runShell(config.buildCmd, { timeout: BUILD_TIMEOUT, captureStderr: true });
    return true;
  } catch (e) {
    console.log('  build failed:', e.message.split('\n')[0]);
    return false;
  }
}

function applyMutation(mut, original) {
  // Returns { state, error? }
  if (typeof mut.apply === 'function') {
    try {
      return { state: mut.apply(JSON.parse(JSON.stringify(original))) };
    } catch (e) {
      return { error: 'apply threw: ' + e.message };
    }
  }
  if (typeof mut.applyCmd === 'string') {
    // applyCmd modifies project files in place. Run, then re-read state.
    try {
      runShell(mut.applyCmd, { timeout: 30000, captureStderr: true });
      return { state: readState() };
    } catch (e) {
      return { error: 'applyCmd failed: ' + e.message.split('\n')[0] };
    }
  }
  return { error: 'mutation has neither apply nor applyCmd' };
}

async function runOne(mut, idx, total) {
  const label = `[${idx + 1}/${total}] ${mut.name}`;
  console.log(`\n${label}`);

  const original = readState();
  const { state: modified, error } = applyMutation(mut, original);

  if (error) {
    console.log('  ' + error + ', skipping');
    experiments.push({ name: mut.name, hash: mutationHash(mut), status: 'skip', score: null });
    save('running');
    return;
  }

  if (!modified || statesEqual(modified, original)) {
    console.log('  no-op, skipping');
    experiments.push({ name: mut.name, hash: mutationHash(mut), status: 'skip', score: null });
    save('running');
    return;
  }

  writeState(modified);
  save('running');

  if (!runBuild()) {
    console.log('  reverting');
    writeState(bestState || original);
    experiments.push({ name: mut.name, hash: mutationHash(mut), status: 'crash', score: null });
    save('running');
    return;
  }

  const result = measure();

  if (!result || result.score === null || result.score === undefined) {
    console.log('  measurement crashed, reverting');
    writeState(bestState || original);
    experiments.push({ name: mut.name, hash: mutationHash(mut), status: 'crash', score: null });
    save('running');
    return;
  }

  const { score, ...rest } = result;
  console.log(`  ${config.metric}: ${score}`);

  const record = { name: mut.name, hash: mutationHash(mut), score, ...rest };

  if (isBetter(score)) {
    console.log(`  ✓ keep (${bestScore ?? '—'} → ${score})`);
    bestScore = score;
    bestState = modified;
    snapshotBest(modified, score);
    experiments.push({ ...record, status: 'keep' });
    consecutiveDiscards = 0;
  } else {
    const reason =
      bestScore !== null && Math.abs(score - bestScore) <= MIN_IMPROVEMENT
        ? `within noise floor (±${MIN_IMPROVEMENT})`
        : 'no improvement';
    console.log(`  ✗ revert — ${reason}`);
    writeState(bestState || original);
    experiments.push({ ...record, status: 'discard' });
    consecutiveDiscards++;
  }

  save('running', record);
}

function preflight(queue) {
  // Only checks JS-apply mutations (applyCmd would have side effects).
  const jsApply = queue.filter((m) => typeof m.apply === 'function');
  if (!jsApply.length) return { dryable: 0, nonNoop: 0 };
  const state = readState();
  let nonNoop = 0;
  for (const mut of jsApply) {
    try {
      const m = mut.apply(JSON.parse(JSON.stringify(state)));
      if (m && !statesEqual(m, state)) nonNoop++;
    } catch {}
  }
  return { dryable: jsApply.length, nonNoop };
}

async function main() {
  console.log(`autoresearch: ${config.metric} (${config.maximize ? 'maximize' : 'minimize'})`);
  console.log(`dashboard:    http://localhost:${config.dashboardPort || 3456}/dashboard.html`);
  console.log(`target files: ${config.targetFiles.join(', ')}`);
  if (MIN_IMPROVEMENT) console.log(`noise floor:  ±${MIN_IMPROVEMENT}`);
  if (config.samples > 1) console.log(`samples:      ${config.samples}x median`);
  if (config.buildCmd) console.log(`build:        ${config.buildCmd}`);
  console.log(`plateau:      ${PLATEAU_LIMIT} consecutive discards → stop`);

  loadExisting();
  const snapshot = loadBestSnapshot();
  if (snapshot) {
    bestState = snapshot.state;
    if (snapshot.score !== null && bestScore === null) bestScore = snapshot.score;
    console.log(`resumed from best/ snapshot (score: ${snapshot.score})`);
  } else {
    bestState = readState();
  }

  if (experiments.length === 0) {
    console.log('\nbaseline...');
    const baseline = measure();
    if (!baseline) {
      console.error('baseline measurement failed. fix the measure command and retry.');
      save('error');
      process.exit(1);
    }
    bestScore = baseline.score;
    const { score, ...rest } = baseline;
    experiments.push({ name: 'baseline', hash: 'baseline', status: 'keep', score, ...rest });
    snapshotBest(bestState, score);
    save('running', { name: 'baseline', score, ...rest });
    console.log(`  ${config.metric}: ${score}`);
  }

  // Dedup by hash (catches "different name same code" and "same name different code" both correctly).
  const triedHashes = new Set(experiments.map((e) => e.hash).filter(Boolean));
  const queue = mutations.filter((m) => !triedHashes.has(mutationHash(m)));
  const skipped = mutations.length - queue.length;
  if (skipped > 0) console.log(`\nskipping ${skipped} already-tried mutation(s) by hash`);

  if (queue.length === 0) {
    console.log('\nall mutations already tried. nothing to do.');
    save('exhausted', experiments[experiments.length - 1]);
    return;
  }

  // Pre-flight: warn if the JS-apply mutations are all no-ops against current state.
  const { dryable, nonNoop } = preflight(queue);
  if (dryable > 0 && nonNoop === 0) {
    console.error(
      `\n⚠  pre-flight: all ${dryable} dryable mutations produce no diff against current state.`
    );
    console.error(`  the model likely wrote regex against imagined file content.`);
    console.error(`  re-read the actual ${config.targetFiles.join(', ')} and rewrite mutations.js.`);
    save('preflight-failed');
    process.exit(2);
  }

  console.log(`\nstarting from best: ${bestScore}`);

  let stoppedReason = 'exhausted';

  for (let i = 0; i < queue.length; i++) {
    await runOne(queue[i], i, queue.length);
    if (consecutiveDiscards >= PLATEAU_LIMIT) {
      stoppedReason = 'plateau';
      console.log(`\nplateau: ${PLATEAU_LIMIT} consecutive discards. stopping.`);
      break;
    }
    if (config.targetScore !== undefined) {
      const hit = config.maximize ? bestScore >= config.targetScore : bestScore <= config.targetScore;
      if (hit) {
        stoppedReason = 'target';
        console.log(`\ntarget reached (${config.targetScore}). stopping.`);
        break;
      }
    }
  }

  save(stoppedReason, experiments[experiments.length - 1]);

  const kept = experiments.filter((e) => e.status === 'keep');
  console.log(`\n=== ${stoppedReason} ===`);
  console.log(`tried:   ${experiments.length}`);
  console.log(`kept:    ${kept.length}`);
  console.log(`best:    ${bestScore}`);
  console.log(`gain:    ${experiments[0].score} → ${bestScore}`);
  if (stoppedReason === 'exhausted') {
    console.log(`\nbatch exhausted, no plateau. read results.json, generate next batch, re-run.`);
  }
}

process.on('SIGINT', () => {
  console.log('\ninterrupted');
  save('interrupted', experiments[experiments.length - 1]);
  process.exit(130);
});

main().catch((e) => {
  console.error(e);
  save('error');
  process.exit(1);
});
