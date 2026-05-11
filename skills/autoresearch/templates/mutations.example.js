// autoresearch mutations — copy to mutations.js and replace with project-specific tries.
//
// Two mutation shapes are supported:
//
//   { name, apply: (state) => state }
//     `state` is { [filename]: contents } — same keys as config.targetFiles.
//     Mutate the strings, return the same object. Return state unchanged → skipped.
//     Throw to skip.
//
//   { name, applyCmd: 'shell command' }
//     Shell command runs from projectRoot. Modifies project files in place.
//     Use for: Python codebases (where regex over source is fragile), patch files
//     (`patch -p1 < my.diff`), formatters, AST transforms (`jscodeshift`).
//     Runner re-reads state after the command exits.
//     Nonzero exit = skip.
//
// Rules:
//   - one logical change per mutation. compound diffs hide what worked.
//   - prefer specific changes ("add loading=lazy to img tags") over vague ("optimize images").
//   - fast first, slow last. cheap wins build the best ground state.
//   - VERIFY THE PATTERN EXISTS IN THE FILE before writing the mutation. A regex
//     that matches nothing produces a no-op skip and gives the loop no signal.
//   - Generate by READING the codebase, not from a generic checklist.
//
// Resume safety:
//   The runner dedupes by content hash (sha256 of apply.toString() or applyCmd).
//   Identical name + identical code → skipped (already tried).
//   Identical name + different code → runs (it's a new mutation).
//   Different name + identical code → skipped (it's the same mutation).

module.exports = [
  // Pattern 1: in-process JS mutation (preferred for HTML/CSS/JS/JSON/YAML)
  {
    name: 'lazy load all images',
    apply: (state) => {
      state['index.html'] = state['index.html'].replace(
        /<img(?![^>]*loading)/g,
        '<img loading="lazy"'
      );
      return state;
    },
  },
  {
    name: 'add fetchpriority high to hero image',
    apply: (state) => {
      state['index.html'] = state['index.html'].replace(
        /(<div class="hero-image">\s*<img)/,
        '$1 fetchpriority="high" loading="eager"'
      );
      return state;
    },
  },

  // Pattern 2: shell-out (for Python, Rust, Go, or anything regex-fragile)
  // {
  //   name: 'remove unused imports via ruff',
  //   applyCmd: 'ruff check --select F401 --fix src/',
  // },
  // {
  //   name: 'apply prompt-v2.diff',
  //   applyCmd: 'patch -p1 < .autoresearch/patches/prompt-v2.diff',
  // },
];
