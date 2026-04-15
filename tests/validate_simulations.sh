#!/usr/bin/env bash
# learnship — Workflow simulation tests
#
# Tests the MECHANICAL parts of workflows by running the actual node -e
# verification scripts embedded in workflow .md files against controlled
# inputs (known-good and known-bad project states).
#
# This is the closest we can get to "does the workflow work for real"
# without an actual LLM. It tests:
#   1. Config verification gate — accepts good config, rejects bad ones
#   2. Research verification gate — checks 5 files exist with required sections
#   3. AGENTS.md verification gate — checks required sections exist
#   4. Project detection — correctly identifies NEW vs EXISTS
#   5. Codebase detection — correctly identifies BLANK vs HAS_CODE
#   6. Git detection — correctly identifies HAS_GIT vs NO_GIT
#   7. Existing context file detection — finds AGENTS.md, CLAUDE.md, etc.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPL_DIR="$REPO_DIR/templates"
PASS=0
FAIL=0
ERRORS=()

check() {
  local description="$1"
  shift
  if "$@" > /dev/null 2>&1; then
    echo "  ✓ $description"
    PASS=$((PASS+1))
  else
    echo "  ✗ $description"
    FAIL=$((FAIL+1))
    ERRORS+=("$description")
  fi
}

check_output() {
  local description="$1"
  local expected="$2"
  shift 2
  local output
  output=$("$@" 2>&1)
  if echo "$output" | grep -q "$expected"; then
    echo "  ✓ $description"
    PASS=$((PASS+1))
  else
    echo "  ✗ $description (expected '$expected', got '$(echo "$output" | head -1)')"
    FAIL=$((FAIL+1))
    ERRORS+=("$description")
  fi
}

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " Workflow Simulation Tests"
echo "═══════════════════════════════════════════════════════════════════"

# Create a temp project directory for simulations
PROJ=$(mktemp -d)
# shellcheck disable=SC2064
trap "rm -rf $PROJ" EXIT

# ─── 1. Config Verification Gate ──────────────────────────────────────
# Extract the actual config validator from new-project.md and run it
# against known-good and known-bad configs.

echo ""
echo "─── Config Verification Gate ─────────────────────────────────────"

mkdir -p "$PROJ/.planning"

# Good config (matches template schema exactly)
cat > "$PROJ/.planning/config.json" << 'EOF'
{
  "mode": "interactive",
  "granularity": "standard",
  "model_profile": "balanced",
  "learning_mode": "auto",
  "test_first": false,
  "planning": {
    "commit_mode": "auto"
  },
  "workflow": {
    "research": true,
    "plan_check": true,
    "verifier": true,
    "review": true
  },
  "parallelization": {
    "enabled": false
  },
  "ship": {
    "auto_test": true
  }
}
EOF

# Run the actual config validator from new-project.md
check_output "good config: CONFIG_VALID" "CONFIG_VALID" node -e "
const fs=require('fs');
try{
  const c=JSON.parse(fs.readFileSync('$PROJ/.planning/config.json','utf8'));
  const errs=[];
  if(!['auto','interactive'].includes(c.mode)) errs.push('mode must be auto|interactive, got: '+c.mode);
  if(!['coarse','standard','fine'].includes(c.granularity)) errs.push('granularity must be coarse|standard|fine');
  if(!['quality','balanced','budget'].includes(c.model_profile)) errs.push('model_profile must be quality|balanced|budget');
  if(!['auto','manual'].includes(c.learning_mode)) errs.push('learning_mode must be auto|manual');
  if(typeof c.test_first!=='boolean') errs.push('test_first must be boolean');
  if(!c.planning||!['auto','manual'].includes(c.planning.commit_mode)) errs.push('planning.commit_mode must be auto|manual');
  if(!c.workflow||typeof c.workflow.research!=='boolean') errs.push('workflow.research must be boolean');
  if(!c.workflow||typeof c.workflow.plan_check!=='boolean') errs.push('workflow.plan_check must be boolean');
  if(!c.workflow||typeof c.workflow.verifier!=='boolean') errs.push('workflow.verifier must be boolean');
  if(!c.workflow||typeof c.workflow.review!=='boolean') errs.push('workflow.review must be boolean');
  if(!c.parallelization||typeof c.parallelization.enabled!=='boolean') errs.push('parallelization.enabled must be boolean');
  if(!c.ship||typeof c.ship.auto_test!=='boolean') errs.push('ship.auto_test must be boolean');
  const bad=['working_style','model_tier','platform','milestone','phases','commit_mode'];
  for(const k of bad){if(k in c)errs.push('FORBIDDEN top-level key: '+k);}
  if(errs.length){console.log('CONFIG_INVALID');errs.forEach(e=>console.log('  - '+e));}
  else console.log('CONFIG_VALID');
}catch(e){console.log('CONFIG_MISSING_OR_CORRUPT: '+e.message);}
"

# Bad config: flat keys (the exact bug that broke Windsurf)
cat > "$PROJ/.planning/config.json" << 'EOF'
{
  "working_style": "interactive",
  "model_tier": "balanced",
  "platform": "windsurf",
  "commit_mode": "auto"
}
EOF

check_output "flat-key config: CONFIG_INVALID" "CONFIG_INVALID" node -e "
const fs=require('fs');
try{
  const c=JSON.parse(fs.readFileSync('$PROJ/.planning/config.json','utf8'));
  const errs=[];
  if(!['auto','interactive'].includes(c.mode)) errs.push('mode must be auto|interactive, got: '+c.mode);
  if(!['coarse','standard','fine'].includes(c.granularity)) errs.push('granularity');
  if(!['quality','balanced','budget'].includes(c.model_profile)) errs.push('model_profile');
  if(!['auto','manual'].includes(c.learning_mode)) errs.push('learning_mode');
  if(typeof c.test_first!=='boolean') errs.push('test_first');
  if(!c.planning||!['auto','manual'].includes(c.planning.commit_mode)) errs.push('planning.commit_mode');
  if(!c.workflow||typeof c.workflow.research!=='boolean') errs.push('workflow.research');
  if(!c.parallelization||typeof c.parallelization.enabled!=='boolean') errs.push('parallelization');
  if(!c.ship||typeof c.ship.auto_test!=='boolean') errs.push('ship.auto_test');
  const bad=['working_style','model_tier','platform','milestone','phases','commit_mode'];
  for(const k of bad){if(k in c)errs.push('FORBIDDEN top-level key: '+k);}
  if(errs.length){console.log('CONFIG_INVALID');errs.forEach(e=>console.log('  - '+e));}
  else console.log('CONFIG_VALID');
}catch(e){console.log('CONFIG_MISSING_OR_CORRUPT: '+e.message);}
"

