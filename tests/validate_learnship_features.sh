#!/usr/bin/env bash
# learnship — Unique feature validation
#
# Tests features that are unique to learnship (not shared with other tools):
#   1. Skills system — agentic-learning actions, impeccable actions, reference files
#   2. Learning mode integration — workflows invoke @agentic-learning correctly
#   3. Root SKILL.md — stays in sync with actual workflows and skills
#   4. Context profiles — dev/research/review modes exist and are substantive
#   5. Reference files — all workflow @./references/ links resolve
#   6. Routing protocol — learning_mode routing is consistent across workflows
#   7. Skills installation — skills survive install.js for all platforms
#   8. Skill/workflow sync — .windsurf/skills/ mirrors skills/

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_WF="$REPO_DIR/learnship/workflows"
SKILLS_DIR="$REPO_DIR/skills"
WS_SKILLS="$REPO_DIR/.windsurf/skills"
CONTEXTS_DIR="$REPO_DIR/learnship/contexts"
REFS_DIR="$REPO_DIR/learnship/references"
ROOT_SKILL="$REPO_DIR/SKILL.md"
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

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " Learnship Unique Features Validation"
echo "═══════════════════════════════════════════════════════════════════"

# ─── 1. Agentic-Learning Skill ────────────────────────────────────────
# The agentic-learning skill is a core differentiator — 11 actions,
# 3 reference files, neuroscience-backed learning techniques.

echo ""
echo "─── Agentic-Learning Skill ───────────────────────────────────────"

AL_SKILL="$SKILLS_DIR/agentic-learning/SKILL.md"
AL_REFS="$SKILLS_DIR/agentic-learning/references"

check "agentic-learning: SKILL.md exists" test -f "$AL_SKILL"
check "agentic-learning: SKILL.md has frontmatter" grep -q '^---' "$AL_SKILL"
check "agentic-learning: has name field" grep -q '^name: agentic-learning' "$AL_SKILL"
check "agentic-learning: has version field" grep -q 'version:' "$AL_SKILL"

# Verify all 11 documented actions exist in SKILL.md
for action in learn quiz reflect space brainstorm explain-first struggle either-or explain interleave cognitive-load; do
  check "agentic-learning: action '$action' defined" grep -q "\`$action\`" "$AL_SKILL"
done

# Verify reference files exist and are substantive
check "agentic-learning: references/ dir exists" test -d "$AL_REFS"
for ref in learning-science.md either-or-format.md struggle-ladder.md; do
  check "agentic-learning: reference $ref exists" test -f "$AL_REFS/$ref"
  check "agentic-learning: reference $ref is substantive (>1KB)" node -e "
    const s=require('fs').statSync('$AL_REFS/$ref');
    if(s.size<1000)process.exit(1);
  "
done

# Verify SKILL.md references its own reference files
check "agentic-learning: SKILL.md references learning-science.md" grep -q 'learning-science.md' "$AL_SKILL"

# ─── 2. Impeccable Skill ─────────────────────────────────────────────
# The impeccable skill provides 21 design quality actions with supporting
# reference files in frontend-design/.

echo ""
echo "─── Impeccable Skill ─────────────────────────────────────────────"

IMP_SKILL="$SKILLS_DIR/impeccable/SKILL.md"

check "impeccable: SKILL.md exists" test -f "$IMP_SKILL"
check "impeccable: SKILL.md has frontmatter" grep -q '^---' "$IMP_SKILL"
check "impeccable: has name field" grep -q '^name: impeccable' "$IMP_SKILL"

# Verify all 21 documented actions have corresponding directories
IMP_ACTIONS=(adapt animate arrange audit bolder clarify colorize critique delight distill extract frontend-design harden normalize onboard optimize overdrive polish quieter teach-impeccable typeset)
for action in "${IMP_ACTIONS[@]}"; do
  check "impeccable: action '$action' has directory" test -d "$SKILLS_DIR/impeccable/$action"
done

