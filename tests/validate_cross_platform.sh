#!/usr/bin/env bash
# learnship — Cross-platform install & workflow integrity validation
#
# Installs learnship to temp dirs for all 5 installable platforms (Windsurf,
# Claude Code, OpenCode, Gemini CLI, Codex CLI), then validates:
#   1. Tool name rewrites (AskUserQuestion → platform-native)
#   2. Web tool rewrites (WebSearch/WebFetch → platform-native)
#   3. Agent persona integrity (persona_context, @./agents/, Task() definitions)
#   4. STOP gate preservation across all platforms
#   5. Config verification gate preservation
#   6. Agent files exist for every referenced persona
#   7. AskUserQuestion STOP gates in ALL workflows that use interactive questions
#   8. Workflow file counts match across platforms
#
# This catches the class of bugs where:
# - install.js silently drops tool rewrites for a platform
# - Agent persona references break after install
# - STOP gates or config gates get stripped during transform
# - A platform is missing workflows that other platforms have

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$REPO_DIR/bin/install.js"
TMPBASE=$(mktemp -d)
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

cleanup() {
  rm -rf "$TMPBASE"
}
trap cleanup EXIT

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " Cross-Platform Install & Workflow Integrity"
echo "═══════════════════════════════════════════════════════════════════"

# ─── Install all 5 platforms ──────────────────────────────────────────
echo ""
echo "─── Installing to temp dirs ──────────────────────────────────────"

PLATFORMS="windsurf claude opencode gemini codex"
for p in $PLATFORMS; do
  DIR="$TMPBASE/$p"
  mkdir -p "$DIR"
  node "$INSTALLER" "--$p" --target "$DIR" > /dev/null 2>&1
  check "$p install succeeded" test -d "$DIR/learnship/workflows"
done

# ─── Platform tool name expectations ──────────────────────────────────
# Each platform has a PRIMARY question tool and a PRIMARY web search tool.
# The primary tool should have 9+ occurrences in new-project.md.
# Other platform tool names should appear 1 time each (in the enforcement header).

declare -A ASK_TOOL
ASK_TOOL[windsurf]="ask_user_question"
ASK_TOOL[claude]="AskUserQuestion"
ASK_TOOL[opencode]="question"  # OpenCode convertToOpencode rewrites to 'question'
ASK_TOOL[gemini]="ask_user"
ASK_TOOL[codex]="request_user_input"

declare -A WEB_TOOL
WEB_TOOL[windsurf]="search_web"
WEB_TOOL[claude]="WebSearch"
WEB_TOOL[opencode]="websearch"  # OpenCode convertToOpencode rewrites to 'websearch'
WEB_TOOL[gemini]="google_web_search"
WEB_TOOL[codex]="WebSearch"  # Codex keeps Claude tools

declare -A RAW_ASK_FORBIDDEN
RAW_ASK_FORBIDDEN[windsurf]="AskUserQuestion"
RAW_ASK_FORBIDDEN[opencode]="AskUserQuestion"
RAW_ASK_FORBIDDEN[gemini]="AskUserQuestion"
# Claude and Codex keep AskUserQuestion, so no forbidden check for them

echo ""
echo "─── Tool Name Rewrites (new-project.md) ──────────────────────────"

for p in $PLATFORMS; do
  NP="$TMPBASE/$p/learnship/workflows/new-project.md"
  if [ ! -f "$NP" ]; then
    echo "  ✗ $p: new-project.md not found in learnship/workflows/"
    FAIL=$((FAIL+1))
    ERRORS+=("$p: new-project.md not found")
    continue
  fi

  # Primary ask tool should appear 5+ times (in actual AskUserQuestion calls)
  primary="${ASK_TOOL[$p]}"
  count=$(grep -c "$primary" "$NP" 2>/dev/null; true)
  count=$(echo "$count" | tr -d '[:space:]')
  check "$p: primary ask tool '$primary' appears $count times (need ≥5)" test "$count" -ge 5

  # Forbidden raw tool should be 0
  forbidden="${RAW_ASK_FORBIDDEN[$p]}"
  if [ -n "$forbidden" ]; then
    raw_count=$(grep -c "$forbidden" "$NP" 2>/dev/null; true)
    raw_count=$(echo "$raw_count" | tr -d '[:space:]')
    check "$p: raw '$forbidden' is 0 (got $raw_count)" test "$raw_count" -eq 0
  fi

  # Primary web tool should appear 5+ times
  web="${WEB_TOOL[$p]}"
  web_count=$(grep -c "$web" "$NP" 2>/dev/null; true)
  web_count=$(echo "$web_count" | tr -d '[:space:]')
  check "$p: primary web tool '$web' appears $web_count times (need ≥5)" test "$web_count" -ge 5