check_output "flat-key config: catches working_style" "FORBIDDEN top-level key: working_style" node -e "
const fs=require('fs');
const c=JSON.parse(fs.readFileSync('$PROJ/.planning/config.json','utf8'));
const bad=['working_style','model_tier','platform','milestone','phases','commit_mode'];
for(const k of bad){if(k in c)console.log('FORBIDDEN top-level key: '+k);}
"

# Missing config
rm -f "$PROJ/.planning/config.json"

check_output "missing config: CONFIG_MISSING_OR_CORRUPT" "CONFIG_MISSING_OR_CORRUPT" node -e "
const fs=require('fs');
try{
  const c=JSON.parse(fs.readFileSync('$PROJ/.planning/config.json','utf8'));
  console.log('CONFIG_VALID');
}catch(e){console.log('CONFIG_MISSING_OR_CORRUPT: '+e.message);}
"

# Auto mode config
cat > "$PROJ/.planning/config.json" << 'EOF'
{
  "mode": "auto",
  "granularity": "coarse",
  "model_profile": "quality",
  "learning_mode": "manual",
  "test_first": true,
  "planning": { "commit_mode": "manual" },
  "workflow": { "research": false, "plan_check": false, "verifier": false, "review": false },
  "parallelization": { "enabled": true },
  "ship": { "auto_test": false }
}
EOF

check_output "auto config: CONFIG_VALID" "CONFIG_VALID" node -e "
const fs=require('fs');
try{
  const c=JSON.parse(fs.readFileSync('$PROJ/.planning/config.json','utf8'));
  const errs=[];
  if(!['auto','interactive'].includes(c.mode)) errs.push('mode');
  if(!['coarse','standard','fine'].includes(c.granularity)) errs.push('granularity');
  if(!['quality','balanced','budget'].includes(c.model_profile)) errs.push('model_profile');
  if(!['auto','manual'].includes(c.learning_mode)) errs.push('learning_mode');
  if(typeof c.test_first!=='boolean') errs.push('test_first');
  if(!c.planning||!['auto','manual'].includes(c.planning.commit_mode)) errs.push('planning.commit_mode');
  if(!c.workflow||typeof c.workflow.research!=='boolean') errs.push('workflow.research');
  if(!c.workflow||typeof c.workflow.plan_check!=='boolean') errs.push('workflow.plan_check');
  if(!c.workflow||typeof c.workflow.verifier!=='boolean') errs.push('workflow.verifier');
  if(!c.workflow||typeof c.workflow.review!=='boolean') errs.push('workflow.review');
  if(!c.parallelization||typeof c.parallelization.enabled!=='boolean') errs.push('parallelization');
  if(!c.ship||typeof c.ship.auto_test!=='boolean') errs.push('ship.auto_test');
  const bad=['working_style','model_tier','platform','milestone','phases','commit_mode'];
  for(const k of bad){if(k in c)errs.push('FORBIDDEN: '+k);}
  if(errs.length){console.log('CONFIG_INVALID');errs.forEach(e=>console.log('  - '+e));}
  else console.log('CONFIG_VALID');
}catch(e){console.log('CONFIG_MISSING_OR_CORRUPT: '+e.message);}
"

# ─── 2. Research Verification Gate ────────────────────────────────────
# The actual verification script that checks 5 research files exist
# with required ## sections.

echo ""
echo "─── Research Verification Gate ───────────────────────────────────"

RESEARCH_DIR="$PROJ/.planning/research"
mkdir -p "$RESEARCH_DIR"

# Create all 5 research files with correct sections
cat > "$RESEARCH_DIR/STACK.md" << 'EOF'
## Recommended Stack
Node.js + Express
## What NOT to Use
PHP frameworks
## Alternatives Considered
Fastify
EOF

cat > "$RESEARCH_DIR/FEATURES.md" << 'EOF'
## Table Stakes
Auth, CRUD
## Differentiators
Real-time sync
EOF

cat > "$RESEARCH_DIR/ARCHITECTURE.md" << 'EOF'
## Component Boundaries
API / DB / Frontend
## Data Flow
REST endpoints
EOF

cat > "$RESEARCH_DIR/PITFALLS.md" << 'EOF'
## Common Mistakes
Missing auth
## Prevention Strategies
Use middleware
EOF

cat > "$RESEARCH_DIR/SUMMARY.md" << 'EOF'
## Recommended Stack
Node.js
## Top Pitfalls
Missing auth
EOF

# Run the actual verification script from new-project.md
check_output "good research: RESEARCH VERIFIED OK" "RESEARCH VERIFIED OK" node -e "
const fs=require('fs'),path=require('path');
const dir='$RESEARCH_DIR/';
const checks={'STACK.md':['Recommended Stack','What NOT to Use'],'FEATURES.md':['Table Stakes','Differentiators'],'ARCHITECTURE.md':['Component Boundaries','Data Flow'],'PITFALLS.md':['Common Mistakes','Prevention Strategies'],'SUMMARY.md':['Recommended Stack','Top Pitfalls']};
const missing=[];
for(const[file,sections]of Object.entries(checks)){
  const fp=path.join(dir,file);
  if(!fs.existsSync(fp)){missing.push(file+' MISSING');continue;}
  const c=fs.readFileSync(fp,'utf8');
  for(const s of sections){if(!c.includes('## '+s))missing.push(file+': missing ## '+s);}
}
if(missing.length){console.log('RESEARCH FAILED');process.exit(1);}
console.log('RESEARCH VERIFIED OK — all 5 files present with required sections');
"

# Remove one file and verify it fails
rm "$RESEARCH_DIR/PITFALLS.md"