# Verify each action directory has at least one .md file
node -e "
const fs=require('fs'),path=require('path');
const impDir='$SKILLS_DIR/impeccable';
const errs=[];
const dirs=fs.readdirSync(impDir,{withFileTypes:true}).filter(d=>d.isDirectory());
for(const d of dirs){
  const files=fs.readdirSync(path.join(impDir,d.name)).filter(f=>f.endsWith('.md'));
  if(files.length===0)errs.push(d.name+': no .md files');
}
if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('All '+dirs.length+' action dirs have content');
" && { echo "  ✓ All impeccable action directories have .md content"; PASS=$((PASS+1)); } || { echo "  ✗ Impeccable action directories missing content"; FAIL=$((FAIL+1)); ERRORS+=("Impeccable action dirs missing content"); }

# frontend-design has multiple reference files
check "impeccable: frontend-design has SKILL.md + reference dir" node -e "
  const fs=require('fs'),path=require('path');
  const dir='$SKILLS_DIR/impeccable/frontend-design';
  const entries=fs.readdirSync(dir);
  if(!entries.includes('SKILL.md'))process.exit(1);
  if(!entries.includes('reference'))process.exit(1);
  const refs=fs.readdirSync(path.join(dir,'reference'));
  if(refs.length<3)process.exit(1);
"

# ─── 3. Learning Mode Integration ────────────────────────────────────
# Workflows check learning_mode config and invoke @agentic-learning
# based on the setting (auto/active/manual/off).

echo ""
echo "─── Learning Mode Integration ────────────────────────────────────"

# Count workflows that reference learning_mode
node -e "
const fs=require('fs'),path=require('path');
const wfDir='$SRC_WF';
const wfs=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));
const withLM=wfs.filter(wf=>{
  const c=fs.readFileSync(path.join(wfDir,wf),'utf8');
  return c.includes('learning_mode');
});
console.log(withLM.length+' workflows reference learning_mode');
if(withLM.length<30)process.exit(1);
" && { echo "  ✓ 30+ workflows integrate learning_mode config"; PASS=$((PASS+1)); } || { echo "  ✗ Too few workflows reference learning_mode"; FAIL=$((FAIL+1)); ERRORS+=("Too few workflows reference learning_mode"); }

# Workflows that reference learning_mode should also reference @agentic-learning
node -e "
const fs=require('fs'),path=require('path');
const wfDir='$SRC_WF';
const errs=[];
const wfs=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));
// Skip help.md, settings.md (they describe learning_mode but don't invoke skills)
const skip=new Set(['help.md','settings.md','guard.md','sync-upstream-skills.md','update.md','health.md']);
for(const wf of wfs){
  if(skip.has(wf))continue;
  const c=fs.readFileSync(path.join(wfDir,wf),'utf8');
  if(c.includes('learning_mode')&&!c.includes('@agentic-learning')){
    errs.push(wf+': references learning_mode but never invokes @agentic-learning');
  }
}
if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ All learning_mode workflows invoke @agentic-learning"; PASS=$((PASS+1)); } || { echo "  ✗ Learning mode workflows missing @agentic-learning invocations"; FAIL=$((FAIL+1)); ERRORS+=("learning_mode workflows missing skill invocations"); }

# Verify routing protocol consistency — auto/active should trigger skill, manual should be quiet tip
node -e "
const fs=require('fs'),path=require('path');
const wfDir='$SRC_WF';
const wfs=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));
let autoCount=0,manualCount=0;
for(const wf of wfs){
  const c=fs.readFileSync(path.join(wfDir,wf),'utf8');
  if(c.includes('auto\`')||c.includes('active\`')||c.includes('\`auto\`')||c.includes('auto\`:'))autoCount++;
  if(c.includes('\`manual\`')||c.includes('manual\`:'))manualCount++;
}
// Both routing modes should be referenced (auto/active for proactive, manual for quiet)
if(autoCount<5||manualCount<5)process.exit(1);
console.log('auto/active: '+autoCount+' refs, manual: '+manualCount+' refs');
" && { echo "  ✓ Routing protocol has both auto/active and manual modes"; PASS=$((PASS+1)); } || { echo "  ✗ Routing protocol missing mode references"; FAIL=$((FAIL+1)); ERRORS+=("Routing protocol missing modes"); }

