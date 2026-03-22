#!/usr/bin/env bash
# config.sh — Shared config reader for founder-os components.
# Sources founder.yml and provides cfg() function.
#
# Usage (from any bin/ script):
#   source "$(dirname "$0")/lib/config.sh"
#   cache_ttl=$(cfg scoring.cache_ttl 300)

if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    _FOUNDER_CONFIG_DIR="$CLAUDE_PLUGIN_ROOT"
else
    _FOUNDER_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
_FOUNDER_CONFIG_FILE="$_FOUNDER_CONFIG_DIR/config/founder.yml"

# Discover all lens configs (glob into array, last match wins in cfg())
_FOUNDER_LENS_CONFIGS=()
for _lc in "$_FOUNDER_CONFIG_DIR"/lens/*/config/founder-*.yml; do
    [[ -f "$_lc" ]] && _FOUNDER_LENS_CONFIGS+=("$_lc")
done

# Read a dotted key from a YAML file.
# Usage: _cfg_from_file "file.yml" "key.path" "default"
_cfg_from_file() {
    local file="$1"
    local key="$2"
    local default="${3:-}"
    if [[ ! -f "$file" ]]; then
        echo "$default"
        return 1
    fi

    local OLD_IFS="$IFS"
    IFS='.'
    read -ra parts <<< "$key"
    IFS="$OLD_IFS"
    local matched=0
    local target_indent=-1

    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Count leading spaces (bash 3 compatible — [![:space:]] broken in parameter expansion)
        local stripped="$line"
        while [[ "${stripped:0:1}" == " " || "${stripped:0:1}" == "	" ]]; do
            stripped="${stripped:1}"
        done
        local spaces=$(( ${#line} - ${#stripped} ))

        # If we've matched some parts but indent went back, reset
        if [[ "$matched" -gt 0 && "$target_indent" -ge 0 && "$spaces" -le "$target_indent" && "$matched" -lt "${#parts[@]}" ]]; then
            matched=0
            target_indent=-1
        fi

        if [[ "$stripped" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*):(.*)$ ]]; then
            local ykey="${BASH_REMATCH[1]}"
            local yval="${BASH_REMATCH[2]}"
            # Strip leading whitespace from value (bash 3 compatible)
            while [[ "${yval:0:1}" == " " || "${yval:0:1}" == "	" ]]; do
                yval="${yval:1}"
            done

            if [[ "$ykey" == "${parts[$matched]}" ]]; then
                ((matched++))
                target_indent=$spaces
                if [[ "$matched" -eq "${#parts[@]}" ]]; then
                    # Strip inline comments: remove " #..." suffix
                    yval="${yval%%[[:space:]]#*}"
                    # Strip trailing whitespace (bash 3 compatible)
                    while [[ "${yval: -1}" == " " || "${yval: -1}" == "	" ]]; do
                        yval="${yval%?}"
                    done
                    if [[ -z "$yval" || "$yval" == "~" ]]; then
                        echo "$default"
                    else
                        echo "$yval"
                    fi
                    return 0
                fi
            fi
        fi
    done < "$file"
    echo "$default"
    return 1
}

# Read a dotted key. Checks all lens configs (last match wins), then base config.
# Usage: cfg "scoring.cache_ttl" "300"
cfg() {
    local key="$1"
    local default="${2:-}"

    # Try lens configs (iterate all, last match wins)
    local lens_val="" found=false
    for _lcf in "${_FOUNDER_LENS_CONFIGS[@]}"; do
        [[ ! -f "$_lcf" ]] && continue
        local _v
        _v=$(_cfg_from_file "$_lcf" "$key" "")
        if [[ $? -eq 0 && -n "$_v" ]]; then
            lens_val="$_v"
            found=true
        fi
    done
    if [[ "$found" == "true" ]]; then
        echo "$lens_val"
        return
    fi

    # Fall back to base config
    _cfg_from_file "$_FOUNDER_CONFIG_FILE" "$key" "$default"
}