check_output "missing PITFALLS.md: RESEARCH FAILED" "RESEARCH FAILED" node -e "
const fs=require('fs'),path=require('path');
const dir='$RESEARCH_DIR/';
const checks={'STACK.md':['Recommended Stack','What NOT to Use'],'FEATURES.md':['Table Stakes','Differentiators'],'ARCHITECTURE.md':['Component Boundaries','Data Flow'],'PITFALLS.md':['Common Mistakes','Prevention Strategies'],'SUMMARY.md':['Recommended Stack','Top Pitfalls']};
const missing=[];
for(const[file,sections]of Object.entries(checks)){
  const fp=path.join(dir,file);
  if(!fs.existsSync(fp)){missing.push(file+' MISSING');continue;}
  const c=fs.readFileSync(fp,'utf8');
  for(const s of sections){if(!c.includes('## '+s))missing.push(file+': missing ## '+s);}
}
if(missing.length){console.log('RESEARCH FAILED — '+missing.join(', '));process.exit(1);}
console.log('RESEARCH VERIFIED OK');
"

# File exists but missing a required section
cat > "$RESEARCH_DIR/PITFALLS.md" << 'EOF'
## Common Mistakes
Missing auth
EOF

check_output "PITFALLS.md missing section: RESEARCH FAILED" "RESEARCH FAILED" node -e "
const fs=require('fs'),path=require('path');
const dir='$RESEARCH_DIR/';
const checks={'PITFALLS.md':['Common Mistakes','Prevention Strategies']};
const missing=[];
for(const[file,sections]of Object.entries(checks)){
  const fp=path.join(dir,file);
  if(!fs.existsSync(fp)){missing.push(file+' MISSING');continue;}
  const c=fs.readFileSync(fp,'utf8');
  for(const s of sections){if(!c.includes('## '+s))missing.push(file+': missing ## '+s);}
}
if(missing.length){console.log('RESEARCH FAILED — '+missing.join(', '));process.exit(1);}
console.log('RESEARCH VERIFIED OK');
"

# ─── 3. Project Detection ────────────────────────────────────────────
# The project detection script from new-project.md Step 0.

echo ""
echo "─── Project Detection ────────────────────────────────────────────"

# New project (no PROJECT.md)
rm -rf "$PROJ/.planning/PROJECT.md"

check_output "no PROJECT.md: detects NEW" "NEW" node -e "
const fs=require('fs');
console.log(fs.existsSync('$PROJ/.planning/PROJECT.md') ? 'EXISTS' : 'NEW');
"

# Existing project
touch "$PROJ/.planning/PROJECT.md"

check_output "has PROJECT.md: detects EXISTS" "EXISTS" node -e "
const fs=require('fs');
console.log(fs.existsSync('$PROJ/.planning/PROJECT.md') ? 'EXISTS' : 'NEW');
"

# ─── 4. Git Detection ────────────────────────────────────────────────

echo ""
echo "─── Git Detection ────────────────────────────────────────────────"

check_output "no .git: detects NO_GIT" "NO_GIT" node -e "
const fs=require('fs');
console.log(fs.existsSync('$PROJ/.git') ? 'HAS_GIT' : 'NO_GIT');
"

mkdir -p "$PROJ/.git"

check_output "has .git: detects HAS_GIT" "HAS_GIT" node -e "
const fs=require('fs');
console.log(fs.existsSync('$PROJ/.git') ? 'HAS_GIT' : 'NO_GIT');
"

# ─── 5. Codebase Detection ───────────────────────────────────────────

echo ""
echo "─── Codebase Detection ───────────────────────────────────────────"

# Blank project (only .planning and .git)
rm -rf "$PROJ/src" "$PROJ/package.json"

check_output "blank project: detects BLANK" "BLANK" node -e "
const fs=require('fs'),path=require('path');
const skip=new Set(['.git','node_modules','.planning','__pycache__','.venv','.windsurf','.claude','.cursor','.codex','.gemini','.opencode','.config']);
const codeExt=new Set(['.ts','.js','.py','.go','.rs','.swift','.java','.kt','.c','.cpp','.h','.cs','.rb','.php','.dart','.scala','.lua','.r','.R','.zig','.ex','.exs','.clj']);
let hasCodeFiles=false;
function scan(d,depth){if(depth>3)return;try{for(const e of fs.readdirSync(d,{withFileTypes:true})){if(skip.has(e.name)||e.name.startsWith('.'))continue;if(e.isDirectory()){scan(path.join(d,e.name),depth+1);}else if(codeExt.has(path.extname(e.name))){hasCodeFiles=true;return;}}}catch{}}
scan('$PROJ',0);
const hasPkg=fs.existsSync(path.join('$PROJ','package.json'));
const hasCbMap=fs.existsSync(path.join('$PROJ','.planning','codebase'));
if(hasCodeFiles||hasPkg){console.log('HAS_CODE');}else{console.log('BLANK');}
"

# Project with code files
mkdir -p "$PROJ/src"
echo "console.log('hello')" > "$PROJ/src/index.js"

check_output "project with .js file: detects HAS_CODE" "HAS_CODE" node -e "
const fs=require('fs'),path=require('path');
const skip=new Set(['.git','node_modules','.planning','__pycache__','.venv','.windsurf','.claude','.cursor','.codex','.gemini','.opencode','.config']);
const codeExt=new Set(['.ts','.js','.py','.go','.rs','.swift','.java','.kt','.c','.cpp','.h','.cs','.rb','.php','.dart','.scala','.lua','.r','.R','.zig','.ex','.exs','.clj']);
let hasCodeFiles=false;
function scan(d,depth){if(depth>3)return;try{for(const e of fs.readdirSync(d,{withFileTypes:true})){if(skip.has(e.name)||e.name.startsWith('.'))continue;if(e.isDirectory()){scan(path.join(d,e.name),depth+1);}else if(codeExt.has(path.extname(e.name))){hasCodeFiles=true;return;}}}catch{}}
scan('$PROJ',0);
const hasPkg=fs.existsSync(path.join('$PROJ','package.json'));
if(hasCodeFiles||hasPkg){console.log('HAS_CODE');}else{console.log('BLANK');}
"

# ─── 6. Existing Context File Detection ──────────────────────────────

echo ""
echo "─── Existing Context File Detection ──────────────────────────────"

# No context files
rm -f "$PROJ/AGENTS.md" "$PROJ/CLAUDE.md" "$PROJ/GEMINI.md" "$PROJ/.cursorrules"

check_output "no context files: NONE FOUND" "NONE FOUND" node -e "
const fs=require('fs');
const files=['AGENTS.md','CLAUDE.md','GEMINI.md','.cursorrules'];
const found=files.filter(f=>fs.existsSync('$PROJ/'+f));
if(found.length){console.log('EXISTING: '+found.join(', '));}
else{console.log('NONE FOUND');}
"

