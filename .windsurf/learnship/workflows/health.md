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
node -e "const fs=require('fs'); console.log(fs.existsSync('.planning') ? 'OK' : 'MISSING')"
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
node -e "const fs=require('fs'); if(!fs.existsSync('.planning/PROJECT.md')) console.log('E002: PROJECT.md not found')"
node -e "const fs=require('fs'); if(!fs.existsSync('.planning/ROADMAP.md')) console.log('E003: ROADMAP.md not found')"
node -e "const fs=require('fs'); if(!fs.existsSync('.planning/STATE.md')) console.log('E004: STATE.md not found (repairable)')"
node -e "const fs=require('fs'); if(!fs.existsSync('.planning/config.json')) console.log('W003: config.json not found (repairable)')"
```

### Config Validity
```bash
node -e "try{JSON.parse(require('fs').readFileSync('.planning/config.json','utf8'))}catch(e){console.log('E005: config.json parse error (repairable)')}"
```

### State / Roadmap Consistency
```bash
node -e "
const fs=require('fs');
if(!fs.existsSync('.planning/STATE.md')||!fs.existsSync('.planning/ROADMAP.md'))process.exit(0);
const state=fs.readFileSync('.planning/STATE.md','utf8');
const m=state.match(/^Phase:\s*(\d+)/m);
if(m){
  const roadmap=fs.readFileSync('.planning/ROADMAP.md','utf8');
  if(!roadmap.includes('Phase '+m[1]+':'))console.log('W002: STATE.md references phase '+m[1]+' not found in roadmap (repairable)');
}
"
```

### Phase Directory Checks
```bash
node -e "
const fs=require('fs'),path=require('path');
if(!fs.existsSync('.planning/ROADMAP.md'))process.exit(0);
const roadmap=fs.readFileSync('.planning/ROADMAP.md','utf8');
const phases=[...roadmap.matchAll(/^## Phase (\d+):/mg)].map(m=>m[1]);
const phasesDir='.planning/phases';
const dirs=fs.existsSync(phasesDir)?fs.readdirSync(phasesDir):[];
for(const n of phases){
  const pad=n.padStart(2,'0');
  if(!dirs.some(d=>d.startsWith(pad+'-')))console.log('W006: Phase '+n+' in roadmap but no directory');
}
for(const d of dirs){
  const slug=d.replace(/^\d+-/,'');
  if(!roadmap.includes(slug))console.log('W007: Directory '+d+' not in roadmap');
}
"
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
# PowerShell: git status --short .planning/ 2>$null | Select-Object -First 10
```

### Config Fields
```bash
node -e "
try{
  const cfg=JSON.parse(require('fs').readFileSync('.planning/config.json','utf8'));
  const top=['mode','granularity','model_profile','learning_mode','parallelization','test_first'].filter(k=>!(k in cfg));
  const nested=[];
  if(!cfg.planning||!('commit_mode' in cfg.planning)) nested.push('planning.commit_mode');
  if(!cfg.workflow||!('review' in cfg.workflow)) nested.push('workflow.review');
  if(!cfg.workflow||!('solutions_search' in cfg.workflow)) nested.push('workflow.solutions_search');
  if(!cfg.review||!('auto_after_verify' in cfg.review)) nested.push('review.auto_after_verify');
  if(!cfg.ship) nested.push('ship.*');
  const missing=[...top,...nested];
  if(missing.length)console.log('W004: config.json missing fields: '+missing.join(', '));
}catch(e){}
"
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
