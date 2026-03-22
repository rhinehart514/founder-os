#!/usr/bin/env bash
# Detect project type, framework, language, and key structural info.
# Outputs structured data for /onboard to consume.
set -euo pipefail
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

echo "── project detection ──"
echo ""

# Language detection
echo "  languages:"
[[ -f "$PROJECT_DIR/package.json" ]] && echo "    node: $(jq -r '.name // "unnamed"' "$PROJECT_DIR/package.json" 2>/dev/null) ($(jq -r '.version // "0.0.0"' "$PROJECT_DIR/package.json" 2>/dev/null))"
[[ -f "$PROJECT_DIR/Cargo.toml" ]] && echo "    rust: $(grep -m1 'name' "$PROJECT_DIR/Cargo.toml" | sed 's/.*= *//' | tr -d '"')"
[[ -f "$PROJECT_DIR/pyproject.toml" ]] && echo "    python: pyproject.toml"
[[ -f "$PROJECT_DIR/requirements.txt" ]] && echo "    python: requirements.txt"
[[ -f "$PROJECT_DIR/go.mod" ]] && echo "    go: $(head -1 "$PROJECT_DIR/go.mod" | awk '{print $2}')"
[[ -f "$PROJECT_DIR/Gemfile" ]] && echo "    ruby: Gemfile"
[[ -f "$PROJECT_DIR/pom.xml" ]] && echo "    java: pom.xml"
[[ -f "$PROJECT_DIR/build.gradle" || -f "$PROJECT_DIR/build.gradle.kts" ]] && echo "    java/kotlin: gradle"
[[ -f "$PROJECT_DIR/mix.exs" ]] && echo "    elixir: mix.exs"
[[ -f "$PROJECT_DIR/composer.json" ]] && echo "    php: composer.json"

# Framework detection
echo ""
echo "  framework:"
[[ -f "$PROJECT_DIR/next.config.js" || -f "$PROJECT_DIR/next.config.mjs" || -f "$PROJECT_DIR/next.config.ts" ]] && echo "    next.js"
[[ -f "$PROJECT_DIR/nuxt.config.ts" || -f "$PROJECT_DIR/nuxt.config.js" ]] && echo "    nuxt"
[[ -f "$PROJECT_DIR/svelte.config.js" ]] && echo "    sveltekit"
[[ -f "$PROJECT_DIR/astro.config.mjs" || -f "$PROJECT_DIR/astro.config.ts" ]] && echo "    astro"
[[ -f "$PROJECT_DIR/remix.config.js" || -f "$PROJECT_DIR/remix.config.ts" ]] && echo "    remix"
[[ -f "$PROJECT_DIR/vite.config.ts" || -f "$PROJECT_DIR/vite.config.js" ]] && echo "    vite"
[[ -f "$PROJECT_DIR/angular.json" ]] && echo "    angular"
[[ -f "$PROJECT_DIR/gatsby-config.js" || -f "$PROJECT_DIR/gatsby-config.ts" ]] && echo "    gatsby"
[[ -f "$PROJECT_DIR/Dockerfile" ]] && echo "    docker"
[[ -f "$PROJECT_DIR/docker-compose.yml" || -f "$PROJECT_DIR/docker-compose.yaml" ]] && echo "    docker-compose"
# Django/Flask/FastAPI
[[ -f "$PROJECT_DIR/manage.py" ]] && echo "    django"
grep -ql "fastapi\|FastAPI" "$PROJECT_DIR"/*.py 2>/dev/null && echo "    fastapi"
grep -ql "flask\|Flask" "$PROJECT_DIR"/*.py 2>/dev/null && echo "    flask"
# Rails
[[ -f "$PROJECT_DIR/config/routes.rb" ]] && echo "    rails"

# Styling detection
echo ""
echo "  styling:"
[[ -f "$PROJECT_DIR/tailwind.config.js" || -f "$PROJECT_DIR/tailwind.config.ts" || -f "$PROJECT_DIR/tailwind.config.mjs" ]] && echo "    tailwind"
[[ -f "$PROJECT_DIR/postcss.config.js" || -f "$PROJECT_DIR/postcss.config.mjs" ]] && echo "    postcss"
grep -q "styled-components\|@emotion" "$PROJECT_DIR/package.json" 2>/dev/null && echo "    css-in-js"
grep -q "sass\|scss" "$PROJECT_DIR/package.json" 2>/dev/null && echo "    sass/scss"

# Key files
echo ""
echo "  key files:"
for f in README.md CLAUDE.md .claude/design-system.md config/founder.yml beliefs.yml .claude/plans/strategy.yml .claude/plans/roadmap.yml; do
    [[ -f "$PROJECT_DIR/$f" ]] && echo "    ✓ $f" || echo "    · $f (missing)"
done

# Testing
echo ""
echo "  testing:"
[[ -f "$PROJECT_DIR/jest.config.js" || -f "$PROJECT_DIR/jest.config.ts" ]] && echo "    jest"
[[ -f "$PROJECT_DIR/vitest.config.ts" || -f "$PROJECT_DIR/vitest.config.js" ]] && echo "    vitest"
[[ -f "$PROJECT_DIR/playwright.config.ts" ]] && echo "    playwright"
[[ -f "$PROJECT_DIR/cypress.config.ts" || -f "$PROJECT_DIR/cypress.config.js" ]] && echo "    cypress"
grep -q "pytest\|unittest" "$PROJECT_DIR/pyproject.toml" 2>/dev/null && echo "    pytest"

# Source structure
echo ""
echo "  source:"
for d in src app pages components lib bin skills public api routes controllers models services; do
    [[ -d "$PROJECT_DIR/$d" ]] && echo "    $d/ ($(find "$PROJECT_DIR/$d" -type f 2>/dev/null | wc -l | tr -d ' ') files)"
done

# Package manager
echo ""
echo "  package manager:"
[[ -f "$PROJECT_DIR/package-lock.json" ]] && echo "    npm"
[[ -f "$PROJECT_DIR/yarn.lock" ]] && echo "    yarn"
[[ -f "$PROJECT_DIR/pnpm-lock.yaml" ]] && echo "    pnpm"
[[ -f "$PROJECT_DIR/bun.lockb" ]] && echo "    bun"

# Git info
echo ""
echo "  git:"
if [[ -d "$PROJECT_DIR/.git" ]]; then
    echo "    commits: $(git -C "$PROJECT_DIR" rev-list --count HEAD 2>/dev/null || echo 'unknown')"
    echo "    branch: $(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo 'unknown')"
    echo "    last commit: $(git -C "$PROJECT_DIR" log -1 --format='%ar — %s' 2>/dev/null || echo 'unknown')"
else
    echo "    not a git repo"
fi