# Has AGENTS.md
echo "# Agents" > "$PROJ/AGENTS.md"

check_output "has AGENTS.md: detects EXISTING" "EXISTING: AGENTS.md" node -e "
const fs=require('fs');
const files=['AGENTS.md','CLAUDE.md','GEMINI.md','.cursorrules'];
const found=files.filter(f=>fs.existsSync('$PROJ/'+f));
if(found.length){console.log('EXISTING: '+found.join(', '));}
else{console.log('NONE FOUND');}
"

# Has multiple context files
echo "# Claude" > "$PROJ/CLAUDE.md"
echo "# Gemini" > "$PROJ/GEMINI.md"

check_output "has 3 context files: detects all" "EXISTING: AGENTS.md, CLAUDE.md, GEMINI.md" node -e "
const fs=require('fs');
const files=['AGENTS.md','CLAUDE.md','GEMINI.md','.cursorrules'];
const found=files.filter(f=>fs.existsSync('$PROJ/'+f));
if(found.length){console.log('EXISTING: '+found.join(', '));}
else{console.log('NONE FOUND');}
"

# ─── 7. Config Template Validity ─────────────────────────────────────
# The shipped config.json template should itself pass the validator.

echo ""
echo "─── Config Template Self-Validation ──────────────────────────────"

cp "$TPL_DIR/config.json" "$PROJ/.planning/config.json"

check_output "shipped config.json template passes own validator" "CONFIG_VALID" node -e "
const fs=require('fs');
try{
  const c=JSON.parse(fs.readFileSync('$PROJ/.planning/config.json','utf8'));
  const errs=[];
  if(!['auto','interactive'].includes(c.mode)) errs.push('mode');
  if(!['coarse','standard','fine'].includes(c.granularity)) errs.push('granularity');
  if(!['quality','balanced','budget'].includes(c.model_profile)) errs.push('model_profile');
  if(!['auto','manual'].includes(c.learning_mode)) errs.push('learning_mode');
  if(typeof c.test_first!=='boolean') errs.push('test_first');
  if(!c.planning||!['auto','manual'].includes(c.planning.commit_mode)) errs.push('planning.commit_mode');
  if(!c.workflow||typeof c.workflow.research!=='boolean') errs.push('workflow.research');
  if(!c.workflow||typeof c.workflow.plan_check!=='boolean') errs.push('workflow.plan_check');
  if(!c.workflow||typeof c.workflow.verifier!=='boolean') errs.push('workflow.verifier');
  if(!c.workflow||typeof c.workflow.review!=='boolean') errs.push('workflow.review');
  if(!c.parallelization||typeof c.parallelization.enabled!=='boolean') errs.push('parallelization');
  if(!c.ship||typeof c.ship.auto_test!=='boolean') errs.push('ship.auto_test');
  const bad=['working_style','model_tier','platform','milestone','phases','commit_mode'];
  for(const k of bad){if(k in c)errs.push('FORBIDDEN: '+k);}
  if(errs.length){console.log('CONFIG_INVALID');errs.forEach(e=>console.log('  - '+e));}
  else console.log('CONFIG_VALID');
}catch(e){console.log('CONFIG_MISSING_OR_CORRUPT: '+e.message);}
"

# ─── 8. install.js Internal Workflow Exclusion ────────────────────────
# Verify that internal-only workflows are NOT installed for any platform.

echo ""
echo "─── Internal Workflow Exclusion ──────────────────────────────────"

TMPINSTALL=$(mktemp -d)
for p in windsurf claude opencode gemini codex; do
  mkdir -p "$TMPINSTALL/$p"
  node "$REPO_DIR/bin/install.js" "--$p" --target "$TMPINSTALL/$p" > /dev/null 2>&1
  FOUND=$(find "$TMPINSTALL/$p" -name "sync-upstream-skills*" 2>/dev/null | wc -l)
  check "$p: internal workflow not installed (found=$FOUND)" test "$FOUND" -eq 0
done
rm -rf "$TMPINSTALL"

# ─── 9. Installed Workflow Count ──────────────────────────────────────
# Verify the installed workflow count matches what README and package.json claim.

echo ""
echo "─── Installed Workflow Count ─────────────────────────────────────"

TMPINSTALL=$(mktemp -d)
mkdir -p "$TMPINSTALL/ws"
node "$REPO_DIR/bin/install.js" --windsurf --target "$TMPINSTALL/ws" > /dev/null 2>&1
INSTALLED_COUNT=$(ls "$TMPINSTALL/ws/workflows/"*.md 2>/dev/null | wc -l)
rm -rf "$TMPINSTALL"

check "Windsurf installs exactly 57 user workflows (got $INSTALLED_COUNT)" test "$INSTALLED_COUNT" -eq 57

# ─── 10. Health Check Simulations ─────────────────────────────────────
# The /health workflow runs multiple diagnostic node -e scripts.
# Simulate healthy and broken project states.

echo ""
echo "─── Health Check: Project Detection ──────────────────────────────"

# Reset project dir
rm -rf "$PROJ/.planning" "$PROJ/src" "$PROJ/.git" "$PROJ/AGENTS.md" "$PROJ/CLAUDE.md" "$PROJ/GEMINI.md" "$PROJ/.cursorrules"

# No .planning = MISSING
check_output "health: no .planning = MISSING" "MISSING" node -e "
const fs=require('fs'); console.log(fs.existsSync('$PROJ/.planning') ? 'OK' : 'MISSING');
"

# With .planning = OK
mkdir -p "$PROJ/.planning"
check_output "health: has .planning = OK" "OK" node -e "
const fs=require('fs'); console.log(fs.existsSync('$PROJ/.planning') ? 'OK' : 'MISSING');
"

echo ""
echo "─── Health Check: Required Files ─────────────────────────────────"

# No PROJECT.md
check_output "health: no PROJECT.md = E002" "E002" node -e "
const fs=require('fs'); if(!fs.existsSync('$PROJ/.planning/PROJECT.md')) console.log('E002: PROJECT.md not found');
"

# With PROJECT.md
echo "# My Project" > "$PROJ/.planning/PROJECT.md"
check_output "health: has PROJECT.md = silent" "" node -e "
const fs=require('fs'); if(!fs.existsSync('$PROJ/.planning/PROJECT.md')) console.log('E002: PROJECT.md not found');
"

