# grade-consolidation.sh — Knowledge consolidation + staleness detection
#
# Functions: consolidate_knowledge, detect_stale_entries
#
# Requires: PROJECT_DIR, PRED_FILE, QUIET (set by parent grade.sh)

# --- Consolidate knowledge: append model_updates to experiment-learnings.md ---
consolidate_knowledge() {
    local learnings_file="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
    [[ ! -f "$learnings_file" ]] && learnings_file="$HOME/.claude/knowledge/experiment-learnings.md"
    [[ ! -f "$learnings_file" ]] && return 0

    # Collect new updates by zone: known, uncertain, dead_end
    local known_entries="" uncertain_entries="" dead_entries=""
    local consolidated=0

    while IFS=$'\t' read -r _date _agent _prediction _evidence _result _correct model_update; do
        [[ -z "$model_update" ]] && continue
        [[ -z "$_correct" ]] && continue

        # Deduplicate: skip if date + first 40 chars of update already present
        local dedup_key="${_date}) ${model_update:0:40}"
        dedup_key=$(echo "$dedup_key" | tr -s ' ')  # normalize whitespace
        if grep -qF "$dedup_key" "$learnings_file" 2>/dev/null; then
            continue
        fi
        # Also check without date prefix (catches reformatted entries)
        local dedup_content="${model_update:0:50}"
        dedup_content=$(echo "$dedup_content" | tr -s ' ')
        if grep -qF "$dedup_content" "$learnings_file" 2>/dev/null; then
            continue
        fi

        # Skip empty model_updates (tautological predictions filtered upstream)
        [[ -z "$model_update" || "$model_update" == "Confirmed: " ]] && continue

        # Tautology filter: model_update must contain a mechanism word/phrase
        # Not just restating the outcome — must explain WHY
        if ! echo "$model_update" | grep -qiE 'because|the assumption was|discovered that|the mechanism|turns out|caused by|due to|implies that|root cause|the reason|driven by|explained by|which means|indicating|suggests that'; then
            $QUIET || echo "  ⚠ Skipping tautological model_update (no mechanism): ${model_update:0:60}"
            continue
        fi

        local entry="- (${_date}) ${model_update}"

        # Route to correct zone based on grading result
        case "$_correct" in
            yes)
                # Count how many similar entries already exist in Known Patterns
                local known_count=0
                # Extract a keyword from the prediction for matching (first 3+ char word)
                local keyword=""
                if [[ "$_prediction" =~ ([a-zA-Z_-]{4,}) ]]; then
                    keyword="${BASH_REMATCH[1]}"
                fi
                if [[ -n "$keyword" ]]; then
                    # Count entries in Known Patterns section that reference this keyword
                    known_count=$(awk '/^## Known Patterns/,/^## [A-Z]/' "$learnings_file" | grep -ciF "$keyword" 2>/dev/null || echo "0")
                fi
                if [[ "$known_count" -ge 2 ]]; then
                    # 2+ existing matches + this new one = 3+ → Known Patterns
                    known_entries="${known_entries}\n${entry}"
                else
                    # <3 matching entries → Uncertain Patterns
                    uncertain_entries="${uncertain_entries}\n${entry}"
                fi
                ;;
            no)
                # Check if this is a repeated failure (dead end candidate)
                local fail_count=0
                local fail_keyword=""
                if [[ "$_prediction" =~ ([a-zA-Z_-]{4,}) ]]; then
                    fail_keyword="${BASH_REMATCH[1]}"
                fi
                if [[ -n "$fail_keyword" ]]; then
                    fail_count=$(awk '/^## Dead Ends/,0' "$learnings_file" | grep -ciF "$fail_keyword" 2>/dev/null || echo "0")
                fi
                if [[ "$fail_count" -ge 1 ]]; then
                    # Already a dead end entry → add to Dead Ends
                    dead_entries="${dead_entries}\n${entry}"
                else
                    # First failure → Uncertain Patterns (might be noise)
                    uncertain_entries="${uncertain_entries}\n${entry}"
                fi
                ;;
            partial)
                # Partial results always go to Uncertain Patterns
                uncertain_entries="${uncertain_entries}\n${entry}"
                ;;
        esac
        consolidated=$((consolidated + 1))
    done < <(tail -n +2 "$PRED_FILE")

    [[ "$consolidated" -eq 0 ]] && return 0

    # Insert entries into their correct zones
    local temp_learnings
    temp_learnings=$(mktemp)
    local inserted_known=false inserted_uncertain=false inserted_dead=false

    while IFS= read -r line; do
        # Insert known entries before "## Uncertain Patterns"
        if [[ "$line" == "## Uncertain Patterns"* ]] && ! $inserted_known && [[ -n "$known_entries" ]]; then
            printf "%b\n\n" "$known_entries" >> "$temp_learnings"
            inserted_known=true
        fi
        # Insert uncertain entries before "## Unknown Territory"
        if [[ "$line" == "## Unknown Territory"* ]] && ! $inserted_uncertain && [[ -n "$uncertain_entries" ]]; then
            printf "%b\n\n" "$uncertain_entries" >> "$temp_learnings"
            inserted_uncertain=true
        fi
        # Insert dead end entries before end-of-file (after "## Dead Ends" section heading)
        if [[ "$line" == "## Dead Ends"* ]] && ! $inserted_dead && [[ -n "$dead_entries" ]]; then
            printf "%s\n" "$line" >> "$temp_learnings"
            # Read next line (usually blank or first entry) then insert
            printf "%b\n" "$dead_entries" >> "$temp_learnings"
            inserted_dead=true
            continue
        fi
        printf "%s\n" "$line" >> "$temp_learnings"
    done < "$learnings_file"

    # Fallback: if sections weren't found, append at end
    if [[ -n "$known_entries" ]] && ! $inserted_known; then
        printf "\n%b\n" "$known_entries" >> "$temp_learnings"
    fi
    if [[ -n "$uncertain_entries" ]] && ! $inserted_uncertain; then
        printf "\n%b\n" "$uncertain_entries" >> "$temp_learnings"
    fi
    if [[ -n "$dead_entries" ]] && ! $inserted_dead; then
        printf "\n%b\n" "$dead_entries" >> "$temp_learnings"
    fi

    mv "$temp_learnings" "$learnings_file"
    $QUIET || echo "Consolidated $consolidated learning(s) into experiment-learnings.md"

    # Post-consolidation: deduplicate and promote
    detect_duplicates "$learnings_file"
    promote_uncertain_to_known "$learnings_file"
}

