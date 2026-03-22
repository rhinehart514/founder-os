#!/usr/bin/env bash
# claim-verify.sh — Mechanically check if features deliver what they claim.
# Runs each feature's commands, checks output against the delivers: claim.
# Usage: bash skills/shared/claim-verify.sh [project-dir] [feature]
# Output: JSON with per-feature claim verification results
set -uo pipefail

PROJECT_DIR="${1:-.}"
TARGET_FEATURE="${2:-}"
FOUNDER_YML="$PROJECT_DIR/config/founder.yml"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -f "$FOUNDER_YML" ]]; then
    echo '{"error": "no founder.yml found"}'
    exit 1
fi

python3 - "$PROJECT_DIR" "$TARGET_FEATURE" "$FOUNDER_YML" << 'PYEOF'
import json, re, os, sys, subprocess

project_dir = sys.argv[1]
target_feature = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else None
founder_yml = sys.argv[3]

# Parse features from founder.yml
features = {}
current = None
in_features = False
with open(founder_yml) as f:
    for line in f:
        s = line.rstrip()
        if s == "features:":
            in_features = True
            continue
        if in_features:
            if s and not s.startswith(" ") and not s.startswith("#"):
                in_features = False
                continue
            m = re.match(r'^  ([a-zA-Z0-9_-]+):\s*$', s)
            if m:
                current = m.group(1)
                features[current] = {"delivers": "", "commands": [], "code": [], "skills": [], "internal": [], "status": "active"}
                continue
            if current:
                fm = re.match(r'^    ([a-zA-Z_-]+):\s*(.+)$', s)
                if fm:
                    k, v = fm.group(1), fm.group(2).strip().strip('"').strip("'")
                    if k in ("code", "commands", "skills", "internal"):
                        v = [x.strip().strip('"').strip("'") for x in v.strip('[]').split(',') if x.strip()]
                    features[current][k] = v

# Filter
active = {k: v for k, v in features.items() if v.get("status") in ("active", "proven")}
if target_feature:
    active = {k: v for k, v in active.items() if k == target_feature}

results = {}

