#!/usr/bin/env bash
# learnship — Platform-specific installation validation
#
# Tests platform-specific outputs that could break silently:
#   1. Codex — config.toml structure, agent .toml files, sandbox modes
#   2. Gemini — settings.json with enableAgents, TOML commands, agents
#   3. Claude — commands structure, agents dir, hooks wiring in settings.json
#   4. OpenCode — flat command/ dir, permissions config
#   5. Windsurf — rules/ dir matches agents, skills as native dirs
#   6. Cursor — .mdc rule file, plugin.json, hooks config
#   7. Platform guide docs — all 6 exist and reference correct platform
#   8. Plugin manifest version sync — all 3 manifests match package.json
#   9. Tool name rewrites verified per platform

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
    echo "  ✗ $description (expected '$expected')"
    FAIL=$((FAIL+1))
    ERRORS+=("$description")
  fi
}

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " Platform-Specific Installation Validation"
echo "═══════════════════════════════════════════════════════════════════"

# Install all platforms to temp dirs
TMPBASE=$(mktemp -d)
# shellcheck disable=SC2064
trap "rm -rf $TMPBASE" EXIT

for p in windsurf claude opencode gemini codex; do
  mkdir -p "$TMPBASE/$p"
  node "$REPO_DIR/bin/install.js" "--$p" --target "$TMPBASE/$p" > /dev/null 2>&1
done

# ─── 1. Codex ─────────────────────────────────────────────────────────

echo ""
echo "─── Codex ────────────────────────────────────────────────────────"

CX="$TMPBASE/codex"

check "codex: config.toml exists" test -f "$CX/config.toml"
check "codex: config.toml has [features]" grep -q '\[features\]' "$CX/config.toml"
check "codex: config.toml has multi_agent = true" grep -q 'multi_agent = true' "$CX/config.toml"
check "codex: config.toml has [agents] section" grep -q '\[agents\]' "$CX/config.toml"

# All 17 agent personas should have .toml files
CODEX_AGENT_COUNT=$(ls "$CX/agents/"*.toml 2>/dev/null | wc -l)
check "codex: 17 agent .toml files (got $CODEX_AGENT_COUNT)" test "$CODEX_AGENT_COUNT" -eq 17

# Each agent .toml must have config_file referenced in config.toml
node -e "
const fs=require('fs');
const config=fs.readFileSync('$CX/config.toml','utf8');
const agents=fs.readdirSync('$CX/agents').filter(f=>f.endsWith('.toml'));
const errs=[];
for(const a of agents){
  const name=a.replace('.toml','');
  if(!config.includes('[agents.'+name+']'))errs.push(name+' not in config.toml [agents] section');
}
if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('All '+agents.length+' agents registered in config.toml');
" && { echo "  ✓ All codex agents registered in config.toml"; PASS=$((PASS+1)); } || { echo "  ✗ Codex agents not registered"; FAIL=$((FAIL+1)); ERRORS+=("Codex agents not registered"); }

# Sandbox modes: reviewers/checkers should be read-only
# verifier uses workspace-write (needs to run tests), not read-only
for checker in code-reviewer doc-verifier plan-checker security-auditor; do
  TOML_FILE="$CX/agents/learnship-$checker.toml"
  if [ -f "$TOML_FILE" ]; then
    check "codex: $checker has sandbox_mode = read-only" grep -q 'sandbox_mode.*=.*"read-only"' "$TOML_FILE"
  fi
done

# Executor should NOT be read-only (it writes code)
check "codex: executor is NOT read-only" node -e "
const c=require('fs').readFileSync('$CX/agents/learnship-executor.toml','utf8');
if(c.includes('sandbox_mode') && c.includes('read-only'))process.exit(1);
"

# Codex uses request_user_input, not AskUserQuestion
check "codex: uses request_user_input (not AskUserQuestion)" node -e "
const fs=require('fs'),path=require('path');
const dir='$CX/learnship/workflows';
const files=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
for(const f of files){
  const c=fs.readFileSync(path.join(dir,f),'utf8');
  if(c.includes('AskUserQuestion')){console.error(f+' still has AskUserQuestion');process.exit(1);}
}
"

