#!/bin/bash
# founder-os installer — idempotent
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDER_DIR="$SCRIPT_DIR"
CLAUDE_DIR="$HOME/.claude"
FOUNDER_HOME="$HOME/.founder-os"
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --check|--dry-run) DRY_RUN=true ;;
    esac
done

# NO_COLOR support (https://no-color.org/)
if [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 1 ]]; then
    RED='' GREEN='' YELLOW='' CYAN='' BOLD='' DIM='' NC=''
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
fi

action() {
    if $DRY_RUN; then
        echo -e "    ${DIM}[dry-run]${NC} $1"
    else
        echo -e "    ${GREEN}✓${NC} $1"
    fi
}

skip() {
    echo -e "    ${DIM}· $1 (exists)${NC}"
}

warn() {
    echo -e "    ${YELLOW}⚠${NC} $1"
}

echo ""
echo -e "  ${CYAN}◆${NC} ${BOLD}founder-os installer${NC}"
echo ""

# --- 0. Check dependencies ---
echo -e "  ${BOLD}Dependencies${NC}"
echo ""

# jq is required for scoring, eval, and data processing
if command -v jq &>/dev/null; then
    action "jq available ($(jq --version 2>&1 || echo 'unknown'))"
else
    echo -e "    ${RED}✗${NC} jq is required — install it and re-run install.sh"
    echo -e "      ${DIM}Install: brew install jq  (macOS) or apt install jq  (Linux)${NC}"
    echo -e "      ${DIM}https://jqlang.github.io/jq/download/${NC}"
    echo ""
    exit 1
fi

# Claude Code is required
if command -v claude &>/dev/null; then
    action "Claude Code available"
else
    echo -e "    ${RED}✗${NC} claude CLI is required — founder-os is a Claude Code plugin"
    echo -e "      ${DIM}Install: https://docs.anthropic.com/en/docs/claude-code${NC}"
    echo ""
    exit 1
fi

echo ""

# --- 1. Make bin/* scripts executable ---
echo -e "  ${BOLD}CLI${NC}"
echo ""