done

echo ""
echo "─── STOP Gates & Config Verification (all platforms) ─────────────"

for p in $PLATFORMS; do
  NP="$TMPBASE/$p/learnship/workflows/new-project.md"
  [ ! -f "$NP" ] && continue

  stop_count=$(grep -c '🛑 STOP' "$NP" 2>/dev/null; true)
  stop_count=$(echo "$stop_count" | tr -d '[:space:]')
  check "$p: STOP gates in new-project ($stop_count, need ≥6)" test "$stop_count" -ge 6

  check "$p: CONFIG_VALID gate present" grep -q 'CONFIG_VALID' "$NP"
  check "$p: CONFIG_INVALID gate present" grep -q 'CONFIG_INVALID' "$NP"
  check "$p: key mapping table present" grep -q 'Key mapping from questions to config' "$NP"
  check "$p: MANDATORY INTERACTIVE QUESTIONS header" grep -q 'MANDATORY INTERACTIVE QUESTIONS' "$NP"
done

echo ""
echo "─── Agent Persona Integrity (source workflows) ───────────────────"

# Every workflow that references persona_context must also reference @./agents/
# Every @./agents/ reference must point to a file that exists
AGENTS_DIR="$REPO_DIR/learnship/agents"
SRC_WF="$REPO_DIR/learnship/workflows"

node -e "
const fs=require('fs'),path=require('path');
const wfDir='$SRC_WF';
const agDir='$AGENTS_DIR';
const errs=[];

const wfs=fs.readdirSync(wfDir).filter(f=>f.endsWith('.md'));

for(const wf of wfs){
  const c=fs.readFileSync(path.join(wfDir,wf),'utf8');

  // Check: persona_context must have @./agents/ ref
  if(c.includes('<persona_context>') && !c.includes('@./agents/')){
    errs.push(wf+': has <persona_context> but no @./agents/ reference');
  }

  // Check: every @./agents/ ref points to existing file
  const refs=[...c.matchAll(/@\.\/agents\/([a-z-]+\.md)/g)];
  for(const m of refs){
    const agFile=path.join(agDir,m[1]);
    if(!fs.existsSync(agFile)){
      errs.push(wf+': references @./agents/'+m[1]+' but file does not exist');
    }
  }

  // Check: every Task() with subagent_type has an agent_definition block
  const tasks=[...c.matchAll(/Task\(\s*\n\s*subagent_type=\"([^\"]+)\"/g)];
  for(const t of tasks){
    if(!c.includes('<agent_definition>')){
      errs.push(wf+': Task() with subagent_type='+t[1]+' but no <agent_definition> block');
    }
  }
}

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
else{console.log('OK');}
" && { echo "  ✓ All persona_context blocks have @./agents/ refs"; PASS=$((PASS+1)); echo "  ✓ All @./agents/ refs point to existing files"; PASS=$((PASS+1)); echo "  ✓ All Task() calls have agent_definition blocks"; PASS=$((PASS+1)); } || { echo "  ✗ Agent persona integrity check failed (see above)"; FAIL=$((FAIL+1)); ERRORS+=("Agent persona integrity check failed"); }

echo ""
echo "─── Agent Persona Preservation Across Platforms ──────────────────"

# persona_context blocks and @./agents/ refs must survive install.js transforms
for p in $PLATFORMS; do
  WF_DIR="$TMPBASE/$p/learnship/workflows"
  [ ! -d "$WF_DIR" ] && continue

  node -e "
  const fs=require('fs'),path=require('path');
  const dir='$WF_DIR';
  const wfs=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
  let pcCount=0,agCount=0;
  for(const wf of wfs){
    const c=fs.readFileSync(path.join(dir,wf),'utf8');
    if(c.includes('<persona_context>'))pcCount++;
    if(c.includes('@./agents/'))agCount++;
  }
  // Source has 18 workflows with persona_context and 18 with @./agents/
  if(pcCount<16){console.error('Only '+pcCount+' workflows have persona_context (expected ≥16)');process.exit(1);}
  if(agCount<16){console.error('Only '+agCount+' workflows have @./agents/ refs (expected ≥16)');process.exit(1);}
  " && check "$p: persona_context blocks preserved (≥16 workflows)" true || { echo "  ✗ $p: persona_context blocks lost during install"; FAIL=$((FAIL+1)); ERRORS+=("$p: persona_context blocks lost"); }
done

echo ""
echo "─── Agent Files Exist Per Platform ───────────────────────────────"

# Each platform must have agent files installed
for p in $PLATFORMS; do
  AG_DIR=""
  case $p in
    windsurf) AG_DIR="$TMPBASE/$p/rules" ;;
    claude|gemini) AG_DIR="$TMPBASE/$p/agents" ;;
    opencode) AG_DIR="$TMPBASE/$p/agents" ;;
    codex) AG_DIR="$TMPBASE/$p/agents" ;;
  esac

  if [ -d "$AG_DIR" ]; then
    ag_count=$(find "$AG_DIR" -type f | wc -l | tr -d ' ')
    check "$p: agent persona files installed ($ag_count, need ≥15)" test "$ag_count" -ge 15
  else
    echo "  ✗ $p: agent directory not found at $AG_DIR"
    FAIL=$((FAIL+1))
    ERRORS+=("$p: agent directory not found")
  fi