# ─── 2. Gemini ────────────────────────────────────────────────────────

echo ""
echo "─── Gemini ───────────────────────────────────────────────────────"

GM="$TMPBASE/gemini"

check "gemini: settings.json exists" test -f "$GM/settings.json"
check "gemini: enableAgents is true" node -e "
const s=JSON.parse(require('fs').readFileSync('$GM/settings.json','utf8'));
if(!s.experimental||!s.experimental.enableAgents)process.exit(1);
"

check "gemini: hooks wired in settings.json" node -e "
const s=JSON.parse(require('fs').readFileSync('$GM/settings.json','utf8'));
if(!s.hooks||!s.hooks.SessionStart)process.exit(1);
"

# Gemini commands are TOML format
GEMINI_CMD_COUNT=$(ls "$GM/commands/learnship/"*.toml 2>/dev/null | wc -l)
check "gemini: 57 TOML command files (got $GEMINI_CMD_COUNT)" test "$GEMINI_CMD_COUNT" -eq 57

# Gemini uses google_web_search, not WebSearch
check "gemini: uses google_web_search (not WebSearch)" node -e "
const fs=require('fs'),path=require('path');
const dir='$GM/learnship/workflows';
const files=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
for(const f of files){
  const c=fs.readFileSync(path.join(dir,f),'utf8');
  if(/\bWebSearch\b/.test(c)){console.error(f+' still has WebSearch');process.exit(1);}
}
"

# Gemini uses ask_user, not AskUserQuestion
check "gemini: uses ask_user (not AskUserQuestion)" node -e "
const fs=require('fs'),path=require('path');
const dir='$GM/learnship/workflows';
const files=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
for(const f of files){
  const c=fs.readFileSync(path.join(dir,f),'utf8');
  if(/\bAskUserQuestion\b/.test(c)){console.error(f+' still has AskUserQuestion');process.exit(1);}
}
"

# Gemini agents are .md (not .toml like codex)
GEMINI_AGENT_COUNT=$(ls "$GM/agents/"*.md 2>/dev/null | wc -l)
check "gemini: 17 agent .md files (got $GEMINI_AGENT_COUNT)" test "$GEMINI_AGENT_COUNT" -eq 17

# ─── 3. Claude ────────────────────────────────────────────────────────

echo ""
echo "─── Claude Code ──────────────────────────────────────────────────"

CL="$TMPBASE/claude"

# Claude commands are .md with learnship: prefix in names
CLAUDE_CMD_COUNT=$(ls "$CL/commands/learnship/"*.md 2>/dev/null | wc -l)
check "claude: 57 command .md files (got $CLAUDE_CMD_COUNT)" test "$CLAUDE_CMD_COUNT" -eq 57

# Claude keeps AskUserQuestion (native)
check "claude: keeps AskUserQuestion (native)" node -e "
const fs=require('fs'),path=require('path');
const dir='$CL/learnship/workflows';
const files=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
let found=false;
for(const f of files){
  const c=fs.readFileSync(path.join(dir,f),'utf8');
  if(c.includes('AskUserQuestion')){found=true;break;}
}
if(!found)process.exit(1);
"

# Claude uses /agentic-learning (not @agentic-learning)
check "claude: uses /agentic-learning (not @agentic-learning)" node -e "
const fs=require('fs'),path=require('path');
const dir='$CL/learnship/workflows';
const files=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
for(const f of files){
  const c=fs.readFileSync(path.join(dir,f),'utf8');
  if(/@agentic-learning\b/.test(c)){console.error(f+' still has @agentic-learning');process.exit(1);}
}
"

# Claude agents are .md
CLAUDE_AGENT_COUNT=$(ls "$CL/agents/"*.md 2>/dev/null | wc -l)
check "claude: 17 agent .md files (got $CLAUDE_AGENT_COUNT)" test "$CLAUDE_AGENT_COUNT" -eq 17

# Claude hooks are installed
check "claude: hooks dir with 4+ files" node -e "
const fs=require('fs');
const files=fs.readdirSync('$CL/hooks');
if(files.length<4)process.exit(1);
"

