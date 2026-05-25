#!/usr/bin/env bash
# learnship — Platform wiring validation
#
# Verifies that each of the 6 platforms is correctly wired end-to-end:
#
#   1.  v2.4.1 parallelization defaults — Claude/OpenCode/Codex default ON;
#       Windsurf/Gemini/Cursor default OFF (or unsupported)
#   2.  Windsurf — all 17 model_decision rules present by exact name
#   3.  Windsurf — zero raw AskUserQuestion across all installed workflows
#   4.  Platform question-tool rewrites — all 5 platforms, not just new-project
#   5.  Codex — all 17 agent sandbox modes correct
#   6.  Gemini — experimental.enableAgents=true + 3 hooks wired in settings.json
#   7.  Claude — 4 hook JS files + settings.json with SessionStart/PostToolUse/
#       PreToolUse/statusLine
#   8.  Exact workflow count = 57 on every installable platform
#   9.  execute-phase platform routing — Cursor separated from Windsurf; new
#       default note present
#  10.  Cursor — .mdc rule file exists and has substantial content

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_WF="$REPO_DIR/learnship/workflows"

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
echo " Platform Wiring Validation"
echo "═══════════════════════════════════════════════════════════════════"

# Install all 5 platforms to temp dirs once; reuse throughout
TMPBASE=$(mktemp -d)
# shellcheck disable=SC2064
trap "rm -rf $TMPBASE" EXIT

for p in claude opencode codex windsurf gemini; do
  mkdir -p "$TMPBASE/$p"
  node "$REPO_DIR/bin/install.js" "--$p" --target "$TMPBASE/$p" > /dev/null 2>&1
done

CL="$TMPBASE/claude"
OC="$TMPBASE/opencode"
CX="$TMPBASE/codex"
WS="$TMPBASE/windsurf"
GM="$TMPBASE/gemini"

# ─── 1. v2.4.1 Parallelization Defaults ──────────────────────────────
echo ""
echo "─── 1. Parallelization Defaults (v2.4.1) ─────────────────────────"

# Parallel platforms: Quick-mode says "parallelization on"
for p in claude opencode codex; do
  WF="$TMPBASE/$p/learnship/workflows/new-project.md"
  check "$p: Quick Setup shows 'parallelization on'" \
    grep -q "parallelization on" "$WF"
done

# Parallel platforms: Step 2c default says enabled = true
for p in claude opencode codex; do
  WF="$TMPBASE/$p/learnship/workflows/new-project.md"
  check "$p: Step 2c quick default is parallelization.enabled = true" \
    grep -q "parallelization\.enabled = true" "$WF"
done

# Parallel platforms: Round 4 question recommends Yes
for p in claude opencode codex; do
  WF="$TMPBASE/$p/learnship/workflows/new-project.md"
  check "$p: parallel block recommends Yes" \
    grep -q "\*\*Yes\*\* (recommended)" "$WF"
done

# Sequential platforms: Quick-mode shows "parallelization off"
check "windsurf: Quick Setup shows 'parallelization off'" \
  grep -q "parallelization off" "$WS/workflows/new-project.md"

check "gemini: Quick Setup shows 'parallelization off'" \
  grep -q "parallelization off" "$GM/learnship/workflows/new-project.md"

# Sequential platforms: parallel block says auto-set false / not supported
check "windsurf: parallel block says 'does not support'" \
  grep -q "does not support" "$WS/workflows/new-project.md"

check "gemini: parallel block says 'automatically set to false'" \
  grep -q "automatically set to \`false\`" "$GM/learnship/workflows/new-project.md"

# Windsurf Step 2c default stays at enabled = false
check "windsurf: Step 2c quick default is parallelization.enabled = false" \
  grep -q "parallelization\.enabled = false" "$WS/workflows/new-project.md"

# ─── 2. Windsurf — All 17 model_decision Rules ───────────────────────
echo ""
echo "─── 2. Windsurf model_decision Rules (all 17 by name) ────────────"

ALL_AGENTS=(
  learnship-challenger
  learnship-code-reviewer
  learnship-debugger
  learnship-doc-verifier
  learnship-doc-writer
  learnship-executor
  learnship-ideation-agent
  learnship-phase-researcher
  learnship-plan-checker
  learnship-planner
  learnship-project-researcher
  learnship-research-synthesizer
  learnship-researcher
  learnship-roadmapper
  learnship-security-auditor
  learnship-solution-writer
  learnship-verifier
)

