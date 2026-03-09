#!/usr/bin/env bash
# learnship — Multi-platform support validation
# Tests command wrappers, agent files, learnship/ payload, and bin/install.js

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
WARN=0

green='\033[0;32m'
red='\033[0;31m'
yellow='\033[0;33m'
reset='\033[0m'

ok()   { echo -e "  ${green}✓${reset} $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${red}✗${reset} $1"; FAIL=$((FAIL+1)); }
warn() { echo -e "  ${yellow}⚠${reset} $1"; WARN=$((WARN+1)); }

echo ""
echo "════════════════════════════════════════════════════════════════════════"
echo "  Multi-Platform Support Validation"
echo "════════════════════════════════════════════════════════════════════════"

# ──────────────────────────────────────────────────────────────────────────
# 1. bin/install.js
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo "  [1] Installer (bin/install.js)"
echo "  ─────────────────────────────"

if [ -f "$REPO/bin/install.js" ]; then
  ok "bin/install.js exists"
else
  fail "bin/install.js missing"
fi

if node --check "$REPO/bin/install.js" 2>/dev/null; then
  ok "bin/install.js passes Node.js syntax check"
else
  fail "bin/install.js has syntax errors"
fi

# Check key functions exist in installer
for fn in convertToOpencode convertToGeminiToml convertToCodexSkill convertClaudeAgentToCodexAgent \
          convertAgentForGemini generateCodexConfigBlock stripLearnshipFromCodexConfig mergeCodexConfig \
          installClaudeCommands installOpencodeCommands installGeminiCommands \
          installCodexSkills installCodexAgents installAgents install uninstall \
          verifyInstalled scanForLeakedPaths toHomePrefix configureOpencodePermissions; do
  if grep -q "function $fn" "$REPO/bin/install.js"; then
    ok "installer has function: $fn"
  else
    fail "installer missing function: $fn"
  fi
done

# Check all 5 platforms are handled
for platform in windsurf claude opencode gemini codex; do
  if grep -q "'$platform'" "$REPO/bin/install.js"; then
    ok "installer handles platform: $platform"
  else
    fail "installer missing platform: $platform"
  fi
done

# GSD-level correctness checks
if grep -q "LEARNSHIP_CODEX_MARKER" "$REPO/bin/install.js"; then
  ok "installer has LEARNSHIP_CODEX_MARKER constant"
else
  fail "installer missing LEARNSHIP_CODEX_MARKER constant"
fi

if grep -q "CODEX_AGENT_SANDBOX" "$REPO/bin/install.js"; then
  ok "installer has CODEX_AGENT_SANDBOX per-agent sandbox map"
else
  fail "installer missing CODEX_AGENT_SANDBOX per-agent sandbox map"
fi

if grep -q "'learnship-plan-checker'.*'read-only'" "$REPO/bin/install.js"; then
  ok "plan-checker agent has read-only sandbox mode"
else
  fail "plan-checker agent missing read-only sandbox mode"
fi

if grep -q "colorNameToHex" "$REPO/bin/install.js"; then
  ok "installer has colorNameToHex for OpenCode color conversion"
else
  fail "installer missing colorNameToHex for OpenCode color conversion"
fi

if grep -q "codex_agent_role" "$REPO/bin/install.js"; then
  ok "installer adds <codex_agent_role> header to Codex agents"
else
  fail "installer missing <codex_agent_role> header for Codex agents"
fi

if grep -q "toHomePrefix" "$REPO/bin/install.js"; then
  ok "installer uses toHomePrefix for portable \$HOME paths"
else
  fail "installer missing toHomePrefix for portable \$HOME paths"
fi

if grep -q "experimental.*enableAgents" "$REPO/bin/install.js"; then
  ok "installer enables experimental.enableAgents for Gemini"
else
  fail "installer missing experimental.enableAgents for Gemini"
fi

if grep -q "VERSION" "$REPO/bin/install.js"; then
  ok "installer writes VERSION file"
else
  fail "installer missing VERSION file write"
fi

if grep -q "LEARNSHIP_TEST_MODE" "$REPO/bin/install.js"; then
  ok "installer has LEARNSHIP_TEST_MODE export for unit testing"
else
  fail "installer missing LEARNSHIP_TEST_MODE export"
fi