for fname, feat in active.items():
    claim = feat.get("delivers", "")
    commands = feat.get("commands", []) + feat.get("internal", []) + feat.get("skills", [])
    code_paths = feat.get("code", [])

    verification = {
        "claim": claim,
        "checks": [],
        "score": 0,
        "max_score": 0,
        "verdict": "unknown"
    }

    # --- Check 1: Code exists ---
    code_exists = 0
    code_total = 0
    for cp in code_paths:
        code_total += 1
        # Resolve paths
        full_path = cp
        if cp.startswith("~"):
            full_path = os.path.expanduser(cp)
        elif not cp.startswith("/"):
            full_path = os.path.join(project_dir, cp)

        if os.path.exists(full_path):
            code_exists += 1
            # Check file isn't empty
            try:
                size = os.path.getsize(full_path)
                if size < 10:
                    verification["checks"].append({
                        "check": f"code_exists:{cp}",
                        "pass": False,
                        "detail": f"file exists but is nearly empty ({size} bytes)"
                    })
                    continue
            except:
                pass
            verification["checks"].append({
                "check": f"code_exists:{cp}",
                "pass": True,
                "detail": f"exists ({os.path.getsize(full_path)} bytes)"
            })
        else:
            verification["checks"].append({
                "check": f"code_exists:{cp}",
                "pass": False,
                "detail": "file not found"
            })

    # --- Check 2: Commands run ---
    for cmd in commands:
        # Resolve command to something runnable
        actual_cmd = cmd
        # founder commands -> bin/founder wrapper
        if cmd.startswith("founder "):
            founder_bin = os.path.join(project_dir, "bin", "founder")
            if os.path.exists(founder_bin):
                actual_cmd = f"bash {founder_bin} {cmd[8:]}"
        # npm/npx/yarn/pnpm commands -> run as-is (assumes deps installed)
        # python/node/go commands -> run as-is
        # slash commands (/eval, /plan) -> skip (these are skill invocations, not CLI)
        if cmd.startswith("/"):
            verification["checks"].append({
                "check": f"command_runs:{cmd}",
                "pass": True,
                "detail": "skill invocation — verified by skill existence"
            })
            # Check the skill file exists
            skill_name = cmd.lstrip("/").split()[0]
            skill_path = os.path.join(project_dir, "skills", skill_name, "SKILL.md")
            if not os.path.exists(skill_path):
                # Check .claude/skills too
                skill_path = os.path.join(project_dir, ".claude", "skills", skill_name, "SKILL.md")
            verification["checks"][-1]["pass"] = os.path.exists(skill_path)
            if not os.path.exists(skill_path):
                verification["checks"][-1]["detail"] = f"skill '{skill_name}' not found"
            continue

        try:
            result = subprocess.run(
                actual_cmd, shell=True,
                capture_output=True, text=True,
                timeout=30, cwd=project_dir
            )
            exit_ok = result.returncode == 0
            has_output = len(result.stdout.strip()) > 0
            output_lines = len(result.stdout.strip().split('\n')) if result.stdout.strip() else 0

            verification["checks"].append({
                "check": f"command_runs:{cmd}",
                "pass": exit_ok,
                "detail": f"exit:{result.returncode} lines:{output_lines}",
                "stdout_preview": result.stdout[:200] if result.stdout else "",
                "stderr_preview": result.stderr[:200] if result.stderr else ""
            })

            # --- Check 3: Output substantive (not empty/minimal) ---
            verification["checks"].append({
                "check": f"output_substantive:{cmd}",
                "pass": output_lines >= 3,
                "detail": f"{output_lines} lines of output"
            })

            # --- Check 4: Claim keywords in output ---
            if claim and has_output:
                # Extract key nouns from the claim
                claim_words = set(re.findall(r'\b([a-z]{4,})\b', claim.lower()))
                noise_words = {"that", "this", "with", "from", "have", "been", "into",
                               "than", "they", "them", "were", "more", "each", "also",
                               "does", "make", "solo", "founder", "just", "their",
                               "every", "when", "what", "which", "about"}
                claim_words -= noise_words

                output_lower = result.stdout.lower()
                found = [w for w in claim_words if w in output_lower]
                match_pct = round(len(found) / max(len(claim_words), 1) * 100)

                verification["checks"].append({
                    "check": f"claim_in_output:{cmd}",
                    "pass": match_pct >= 30,
                    "detail": f"{match_pct}% claim keywords found in output ({len(found)}/{len(claim_words)})",
                    "found": found,
                    "missing": sorted(claim_words - set(found))
                })

        except subprocess.TimeoutExpired:
            verification["checks"].append({
                "check": f"command_runs:{cmd}",
                "pass": False,
                "detail": "timeout (30s)"
            })
        except Exception as e:
            verification["checks"].append({
                "check": f"command_runs:{cmd}",
                "pass": False,
                "detail": str(e)
            })

    # --- Check 5: Code paths referenced in claim exist in actual code ---
    # Does the code contain logic that matches the claim's intent?
    if claim and code_paths:
        claim_keywords = set(re.findall(r'\b([a-z]{4,})\b', claim.lower())) - noise_words
        code_matches = 0
        for cp in code_paths:
            full_path = cp if cp.startswith("/") else os.path.join(project_dir, cp.replace("~", os.path.expanduser("~")))
            if not os.path.exists(full_path):
                continue
            try:
                with open(full_path) as f:
                    code_content = f.read().lower()
                matches = [w for w in claim_keywords if w in code_content]
                if len(matches) >= len(claim_keywords) * 0.3:
                    code_matches += 1
            except:
                pass

        verification["checks"].append({
            "check": "claim_in_code",
            "pass": code_matches > 0,
            "detail": f"{code_matches}/{len(code_paths)} code files contain claim-relevant logic"
        })

    # Score
    passed = sum(1 for c in verification["checks"] if c["pass"])
    total = len(verification["checks"])
    verification["score"] = passed
    verification["max_score"] = total
    pct = round(passed / max(total, 1) * 100)

    if pct >= 80:
        verification["verdict"] = "delivering"
    elif pct >= 50:
        verification["verdict"] = "partial"
    elif pct >= 20:
        verification["verdict"] = "gap"
    else:
        verification["verdict"] = "broken"

    verification["pass_rate"] = pct
    results[fname] = verification

# Overall
total_pass = sum(r["score"] for r in results.values())
total_max = sum(r["max_score"] for r in results.values())
overall_pct = round(total_pass / max(total_max, 1) * 100)

output = {
    "features": results,
    "overall_pass_rate": overall_pct,
    "feature_count": len(results),
    "verdicts": {v: sum(1 for r in results.values() if r["verdict"] == v)
                 for v in ("delivering", "partial", "gap", "broken")}
}

print(json.dumps(output, indent=2))

# Cache results for downstream consumers (product-nudge, coherence-check, product-brief)
cache_path = os.path.join(project_dir, ".claude", "cache", "claim-verify.json")
os.makedirs(os.path.dirname(cache_path), exist_ok=True)
with open(cache_path, "w") as f:
    json.dump(output, f, indent=2)
PYEOF