if [[ -d "$FOUNDER_DIR/bin" ]]; then
    chmod_count=0
    for f in "$FOUNDER_DIR"/bin/*.sh "$FOUNDER_DIR"/bin/founder; do
        [[ ! -f "$f" ]] && continue
        if [[ ! -x "$f" ]]; then
            $DRY_RUN || chmod +x "$f"
            action "chmod +x $(basename "$f")"
            chmod_count=$((chmod_count + 1))
        fi
    done
    if [[ $chmod_count -eq 0 ]]; then
        skip "all bin/* already executable"
    fi
else
    warn "bin/ directory not found"
fi

echo ""

# --- 2. Make hooks/*.sh executable ---
echo -e "  ${BOLD}Hooks${NC}"
echo ""

if [[ -d "$FOUNDER_DIR/hooks" ]]; then
    hook_count=0
    for f in "$FOUNDER_DIR"/hooks/*.sh; do
        [[ ! -f "$f" ]] && continue
        if [[ ! -x "$f" ]]; then
            $DRY_RUN || chmod +x "$f"
            action "chmod +x hooks/$(basename "$f")"
            hook_count=$((hook_count + 1))
        fi
    done
    if [[ $hook_count -eq 0 ]]; then
        skip "all hooks/*.sh already executable"
    fi

    # Verify hooks.json is valid
    hooks_json="$FOUNDER_DIR/hooks/hooks.json"
    if [[ -f "$hooks_json" ]]; then
        if command -v jq &>/dev/null && jq empty "$hooks_json" 2>/dev/null; then
            action "hooks.json valid"
        else
            warn "hooks.json exists but is not valid JSON"
        fi
    else
        warn "hooks.json not found"
    fi
else
    warn "hooks/ directory not found"
fi

echo ""

# --- 3. Create ~/.founder-os/ directory ---
echo -e "  ${BOLD}Config${NC}"
echo ""

if [[ ! -d "$FOUNDER_HOME" ]]; then
    $DRY_RUN || mkdir -p "$FOUNDER_HOME"
    action "created $FOUNDER_HOME"
else
    skip "$FOUNDER_HOME"
fi

# Copy portfolio.yml template if it doesn't exist
if [[ ! -f "$FOUNDER_HOME/portfolio.yml" ]]; then
    if [[ -f "$FOUNDER_DIR/config/portfolio.yml" ]]; then
        $DRY_RUN || cp "$FOUNDER_DIR/config/portfolio.yml" "$FOUNDER_HOME/portfolio.yml"
        action "copied portfolio.yml template → $FOUNDER_HOME/"
    else
        warn "config/portfolio.yml template not found"
    fi
else
    skip "portfolio.yml in $FOUNDER_HOME"
fi

echo ""

# --- 4. Create knowledge directories ---
echo -e "  ${BOLD}Knowledge${NC}"
echo ""

for dir in "$CLAUDE_DIR/knowledge" "$CLAUDE_DIR/cache"; do
    if [[ ! -d "$dir" ]]; then
        $DRY_RUN || mkdir -p "$dir"
        action "mkdir $dir"
    fi
done

# Initialize predictions.tsv if missing
if [[ ! -f "$CLAUDE_DIR/knowledge/predictions.tsv" ]]; then
    if ! $DRY_RUN; then
        printf 'date\tprediction\tevidence\tresult\tcorrect\tmodel_update\n' > "$CLAUDE_DIR/knowledge/predictions.tsv"
    fi
    action "predictions.tsv initialized"
else
    skip "predictions.tsv"
fi

# Initialize experiment-learnings.md if missing
if [[ ! -f "$CLAUDE_DIR/knowledge/experiment-learnings.md" ]]; then
    if ! $DRY_RUN; then
        cat > "$CLAUDE_DIR/knowledge/experiment-learnings.md" << 'LEARNINGS'
# Knowledge Model

Pattern library that compounds across ventures. Updated by /retro.

## Known Patterns (3+ ventures, high confidence)

(None yet — build the model by running /retro after decisions)

## Uncertain Patterns (1-2 ventures, test again)

(None yet — patterns emerge after your first few ideas)

## Unknown Territory (0 data, highest information value)

- What pricing models work best for SMB products?
- Does founder-market fit actually predict success, or is it survivorship bias?
- How much research is enough before a go/kill decision?

## Dead Ends (confirmed failures)

(None yet — dead ends are valuable. They prevent repeat mistakes.)
LEARNINGS
    fi
    action "experiment-learnings.md initialized"
else
    skip "experiment-learnings.md"
fi

echo ""

# --- 5. Optional npm install for lens/product/eval ---
EVAL_DIR="$FOUNDER_DIR/lens/product/eval"
if [[ -f "$EVAL_DIR/package.json" ]]; then
    if [[ ! -d "$EVAL_DIR/node_modules" ]]; then
        echo -e "  ${BOLD}Product Eval (optional)${NC}"
        echo ""
        echo -e "    ${DIM}lens/product/eval/ has a package.json but no node_modules.${NC}"
        echo -e "    ${DIM}This is needed for /taste (visual product intelligence).${NC}"
        echo ""
        if [[ -t 0 ]] && ! $DRY_RUN; then
            read -rp "    Install npm dependencies for product eval? [y/N] " response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                (cd "$EVAL_DIR" && npm install)
                action "npm install in lens/product/eval/"
            else
                echo -e "    ${DIM}skipped — run 'cd lens/product/eval && npm install' later if needed${NC}"
            fi
        else
            echo -e "    ${DIM}skipped (non-interactive) — run 'cd lens/product/eval && npm install' later${NC}"
        fi
        echo ""
    fi
fi

# --- 6. Plugin mode verification ---
echo -e "  ${BOLD}Plugin Verification${NC}"
echo ""

plugin_json="$FOUNDER_DIR/.claude-plugin/plugin.json"
if [[ -f "$plugin_json" ]]; then
    if command -v jq &>/dev/null && jq empty "$plugin_json" 2>/dev/null; then
        action "plugin.json valid"
        agent_count=$(jq '.agents | length' "$plugin_json" 2>/dev/null || echo "?")
        action "$agent_count agents registered"
    else
        warn "plugin.json exists but is not valid JSON"
    fi
else
    warn "plugin.json not found"
fi

SKILL_COUNT=$(find "$FOUNDER_DIR/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$SKILL_COUNT" -ge 1 ]]; then
    action "$SKILL_COUNT skills found"
else
    warn "no skills found in skills/"
fi

echo ""

# --- Summary ---
echo -e "  ${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
if $DRY_RUN; then
    echo -e "  ${DIM}Dry run complete. Run without --check to apply.${NC}"
else
    echo -e "  ${GREEN}✓${NC} ${BOLD}founder-os installed${NC}"
    echo ""
    echo -e "  ${BOLD}What was set up:${NC}"
    echo -e "    · bin/ and hooks/ scripts made executable"
    echo -e "    · $FOUNDER_HOME created with portfolio.yml"
    echo -e "    · knowledge files initialized"
    echo -e "    · $SKILL_COUNT skills, $agent_count agents ready"
    echo ""
    echo -e "  ${BOLD}Next:${NC}"
    echo -e "    ${BOLD}cd your-project && claude${NC}, then type ${BOLD}/onboard${NC}"
    echo ""
    echo -e "  ${DIM}Or run /portfolio to see your ideas, /discover to start a new one.${NC}"
fi
echo ""
