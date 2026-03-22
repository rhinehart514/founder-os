#!/usr/bin/env bash
set -euo pipefail

# skill.sh — Manage founder-os lenses (skills)
# Usage: founder skill [list|install|remove|info] [args]

if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    _SKILL_SOURCE="${BASH_SOURCE[0]}"
    while [[ -L "$_SKILL_SOURCE" ]]; do
        _SKILL_SOURCE="$(readlink "$_SKILL_SOURCE")"
    done
    FOUNDER_DIR="$(cd "$(dirname "$_SKILL_SOURCE")/.." && pwd)"
fi

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

LENS_DIR="$FOUNDER_DIR/lens"

cmd_list() {
    echo ""
    echo -e "  ${CYAN}◆${NC} ${BOLD}Installed Lenses${NC}"
    echo ""

    local found=false
    for lyml in "$LENS_DIR"/*/lens.yml; do
        [[ -f "$lyml" ]] || continue
        found=true
        local name desc version
        name=$(grep '^name:' "$lyml" 2>/dev/null | head -1 | sed 's/^name:[[:space:]]*//')
        desc=$(grep '^description:' "$lyml" 2>/dev/null | head -1 | sed 's/^description:[[:space:]]*//' | tr -d '"')
        version=$(grep '^version:' "$lyml" 2>/dev/null | head -1 | sed 's/^version:[[:space:]]*//')
        echo -e "  ${GREEN}✓${NC} ${BOLD}${name}${NC} ${DIM}v${version}${NC}"
        echo -e "    ${DIM}${desc}${NC}"
        echo ""
    done

    if [[ "$found" == "false" ]]; then
        echo -e "  ${DIM}No lenses installed.${NC}"
        echo -e "  ${DIM}Install one with: founder skill install <git-url>${NC}"
        echo ""
    fi
}

cmd_install() {
    local url="${1:-}"
    if [[ -z "$url" ]]; then
        echo -e "${RED}Usage: founder skill install <git-url>${NC}" >&2
        exit 1
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT

    echo -e "  ${DIM}Cloning...${NC}"
    if ! git clone --depth 1 "$url" "$tmp_dir/repo" 2>/dev/null; then
        echo -e "  ${RED}✗${NC} Failed to clone $url" >&2
        exit 1
    fi

    # Validate lens.yml exists
    if [[ ! -f "$tmp_dir/repo/lens.yml" ]]; then
        echo -e "  ${RED}✗${NC} No lens.yml found — not a valid founder-os lens" >&2
        exit 1
    fi

    local name
    name=$(grep '^name:' "$tmp_dir/repo/lens.yml" 2>/dev/null | head -1 | sed 's/^name:[[:space:]]*//')
    if [[ -z "$name" ]]; then
        echo -e "  ${RED}✗${NC} lens.yml missing name: field" >&2
        exit 1
    fi

    # Check if already installed
    if [[ -d "$LENS_DIR/$name" ]]; then
        echo -e "  ${YELLOW}⚠${NC} Lens '$name' already installed — replacing"
        rm -rf "$LENS_DIR/$name"
    fi

    # Copy to lens directory
    cp -r "$tmp_dir/repo" "$LENS_DIR/$name"
    rm -rf "$LENS_DIR/$name/.git"

    # Install npm deps if eval/package.json exists
    if [[ -f "$LENS_DIR/$name/eval/package.json" ]]; then
        echo -e "  ${DIM}Installing dependencies...${NC}"
        (cd "$LENS_DIR/$name/eval" && npm install --silent 2>/dev/null) || true
    fi

    local version
    version=$(grep '^version:' "$LENS_DIR/$name/lens.yml" 2>/dev/null | head -1 | sed 's/^version:[[:space:]]*//')
    echo -e "  ${GREEN}✓${NC} Installed ${BOLD}${name}${NC} ${DIM}v${version}${NC}"
    echo -e "  ${DIM}Run /onboard to wire up mind files and skills.${NC}"
    echo ""
}

cmd_remove() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo -e "${RED}Usage: founder skill remove <name>${NC}" >&2
        exit 1
    fi

    if [[ ! -d "$LENS_DIR/$name" ]]; then
        echo -e "  ${RED}✗${NC} Lens '$name' not found" >&2
        exit 1
    fi

    rm -rf "$LENS_DIR/$name"
    echo -e "  ${GREEN}✓${NC} Removed lens ${BOLD}${name}${NC}"
    echo -e "  ${DIM}Run /onboard to clean up mind symlinks and skills.${NC}"
    echo ""
}

cmd_info() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo -e "${RED}Usage: founder skill info <name>${NC}" >&2
        exit 1
    fi

    local lyml="$LENS_DIR/$name/lens.yml"
    if [[ ! -f "$lyml" ]]; then
        echo -e "  ${RED}✗${NC} Lens '$name' not found or missing lens.yml" >&2
        exit 1
    fi

    echo ""
    echo -e "  ${CYAN}◆${NC} ${BOLD}$name${NC}"
    echo ""

    # Display lens.yml contents formatted
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        if [[ "$line" =~ ^([a-zA-Z_]+): ]]; then
            local key="${BASH_REMATCH[1]}"
            local val="${line#*: }"
            printf "  %-20s %s\n" "$key" "$val"
        elif [[ "$line" =~ ^[[:space:]]+-[[:space:]] ]]; then
            # List item under provides/dependencies
            local item="${line#*- }"
            echo "                      - $item"
        else
            echo "  $line"
        fi
    done < "$lyml"
    echo ""

    # Show what's in the lens directory
    echo -e "  ${BOLD}Contents${NC}"
    for subdir in scoring eval mind commands config; do
        if [[ -d "$LENS_DIR/$name/$subdir" ]]; then
            local count
            count=$(find "$LENS_DIR/$name/$subdir" -type f | wc -l | tr -d ' ')
            echo -e "    ${GREEN}✓${NC} $subdir/ ($count files)"
        fi
    done
    echo ""
}

cmd_help() {
    echo ""
    echo -e "  ${CYAN}◆${NC} ${BOLD}founder skill${NC}"
    echo ""
    echo -e "  ${BOLD}Usage${NC}  founder skill <command> [args]"
    echo ""
    echo -e "    list              ${DIM}Show installed lenses${NC}"
    echo -e "    install <url>     ${DIM}Install a lens from a git repository${NC}"
    echo -e "    remove <name>     ${DIM}Remove an installed lens${NC}"
    echo -e "    info <name>       ${DIM}Show lens details${NC}"
    echo ""
}

case "${1:-list}" in
    list)       cmd_list ;;
    install)    shift; cmd_install "$@" ;;
    remove)     shift; cmd_remove "$@" ;;
    info)       shift; cmd_info "$@" ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}Unknown skill command: $1${NC}" >&2
        cmd_help
        exit 1
        ;;
esac
