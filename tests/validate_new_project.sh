#!/usr/bin/env bash
# learnship — new-project workflow structural validation
# Validates config schema enforcement, AskUserQuestion usage, questioning ceremony,
# STOP gates, and cross-platform correctness.
#
# This test suite catches the class of bugs where:
# - AI renders questions as plain text instead of using interactive tool
# - AI invents wrong config.json schema (flat keys, missing nested objects)
# - AI skips questioning rounds or combines them
# - Platform tool name rewrites are missing or wrong

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
ERRORS=()

check() {
  local description="$1"
  shift
  # remaining args: the test command
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
echo " new-project Workflow Structural Validation"
echo "═══════════════════════════════════════════════════════════════════"

# ─── Source files ────────────────────────────────────────────────────
SRC="$REPO_DIR/learnship/workflows/new-project.md"
WS="$REPO_DIR/.windsurf/workflows/new-project.md"
TEMPLATE="$REPO_DIR/templates/config.json"

echo ""
echo "─── Config Schema Enforcement ────────────────────────────────────"

# The config template must exist and be valid JSON
check "config.json template exists" test -f "$TEMPLATE"
check "config.json template is valid JSON" node -e "JSON.parse(require('fs').readFileSync('$TEMPLATE','utf8'))"

# Required top-level keys in the template
node -e "
const fs=require('fs');
const c=JSON.parse(fs.readFileSync('$TEMPLATE','utf8'));
const required=['mode','granularity','model_profile','learning_mode','test_first','planning','workflow','parallelization','gates','safety','review','ship','hooks','git'];
const missing=required.filter(k=>!(k in c));
if(missing.length){console.error('Missing: '+missing.join(', '));process.exit(1);}
" && { echo "  ✓ config template has all required top-level keys"; PASS=$((PASS+1)); } || { echo "  ✗ config template missing top-level keys"; FAIL=$((FAIL+1)); ERRORS+=("config template missing top-level keys"); }

# Required nested keys
node -e "
const fs=require('fs');
const c=JSON.parse(fs.readFileSync('$TEMPLATE','utf8'));
const checks=[
  [c.planning,'planning','commit_docs','commit_mode','search_gitignored'],
  [c.workflow,'workflow','research','plan_check','verifier','review','solutions_search'],
  [c.parallelization,'parallelization','enabled','plan_level','task_level'],
  [c.ship,'ship','auto_test','conventional_commits','pr_template'],
  [c.gates,'gates','confirm_project','confirm_roadmap','confirm_plan'],
  [c.review,'review','auto_after_verify'],
];
const errs=[];
for(const [obj,name,...keys] of checks){
  if(!obj){errs.push(name+' missing');continue;}
  for(const k of keys){if(!(k in obj))errs.push(name+'.'+k+' missing');}
}
if(errs.length){console.error(errs.join(', '));process.exit(1);}
" && { echo "  ✓ config template has all required nested keys"; PASS=$((PASS+1)); } || { echo "  ✗ config template missing nested keys"; FAIL=$((FAIL+1)); ERRORS+=("config template missing nested keys"); }

# Source workflow must have config schema with nested objects
check "new-project has 'mode' key in config schema" grep -q '"mode":' "$SRC"
check "new-project has 'planning' nested object in config schema" grep -q '"planning":' "$SRC"
check "new-project has 'workflow' nested object in config schema" grep -q '"workflow":' "$SRC"
check "new-project has 'parallelization' nested object in config schema" grep -q '"parallelization":' "$SRC"
check "new-project has 'ship' nested object in config schema" grep -q '"ship":' "$SRC"
check "new-project has 'gates' nested object in config schema" grep -q '"gates":' "$SRC"
check "new-project has 'safety' nested object in config schema" grep -q '"safety":' "$SRC"
check "new-project has 'git' nested object in config schema" grep -q '"git":' "$SRC"

# Config verification gate must exist
check "new-project has config verification gate (CONFIG_VALID)" grep -q 'CONFIG_VALID' "$SRC"
check "new-project has config verification gate (CONFIG_INVALID)" grep -q 'CONFIG_INVALID' "$SRC"
check "new-project forbids flat 'working_style' key" grep -q 'working_style' "$SRC"
check "new-project forbids flat 'model_tier' key" grep -q 'model_tier' "$SRC"
check "new-project forbids flat 'platform' key as config key" grep -q "'platform'" "$SRC"

# Key mapping table must exist
check "new-project has explicit key mapping table" grep -q 'Key mapping from questions to config' "$SRC"
check "new-project maps Working Style to mode" grep -q 'Working Style.*mode' "$SRC"
check "new-project maps Granularity to granularity" grep -q 'Granularity.*granularity' "$SRC"
check "new-project maps Learning Partner to learning_mode" grep -q 'Learning Partner.*learning_mode' "$SRC"
check "new-project maps AI Models to model_profile" grep -q 'AI Models.*model_profile' "$SRC"

echo ""
echo "─── AskUserQuestion & STOP Gates ─────────────────────────────────"

# Source must use AskUserQuestion (Claude Code canonical name)
SRC_AUQ_COUNT=$(grep -c 'AskUserQuestion' "$SRC")
check "new-project source uses AskUserQuestion ($SRC_AUQ_COUNT occurrences)" test "$SRC_AUQ_COUNT" -ge 4

# Must have STOP gates between rounds
STOP_COUNT=$(grep -c '🛑 STOP' "$SRC")
check "new-project has STOP gates ($STOP_COUNT found, need ≥6)" test "$STOP_COUNT" -ge 6

# Must have round-specific blocking instructions
check "new-project has Round 1 blocking instruction" grep -q 'Round 1.*reply before' "$SRC"
check "new-project has Round 2 blocking instruction" grep -q 'Round 2.*reply before' "$SRC"
check "new-project has Round 3 blocking instruction" grep -q 'Round 3.*reply before' "$SRC"

# Must have MANDATORY INTERACTIVE QUESTIONS header
check "new-project has MANDATORY INTERACTIVE QUESTIONS enforcement" grep -q 'MANDATORY INTERACTIVE QUESTIONS' "$SRC"

# Must have FORBIDDEN plain-text instruction
check "new-project FORBIDS plain text question rendering" grep -q 'Do NOT render questions as plain text' "$SRC"
check "new-project FORBIDS presenting all questions at once" grep -q 'Do NOT present all questions at once' "$SRC"

echo ""
echo "─── Cross-Platform Tool Name Rewrites ────────────────────────────"

# Windsurf must use ask_user_question (not AskUserQuestion)
if [ -f "$WS" ]; then
  WS_ASK_COUNT=$(grep -c 'ask_user_question' "$WS")
  WS_RAW_COUNT=$(grep -c 'AskUserQuestion' "$WS" || true)
  check "Windsurf uses ask_user_question ($WS_ASK_COUNT occurrences)" test "$WS_ASK_COUNT" -ge 4
  check "Windsurf has no raw AskUserQuestion ($WS_RAW_COUNT found)" test "$WS_RAW_COUNT" -eq 0

  # Windsurf must have all STOP gates too
  WS_STOP_COUNT=$(grep -c '🛑 STOP' "$WS")
  check "Windsurf new-project has STOP gates ($WS_STOP_COUNT)" test "$WS_STOP_COUNT" -ge 6

  # Windsurf must have config verification gate
  check "Windsurf new-project has config verification gate" grep -q 'CONFIG_VALID' "$WS"

  # Windsurf must mention ask_user_question in the enforcement header
  check "Windsurf enforcement header mentions ask_user_question" grep -q 'ask_user_question' "$WS"

  # Windsurf must have key mapping table
  check "Windsurf new-project has key mapping table" grep -q 'Key mapping from questions to config' "$WS"
else
  echo "  ⚠ Windsurf new-project.md not found — skipping platform checks"
fi

echo ""
echo "─── Questioning Ceremony ─────────────────────────────────────────"

# Deep questioning must have 4 exchanges
check "new-project has 4-exchange questioning ceremony" grep -q 'Exchange 1\|EXCHANGE_1\|exchange 1' "$SRC"
check "new-project has Exchange 4 reference" grep -q 'Exchange 4\|EXCHANGE_4\|exchange 4' "$SRC"

# Research decision gate
check "new-project has MANDATORY research decision gate" grep -q 'MANDATORY USER CHOICE' "$SRC"
check "new-project research gate forbids AI self-decision" grep -q 'You are NOT allowed to decide this yourself' "$SRC"

# AGENTS.md generation
check "new-project generates AGENTS.md" grep -q 'AGENTS.md' "$SRC"

# HARD STOP at end
check "new-project has HARD STOP after done banner" grep -q 'HARD STOP' "$SRC"
check "new-project forbids auto-starting Phase 1" grep -q 'Do NOT automatically start' "$SRC"

echo ""
echo "─── Config Schema Sync ───────────────────────────────────────────"

# The config schema in the workflow must mention the same keys as the template
node -e "
const fs=require('fs');
const template=JSON.parse(fs.readFileSync('$TEMPLATE','utf8'));
const workflow=fs.readFileSync('$SRC','utf8');
const errs=[];
// Check that critical template keys appear in the workflow
const criticalKeys=['mode','granularity','model_profile','learning_mode','test_first','commit_docs','commit_mode','research','plan_check','verifier','review','solutions_search','auto_test','conventional_commits','pr_template','enabled'];
for(const k of criticalKeys){
  if(!workflow.includes('\"'+k+'\"')){errs.push('workflow missing config key reference: '+k);}
}
if(errs.length){console.error(errs.join('\n'));process.exit(1);}
" && { echo "  ✓ new-project workflow references all critical config keys"; PASS=$((PASS+1)); } || { echo "  ✗ new-project workflow missing config key references"; FAIL=$((FAIL+1)); ERRORS+=("new-project workflow missing config key references"); }

# Verify config verification gate checks the same keys as the template
node -e "
const fs=require('fs');
const wf=fs.readFileSync('$SRC','utf8');
// The verification gate must check these keys
const mustCheck=['c.mode','c.granularity','c.model_profile','c.learning_mode','c.test_first','c.planning','c.workflow','c.parallelization','c.ship'];
const errs=[];
for(const k of mustCheck){
  if(!wf.includes(k)){errs.push('verification gate does not check: '+k);}
}
if(errs.length){console.error(errs.join('\n'));process.exit(1);}
" && { echo "  ✓ config verification gate checks all critical keys"; PASS=$((PASS+1)); } || { echo "  ✗ config verification gate missing checks"; FAIL=$((FAIL+1)); ERRORS+=("config verification gate missing checks"); }

echo ""
echo "─── Quick Setup Mode (Step 2a) ───────────────────────────────────"

# new-project must offer a Quick Setup mode so users can opt out of the
# 15-question wizard. This is the fastest path to a usable project.
check "new-project source has Step 2a Setup Mode" grep -q '### Step 2a — Setup Mode' "$SRC"
check "new-project source has SETUP_MODE variable" grep -q 'SETUP_MODE = quick | custom' "$SRC"
check "new-project source has Step 2b Customize" grep -q '### Step 2b — Customize' "$SRC"
check "new-project source has Step 2c Write Config" grep -q '### Step 2c — Write Config' "$SRC"
check "new-project source documents quick-mode skip" grep -q 'SETUP_MODE = quick.*Skip Step 2b' "$SRC"
check "windsurf install has Step 2a Setup Mode" grep -q '### Step 2a — Setup Mode' "$WS"
check "windsurf install has SETUP_MODE variable" grep -q 'SETUP_MODE = quick | custom' "$WS"

# Quick Setup must be preserved across all 5 installable platforms
TMP_QS=$(mktemp -d)
trap "rm -rf $TMP_QS" EXIT
for p in windsurf claude opencode gemini codex; do
  mkdir -p "$TMP_QS/$p"
  node "$REPO_DIR/bin/install.js" "--$p" --target "$TMP_QS/$p" > /dev/null 2>&1
  WF="$TMP_QS/$p/learnship/workflows/new-project.md"
  [ "$p" = "windsurf" ] && WF="$TMP_QS/$p/workflows/new-project.md"
  if [ -f "$WF" ]; then
    check "$p: Step 2a Setup Mode preserved through install" grep -q 'Step 2a — Setup Mode' "$WF"
    check "$p: SETUP_MODE variable preserved through install" grep -q 'SETUP_MODE = quick' "$WF"
  fi
done

echo ""
echo "─── All-Platform Question Tool Coverage ──────────────────────────"

# Every platform's tool name must be mentioned in the enforcement header
node -e "
const fs=require('fs');
const src=fs.readFileSync('$SRC','utf8');
const tools=['AskUserQuestion','ask_user_question','ask_user','request_user_input'];
const missing=tools.filter(t=>!src.includes(t));
if(missing.length){console.error('Missing tool names in enforcement: '+missing.join(', '));process.exit(1);}
" && { echo "  ✓ enforcement header mentions all 4 platform tool names"; PASS=$((PASS+1)); } || { echo "  ✗ enforcement header missing platform tool names"; FAIL=$((FAIL+1)); ERRORS+=("enforcement header missing platform tool names"); }

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
