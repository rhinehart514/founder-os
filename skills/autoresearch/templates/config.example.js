// autoresearch config — copy to config.js and fill in for the project.
//
// Required:
//   metric        - human-readable name of what we're optimizing (e.g. "performance", "bundle_kb")
//   maximize      - true if higher is better, false if lower is better
//   targetFiles   - array of paths (relative to projectRoot) the mutations are allowed to edit
//   measureCmd    - shell command run from projectRoot. stdout (or stderr if no parse()) gets
//                   parsed: last numeric line is the score. Override with parse() for JSON output.
//
// Recommended:
//   minImprovement - score must improve by MORE than this to keep. Set to noise band.
//                    Lighthouse: 3 (jitter ±2). bundle bytes: 0. latency p99: 5%.
//                    Prevents jitter wins from compounding into an inflated baseline.
//   samples        - run measureCmd N times per experiment, take median. Default 1.
//                    Use 3 for Lighthouse / latency, 1 for deterministic metrics.
//   plateauLimit   - stop after N consecutive discards. Default 5.
//   targetScore    - stop when bestScore reaches this. Optional ceiling.
//   buildCmd       - shell command run from projectRoot AFTER writing mutated files,
//                    BEFORE measure. Use for compiled targets (TS, Rust, Go, bundlers).
//                    A nonzero exit = mutation crashes; runner reverts.
//   buildTimeoutMs - default 60000.
//
// Optional:
//   projectRoot   - relative to this dir. defaults to ".." (assumes .autoresearch/ inside project root)
//   subMetrics    - extra fields to display on the dashboard. parse() must return them on the result object.
//   parse(stdout) - return { score: number, [extraField]: number, ... } or null on failure.
//                   When provided, only stdout is captured. When omitted, stderr is folded in
//                   so tools like /usr/bin/time and pytest don't silently null out.
//   timeoutMs     - per-measurement timeout. default 120000.
//   dashboardPort - default 3456.

module.exports = {
  metric: 'performance',
  maximize: true,
  projectRoot: '..',
  targetFiles: ['index.html'],
  subMetrics: ['lcp', 'fcp', 'tbt'],
  measureCmd:
    'npx -y lighthouse http://localhost:3000 --output=json --quiet ' +
    '--chrome-flags="--headless --no-sandbox" --only-categories=performance',
  parse(stdout) {
    const report = JSON.parse(stdout);
    const a = report.audits;
    return {
      score: Math.round(report.categories.performance.score * 100),
      lcp: a['largest-contentful-paint']?.numericValue ?? null,
      fcp: a['first-contentful-paint']?.numericValue ?? null,
      tbt: a['total-blocking-time']?.numericValue ?? null,
    };
  },
  minImprovement: 3,
  samples: 3,
  plateauLimit: 5,
  targetScore: 99,
  // buildCmd: 'npm run build',         // uncomment for compiled targets
  // buildTimeoutMs: 90000,
  dashboardPort: 3456,
  timeoutMs: 90000,
};
