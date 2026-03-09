---
description: Project health check — stale files, uncommitted changes, missing artifacts, config drift
---

# Health

Validate `.planning/` directory integrity and report actionable issues. Optionally repairs auto-fixable problems.

**Usage:** `health` or `health --repair`

## Step 1: Parse Arguments

Check if `--repair` flag is present.

## Step 2: Check Project Exists

```bash
test -d .planning && echo "OK" || echo "MISSING"
```

If `.planning/` doesn't exist:
```
No .planning/ directory found.

This project hasn't been initialized. Run new-project to start.
```
Stop.

## Step 3: Run Health Checks

Run the following checks and classify each as error, warning, or info:

### Required Files
```bash
test -f .planning/PROJECT.md   || echo "E002: PROJECT.md not found"
test -f .planning/ROADMAP.md   || echo "E003: ROADMAP.md not found"
test -f .planning/STATE.md     || echo "E004: STATE.md not found (repairable)"
test -f .planning/config.json  || echo "W003: config.json not found (repairable)"
```

### Config Validity
```bash
cat .planning/config.json | python3 -c "import sys,json; json.load(sys.stdin)" 2>&1 || echo "E005: config.json parse error (repairable)"
```

### State / Roadmap Consistency
```bash
# Check if STATE.md references a phase that exists in ROADMAP.md
CURRENT_PHASE=$(grep -E "^Phase:" .planning/STATE.md 2>/dev/null | head -1 | grep -oE "[0-9]+")
if [ -n "$CURRENT_PHASE" ]; then
  grep -q "Phase ${CURRENT_PHASE}:" .planning/ROADMAP.md || echo "W002: STATE.md references phase ${CURRENT_PHASE} not found in roadmap (repairable)"
fi
```

### Phase Directory Checks
```bash
# Phases in ROADMAP but no directory
grep -oE "Phase [0-9]+:" .planning/ROADMAP.md | while read phase; do
  num=$(echo "$phase" | grep -oE "[0-9]+")
  padded=$(printf "%02d" $num)
  ls .planning/phases/${padded}-* 2>/dev/null | head -1 || echo "W006: Phase ${num} in roadmap but no directory"
done

# Phase directories not in ROADMAP
for dir in .planning/phases/*/; do
  slug=$(basename "$dir" | sed 's/^[0-9]*-//')
  grep -q "$slug" .planning/ROADMAP.md || echo "W007: Directory $(basename $dir) not in roadmap"
done
```

### Plans Without Summaries
```bash
for plan in .planning/phases/*/*-PLAN.md; do
  summary="${plan%-PLAN.md}-SUMMARY.md"
  test -f "$summary" || echo "I001: $(basename $plan) has no SUMMARY (may be in progress)"
done
```

### Uncommitted Changes
```bash
git status --short .planning/ 2>/dev/null | head -10
```

### Config Fields
```bash
# Check for required config keys
python3 -c "
import json
cfg = json.load(open('.planning/config.json'))
missing = []
for key in ['mode', 'granularity', 'model_profile', 'learning_mode']:
    if key not in cfg:
        missing.append(key)
if missing:
    print('W004: config.json missing fields: ' + ', '.join(missing))
" 2>/dev/null
```

## Step 4: Format Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► HEALTH CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status: HEALTHY | DEGRADED | BROKEN
Errors: [N]   Warnings: [N]   Info: [N]
```

**Errors** (must fix):
```
[E002] PROJECT.md not found
  Fix: Run new-project to initialize

[E005] config.json parse error
  Fix: Run health --repair to reset to defaults
```

**Warnings** (should fix):
```
[W002] STATE.md references phase 5, but only phases 1-3 exist in roadmap
  Fix: Run health --repair to regenerate STATE.md

[W006] Phase 4 in roadmap but no directory
  Fix: Create .planning/phases/04-[slug]/ manually
```

**Info** (no action needed):
```
[I001] 02-auth/02-01-PLAN.md has no SUMMARY.md
  Note: May be in progress
```

**If uncommitted .planning/ changes:**
```
Uncommitted changes in .planning/:
  M .planning/STATE.md
  ? .planning/phases/03-api/03-01-PLAN.md

Consider: git add .planning/ && git commit -m "docs: update planning artifacts"
```

**Footer if repairable issues and --repair not used:**
```
[N] issue(s) can be auto-repaired. Run: health --repair
```

## Step 5: Repair (if --repair flag)

Run repairs for each repairable issue found:

| Issue | Repair action |
|-------|--------------|
| `STATE.md not found` | Generate from ROADMAP.md structure with current phase from roadmap |
| `config.json not found` | Create with defaults from `templates/config.json` |
| `config.json parse error` | Reset to defaults (warn: loses custom settings) |
| `config.json missing fields` | Add missing fields with default values |

For each repair:
```bash
# Example: regenerate STATE.md
cp templates/state.md .planning/STATE.md
# Then fill in project name from PROJECT.md and current phase from ROADMAP.md
```

After repairs, re-run the health checks and report final status.

**Not repairable:**
- `PROJECT.md`, `ROADMAP.md` content (too risky to auto-generate)
- Phase directory renaming
- Orphaned plan cleanup