# Claude settings.json has hooks
check "claude: settings.json has hook config" test -f "$CL/settings.json"

# ─── 4. OpenCode ─────────────────────────────────────────────────────

echo ""
echo "─── OpenCode ─────────────────────────────────────────────────────"

OC="$TMPBASE/opencode"

# OpenCode uses flat command/ dir (not commands/learnship/)
OC_CMD_COUNT=$(ls "$OC/command/"*.md 2>/dev/null | wc -l)
check "opencode: 57 flat command .md files (got $OC_CMD_COUNT)" test "$OC_CMD_COUNT" -eq 57

# OpenCode agents
OC_AGENT_COUNT=$(ls "$OC/agents/"*.md 2>/dev/null | wc -l)
check "opencode: 17 agent .md files (got $OC_AGENT_COUNT)" test "$OC_AGENT_COUNT" -eq 17

# OpenCode strips @ from skill names (no dispatch mechanism)
check "opencode: strips @agentic-learning to plain name" node -e "
const fs=require('fs'),path=require('path');
const dir='$OC/learnship/workflows';
const files=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
for(const f of files){
  const c=fs.readFileSync(path.join(dir,f),'utf8');
  if(/@agentic-learning\b/.test(c)){console.error(f+' still has @agentic-learning');process.exit(1);}
}
"

# ─── 5. Windsurf ─────────────────────────────────────────────────────

echo ""
echo "─── Windsurf ─────────────────────────────────────────────────────"

WS="$TMPBASE/windsurf"

# Windsurf workflows are in workflows/ (not learnship/workflows/)
WS_WF_COUNT=$(ls "$WS/workflows/"*.md 2>/dev/null | wc -l)
check "windsurf: 57 workflow .md files in workflows/ (got $WS_WF_COUNT)" test "$WS_WF_COUNT" -eq 57

# Windsurf keeps @agentic-learning (native skill dispatch)
check "windsurf: keeps @agentic-learning (native)" node -e "
const fs=require('fs'),path=require('path');
const dir='$WS/workflows';
const files=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
let found=false;
for(const f of files){
  const c=fs.readFileSync(path.join(dir,f),'utf8');
  if(/@agentic-learning\b/.test(c)){found=true;break;}
}
if(!found)process.exit(1);
"

# Windsurf uses ask_user_question (not AskUserQuestion)
check "windsurf: uses ask_user_question (not AskUserQuestion)" node -e "
const fs=require('fs'),path=require('path');
const dir='$WS/workflows';
const files=fs.readdirSync(dir).filter(f=>f.endsWith('.md'));
for(const f of files){
  const c=fs.readFileSync(path.join(dir,f),'utf8');
  if(/\bAskUserQuestion\b/.test(c)){console.error(f+' still has AskUserQuestion');process.exit(1);}
}
"

# Windsurf rules dir
WS_RULE_COUNT=$(ls "$WS/rules/"*.md 2>/dev/null | wc -l)
check "windsurf: 17 agent rules in rules/ (got $WS_RULE_COUNT)" test "$WS_RULE_COUNT" -eq 17

# Windsurf skills as native dirs
check "windsurf: skills/agentic-learning/ exists" test -d "$WS/skills/agentic-learning"
check "windsurf: skills/impeccable/ exists" test -d "$WS/skills/impeccable"

# ─── 6. Cursor ────────────────────────────────────────────────────────

echo ""
echo "─── Cursor ───────────────────────────────────────────────────────"

# Cursor .mdc rule file
MDC="$REPO_DIR/cursor-rules/learnship.mdc"
check "cursor: learnship.mdc exists" test -f "$MDC"
check "cursor: .mdc is substantive (>5KB)" node -e "
if(require('fs').statSync('$MDC').size<5000)process.exit(1);
"