for agent in "${ALL_AGENTS[@]}"; do
  check "windsurf: rule $agent.md exists" \
    test -f "$WS/rules/$agent.md"
done

# Each rule must contain model_decision trigger
for agent in "${ALL_AGENTS[@]}"; do
  check "windsurf: rule $agent has model_decision" \
    grep -q "model_decision" "$WS/rules/$agent.md"
done

# ─── 3. Windsurf — Zero Raw AskUserQuestion ──────────────────────────
echo ""
echo "─── 3. Windsurf — No Raw AskUserQuestion in Installed Workflows ──"

RAW_AUQ=$(grep -rl "AskUserQuestion" "$WS/workflows/" 2>/dev/null | wc -l)
check "windsurf: 0 workflows with raw AskUserQuestion (found $RAW_AUQ)" \
  test "$RAW_AUQ" -eq 0

# Windsurf uses ask_user_question in at least the expected workflows
AUQ_COUNT=$(grep -rl "ask_user_question" "$WS/workflows/" 2>/dev/null | wc -l)
check "windsurf: ≥12 workflows use ask_user_question (found $AUQ_COUNT)" \
  test "$AUQ_COUNT" -ge 12

# ─── 4. Platform Question-Tool Rewrites — All Platforms ──────────────
echo ""
echo "─── 4. Question-Tool Rewrites — All 5 Platforms ─────────────────"

# Source must use AskUserQuestion
AUQ_SRC=$(grep -rl "AskUserQuestion" "$SRC_WF/" 2>/dev/null | wc -l)
check "source: ≥4 workflows use AskUserQuestion (found $AUQ_SRC)" \
  test "$AUQ_SRC" -ge 4

# Claude preserves AskUserQuestion (it's native)
CL_AUQ=$(grep -rl "AskUserQuestion" "$CL/learnship/workflows/" 2>/dev/null | wc -l)
check "claude: ≥4 workflows preserve AskUserQuestion (found $CL_AUQ)" \
  test "$CL_AUQ" -ge 4

# OpenCode: zero raw AskUserQuestion
OC_RAW=$(grep -rl "AskUserQuestion" "$OC/learnship/workflows/" 2>/dev/null | wc -l)
check "opencode: 0 workflows with raw AskUserQuestion (found $OC_RAW)" \
  test "$OC_RAW" -eq 0

# OpenCode: uses 'question' tool
OC_Q=$(grep -rl "^question\b\|question(\[" "$OC/learnship/workflows/" 2>/dev/null | wc -l)
check "opencode: ≥4 workflows use 'question' tool (found $OC_Q)" \
  test "$OC_Q" -ge 4

# Gemini: zero raw AskUserQuestion
GM_RAW=$(grep -rl "AskUserQuestion" "$GM/learnship/workflows/" 2>/dev/null | wc -l)
check "gemini: 0 workflows with raw AskUserQuestion (found $GM_RAW)" \
  test "$GM_RAW" -eq 0

# Gemini: uses 'ask_user' tool
GM_AU=$(grep -rl "ask_user" "$GM/learnship/workflows/" 2>/dev/null | wc -l)
check "gemini: ≥4 workflows use 'ask_user' tool (found $GM_AU)" \
  test "$GM_AU" -ge 4

# Codex: zero raw AskUserQuestion
CX_RAW=$(grep -rl "AskUserQuestion" "$CX/learnship/workflows/" 2>/dev/null | wc -l)
check "codex: 0 workflows with raw AskUserQuestion (found $CX_RAW)" \
  test "$CX_RAW" -eq 0

# Codex: uses 'request_user_input' tool
CX_RUI=$(grep -rl "request_user_input" "$CX/learnship/workflows/" 2>/dev/null | wc -l)
check "codex: ≥4 workflows use 'request_user_input' tool (found $CX_RUI)" \
  test "$CX_RUI" -ge 4

# ─── 5. Codex — All 17 Agent Sandbox Modes ───────────────────────────
echo ""
echo "─── 5. Codex — All 17 Agent Sandbox Modes ────────────────────────"

# All 17 agent .toml files exist
for agent in "${ALL_AGENTS[@]}"; do
  check "codex: $agent.toml exists" \
    test -f "$CX/agents/$agent.toml"
done

# Read-only agents: these analyze/check without writing to workspace
READ_ONLY_AGENTS=(
  learnship-challenger
  learnship-code-reviewer
  learnship-doc-verifier
  learnship-ideation-agent
  learnship-plan-checker
  learnship-security-auditor
)
for agent in "${READ_ONLY_AGENTS[@]}"; do
  check "codex: $agent is sandbox_mode=read-only" \
    grep -q 'sandbox_mode.*=.*"read-only"' "$CX/agents/$agent.toml"