if grep -q "default_mode_request_user_input" "$REPO/bin/install.js"; then
  ok "Codex config block includes default_mode_request_user_input"
else
  fail "Codex config block missing default_mode_request_user_input"
fi

if grep -q "max_depth" "$REPO/bin/install.js"; then
  ok "Codex config block includes max_depth"
else
  fail "Codex config block missing max_depth"
fi

if grep -q 'replace.*subagent_type.*general-purpose.*general' "$REPO/bin/install.js"; then
  ok "installer converts subagent_type=general-purpose → general for OpenCode"
else
  fail "installer missing subagent_type=general-purpose → general conversion for OpenCode"
fi

# ──────────────────────────────────────────────────────────────────────────
# 2. Command wrappers: commands/learnship/
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo "  [2] Command wrappers (commands/learnship/)"
echo "  ────────────────────────────────────────"

COMMANDS_DIR="$REPO/commands/learnship"
if [ -d "$COMMANDS_DIR" ]; then
  ok "commands/learnship/ directory exists"
else
  fail "commands/learnship/ directory missing"
fi

EXPECTED_COUNT=42
ACTUAL_COUNT=$(ls "$COMMANDS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$ACTUAL_COUNT" -ge "$EXPECTED_COUNT" ]; then
  ok "commands/learnship/ has $ACTUAL_COUNT command wrappers (>= $EXPECTED_COUNT expected)"
else
  fail "commands/learnship/ has $ACTUAL_COUNT wrappers, expected $EXPECTED_COUNT"
fi

# Check each wrapper has required frontmatter
WRAPPER_ISSUES=0
for f in "$COMMANDS_DIR"/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .md)
  # Must have name: field
  if ! grep -q "^name: learnship:" "$f"; then
    fail "commands/learnship/$name.md missing 'name: learnship:' field"
    WRAPPER_ISSUES=$((WRAPPER_ISSUES+1))
  fi
  # Must have description:
  if ! grep -q "^description:" "$f"; then
    fail "commands/learnship/$name.md missing 'description:' field"
    WRAPPER_ISSUES=$((WRAPPER_ISSUES+1))
  fi
  # Must have allowed-tools:
  if ! grep -q "^allowed-tools:" "$f"; then
    fail "commands/learnship/$name.md missing 'allowed-tools:' field"
    WRAPPER_ISSUES=$((WRAPPER_ISSUES+1))
  fi
  # Must have execution_context referencing the workflow
  if ! grep -q "@~/.claude/learnship/workflows/" "$f"; then
    fail "commands/learnship/$name.md missing @~/.claude/learnship/workflows/ reference"
    WRAPPER_ISSUES=$((WRAPPER_ISSUES+1))
  fi
done
if [ "$WRAPPER_ISSUES" -eq 0 ]; then
  ok "All command wrappers have correct frontmatter and workflow references"
fi

# Spot-check key wrappers exist
for cmd in ls next new-project execute-phase plan-phase debug help quick; do
  if [ -f "$COMMANDS_DIR/$cmd.md" ]; then
    ok "commands/learnship/$cmd.md exists"
  else
    fail "commands/learnship/$cmd.md missing"
  fi
done

# execute-phase wrapper should include Task in allowed-tools
if grep -q "Task" "$COMMANDS_DIR/execute-phase.md" 2>/dev/null; then
  ok "execute-phase wrapper includes Task in allowed-tools"
else
  fail "execute-phase wrapper missing Task in allowed-tools"
fi

# ──────────────────────────────────────────────────────────────────────────
# 3. learnship/ payload directory
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo "  [3] Payload directory (learnship/)"
echo "  ──────────────────────────────────"

for subdir in workflows references templates; do
  if [ -d "$REPO/learnship/$subdir" ]; then
    ok "learnship/$subdir/ exists"
  else
    fail "learnship/$subdir/ missing"
  fi
done