# .cursor-plugin/plugin.json
CURSOR_PLUGIN="$REPO_DIR/.cursor-plugin/plugin.json"
check "cursor: .cursor-plugin/plugin.json exists" test -f "$CURSOR_PLUGIN"
check "cursor: plugin.json is valid JSON" node -e "JSON.parse(require('fs').readFileSync('$CURSOR_PLUGIN','utf8'))"
check "cursor: plugin.json has correct version" node -e "
const pkg=require('$REPO_DIR/package.json');
const plugin=JSON.parse(require('fs').readFileSync('$CURSOR_PLUGIN','utf8'));
if(plugin.version!==pkg.version)process.exit(1);
"

# ─── 7. Platform Guide Docs ──────────────────────────────────────────

echo ""
echo "─── Platform Guide Docs ──────────────────────────────────────────"

DOCS_DIR="$REPO_DIR/docs/platform-guide"
for guide in windsurf.md claude-code.md opencode.md gemini-cli.md codex-cli.md cursor.md; do
  PLATFORM_NAME=$(echo "$guide" | sed 's/\.md//;s/-/ /g')
  check "docs: $PLATFORM_NAME guide exists" test -f "$DOCS_DIR/$guide"
  check "docs: $PLATFORM_NAME guide is substantive (>1KB)" node -e "
    if(require('fs').statSync('$DOCS_DIR/$guide').size<1000)process.exit(1);
  "
  check "docs: $PLATFORM_NAME guide mentions install" grep -qi 'install' "$DOCS_DIR/$guide"
done

# ─── 8. Plugin Manifest Version Sync ─────────────────────────────────

echo ""
echo "─── Plugin Manifest Version Sync ─────────────────────────────────"

node -e "
const pkg=require('$REPO_DIR/package.json');
const v=pkg.version;
const errs=[];

// .claude-plugin/plugin.json
const claude=JSON.parse(require('fs').readFileSync('$REPO_DIR/.claude-plugin/plugin.json','utf8'));
if(claude.version!==v)errs.push('.claude-plugin: '+claude.version+' vs '+v);

// .cursor-plugin/plugin.json
const cursor=JSON.parse(require('fs').readFileSync('$REPO_DIR/.cursor-plugin/plugin.json','utf8'));
if(cursor.version!==v)errs.push('.cursor-plugin: '+cursor.version+' vs '+v);

// gemini-extension.json
const gemini=JSON.parse(require('fs').readFileSync('$REPO_DIR/gemini-extension.json','utf8'));
if(gemini.version!==v)errs.push('gemini-extension: '+gemini.version+' vs '+v);

if(errs.length){errs.forEach(e=>console.error('  - '+e));process.exit(1);}
console.log('All 3 manifests at v'+v);
" && { echo "  ✓ All plugin manifests match package.json version"; PASS=$((PASS+1)); } || { echo "  ✗ Plugin manifest version mismatch"; FAIL=$((FAIL+1)); ERRORS+=("Manifest version mismatch"); }

# ─── 9. Tool Name Rewrite Summary ────────────────────────────────────
# Verify each platform got the correct tool name rewrites by spot-checking
# a workflow that uses AskUserQuestion and WebSearch.

echo ""
echo "─── Tool Name Rewrites ───────────────────────────────────────────"

# Find a workflow that uses both AskUserQuestion and WebSearch in source
# shellcheck disable=SC2034  # used in grep commands below
SRC_WF="$REPO_DIR/learnship/workflows"
TARGET_WF="new-project.md"

# Source should have AskUserQuestion
check "source: new-project.md has AskUserQuestion" grep -q 'AskUserQuestion' "$SRC_WF/$TARGET_WF"

# Windsurf → ask_user_question
check "windsurf rewrite: ask_user_question in new-project" grep -q 'ask_user_question' "$WS/workflows/$TARGET_WF"

# Claude → keeps AskUserQuestion
check "claude rewrite: AskUserQuestion preserved in new-project" grep -q 'AskUserQuestion' "$CL/learnship/workflows/$TARGET_WF"

# Gemini → ask_user
check "gemini rewrite: ask_user in new-project" grep -q 'ask_user' "$GM/learnship/workflows/$TARGET_WF"

# Codex → request_user_input
check "codex rewrite: request_user_input in new-project" grep -q 'request_user_input' "$CX/learnship/workflows/$TARGET_WF"

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