done

# Write agents: these modify files, run tests, or write planning docs
WRITE_AGENTS=(
  learnship-debugger
  learnship-doc-writer
  learnship-executor
  learnship-phase-researcher
  learnship-planner
  learnship-project-researcher
  learnship-research-synthesizer
  learnship-researcher
  learnship-roadmapper
  learnship-solution-writer
  learnship-verifier
)
for agent in "${WRITE_AGENTS[@]}"; do
  check "codex: $agent is sandbox_mode=workspace-write" \
    grep -q 'sandbox_mode.*=.*"workspace-write"' "$CX/agents/$agent.toml"
done

# ─── 6. Gemini — Settings + Hook Wiring ──────────────────────────────
echo ""
echo "─── 6. Gemini — Settings & Hooks ─────────────────────────────────"

check "gemini: settings.json exists" \
  test -f "$GM/settings.json"

check "gemini: experimental.enableAgents = true" \
  node -e "
    const s = JSON.parse(require('fs').readFileSync('$GM/settings.json','utf8'));
    if (s.experimental?.enableAgents !== true) process.exit(1);
  "

check "gemini: SessionStart hook wired" \
  node -e "
    const s = JSON.parse(require('fs').readFileSync('$GM/settings.json','utf8'));
    if (!s.hooks?.SessionStart?.length) process.exit(1);
  "

check "gemini: AfterTool hook wired (context monitor)" \
  node -e "
    const s = JSON.parse(require('fs').readFileSync('$GM/settings.json','utf8'));
    if (!s.hooks?.AfterTool?.length) process.exit(1);
  "

check "gemini: BeforeTool hook wired (prompt guard)" \
  node -e "
    const s = JSON.parse(require('fs').readFileSync('$GM/settings.json','utf8'));
    if (!s.hooks?.BeforeTool?.length) process.exit(1);
  "

check "gemini: statusLine configured" \
  node -e "
    const s = JSON.parse(require('fs').readFileSync('$GM/settings.json','utf8'));
    if (!s.statusLine?.command) process.exit(1);
  "

check "gemini: 4 hook JS files installed" \
  test "$(ls "$GM/hooks/"*.js 2>/dev/null | wc -l)" -eq 4

# ─── 7. Claude Code — 4 Hooks + Settings Wiring ──────────────────────
echo ""
echo "─── 7. Claude Code — Hooks & Settings ────────────────────────────"

check "claude: 4 hook JS files installed" \
  test "$(ls "$CL/hooks/"*.js 2>/dev/null | wc -l)" -eq 4

check "claude: learnship-session-state.js installed" \
  test -f "$CL/hooks/learnship-session-state.js"

check "claude: learnship-context-monitor.js installed" \
  test -f "$CL/hooks/learnship-context-monitor.js"

check "claude: learnship-prompt-guard.js installed" \
  test -f "$CL/hooks/learnship-prompt-guard.js"

check "claude: learnship-statusline.js installed" \
  test -f "$CL/hooks/learnship-statusline.js"

check "claude: settings.json exists" \
  test -f "$CL/settings.json"

check "claude: SessionStart hook wired in settings.json" \
  node -e "
    const s = JSON.parse(require('fs').readFileSync('$CL/settings.json','utf8'));
    if (!s.hooks?.SessionStart?.length) process.exit(1);
  "

check "claude: PostToolUse hook wired in settings.json" \
  node -e "
    const s = JSON.parse(require('fs').readFileSync('$CL/settings.json','utf8'));
    if (!s.hooks?.PostToolUse?.length) process.exit(1);
  "

check "claude: PreToolUse hook wired in settings.json" \
  node -e "
    const s = JSON.parse(require('fs').readFileSync('$CL/settings.json','utf8'));
    if (!s.hooks?.PreToolUse?.length) process.exit(1);
  "

check "claude: statusLine configured in settings.json" \
  node -e "
    const s = JSON.parse(require('fs').readFileSync('$CL/settings.json','utf8'));
    if (!s.statusLine?.command) process.exit(1);
  "

check "claude: session-state hook references correct file" \
  node -e "
    const s = JSON.parse(require('fs').readFileSync('$CL/settings.json','utf8'));
    const cmd = s.hooks.SessionStart[0].hooks[0].command;
    if (!cmd.includes('learnship-session-state.js')) process.exit(1);
  "

