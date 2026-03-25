#!/usr/bin/env bash
# extract-design-system.sh — Mechanically pulls design tokens from codebase.
# Checks: tailwind.config, CSS variables, package.json UI libs, theme files.
# Outputs structured token data for the LLM to refine into design-system.md.
# Usage: bash scripts/extract-design-system.sh [project-dir]
set -euo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"

echo "── design system extraction ──"

# --- Tailwind config ---
echo ""
echo "  ▸ tailwind"
TW_CONFIG=""
for f in tailwind.config.ts tailwind.config.js tailwind.config.mjs tailwind.config.cjs; do
    if [[ -f "$PROJECT_DIR/$f" ]]; then
        TW_CONFIG="$PROJECT_DIR/$f"
        break
    fi
done

if [[ -n "$TW_CONFIG" ]]; then
    echo "    found: $TW_CONFIG"
    # Extract theme extensions
    if grep -q 'extend' "$TW_CONFIG" 2>/dev/null; then
        echo "    has theme extensions"
        # Show color definitions
        COLOR_COUNT=$(grep -c 'color\|Color' "$TW_CONFIG" 2>/dev/null || echo 0)
        echo "    color references: $COLOR_COUNT"
    fi
    # Check for custom plugins
    if grep -q 'plugin' "$TW_CONFIG" 2>/dev/null; then
        echo "    has custom plugins"
    fi
    echo "    --- content (for LLM analysis) ---"
    head -100 "$TW_CONFIG"
    echo "    --- end ---"
else
    echo "    no tailwind config found"
fi

# --- CSS Variables ---
echo ""
echo "  ▸ css variables"
CSS_FILES=$(find "$PROJECT_DIR" -maxdepth 5 -name "*.css" -not -path "*/node_modules/*" -not -path "*/.next/*" -not -path "*/dist/*" 2>/dev/null | head -20)

if [[ -n "$CSS_FILES" ]]; then
    VAR_COUNT=0
    for f in $CSS_FILES; do
        VARS=$(grep -c '\-\-' "$f" 2>/dev/null || echo 0)
        if [[ "$VARS" -gt 0 ]]; then
            echo "    $f ($VARS variables)"
            VAR_COUNT=$((VAR_COUNT + VARS))
        fi
    done
    if [[ "$VAR_COUNT" -eq 0 ]]; then
        echo "    no CSS custom properties found"
    else
        echo "    total variables: $VAR_COUNT"
        # Extract root variables from globals.css or similar
        for f in $CSS_FILES; do
            if grep -q ':root' "$f" 2>/dev/null; then
                echo "    --- root variables from $f ---"
                sed -n '/:root/,/}/p' "$f" | head -60
                echo "    --- end ---"
            fi
        done
    fi
else
    echo "    no CSS files found"
fi

# --- UI Libraries ---
echo ""
echo "  ▸ ui libraries"
PKG="$PROJECT_DIR/package.json"
if [[ -f "$PKG" ]]; then
    # Check for common UI libs
    LIBS=("@radix-ui" "shadcn" "@headlessui" "@chakra-ui" "@mantine" "@mui" "antd" "daisyui" "@nextui" "framer-motion" "react-spring" "gsap" "@react-three" "three" "lottie" "lenis")
    for lib in "${LIBS[@]}"; do
        if grep -q "\"$lib" "$PKG" 2>/dev/null; then
            echo "    ✓ $lib"
        fi
    done
    # Check for motion libraries specifically
    echo ""
    echo "    motion libraries:"
    MOTION_FOUND=false
    for lib in "framer-motion" "react-spring" "gsap" "@formkit/auto-animate" "motion" "lenis"; do
        if grep -q "\"$lib" "$PKG" 2>/dev/null; then
            echo "      ✓ $lib"
            MOTION_FOUND=true
        fi
    done
    if [[ "$MOTION_FOUND" = false ]]; then
        echo "      none found — static cap applies (polish/scroll max 75)"
    fi
else
    echo "    no package.json found"
fi

# --- Theme/design files ---
echo ""
echo "  ▸ theme files"
THEME_FILES=$(find "$PROJECT_DIR" -maxdepth 5 \( -name "theme.*" -o -name "tokens.*" -o -name "design-tokens.*" -o -name "colors.*" -o -name "*.theme.*" \) -not -path "*/node_modules/*" 2>/dev/null | head -10)

if [[ -n "$THEME_FILES" ]]; then
    echo "$THEME_FILES" | while read -r f; do
        echo "    found: $f"
    done
else
    echo "    no dedicated theme files"
fi

# --- Component patterns ---
echo ""
echo "  ▸ component directories"
COMP_DIRS=$(find "$PROJECT_DIR" -maxdepth 4 -type d \( -name "components" -o -name "ui" -o -name "primitives" \) -not -path "*/node_modules/*" 2>/dev/null | head -10)

if [[ -n "$COMP_DIRS" ]]; then
    for d in $COMP_DIRS; do
        COUNT=$(find "$d" -maxdepth 1 -name "*.tsx" -o -name "*.jsx" -o -name "*.vue" -o -name "*.svelte" 2>/dev/null | wc -l | tr -d ' ')
        echo "    $d ($COUNT files)"
    done
else
    echo "    no component directories found"
fi

# --- Font usage ---
echo ""
echo "  ▸ fonts"
FONT_IMPORTS=$(grep -rl "font-family\|@font-face\|next/font\|google.*font" "$PROJECT_DIR" --include="*.css" --include="*.tsx" --include="*.ts" --include="*.jsx" 2>/dev/null | grep -v node_modules | head -5 || true)
if [[ -n "$FONT_IMPORTS" ]]; then
    echo "    font references in:"
    echo "$FONT_IMPORTS" | while read -r f; do echo "      $f"; done
else
    echo "    no custom font imports found"
fi

echo ""
echo "── end extraction ──"
echo "LLM: use this data to write .claude/design-system.md with exact tokens."