# ─── 4. Root SKILL.md Sync ───────────────────────────────────────────
# The root SKILL.md is the Windsurf global skill entry point. It must
# list all workflows, reference both skills, and document the config.

echo ""
echo "─── Root SKILL.md Sync ───────────────────────────────────────────"

check "SKILL.md: exists" test -f "$ROOT_SKILL"
check "SKILL.md: references agentic-learning" grep -q 'agentic-learning' "$ROOT_SKILL"
check "SKILL.md: references impeccable" grep -q 'impeccable' "$ROOT_SKILL"
check "SKILL.md: documents learning_mode" grep -q 'learning_mode\|Learning Mode' "$ROOT_SKILL"
check "SKILL.md: has workflow listing" grep -q '/new-project' "$ROOT_SKILL"
check "SKILL.md: has config reference" grep -q 'config.json' "$ROOT_SKILL"
check "SKILL.md: has context profiles section" grep -q 'Context Profiles\|context' "$ROOT_SKILL"

# Verify SKILL.md lists a substantial number of workflows
node -e "
const c=require('fs').readFileSync('$ROOT_SKILL','utf8');
const matches=c.match(/\x60\/[a-z]+-[a-z-]+\x60/g)||[];
if(matches.length<10){
  console.error('Only '+matches.length+' workflow references (expected ≥20)');
  process.exit(1);
}
console.log(matches.length+' workflow references');
" && { echo "  ✓ SKILL.md references 20+ workflows"; PASS=$((PASS+1)); } || { echo "  ✗ SKILL.md missing workflow references"; FAIL=$((FAIL+1)); ERRORS+=("SKILL.md missing workflow refs"); }

# ─── 5. Context Profiles ─────────────────────────────────────────────
# Three output modes that change agent behavior: dev, research, review.

echo ""
echo "─── Context Profiles ─────────────────────────────────────────────"

for profile in dev.md research.md review.md; do
  check "context profile: $profile exists" test -f "$CONTEXTS_DIR/$profile"
  check "context profile: $profile is substantive (>200B)" node -e "
    if(require('fs').statSync('$CONTEXTS_DIR/$profile').size<200)process.exit(1);
  "
done

# ─── 6. Reference Files ──────────────────────────────────────────────
# Workflow @./references/ links must resolve to real files.

echo ""
echo "─── Reference Files ──────────────────────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const wfDir='$SRC_WF';
const refsDir='$REFS_DIR';
const errs=[];