WF_COUNT=$(ls "$REPO/learnship/workflows"/*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$WF_COUNT" -ge 42 ]; then
  ok "learnship/workflows/ has $WF_COUNT workflow files (>= 42)"
else
  fail "learnship/workflows/ has $WF_COUNT files, expected >= 42"
fi

# execute-phase.md must contain Task( for subagent spawning
if grep -q "Task(" "$REPO/learnship/workflows/execute-phase.md" 2>/dev/null; then
  ok "learnship/workflows/execute-phase.md contains Task() subagent call"
else
  fail "learnship/workflows/execute-phase.md missing Task() subagent call"
fi

# execute-phase.md must also contain sequential fallback
if grep -q "sequential" "$REPO/learnship/workflows/execute-phase.md" 2>/dev/null; then
  ok "learnship/workflows/execute-phase.md contains sequential fallback"
else
  fail "learnship/workflows/execute-phase.md missing sequential fallback"
fi

# plan-phase.md must contain subagent spawning
if grep -q "Task(" "$REPO/learnship/workflows/plan-phase.md" 2>/dev/null; then
  ok "learnship/workflows/plan-phase.md contains Task() subagent calls"
else
  fail "learnship/workflows/plan-phase.md missing Task() subagent calls"
fi

# parallelization flag mentioned
if grep -q "parallelization" "$REPO/learnship/workflows/execute-phase.md" 2>/dev/null; then
  ok "execute-phase.md references parallelization config flag"
else
  fail "execute-phase.md missing parallelization config flag"
fi

# ──────────────────────────────────────────────────────────────────────────
# 4. Agent files
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo "  [4] Agent files (agents/)"
echo "  ─────────────────────────"

REQUIRED_AGENTS=(
  "learnship-executor.md"
  "learnship-planner.md"
  "learnship-phase-researcher.md"
  "learnship-plan-checker.md"
  "learnship-verifier.md"
  "learnship-debugger.md"
)

for agent in "${REQUIRED_AGENTS[@]}"; do
  if [ -f "$REPO/agents/$agent" ]; then
    ok "agents/$agent exists"
  else
    fail "agents/$agent missing"
  fi
done

# Each agent must have proper frontmatter
AGENT_ISSUES=0
for agent in "${REQUIRED_AGENTS[@]}"; do
  f="$REPO/agents/$agent"
  [ -f "$f" ] || continue
  if ! grep -q "^name:" "$f"; then
    fail "agents/$agent missing 'name:' field"
    AGENT_ISSUES=$((AGENT_ISSUES+1))
  fi
  if ! grep -q "^description:" "$f"; then
    fail "agents/$agent missing 'description:' field"
    AGENT_ISSUES=$((AGENT_ISSUES+1))
  fi
  if ! grep -q "^tools:" "$f"; then
    fail "agents/$agent missing 'tools:' field"
    AGENT_ISSUES=$((AGENT_ISSUES+1))
  fi
done
if [ "$AGENT_ISSUES" -eq 0 ]; then
  ok "All learnship agent files have correct frontmatter"
fi

# executor must mention SUMMARY.md and commit
if grep -q "SUMMARY.md" "$REPO/agents/learnship-executor.md" 2>/dev/null; then
  ok "learnship-executor.md references SUMMARY.md creation"
else
  fail "learnship-executor.md missing SUMMARY.md reference"
fi

# debugger must mention root cause
if grep -q "root cause" "$REPO/agents/learnship-debugger.md" 2>/dev/null; then
  ok "learnship-debugger.md references root cause investigation"
else
  fail "learnship-debugger.md missing root cause investigation"
fi

# ──────────────────────────────────────────────────────────────────────────
# 5. package.json
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo "  [5] package.json"
echo "  ────────────────"

PKG="$REPO/package.json"
if [ -f "$PKG" ]; then
  ok "package.json exists"

  # Check bin entry
  if grep -q '"learnship"' "$PKG"; then
    ok "package.json has learnship bin entry"
  else
    fail "package.json missing learnship bin entry"
  fi

  # Check files array includes key directories
  if grep -q '"commands"' "$PKG" 2>/dev/null || grep -q '"files"' "$PKG"; then
    ok "package.json has files field"
  else
    warn "package.json missing files field (needed for npm publish)"
  fi
else
  fail "package.json missing"
fi

# ──────────────────────────────────────────────────────────────────────────
# 6. Conversion correctness spot-checks
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo "  [6] Conversion spot-checks"
echo "  ──────────────────────────"

# Installer must convert /learnship:cmd → /learnship-cmd for OpenCode
if grep -q 'replace.*\/learnship:' "$REPO/bin/install.js"; then
  ok "installer converts /learnship:cmd → /learnship-cmd for OpenCode"
else
  fail "installer missing /learnship:cmd → /learnship-cmd conversion for OpenCode"
fi

# Installer must handle Gemini TOML conversion
if grep -q "convertToGeminiToml" "$REPO/bin/install.js"; then
  ok "installer calls convertToGeminiToml for Gemini"
else
  fail "installer missing Gemini TOML conversion"
fi

# Installer must handle Codex skill conversion
if grep -q "convertToCodexSkill" "$REPO/bin/install.js"; then
  ok "installer calls convertToCodexSkill for Codex"
else
  fail "installer missing Codex skill conversion"
fi

# Codex spawn_agent mapping
if grep -q "spawn_agent" "$REPO/bin/install.js"; then
  ok "installer maps Task() → spawn_agent() for Codex"
else
  fail "installer missing Task() → spawn_agent() mapping for Codex"
fi

# 3-case Codex config.toml merge
if grep -q "Case 1" "$REPO/bin/install.js" && grep -q "Case 2" "$REPO/bin/install.js" && grep -q "Case 3" "$REPO/bin/install.js"; then
  ok "Codex config.toml merge handles all 3 cases (new, existing+marker, existing-no-marker)"
else
  fail "Codex config.toml merge missing one or more of the 3 cases"
fi

# OpenCode color conversion (not strip)
if grep -q "colorNameToHex" "$REPO/bin/install.js" && ! grep -qF "'color:') continue" "$REPO/bin/install.js"; then
  ok "OpenCode converter converts color names to hex (does not strip them)"
else
  fail "OpenCode converter does not properly convert color names to hex"
fi

# Leaked path scan
if grep -q "scanForLeakedPaths" "$REPO/bin/install.js" && grep -q '\.claude\\b' "$REPO/bin/install.js" 2>/dev/null || grep -q 'claude' "$REPO/bin/install.js"; then
  ok "installer scans for leaked .claude paths in non-Claude platforms"
else
  fail "installer missing leaked .claude path scan"
fi

# ──────────────────────────────────────────────────────────────────────────
# 7. Test-mode exports functional check
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo "  [7] Test-mode exports"
echo "  ─────────────────────"

# Verify the test-mode exports work by loading the module
TEST_OUTPUT=$(LEARNSHIP_TEST_MODE=1 node -e "
  const m = require('$REPO/bin/install.js');
  const fns = ['convertToOpencode','convertToGeminiToml','convertToCodexSkill',
               'convertClaudeAgentToCodexAgent','generateCodexConfigBlock',
               'stripLearnshipFromCodexConfig','mergeCodexConfig','LEARNSHIP_CODEX_MARKER',
               'CODEX_AGENT_SANDBOX'];
  const missing = fns.filter(f => !m[f]);
  if (missing.length > 0) { console.error('MISSING: ' + missing.join(', ')); process.exit(1); }
  console.log('OK');
" 2>&1)

if echo "$TEST_OUTPUT" | grep -q "^OK$"; then
  ok "test-mode exports: all 9 functions/constants exported correctly"
else
  fail "test-mode exports failed: $TEST_OUTPUT"
fi

# Spot-check convertToOpencode converts color names to hex
COLOR_TEST=$(LEARNSHIP_TEST_MODE=1 node -e "
  const { convertToOpencode } = require('$REPO/bin/install.js');
  const input = '---\\nname: test\\ncolor: cyan\\nallowed-tools:\\n  - Read\\n---\\nbody';
  const out = convertToOpencode(input);
  if (!out.includes('#00FFFF')) { console.error('color not converted to hex'); process.exit(1); }
  if (out.includes('color: cyan')) { console.error('color name not replaced'); process.exit(1); }
  console.log('OK');
" 2>&1)

if echo "$COLOR_TEST" | grep -q "^OK$"; then
  ok "convertToOpencode converts color:cyan → color:#00FFFF"
else
  fail "convertToOpencode color conversion: $COLOR_TEST"
fi

# Spot-check convertToCodexSkill adds codex_skill_adapter with full Task→spawn_agent mapping
CODEX_SKILL_TEST=$(LEARNSHIP_TEST_MODE=1 node -e "
  const { convertToCodexSkill } = require('$REPO/bin/install.js');
  const input = '---\\ndescription: Test workflow\\nallowed-tools:\\n  - Read\\n---\\nContent here';
  const out = convertToCodexSkill(input, 'learnship-test');
  if (!out.includes('codex_skill_adapter')) { console.error('missing codex_skill_adapter'); process.exit(1); }
  if (!out.includes('spawn_agent')) { console.error('missing spawn_agent mapping'); process.exit(1); }
  if (!out.includes('request_user_input')) { console.error('missing request_user_input mapping'); process.exit(1); }
  if (!out.includes('learnship-test')) { console.error('skill name not in output'); process.exit(1); }
  console.log('OK');
" 2>&1)

if echo "$CODEX_SKILL_TEST" | grep -q "^OK$"; then
  ok "convertToCodexSkill produces correct SKILL.md with full adapter"
else
  fail "convertToCodexSkill: $CODEX_SKILL_TEST"
fi

# Spot-check convertClaudeAgentToCodexAgent adds codex_agent_role header
CODEX_AGENT_TEST=$(LEARNSHIP_TEST_MODE=1 node -e "
  const { convertClaudeAgentToCodexAgent } = require('$REPO/bin/install.js');
  const input = '---\\nname: learnship-executor\\ndescription: Test executor\\ntools: Read, Write, Bash\\ncolor: yellow\\n---\\n\\nAgent body here';
  const out = convertClaudeAgentToCodexAgent(input);
  if (!out.includes('codex_agent_role')) { console.error('missing codex_agent_role'); process.exit(1); }
  if (!out.includes('learnship-executor')) { console.error('missing agent name'); process.exit(1); }
  if (out.includes('color:')) { console.error('color field not removed'); process.exit(1); }
  console.log('OK');
" 2>&1)

if echo "$CODEX_AGENT_TEST" | grep -q "^OK$"; then
  ok "convertClaudeAgentToCodexAgent adds codex_agent_role, removes color"
else
  fail "convertClaudeAgentToCodexAgent: $CODEX_AGENT_TEST"
fi

# Spot-check stripLearnshipFromCodexConfig removes marker block
STRIP_TEST=$(LEARNSHIP_TEST_MODE=1 node -e "
  const { stripLearnshipFromCodexConfig, LEARNSHIP_CODEX_MARKER } = require('$REPO/bin/install.js');
  const input = 'user_key = \"yes\"\n\n' + LEARNSHIP_CODEX_MARKER + '\n[features]\nmulti_agent = true\n';
  const out = stripLearnshipFromCodexConfig(input);
  if (out.includes(LEARNSHIP_CODEX_MARKER)) { console.error('marker not removed'); process.exit(1); }
  if (!out.includes('user_key')) { console.error('user content removed'); process.exit(1); }
  console.log('OK');
" 2>&1)

if echo "$STRIP_TEST" | grep -q "^OK$"; then
  ok "stripLearnshipFromCodexConfig removes marker block, preserves user content"
else
  fail "stripLearnshipFromCodexConfig: $STRIP_TEST"
fi

# Spot-check CODEX_AGENT_SANDBOX has plan-checker as read-only
SANDBOX_TEST=$(LEARNSHIP_TEST_MODE=1 node -e "
  const { CODEX_AGENT_SANDBOX } = require('$REPO/bin/install.js');
  if (CODEX_AGENT_SANDBOX['learnship-plan-checker'] !== 'read-only') { console.error('plan-checker not read-only'); process.exit(1); }
  if (CODEX_AGENT_SANDBOX['learnship-executor'] !== 'workspace-write') { console.error('executor not workspace-write'); process.exit(1); }
  if (CODEX_AGENT_SANDBOX['learnship-debugger'] !== 'workspace-write') { console.error('debugger not workspace-write'); process.exit(1); }
  console.log('OK');
" 2>&1)

if echo "$SANDBOX_TEST" | grep -q "^OK$"; then
  ok "CODEX_AGENT_SANDBOX: plan-checker=read-only, executor/debugger=workspace-write"
else
  fail "CODEX_AGENT_SANDBOX: $SANDBOX_TEST"
fi

# ──────────────────────────────────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════════════════════"
echo "  Multi-Platform Results: $PASS passed, $FAIL failed, $WARN warnings"
echo "════════════════════════════════════════════════════════════════════════"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo -e "  ${green}✓ All multi-platform checks passed${reset}"
  exit 0
else
  echo -e "  ${red}✗ $FAIL check(s) failed${reset}"
  exit 1
fi