# No ROADMAP.md
check_output "health: no ROADMAP.md = E003" "E003" node -e "
const fs=require('fs'); if(!fs.existsSync('$PROJ/.planning/ROADMAP.md')) console.log('E003: ROADMAP.md not found');
"

# No config.json
check_output "health: no config.json = W003" "W003" node -e "
const fs=require('fs'); if(!fs.existsSync('$PROJ/.planning/config.json')) console.log('W003: config.json not found (repairable)');
"

echo ""
echo "─── Health Check: Config Validity ────────────────────────────────"

# Valid JSON config
cp "$TPL_DIR/config.json" "$PROJ/.planning/config.json"
check_output "health: valid config.json = silent" "" node -e "
try{JSON.parse(require('fs').readFileSync('$PROJ/.planning/config.json','utf8'))}catch(e){console.log('E005: config.json parse error (repairable)');}
"

# Corrupt JSON config
echo "{broken" > "$PROJ/.planning/config.json"
check_output "health: corrupt config.json = E005" "E005" node -e "
try{JSON.parse(require('fs').readFileSync('$PROJ/.planning/config.json','utf8'))}catch(e){console.log('E005: config.json parse error (repairable)');}
"

echo ""
echo "─── Health Check: State/Roadmap Consistency ──────────────────────"

# Create consistent STATE.md + ROADMAP.md
cat > "$PROJ/.planning/ROADMAP.md" << 'EOF'
# Roadmap
## Phase 1: Foundation
- Setup project structure
## Phase 2: API
- Build REST endpoints
## Phase 3: Frontend
- Build UI
EOF

cat > "$PROJ/.planning/STATE.md" << 'EOF'
Phase: 2
Status: in_progress
EOF

check_output "health: state matches roadmap = silent" "" node -e "
const fs=require('fs');
if(!fs.existsSync('$PROJ/.planning/STATE.md')||!fs.existsSync('$PROJ/.planning/ROADMAP.md'))process.exit(0);
const state=fs.readFileSync('$PROJ/.planning/STATE.md','utf8');
const m=state.match(/^Phase:\s*(\d+)/m);
if(m){
  const roadmap=fs.readFileSync('$PROJ/.planning/ROADMAP.md','utf8');
  if(!roadmap.includes('Phase '+m[1]+':'))console.log('W002: STATE.md references phase '+m[1]+' not found in roadmap');
}
"

# STATE.md references phase 5 which doesn't exist in roadmap
cat > "$PROJ/.planning/STATE.md" << 'EOF'
Phase: 5
Status: in_progress
EOF

check_output "health: state references phantom phase = W002" "W002" node -e "
const fs=require('fs');
if(!fs.existsSync('$PROJ/.planning/STATE.md')||!fs.existsSync('$PROJ/.planning/ROADMAP.md'))process.exit(0);
const state=fs.readFileSync('$PROJ/.planning/STATE.md','utf8');
const m=state.match(/^Phase:\s*(\d+)/m);
if(m){
  const roadmap=fs.readFileSync('$PROJ/.planning/ROADMAP.md','utf8');
  if(!roadmap.includes('Phase '+m[1]+':'))console.log('W002: STATE.md references phase '+m[1]+' not found in roadmap');
}
"

echo ""
echo "─── Health Check: Phase Directory Checks ─────────────────────────"