const wfs=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));
for(const wf of wfs){
  const c=fs.readFileSync(path.join(wfDir,wf),'utf8');
  const refs=[...c.matchAll(/@\.\/references\/([a-zA-Z0-9_-]+\.md)/g)];
  for(const m of refs){
    const refFile=m[1];
    if(!fs.existsSync(path.join(refsDir,refFile))){
      errs.push(wf+': @./references/'+refFile+' does not exist');
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('OK');
" && { echo "  ✓ All @./references/ links in workflows resolve"; PASS=$((PASS+1)); } || { echo "  ✗ Dangling @./references/ links found"; FAIL=$((FAIL+1)); ERRORS+=("Dangling @./references/ links"); }

# Verify all reference files are substantive
node -e "
const fs=require('fs'),path=require('path');
const refsDir='$REFS_DIR';
const errs=[];
const files=fs.readdirSync(refsDir).filter(f=>f.endsWith('.md'));
for(const f of files){
  const size=fs.statSync(path.join(refsDir,f)).size;
  if(size<500)errs.push(f+': only '+size+' bytes (expected ≥500)');
}
if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('All '+files.length+' reference files are substantive');
" && { echo "  ✓ All reference files are substantive (≥500B)"; PASS=$((PASS+1)); } || { echo "  ✗ Reference files too small"; FAIL=$((FAIL+1)); ERRORS+=("Reference files too small"); }

# ─── 7. Skills Installation (Cross-Platform) ─────────────────────────
# Skills must be installed correctly for platforms that support them.

echo ""
echo "─── Skills Installation ──────────────────────────────────────────"

TMPBASE=$(mktemp -d)
# shellcheck disable=SC2064
trap "rm -rf $TMPBASE" EXIT

# Install Windsurf and check skills are present
mkdir -p "$TMPBASE/ws"
node "$REPO_DIR/bin/install.js" --windsurf --target "$TMPBASE/ws" > /dev/null 2>&1

check "Windsurf install: agentic-learning SKILL.md present" test -f "$TMPBASE/ws/skills/agentic-learning/SKILL.md"
check "Windsurf install: impeccable SKILL.md present" test -f "$TMPBASE/ws/skills/impeccable/SKILL.md"

# Verify installed skill content matches source
node -e "
const fs=require('fs');
const src=fs.readFileSync('$SKILLS_DIR/agentic-learning/SKILL.md','utf8');
const inst=fs.readFileSync('$TMPBASE/ws/skills/agentic-learning/SKILL.md','utf8');
if(src!==inst){console.error('Content mismatch');process.exit(1);}
" && { echo "  ✓ Installed agentic-learning SKILL.md matches source"; PASS=$((PASS+1)); } || { echo "  ✗ Installed agentic-learning content differs from source"; FAIL=$((FAIL+1)); ERRORS+=("Installed skill content mismatch"); }

# Verify impeccable action dirs are installed
node -e "
const fs=require('fs'),path=require('path');
const instDir='$TMPBASE/ws/skills/impeccable';
const srcDir='$SKILLS_DIR/impeccable';
const srcDirs=fs.readdirSync(srcDir,{withFileTypes:true}).filter(d=>d.isDirectory()).map(d=>d.name);
const instDirs=fs.readdirSync(instDir,{withFileTypes:true}).filter(d=>d.isDirectory()).map(d=>d.name);
const missing=srcDirs.filter(d=>!instDirs.includes(d));
if(missing.length){console.error('Missing: '+missing.join(', '));process.exit(1);}
console.log('All '+srcDirs.length+' impeccable action dirs installed');
" && { echo "  ✓ All impeccable action directories installed"; PASS=$((PASS+1)); } || { echo "  ✗ Impeccable action dirs missing from install"; FAIL=$((FAIL+1)); ERRORS+=("Impeccable dirs missing from install"); }

# ─── 8. Skills Mirror Sync ───────────────────────────────────────────
# skills/ and .windsurf/skills/ must be identical.

echo ""
echo "─── Skills Mirror Sync ───────────────────────────────────────────"

check "skills/ and .windsurf/skills/ are in sync" diff -rq "$SKILLS_DIR" "$WS_SKILLS"

# ─── 9. Impeccable in Workflows ───────────────────────────────────────
# Workflows that deal with UI/frontend should reference @impeccable.

echo ""
echo "─── Impeccable Integration ───────────────────────────────────────"

node -e "
const fs=require('fs'),path=require('path');
const wfDir='$SRC_WF';
const wfs=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));
const withImp=wfs.filter(wf=>{
  const c=fs.readFileSync(path.join(wfDir,wf),'utf8');
  return c.includes('@impeccable')||c.includes('impeccable');
});
console.log(withImp.length+' workflows reference impeccable');
if(withImp.length<3)process.exit(1);
" && { echo "  ✓ Impeccable skill referenced in 3+ workflows"; PASS=$((PASS+1)); } || { echo "  ✗ Impeccable skill underused in workflows"; FAIL=$((FAIL+1)); ERRORS+=("Impeccable underused"); }

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