done

echo ""
echo "─── AskUserQuestion STOP Gates in ALL Workflows ──────────────────"

# Every workflow that uses AskUserQuestion must have at least one STOP gate nearby
# This prevents the AI from rendering questions as plain text
node -e "
const fs=require('fs'),path=require('path');
const dir='$SRC_WF';
const wfs=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
const violations=[];

for(const wf of wfs){
  const c=fs.readFileSync(path.join(dir,wf),'utf8');
  if(!c.includes('AskUserQuestion'))continue;

  // Count AskUserQuestion calls (code blocks with AskUserQuestion([)
  const askCalls=(c.match(/AskUserQuestion\(\[/g)||[]).length;
  // Count STOP gates
  const stopGates=(c.match(/🛑 STOP/g)||[]).length;

  // Every workflow with AskUserQuestion calls should have at least 1 STOP gate
  if(askCalls>0 && stopGates===0){
    violations.push(wf+': '+askCalls+' AskUserQuestion calls but 0 STOP gates');
  }
}
if(violations.length){violations.forEach(v=>console.error('  - '+v));process.exit(1);}
" && { echo "  ✓ All workflows with AskUserQuestion have STOP gates"; PASS=$((PASS+1)); } || { echo "  ✗ Some workflows with AskUserQuestion lack STOP gates"; FAIL=$((FAIL+1)); ERRORS+=("Workflows with AskUserQuestion lacking STOP gates"); }

echo ""
echo "─── Workflow Count Parity Across Platforms ───────────────────────"

# All platforms should have the same number of workflow files
COUNTS=""
for p in $PLATFORMS; do
  WF_DIR="$TMPBASE/$p/learnship/workflows"
  if [ -d "$WF_DIR" ]; then
    wc=$(find "$WF_DIR" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
    COUNTS="$COUNTS $p:$wc"
    check "$p: workflow count ($wc, need ≥50)" test "$wc" -ge 50
  fi
done
echo "  Counts:$COUNTS"

# All counts should match
node -e "
const counts='$COUNTS'.trim().split(/\s+/).map(s=>{const[p,c]=s.split(':');return{p,c:parseInt(c)};});
const first=counts[0].c;
const mismatches=counts.filter(x=>x.c!==first);
if(mismatches.length){
  console.error('Mismatch: '+counts.map(x=>x.p+'='+x.c).join(', '));
  process.exit(1);
}
" && { echo "  ✓ All platforms have identical workflow count"; PASS=$((PASS+1)); } || { echo "  ✗ Workflow count mismatch across platforms"; FAIL=$((FAIL+1)); ERRORS+=("Workflow count mismatch across platforms"); }

echo ""
echo "─── Tool Rewrites Across ALL Workflows (not just new-project) ────"

# For each platform, count raw AskUserQuestion in ALL workflow files.
# Windsurf, OpenCode, Gemini should have 0 raw AskUserQuestion.
for p in windsurf opencode gemini; do
  WF_DIR="$TMPBASE/$p/learnship/workflows"
  [ ! -d "$WF_DIR" ] && continue

  raw_total=$(grep -rl 'AskUserQuestion' "$WF_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  check "$p: 0 raw AskUserQuestion across ALL workflows (got $raw_total)" test "$raw_total" -eq 0
done

# Windsurf should have 0 raw WebSearch (should be search_web)
WS_WF="$TMPBASE/windsurf/learnship/workflows"
if [ -d "$WS_WF" ]; then
  raw_ws=$(grep -rl '\bWebSearch\b' "$WS_WF"/*.md 2>/dev/null | wc -l | tr -d ' ')
  check "windsurf: 0 raw WebSearch across ALL workflows (got $raw_ws)" test "$raw_ws" -eq 0
fi

# Gemini should have 0 raw WebSearch (should be google_web_search)
GM_WF="$TMPBASE/gemini/learnship/workflows"
if [ -d "$GM_WF" ]; then
  raw_gm=$(grep -rl '\bWebSearch\b' "$GM_WF"/*.md 2>/dev/null | wc -l | tr -d ' ')
  check "gemini: 0 raw WebSearch across ALL workflows (got $raw_gm)" test "$raw_gm" -eq 0
fi

echo ""
echo "─── Windsurf-Specific: model_decision Rules ──────────────────────"

RULES_DIR="$TMPBASE/windsurf/rules"
if [ -d "$RULES_DIR" ]; then
  rule_count=$(find "$RULES_DIR" -name "learnship-*.md" | wc -l | tr -d ' ')
  check "windsurf: model_decision rules installed ($rule_count, need ≥15)" test "$rule_count" -ge 15

  # Every rule must have trigger: model_decision frontmatter
  BAD_RULES=0
  for rf in "$RULES_DIR"/learnship-*.md; do
    if ! head -3 "$rf" | grep -q 'trigger: model_decision'; then
      BAD_RULES=$((BAD_RULES+1))
    fi
  done
  check "windsurf: all rules have 'trigger: model_decision' frontmatter ($BAD_RULES bad)" test "$BAD_RULES" -eq 0

  # Every rule must have a description in frontmatter
  BAD_DESC=0
  for rf in "$RULES_DIR"/learnship-*.md; do
    if ! head -3 "$rf" | grep -q 'description:'; then
      BAD_DESC=$((BAD_DESC+1))
    fi
  done
  check "windsurf: all rules have 'description:' frontmatter ($BAD_DESC bad)" test "$BAD_DESC" -eq 0
fi

echo ""
echo "─── Codex-Specific: Sandbox Modes in config.toml ─────────────────"

CODEX_CFG="$TMPBASE/codex/config.toml"
if [ -f "$CODEX_CFG" ]; then
  check "codex: config.toml exists" test -f "$CODEX_CFG"
  check "codex: config.toml has agent entries" grep -q '\[agents\.' "$CODEX_CFG"
fi

echo ""
echo "─── Gemini-Specific: TOML Command Files ──────────────────────────"

GM_CMD="$TMPBASE/gemini/commands/learnship"
if [ -d "$GM_CMD" ]; then
  toml_count=$(find "$GM_CMD" -name "*.toml" | wc -l | tr -d ' ')
  check "gemini: TOML command files installed ($toml_count, need ≥20)" test "$toml_count" -ge 20
fi

echo ""
echo "─── Agent Template/Reference Paths (regression test) ─────────────"

# Bug found in audit: agent wrappers that say "~/.claude/learnship/templates/..."
# get rewritten to "<targetDir>/learnship/learnship/templates/..." (double learnship)
# because replacePaths replaces "~/.claude/" with "<targetDir>/learnship/".
# Source agent wrappers should use "~/.claude/templates/..." instead.
for p in claude opencode gemini; do
  WRAPPERS_DIR="$TMPBASE/$p/agents"
  [ ! -d "$WRAPPERS_DIR" ] && continue
  # Look for double-learnship paths in installed agent wrappers
  bad=$(grep -l '/learnship/learnship/templates/\|/learnship/learnship/references/' "$WRAPPERS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  check "$p: no double-learnship paths in installed agent wrappers (found $bad)" test "$bad" -eq 0
done

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