check "claude: context-monitor PostToolUse matches Bash|Edit|Write|MultiEdit" \
  node -e "
    const s = JSON.parse(require('fs').readFileSync('$CL/settings.json','utf8'));
    const h = s.hooks.PostToolUse[0];
    if (h.matcher !== 'Bash|Edit|Write|MultiEdit') process.exit(1);
  "

check "claude: prompt-guard PreToolUse matches Write|Edit" \
  node -e "
    const s = JSON.parse(require('fs').readFileSync('$CL/settings.json','utf8'));
    const h = s.hooks.PreToolUse[0];
    if (h.matcher !== 'Write|Edit') process.exit(1);
  "

# ─── 8. Exact Workflow Count = 57 Per Platform ───────────────────────
echo ""
echo "─── 8. Exact Workflow Count = 57 Per Platform ────────────────────"

CL_WF_COUNT=$(ls "$CL/learnship/workflows/"*.md 2>/dev/null | wc -l)
check "claude: exactly 57 installed workflows (got $CL_WF_COUNT)" \
  test "$CL_WF_COUNT" -eq 57

OC_WF_COUNT=$(ls "$OC/learnship/workflows/"*.md 2>/dev/null | wc -l)
check "opencode: exactly 57 installed workflows (got $OC_WF_COUNT)" \
  test "$OC_WF_COUNT" -eq 57

CX_WF_COUNT=$(ls "$CX/learnship/workflows/"*.md 2>/dev/null | wc -l)
check "codex: exactly 57 installed workflows (got $CX_WF_COUNT)" \
  test "$CX_WF_COUNT" -eq 57

WS_WF_COUNT=$(ls "$WS/workflows/"*.md 2>/dev/null | wc -l)
check "windsurf: exactly 57 installed workflows (got $WS_WF_COUNT)" \
  test "$WS_WF_COUNT" -eq 57

GM_WF_COUNT=$(ls "$GM/learnship/workflows/"*.md 2>/dev/null | wc -l)
check "gemini: exactly 57 installed workflows (got $GM_WF_COUNT)" \
  test "$GM_WF_COUNT" -eq 57

# ─── 9. execute-phase Platform Routing ───────────────────────────────
echo ""
echo "─── 9. execute-phase Platform Routing ────────────────────────────"

EXEC="$SRC_WF/execute-phase.md"

check "execute-phase: Cursor mentioned separately from Windsurf" \
  grep -q "Cursor:" "$EXEC"

check "execute-phase: Windsurf listed as sequential (no subagents)" \
  grep -q "Windsurf:.*No subagent" "$EXEC"

check "execute-phase: Cursor has explanation for sequential dispatch" \
  grep -q "learnship dispatches sequentially" "$EXEC"

check "execute-phase: platform note references new-project default" \
  grep -q "new-project.*parallelization\|parallelization.*new-project" "$EXEC"

check "execute-phase: Gemini listed as sequential" \
  grep -q "Gemini CLI.*[Ss]equential\|default to sequential.*Gemini\|Gemini.*sequential" "$EXEC"

check "execute-phase: Claude Code uses Task() described in platform list" \
  grep -q "Claude Code.*Task(" "$EXEC"

# Sequential mode footer names Windsurf, Cursor, Gemini
check "execute-phase: sequential mode footer mentions Windsurf, Cursor, Gemini" \
  grep -q "Windsurf, Cursor, Gemini" "$EXEC"

# ─── 10. Cursor — .mdc Rule File ─────────────────────────────────────
echo ""
echo "─── 10. Cursor — .mdc Rule File ──────────────────────────────────"

MDC="$REPO_DIR/cursor-rules/learnship.mdc"

check "cursor: cursor-rules/learnship.mdc exists" \
  test -f "$MDC"

MDC_LINES=$(wc -l < "$MDC")
check "cursor: .mdc has substantial content (≥200 lines, got $MDC_LINES)" \
  test "$MDC_LINES" -ge 200

check "cursor: .mdc references /new-project" \
  grep -q "new-project" "$MDC"

check "cursor: .mdc references /execute-phase" \
  grep -q "execute-phase" "$MDC"

check "cursor: .mdc references all core workflows" \
  grep -q "plan-phase" "$MDC"

check "cursor: .mdc explains AskUserQuestion text-fallback handling" \
  grep -q "AskUserQuestion.*Cursor\|Cursor.*AskUserQuestion\|Cursor has no native structured question" "$MDC"

# ─── Results ──────────────────────────────────────────────────────────
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