# --- Staleness detection: flag entries not referenced by predictions in 30+ days ---
detect_stale_entries() {
    local learnings_file="$PROJECT_DIR/.claude/knowledge/experiment-learnings.md"
    [[ ! -f "$learnings_file" ]] && learnings_file="$HOME/.claude/knowledge/experiment-learnings.md"
    [[ ! -f "$learnings_file" ]] && return 0

    local stale_days=30
    local cutoff_date
    cutoff_date=$(date -v-${stale_days}d '+%Y-%m-%d' 2>/dev/null || date -d "${stale_days} days ago" '+%Y-%m-%d' 2>/dev/null || echo "")
    [[ -z "$cutoff_date" ]] && return 0

    # Extract dated entries and check which are stale
    local stale_entries=0
    local total_dated=0
    local stale_list=""

    while IFS= read -r entry_line; do
        local entry_date=""
        if [[ "$entry_line" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
            entry_date="${BASH_REMATCH[1]}"
        else
            continue
        fi
        total_dated=$((total_dated + 1))

        if [[ "$entry_date" < "$cutoff_date" ]]; then
            # Check if any recent prediction references this entry
            local entry_snippet="${entry_line:0:60}"
            entry_snippet="${entry_snippet//\"/}"
            local referenced=false
            if [[ -f "$PRED_FILE" ]]; then
                if tail -n +2 "$PRED_FILE" | awk -F'\t' -v cutoff="$cutoff_date" '$1 >= cutoff' | grep -qiF "${entry_snippet:0:25}" 2>/dev/null; then
                    referenced=true
                fi
            fi
            if [[ "$referenced" == "false" ]]; then
                stale_entries=$((stale_entries + 1))
                local display="${entry_line:0:80}"
                stale_list="${stale_list}\n    ${display}..."
            fi
        fi
    done < <(grep '^\s*-\s.*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}' "$learnings_file" 2>/dev/null)

    if [[ "$stale_entries" -gt 0 ]]; then
        $QUIET || echo ""
        $QUIET || echo "Stale knowledge: ${stale_entries} entries not referenced in ${stale_days}d"
        if [[ "$QUIET" == false && -n "$stale_list" ]]; then
            echo -e "$stale_list" | head -5
            [[ "$stale_entries" -gt 5 ]] && echo "    ... and $((stale_entries - 5)) more. Run /retro to prune."
        fi

        # Demote stale Known Patterns → Uncertain Patterns
        # Only demote entries in Known Patterns section that are stale
        local known_section=""
        known_section=$(awk '/^## Known Patterns/,/^## [A-Z]/' "$learnings_file" 2>/dev/null)
        local demoted=0
        while IFS= read -r stale_line; do
            stale_line="${stale_line#    }"  # strip leading spaces from stale_list
            [[ -z "$stale_line" ]] && continue
            # Check if this stale entry is in Known Patterns
            local snippet="${stale_line:0:40}"
            if echo "$known_section" | grep -qF "$snippet" 2>/dev/null; then
                # Mark as stale in-place (non-destructive — /retro can fully prune)
                if [[ "$stale_line" != *"(stale)"* ]]; then
                    local escaped_snippet
                    escaped_snippet=$(printf '%s\n' "$snippet" | sed 's/[[\.*^$()+?{|]/\\&/g')
                    sed "s|${escaped_snippet}|${snippet} (stale)|" "$learnings_file" > "$learnings_file.tmp" 2>/dev/null && mv "$learnings_file.tmp" "$learnings_file" && demoted=$((demoted + 1))
                fi
            fi
        done <<< "$(echo -e "$stale_list")"
        [[ "$demoted" -gt 0 ]] && $QUIET || true
    fi
}

# --- Deduplicate entries: entries sharing the same first 4+ words are duplicates ---
detect_duplicates() {
    local learnings_file="$1"
    [[ ! -f "$learnings_file" ]] && return 0

    local temp_dedup
    temp_dedup=$(mktemp)
    local removed=0

    # Build a list of "first 4 words" keys we've seen, keeping the last (most recent) occurrence
    # Strategy: read the file, for each bullet entry extract first 4+ words after the date,
    # if we've seen that key before, mark the EARLIER line for removal

    # Collect all entry lines with their line numbers and keys
    local -a entry_lines=()
    local -a entry_keys=()
    local line_num=0

    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # Match bullet entries: "- (date) content" or "- content"
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
            # Strip leading "- (YYYY-MM-DD) " or "- " to get content
            local content="$line"
            content="${content#*- }"
            content="${content#(????-??-??) }"
            content="${content#(????) }"
            # Extract first 4 words as dedup key
            local key
            key=$(echo "$content" | awk '{for(i=1;i<=4&&i<=NF;i++) printf "%s ", $i; print ""}' | tr -s ' ' | sed 's/ *$//' | tr '[:upper:]' '[:lower:]')
            if [[ ${#key} -ge 8 ]]; then
                entry_lines+=("$line_num")
                entry_keys+=("$key")
            fi
        fi
    done < "$learnings_file"

    # Find duplicates: for each key, keep only the last occurrence (most recent)
    local -a remove_lines=()
    local i j
    for ((i=0; i<${#entry_keys[@]}; i++)); do
        for ((j=i+1; j<${#entry_keys[@]}; j++)); do
            if [[ "${entry_keys[$i]}" == "${entry_keys[$j]}" ]]; then
                # Mark the earlier one for removal
                remove_lines+=("${entry_lines[$i]}")
                removed=$((removed + 1))
                break
            fi
        done
    done

    if [[ "$removed" -eq 0 ]]; then
        rm -f "$temp_dedup"
        return 0
    fi

    # Rebuild file without removed lines
    line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        local should_remove=false
        for rm_line in "${remove_lines[@]}"; do
            if [[ "$line_num" -eq "$rm_line" ]]; then
                should_remove=true
                break
            fi
        done
        if ! $should_remove; then
            printf "%s\n" "$line" >> "$temp_dedup"
        fi
    done < "$learnings_file"

    mv "$temp_dedup" "$learnings_file"
    $QUIET || echo "Deduplicated: removed $removed duplicate entries from experiment-learnings.md"
}

# --- Promote uncertain entries to known when they have 3+ supporting evidence ---
promote_uncertain_to_known() {
    local learnings_file="$1"
    [[ ! -f "$learnings_file" ]] && return 0

    # Extract Uncertain Patterns section entries
    local uncertain_section
    uncertain_section=$(awk '/^## Uncertain Patterns/,/^## [A-Z]/' "$learnings_file" 2>/dev/null)
    [[ -z "$uncertain_section" ]] && return 0

    local promoted=0
    local entries_to_promote=""

    # For each entry in Uncertain Patterns, count supporting evidence
    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        # Extract a meaningful keyword from the entry (skip dates and common words)
        local content="$entry"
        content="${content#*- }"
        content="${content#(????-??-??) }"

        # Get first distinctive keyword (4+ chars, not a common word)
        local keyword
        keyword=$(echo "$content" | grep -oE '[a-zA-Z_-]{4,}' | \
            grep -viE '^(will|from|that|this|with|have|been|into|than|they|them|were|more|each|also|does|make|confirmed|wrong|partial|mechanism|predicted|because|about|after|before|model|update|held)$' | \
            head -1)
        [[ -z "$keyword" ]] && continue

        # Count how many entries across the ENTIRE file reference this keyword
        local total_refs
        total_refs=$(grep -ciF "$keyword" "$learnings_file" 2>/dev/null || echo "0")

        # If 3+ references exist (including this one), promote
        if [[ "$total_refs" -ge 3 ]]; then
            entries_to_promote="${entries_to_promote}${entry}\n"
            promoted=$((promoted + 1))
        fi
    done < <(echo "$uncertain_section" | grep '^\s*-\s')

    [[ "$promoted" -eq 0 ]] && return 0

    # Move entries: remove from Uncertain, add to Known
    local temp_promote
    temp_promote=$(mktemp)
    local in_uncertain=false
    local inserted_promoted=false

    while IFS= read -r line; do
        if [[ "$line" == "## Known Patterns"* ]]; then
            printf "%s\n" "$line" >> "$temp_promote"
            # Insert promoted entries right after the Known Patterns header
            # (read past any existing content line first)
            inserted_promoted=true
            continue
        fi

        # After Known Patterns header, insert promoted entries before first blank line or next entry
        if [[ "$inserted_promoted" == true ]]; then
            printf "%s\n" "$line" >> "$temp_promote"
            if [[ -z "$line" || "$line" =~ ^[[:space:]]*$ ]]; then
                printf "%b" "$entries_to_promote" >> "$temp_promote"
                inserted_promoted=false
            fi
            continue
        fi

        if [[ "$line" == "## Uncertain Patterns"* ]]; then
            in_uncertain=true
            printf "%s\n" "$line" >> "$temp_promote"
            continue
        fi
        if $in_uncertain && [[ "$line" == "## "* ]]; then
            in_uncertain=false
        fi

        # Skip promoted entries from uncertain section
        if $in_uncertain && [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
            local skip_this=false
            while IFS= read -r promo_entry; do
                [[ -z "$promo_entry" ]] && continue
                local promo_snippet="${promo_entry:0:50}"
                if [[ "$line" == *"$promo_snippet"* ]]; then
                    skip_this=true
                    break
                fi
            done < <(printf "%b" "$entries_to_promote")
            if $skip_this; then
                continue
            fi
        fi

        printf "%s\n" "$line" >> "$temp_promote"
    done < "$learnings_file"

    # Fallback: if Known Patterns header wasn't found, don't modify
    if [[ "$inserted_promoted" == true ]]; then
        # Never found blank line after header — append at end of temp
        printf "%b" "$entries_to_promote" >> "$temp_promote"
    fi

    mv "$temp_promote" "$learnings_file"
    $QUIET || echo "Promoted $promoted entry(ies) from Uncertain → Known Patterns (3+ supporting evidence)"
}