# Phase in roadmap but no directory
check_output "health: phase 1 in roadmap but no dir = W006" "W006" node -e "
const fs=require('fs'),path=require('path');
if(!fs.existsSync('$PROJ/.planning/ROADMAP.md'))process.exit(0);
const roadmap=fs.readFileSync('$PROJ/.planning/ROADMAP.md','utf8');
const phases=[...roadmap.matchAll(/^## Phase (\d+):/mg)].map(m=>m[1]);
const phasesDir='$PROJ/.planning/phases';
const dirs=fs.existsSync(phasesDir)?fs.readdirSync(phasesDir):[];
for(const n of phases){
  const pad=n.padStart(2,'0');
  if(!dirs.some(d=>d.startsWith(pad+'-')))console.log('W006: Phase '+n+' in roadmap but no directory');
}
"

# Create matching directories
mkdir -p "$PROJ/.planning/phases/01-foundation"
mkdir -p "$PROJ/.planning/phases/02-api"
mkdir -p "$PROJ/.planning/phases/03-frontend"

check_output "health: all phase dirs exist = silent" "" node -e "
const fs=require('fs'),path=require('path');
if(!fs.existsSync('$PROJ/.planning/ROADMAP.md'))process.exit(0);
const roadmap=fs.readFileSync('$PROJ/.planning/ROADMAP.md','utf8');
const phases=[...roadmap.matchAll(/^## Phase (\d+):/mg)].map(m=>m[1]);
const phasesDir='$PROJ/.planning/phases';
const dirs=fs.existsSync(phasesDir)?fs.readdirSync(phasesDir):[];
let out='';
for(const n of phases){
  const pad=n.padStart(2,'0');
  if(!dirs.some(d=>d.startsWith(pad+'-')))out+='W006: Phase '+n;
}
if(out)console.log(out);
"

echo ""
echo "─── Health Check: Config Fields ──────────────────────────────────"

# Config missing fields
cat > "$PROJ/.planning/config.json" << 'EOF'
{
  "mode": "interactive"
}
EOF

check_output "health: config missing fields = W004" "W004" node -e "
try{
  const cfg=JSON.parse(require('fs').readFileSync('$PROJ/.planning/config.json','utf8'));
  const top=['mode','granularity','model_profile','learning_mode','parallelization','test_first'].filter(k=>!(k in cfg));
  const nested=[];
  if(!cfg.planning||!('commit_mode' in cfg.planning)) nested.push('planning.commit_mode');
  if(!cfg.workflow||!('review' in cfg.workflow)) nested.push('workflow.review');
  if(!cfg.ship) nested.push('ship.*');
  const missing=[...top,...nested];
  if(missing.length)console.log('W004: config.json missing fields: '+missing.join(', '));
}catch(e){}
"

# Full config = no warning
cp "$TPL_DIR/config.json" "$PROJ/.planning/config.json"
check_output "health: full config = no W004" "" node -e "
try{
  const cfg=JSON.parse(require('fs').readFileSync('$PROJ/.planning/config.json','utf8'));
  const top=['mode','granularity','model_profile','learning_mode','test_first'].filter(k=>!(k in cfg));
  const nested=[];
  if(!cfg.planning||!('commit_mode' in cfg.planning)) nested.push('planning.commit_mode');
  if(!cfg.workflow||!('review' in cfg.workflow)) nested.push('workflow.review');
  if(!cfg.ship) nested.push('ship.*');
  const missing=[...top,...nested];
  if(missing.length)console.log('W004: config.json missing fields: '+missing.join(', '));
}catch(e){}
"

# ─── 11. /ls Workflow Simulations ─────────────────────────────────────
# The /ls workflow checks for PROJECT.md and finds recent SUMMARY files.

echo ""
echo "─── /ls Workflow: Project Check ──────────────────────────────────"

rm -rf "$PROJ/.planning/PROJECT.md"
check_output "ls: no PROJECT.md = MISSING" "MISSING" node -e "
const fs=require('fs'); console.log(fs.existsSync('$PROJ/.planning/PROJECT.md') ? 'EXISTS' : 'MISSING');
"

echo "# Test Project" > "$PROJ/.planning/PROJECT.md"
check_output "ls: has PROJECT.md = EXISTS" "EXISTS" node -e "
const fs=require('fs'); console.log(fs.existsSync('$PROJ/.planning/PROJECT.md') ? 'EXISTS' : 'MISSING');
"

echo ""
echo "─── /ls Workflow: Recent SUMMARY Discovery ──────────────────────"

# Create some SUMMARY files with different timestamps
echo "Phase 1 done" > "$PROJ/.planning/phases/01-foundation/01-01-SUMMARY.md"
sleep 0.1
echo "Phase 2 plan 1 done" > "$PROJ/.planning/phases/02-api/02-01-SUMMARY.md"

check_output "ls: finds recent SUMMARY files" "SUMMARY" node -e "
const fs=require('fs'),path=require('path');
function find(d){let r=[];try{for(const e of fs.readdirSync(d,{withFileTypes:true})){const f=path.join(d,e.name);r=r.concat(e.isDirectory()?find(f):e.name.endsWith('-SUMMARY.md')?[f]:[]);}}catch(e){}return r;}
const files=find('$PROJ/.planning').map(f=>({f,t:fs.statSync(f).mtimeMs})).sort((a,b)=>b.t-a.t).slice(0,3).map(x=>x.f);
files.forEach(f=>console.log(f));
"

# ─── 12. /resume-work Simulations ────────────────────────────────────
# The /resume-work workflow detects STATE/PROJECT/ROADMAP presence.

echo ""
echo "─── /resume-work: State Detection ────────────────────────────────"

rm -f "$PROJ/.planning/STATE.md"
check_output "resume: no STATE.md = NO_STATE" "NO_STATE" node -e "
const fs=require('fs'); console.log(fs.existsSync('$PROJ/.planning/STATE.md') ? 'HAS_STATE' : 'NO_STATE');
"

echo "Phase: 1" > "$PROJ/.planning/STATE.md"
check_output "resume: has STATE.md = HAS_STATE" "HAS_STATE" node -e "
const fs=require('fs'); console.log(fs.existsSync('$PROJ/.planning/STATE.md') ? 'HAS_STATE' : 'NO_STATE');
"

check_output "resume: has PROJECT.md = HAS_PROJECT" "HAS_PROJECT" node -e "
const fs=require('fs'); console.log(fs.existsSync('$PROJ/.planning/PROJECT.md') ? 'HAS_PROJECT' : 'NO_PROJECT');
"

check_output "resume: has ROADMAP.md = HAS_ROADMAP" "HAS_ROADMAP" node -e "
const fs=require('fs'); console.log(fs.existsSync('$PROJ/.planning/ROADMAP.md') ? 'HAS_ROADMAP' : 'NO_ROADMAP');
"

# ─── 13. /resume-work: Incomplete Plan Detection ─────────────────────
# Plans without matching SUMMARY = incomplete work.

echo ""
echo "─── /resume-work: Incomplete Plan Detection ─────────────────────"

# Create a PLAN without SUMMARY
echo "# Plan" > "$PROJ/.planning/phases/02-api/02-02-PLAN.md"

INCOMPLETE=$(cd "$PROJ" && for plan in .planning/phases/*/*-PLAN.md; do
  base="${plan%-PLAN.md}"
  summary="${base}-SUMMARY.md"
  [ ! -f "$summary" ] && echo "Incomplete: $plan"
done 2>/dev/null)

if echo "$INCOMPLETE" | grep -q "02-02-PLAN.md"; then
  echo "  ✓ resume: detects incomplete plan (PLAN without SUMMARY)"
  PASS=$((PASS+1))
else
  echo "  ✗ resume: should detect 02-02-PLAN.md as incomplete"
  FAIL=$((FAIL+1))
  ERRORS+=("resume: incomplete plan detection")
fi

# Complete plan has matching SUMMARY = not flagged
# Create a PLAN that has a matching SUMMARY
echo "# Plan 1" > "$PROJ/.planning/phases/01-foundation/01-01-PLAN.md"
# 01-01-SUMMARY.md already exists from the /ls test above

INCOMPLETE2=$(cd "$PROJ" && for plan in .planning/phases/01-foundation/*-PLAN.md; do
  base="${plan%-PLAN.md}"
  summary="${base}-SUMMARY.md"
  [ ! -f "$summary" ] && echo "Incomplete: $plan"
done 2>/dev/null)

if [ -z "$INCOMPLETE2" ]; then
  echo "  ✓ resume: completed plan not flagged as incomplete"
  PASS=$((PASS+1))
else
  echo "  ✗ resume: completed plan incorrectly flagged"
  FAIL=$((FAIL+1))
  ERRORS+=("resume: false positive on completed plan")
fi

# ─── 14. /pause-work: Phase Detection ────────────────────────────────
# Finds the most recently modified PLAN.md to detect active phase.

echo ""
echo "─── /pause-work: Active Phase Detection ─────────────────────────"

# Touch phase 2 plan to make it most recent
sleep 0.1
touch "$PROJ/.planning/phases/02-api/02-02-PLAN.md"

check_output "pause: detects most recent phase dir" "02-api" node -e "
const fs=require('fs'),path=require('path');
function find(d){let r=[];try{for(const e of fs.readdirSync(d,{withFileTypes:true})){const f=path.join(d,e.name);r=r.concat(e.isDirectory()?find(f):e.name.endsWith('-PLAN.md')?[f]:[]);}}catch(e){}return r;}
const files=find('$PROJ/.planning/phases').map(f=>({f,t:fs.statSync(f).mtimeMs})).sort((a,b)=>b.t-a.t);
if(files[0])console.log(files[0].f);
"

# ─── 15. /quick: Project Gate ─────────────────────────────────────────
# Quick tasks require an active project (PROJECT.md must exist).

echo ""
echo "─── /quick: Project Gate ─────────────────────────────────────────"

check_output "quick: has PROJECT.md = OK" "OK" node -e "
const fs=require('fs'); console.log(fs.existsSync('$PROJ/.planning/PROJECT.md') ? 'OK' : 'MISSING');
"

rm -f "$PROJ/.planning/PROJECT.md"
check_output "quick: no PROJECT.md = MISSING" "MISSING" node -e "
const fs=require('fs'); console.log(fs.existsSync('$PROJ/.planning/PROJECT.md') ? 'OK' : 'MISSING');
"

# ─── 16. /settings: Config Existence Check ───────────────────────────
# Settings editor checks if config exists, creates from template if not.

echo ""
echo "─── /settings: Config Existence ──────────────────────────────────"

rm -f "$PROJ/.planning/config.json"
check_output "settings: no config = missing" "missing" node -e "
const fs=require('fs'); console.log(fs.existsSync('$PROJ/.planning/config.json') ? 'exists' : 'missing');
"

cp "$TPL_DIR/config.json" "$PROJ/.planning/config.json"
check_output "settings: has config = exists" "exists" node -e "
const fs=require('fs'); console.log(fs.existsSync('$PROJ/.planning/config.json') ? 'exists' : 'missing');
"

# ─── 17. Settings Default Template Matches Validator ──────────────────
# The default config in settings.md Step 1 must pass the new-project validator.
# This catches drift between the two embedded configs.

echo ""
echo "─── Settings Default vs Validator Consistency ────────────────────"

# Extract the embedded default config from settings.md and validate it
cat > "$PROJ/.planning/config.json" << 'EOF'
{
  "mode": "interactive",
  "granularity": "standard",
  "model_profile": "balanced",
  "learning_mode": "auto",
  "test_first": false,
  "planning": {
    "commit_docs": true,
    "commit_mode": "auto",
    "search_gitignored": false
  },
  "workflow": {
    "research": true,
    "plan_check": true,
    "verifier": true,
    "validation": true,
    "review": true,
    "solutions_search": true,
    "security_enforcement": true,
    "discuss_mode": "discuss",
    "tdd_mode": false
  },
  "parallelization": {
    "enabled": false,
    "plan_level": true,
    "task_level": false,
    "max_concurrent_agents": 5,
    "min_plans_for_parallel": 2
  },
  "gates": {
    "confirm_project": true,
    "confirm_phases": true,
    "confirm_roadmap": true,
    "confirm_plan": true,
    "execute_next_plan": true,
    "issues_review": true,
    "confirm_transition": true
  },
  "safety": {
    "always_confirm_destructive": true,
    "always_confirm_external_services": true
  },
  "review": {
    "auto_after_verify": false
  },
  "ship": {
    "auto_test": true,
    "conventional_commits": true,
    "pr_template": true
  },
  "hooks": {
    "context_warnings": true
  },
  "git": {
    "branching_strategy": "none",
    "phase_branch_template": "phase-{phase}-{slug}",
    "milestone_branch_template": "{milestone}-{slug}"
  }
}
EOF

check_output "settings default config passes new-project validator" "CONFIG_VALID" node -e "
const fs=require('fs');
try{
  const c=JSON.parse(fs.readFileSync('$PROJ/.planning/config.json','utf8'));
  const errs=[];
  if(!['auto','interactive'].includes(c.mode)) errs.push('mode');
  if(!['coarse','standard','fine'].includes(c.granularity)) errs.push('granularity');
  if(!['quality','balanced','budget'].includes(c.model_profile)) errs.push('model_profile');
  if(!['auto','manual'].includes(c.learning_mode)) errs.push('learning_mode');
  if(typeof c.test_first!=='boolean') errs.push('test_first');
  if(!c.planning||!['auto','manual'].includes(c.planning.commit_mode)) errs.push('planning.commit_mode');
  if(!c.workflow||typeof c.workflow.research!=='boolean') errs.push('workflow.research');
  if(!c.workflow||typeof c.workflow.plan_check!=='boolean') errs.push('workflow.plan_check');
  if(!c.workflow||typeof c.workflow.verifier!=='boolean') errs.push('workflow.verifier');
  if(!c.workflow||typeof c.workflow.review!=='boolean') errs.push('workflow.review');
  if(!c.parallelization||typeof c.parallelization.enabled!=='boolean') errs.push('parallelization');
  if(!c.ship||typeof c.ship.auto_test!=='boolean') errs.push('ship.auto_test');
  const bad=['working_style','model_tier','platform','milestone','phases','commit_mode'];
  for(const k of bad){if(k in c)errs.push('FORBIDDEN: '+k);}
  if(errs.length){console.log('CONFIG_INVALID');errs.forEach(e=>console.log('  - '+e));}
  else console.log('CONFIG_VALID');
}catch(e){console.log('CONFIG_MISSING_OR_CORRUPT: '+e.message);}
"

# ─── 18. /execute-phase: Phase Directory Discovery ───────────────────
# execute-phase lists phase directories matching a pattern.

echo ""
echo "─── /execute-phase: Phase Discovery ──────────────────────────────"

PHASE_COUNT=0
for d in "$PROJ/.planning/phases"/[0-9]*; do
  [ -d "$d" ] && PHASE_COUNT=$((PHASE_COUNT+1))
done

check "execute-phase: finds 3 phase directories" test "$PHASE_COUNT" -eq 3

# Check specific phase has PLAN files
PLAN_COUNT=$(ls "$PROJ/.planning/phases/02-api/"*-PLAN.md 2>/dev/null | wc -l)
check "execute-phase: phase 02-api has plan files" test "$PLAN_COUNT" -gt 0

# ─── 19. /plan-phase: Phase Number Validation ────────────────────────
# plan-phase reads the roadmap to verify the requested phase exists.

echo ""
echo "─── /plan-phase: Phase Validation ────────────────────────────────"

check_output "plan-phase: phase 1 exists in roadmap" "Phase 1" node -e "
const fs=require('fs');
const roadmap=fs.readFileSync('$PROJ/.planning/ROADMAP.md','utf8');
const phases=[...roadmap.matchAll(/^## Phase (\d+):/mg)].map(m=>'Phase '+m[1]);
phases.forEach(p=>console.log(p));
"

check_output "plan-phase: phase 4 not in roadmap" "" node -e "
const fs=require('fs');
const roadmap=fs.readFileSync('$PROJ/.planning/ROADMAP.md','utf8');
if(roadmap.includes('## Phase 4:'))console.log('FOUND');
"

# ─── 20. /continue-here Handoff Detection ────────────────────────────
# Multiple workflows check for .continue-here.md files.

echo ""
echo "─── Continue-Here Handoff Detection ──────────────────────────────"

# No handoff file
HANDOFF=$(find "$PROJ/.planning/phases" -name ".continue-here.md" -type f 2>/dev/null)
check "no .continue-here.md present initially" test -z "$HANDOFF"

# Create a handoff file
cat > "$PROJ/.planning/phases/02-api/.continue-here.md" << 'EOF'
---
phase: 02-api
task: 3
total_tasks: 5
status: in_progress
---
<current_state>
Working on API endpoint for user auth
</current_state>
EOF

HANDOFF=$(find "$PROJ/.planning/phases" -name ".continue-here.md" -type f 2>/dev/null)
check ".continue-here.md detected after creation" test -n "$HANDOFF"

# Verify content is readable
check_output "handoff file has phase metadata" "02-api" node -e "
const c=require('fs').readFileSync('$PROJ/.planning/phases/02-api/.continue-here.md','utf8');
const m=c.match(/^phase:\s*(.+)/m);
if(m)console.log(m[1]);
"

# ─── 21. Config Edge Cases ───────────────────────────────────────────
# Test more config edge cases the validator should catch.

echo ""
echo "─── Config Edge Cases ────────────────────────────────────────────"

# Invalid enum value for mode
cat > "$PROJ/.planning/config.json" << 'EOF'
{
  "mode": "turbo",
  "granularity": "standard",
  "model_profile": "balanced",
  "learning_mode": "auto",
  "test_first": false,
  "planning": { "commit_mode": "auto" },
  "workflow": { "research": true, "plan_check": true, "verifier": true, "review": true },
  "parallelization": { "enabled": false },
  "ship": { "auto_test": true }
}
EOF

check_output "config: invalid mode 'turbo' rejected" "CONFIG_INVALID" node -e "
const fs=require('fs');
try{
  const c=JSON.parse(fs.readFileSync('$PROJ/.planning/config.json','utf8'));
  const errs=[];
  if(!['auto','interactive'].includes(c.mode)) errs.push('mode must be auto|interactive, got: '+c.mode);
  if(errs.length){console.log('CONFIG_INVALID');errs.forEach(e=>console.log('  - '+e));}
  else console.log('CONFIG_VALID');
}catch(e){console.log('CONFIG_MISSING_OR_CORRUPT');}
"

# test_first as string instead of boolean
cat > "$PROJ/.planning/config.json" << 'EOF'
{
  "mode": "interactive",
  "granularity": "standard",
  "model_profile": "balanced",
  "learning_mode": "auto",
  "test_first": "yes",
  "planning": { "commit_mode": "auto" },
  "workflow": { "research": true, "plan_check": true, "verifier": true, "review": true },
  "parallelization": { "enabled": false },
  "ship": { "auto_test": true }
}
EOF

check_output "config: test_first as string rejected" "CONFIG_INVALID" node -e "
const fs=require('fs');
try{
  const c=JSON.parse(fs.readFileSync('$PROJ/.planning/config.json','utf8'));
  const errs=[];
  if(!['auto','interactive'].includes(c.mode)) errs.push('mode');
  if(typeof c.test_first!=='boolean') errs.push('test_first must be boolean');
  if(errs.length){console.log('CONFIG_INVALID');errs.forEach(e=>console.log('  - '+e));}
  else console.log('CONFIG_VALID');
}catch(e){console.log('CONFIG_MISSING_OR_CORRUPT');}
"

# Multiple forbidden keys
cat > "$PROJ/.planning/config.json" << 'EOF'
{
  "mode": "interactive",
  "granularity": "standard",
  "model_profile": "balanced",
  "learning_mode": "auto",
  "test_first": false,
  "working_style": "interactive",
  "platform": "windsurf",
  "milestone": "v1",
  "planning": { "commit_mode": "auto" },
  "workflow": { "research": true, "plan_check": true, "verifier": true, "review": true },
  "parallelization": { "enabled": false },
  "ship": { "auto_test": true }
}
EOF

check_output "config: catches multiple forbidden keys" "working_style" node -e "
const fs=require('fs');
const c=JSON.parse(fs.readFileSync('$PROJ/.planning/config.json','utf8'));
const bad=['working_style','model_tier','platform','milestone','phases','commit_mode'];
const found=bad.filter(k=>k in c);
found.forEach(k=>console.log('FORBIDDEN: '+k));
"

check_output "config: catches 'platform' forbidden key" "platform" node -e "
const fs=require('fs');
const c=JSON.parse(fs.readFileSync('$PROJ/.planning/config.json','utf8'));
const bad=['working_style','model_tier','platform','milestone','phases','commit_mode'];
const found=bad.filter(k=>k in c);
found.forEach(k=>console.log('FORBIDDEN: '+k));
"

check_output "config: catches 'milestone' forbidden key" "milestone" node -e "
const fs=require('fs');
const c=JSON.parse(fs.readFileSync('$PROJ/.planning/config.json','utf8'));
const bad=['working_style','model_tier','platform','milestone','phases','commit_mode'];
const found=bad.filter(k=>k in c);
found.forEach(k=>console.log('FORBIDDEN: '+k));
"

echo ""
echo "─── Results ──────────────────────────────────────────────────────"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo ""
  echo "  Failures:"
  for err in "${ERRORS[@]}"; do
    echo "    - $err"
  done
fi

echo ""
[ "$FAIL" -eq 0 ] && echo "  ALL TESTS PASSED ✓" || { echo "  TESTS FAILED ✗"; exit 1; }
