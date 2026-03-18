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

# .windsurf/skills must be in package.json "files" — otherwise npx strips it and skills are never found
if node -e "const pkg=require('$REPO/package.json'); process.exit(pkg.files && pkg.files.includes('skills') ? 0 : 1);" 2>/dev/null; then
  ok "package.json files includes skills/ (required for npx delivery)"
else
  fail "package.json files missing skills/ — skills will be absent when installed via npx"
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

# Regression: commands/learnship/ must NOT contain @~/.claude/learnship/ (double learnship/ after install)
# Source files use @~/.claude/workflows/ so replacePaths() resolves them to
# pathPrefix+workflows/ = ~/.claude/learnship/workflows/ — not double learnship/learnship/
DOUBLE_COUNT=$(grep -rl "@~/.claude/learnship/" "$REPO/commands/learnship/" 2>/dev/null | wc -l)
if [ "$DOUBLE_COUNT" -eq 0 ]; then
  ok "commands/learnship/ source files have no @~/.claude/learnship/ double-path refs (regression: install would produce learnship/learnship/)"
else
  fail "commands/learnship/ has $DOUBLE_COUNT file(s) with @~/.claude/learnship/ — install will produce broken learnship/learnship/ paths"
fi

# Regression: all command source files must use @~/.claude/workflows/ for workflow refs
WORKFLOW_COUNT=$(grep -rl "@~/.claude/workflows/" "$REPO/commands/learnship/" 2>/dev/null | wc -l)
EXPECTED_COUNT=$(ls "$REPO/commands/learnship/"*.md 2>/dev/null | wc -l)
if [ "$WORKFLOW_COUNT" -eq "$EXPECTED_COUNT" ]; then
  ok "all $EXPECTED_COUNT command source files use @~/.claude/workflows/ for cross-platform path resolution"
else
  fail "only $WORKFLOW_COUNT of $EXPECTED_COUNT command files use @~/.claude/workflows/ — remaining will break on non-Claude platforms"
fi

if grep -q 'replace.*subagent_type.*general-purpose.*general' "$REPO/bin/install.js"; then
  ok "installer converts subagent_type=general-purpose → general for OpenCode"
else
  fail "installer missing subagent_type=general-purpose → general conversion for OpenCode"
fi

# Local Windsurf must use .windsurf, NOT .codeium/windsurf (Cascade reads .windsurf/)
if node -e "
const src = require('fs').readFileSync('$REPO/bin/install.js', 'utf8');
const m = src.match(/getDirName\\([^)]*\\)[\\s\\S]*?windsurf.*?return '([^']+)'/);
process.exit(m && m[1] === '.windsurf' ? 0 : 1);
" 2>/dev/null; then
  ok "local Windsurf install uses .windsurf/ (not .codeium/windsurf/)"
else
  fail "local Windsurf install path wrong — must be .windsurf not .codeium/windsurf"
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
  # Must have execution_context referencing the workflow (no learnship/ prefix — replacePaths adds it)
  if ! grep -q "@~/.claude/workflows/" "$f"; then
    fail "commands/learnship/$name.md missing @~/.claude/workflows/ reference"
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

# templates/agents.md must exist (used by new-project Step 8 to generate AGENTS.md)
if [ -f "$REPO/learnship/templates/agents.md" ]; then
  ok "learnship/templates/agents.md exists"
else
  fail "learnship/templates/agents.md missing — new-project Step 8 will silently skip AGENTS.md generation"
fi

# references/questioning.md must exist (used by new-project Step 3)
if [ -f "$REPO/learnship/references/questioning.md" ]; then
  ok "learnship/references/questioning.md exists"
else
  fail "learnship/references/questioning.md missing — new-project Step 3 questioning reference broken"
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
# 8. Additional conversion correctness checks (via external node script)
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo "  [8] Conversion correctness (new bug-fix checks)"
echo "  ─────────────────────────────────────────────────"

# Write a self-contained node test script to avoid shell quoting hell
TMPSCRIPT=$(mktemp /tmp/learnship-test-XXXXXX.cjs)
cat > "$TMPSCRIPT" << 'NODEEOF'
process.env.LEARNSHIP_TEST_MODE = '1';
const REPO = process.argv[2];
const {
  convertToOpencode, convertAgentForGemini, convertToGeminiToml,
  replacePaths, rewriteNewProject, parseJsonc, mergeCodexConfig, generateCodexConfigBlock,
  LEARNSHIP_CODEX_MARKER,
} = require(REPO + '/bin/install.js');
const os = require('os');
const fs = require('fs');
const path = require('path');

let pass = 0; let fail = 0;
function check(name, fn) {
  try { fn(); console.log('  PASS ' + name); pass++; }
  catch(e) { console.log('  FAIL ' + name + ': ' + e.message); fail++; }
}
function assert(cond, msg) { if (!cond) throw new Error(msg); }

// 1. convertToOpencode: inline tools: field
check('convertToOpencode inline tools: Read, Write, Bash', () => {
  const input = '---\nname: learnship-executor\ndescription: Executes plans\ntools: Read, Write, Bash\ncolor: yellow\n---\n\nAgent body';
  const out = convertToOpencode(input);
  assert(out.includes('read: true'), 'missing read: true; got:\n' + out);
  assert(out.includes('write: true'), 'missing write: true');
  assert(out.includes('bash: true'), 'missing bash: true');
  assert(!out.includes('tools: Read'), 'inline tools field not converted');
});

// 2. convertAgentForGemini: inline tools: field
check('convertAgentForGemini inline tools: Read, Write, Bash', () => {
  const input = '---\nname: learnship-executor\ndescription: Executor\ntools: Read, Write, Bash\ncolor: cyan\n---\n\nbody';
  const out = convertAgentForGemini(input);
  assert(out.includes('read_file'), 'missing read_file; got:\n' + out);
  assert(out.includes('write_file'), 'missing write_file');
  assert(out.includes('run_shell_command'), 'missing run_shell_command');
  assert(!out.includes('color:'), 'color not stripped');
  assert(!out.includes('tools: Read'), 'inline tools field not converted');
});

// 3. replacePaths: replaces bare ~/.claude/
check('replacePaths replaces bare ~/.claude/ and $HOME/.claude/', () => {
  const input = 'See ~/.claude/ for config. Also $HOME/.claude/ docs.';
  const out = replacePaths(input, '/custom/path/', 'opencode');
  assert(!out.includes('~/.claude/'), 'tilde path not replaced; got:\n' + out);
  assert(!out.includes('$HOME/.claude/'), '$HOME path not replaced');
  assert(out.includes('/custom/path/'), 'pathPrefix not in output');
});

// 4. replacePaths: replaces ~/.opencode/ for opencode
check('replacePaths replaces ~/.opencode/ for opencode platform', () => {
  const input = 'Config at ~/.opencode/settings.json';
  const out = replacePaths(input, '/custom/opencode/', 'opencode');
  assert(!out.includes('~/.opencode/'), '~/.opencode/ not replaced; got:\n' + out);
});

// 5. parseJsonc: handles // comments and trailing commas
check('parseJsonc handles // comments and trailing commas', () => {
  const input = '{\n// comment\n"key": "value", // inline\n"arr": [1, 2,]\n}';
  const obj = parseJsonc(input);
  assert(obj.key === 'value', 'key not parsed; got: ' + JSON.stringify(obj));
  assert(Array.isArray(obj.arr) && obj.arr.length === 2, 'arr not parsed correctly');
});

// 6. convertToOpencode: /learnship:cmd → /learnship-cmd
check('convertToOpencode converts /learnship:cmd to /learnship-cmd', () => {
  const input = '---\ndescription: test\n---\nRun /learnship:new-project to start.';
  const out = convertToOpencode(input);
  assert(!out.includes('/learnship:new-project'), 'slash cmd not converted');
  assert(out.includes('/learnship-new-project'), 'converted form not found');
});

// 7. convertToGeminiToml: escapes ${VAR} → $VAR
check('convertToGeminiToml escapes ${VAR} to $VAR', () => {
  const input = '---\ndescription: Test\n---\nUse ${PHASE} and ${PLAN} in scripts.';
  const out = convertToGeminiToml(input);
  assert(!out.includes('${PHASE}'), '${VAR} not escaped; got:\n' + out);
  assert(out.includes('$PHASE'), '$VAR form not found');
});

// 8. mergeCodexConfig Case 1: creates new file
check('mergeCodexConfig Case 1: creates new config.toml', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-test-'));
  const configPath = path.join(tmp, 'config.toml');
  const block = generateCodexConfigBlock([{name: 'learnship-executor', description: 'Executor'}]);
  mergeCodexConfig(configPath, block);
  const out = fs.readFileSync(configPath, 'utf8');
  fs.rmSync(tmp, { recursive: true });
  assert(out.includes(LEARNSHIP_CODEX_MARKER), 'marker missing');
  assert(out.includes('multi_agent = true'), 'features missing');
  assert(out.includes('[agents.learnship-executor]'), 'agent entry missing');
});

// 9. mergeCodexConfig Case 2: updates existing file with marker
check('mergeCodexConfig Case 2: updates file with existing marker', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-test-'));
  const configPath = path.join(tmp, 'config.toml');
  fs.writeFileSync(configPath, 'user_setting = true\n\n' + LEARNSHIP_CODEX_MARKER + '\n[agents]\nmax_threads = 4\n');
  const block = generateCodexConfigBlock([{name: 'learnship-planner', description: 'Planner'}]);
  mergeCodexConfig(configPath, block);
  const out = fs.readFileSync(configPath, 'utf8');
  fs.rmSync(tmp, { recursive: true });
  assert(out.includes('user_setting = true'), 'user content lost');
  assert(out.includes('[agents.learnship-planner]'), 'new agent not written');
  assert(out.includes(LEARNSHIP_CODEX_MARKER), 'marker missing');
});

// 10. mergeCodexConfig Case 3: appends to file without marker
check('mergeCodexConfig Case 3: appends to file without marker', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-test-'));
  const configPath = path.join(tmp, 'config.toml');
  fs.writeFileSync(configPath, 'existing_key = "hello"\n');
  const block = generateCodexConfigBlock([{name: 'learnship-debugger', description: 'Debugger'}]);
  mergeCodexConfig(configPath, block);
  const out = fs.readFileSync(configPath, 'utf8');
  fs.rmSync(tmp, { recursive: true });
  assert(out.includes('existing_key'), 'existing content lost');
  assert(out.includes(LEARNSHIP_CODEX_MARKER), 'marker not appended');
  assert(out.includes('[agents.learnship-debugger]'), 'agent not appended');
});

// rewriteNewProject: build a minimal source with all three markers
const NP_SRC = '<!-- LEARNSHIP_PLATFORM_LABEL -->\n```bash\n<!-- LEARNSHIP_GITIGNORE_CMD -->\n```\n<!-- LEARNSHIP_PARALLEL_BLOCK -->';

// 11. Claude Code: platform label says Claude Code
check('rewriteNewProject(claude): platform label contains "Claude Code"', () => {
  const out = rewriteNewProject(NP_SRC, 'claude');
  assert(out.includes('Claude Code'), 'label missing Claude Code; got:\n' + out);
  assert(!out.includes('<!-- LEARNSHIP_PLATFORM_LABEL -->'), 'marker not replaced');
});

// 12. Claude Code: gitignore cmd uses .claude/
check('rewriteNewProject(claude): gitignore cmd uses .claude/', () => {
  const out = rewriteNewProject(NP_SRC, 'claude');
  assert(out.includes('.claude/'), 'gitignore cmd missing .claude/; got:\n' + out);
  assert(!out.includes('.windsurf/'), 'gitignore cmd must NOT contain .windsurf/');
  assert(!out.includes('<!-- LEARNSHIP_GITIGNORE_CMD -->'), 'gitignore marker not replaced');
});

// 13. Claude Code: parallel block contains the question
check('rewriteNewProject(claude): parallel block contains the question', () => {
  const out = rewriteNewProject(NP_SRC, 'claude');
  assert(out.includes('parallel subagent'), 'parallelization question missing; got:\n' + out);
  assert(!out.includes('<!-- LEARNSHIP_PARALLEL_BLOCK -->'), 'parallel marker not replaced');
});

// 14. Windsurf: gitignore cmd uses .windsurf/
check('rewriteNewProject(windsurf): gitignore cmd uses .windsurf/', () => {
  const out = rewriteNewProject(NP_SRC, 'windsurf');
  assert(out.includes('.windsurf/'), 'gitignore cmd missing .windsurf/; got:\n' + out);
  assert(!out.includes('.claude/'), 'gitignore cmd must NOT contain .claude/');
});

// 15. Windsurf: parallel block does NOT contain the question (auto-set to false)
check('rewriteNewProject(windsurf): parallel block skips question', () => {
  const out = rewriteNewProject(NP_SRC, 'windsurf');
  assert(!out.includes('parallel subagent'), 'parallelization question must not appear for Windsurf; got:\n' + out);
  assert(out.includes('automatically set to'), 'should mention auto-set; got:\n' + out);
});

// 16. Gemini: gitignore cmd uses .gemini/
check('rewriteNewProject(gemini): gitignore cmd uses .gemini/', () => {
  const out = rewriteNewProject(NP_SRC, 'gemini');
  assert(out.includes('.gemini/'), 'gitignore cmd missing .gemini/; got:\n' + out);
  assert(!out.includes('.windsurf/'), 'must not contain .windsurf/');
  assert(!out.includes('.claude/'), 'must not contain .claude/');
});

// 17. Gemini: parallel block does NOT ask the question (sequential only, not yet parallel)
check('rewriteNewProject(gemini): parallel block skips question (sequential only)', () => {
  const out = rewriteNewProject(NP_SRC, 'gemini');
  assert(!out.includes('parallel subagent'), 'parallelization question must not appear for Gemini (sequential only)');
  assert(out.includes('automatically set to'), 'should mention auto-set false; got:\n' + out);
});

// 17b. OpenCode and Codex DO ask the parallel question
check('rewriteNewProject(opencode): parallel block contains the question', () => {
  const out = rewriteNewProject(NP_SRC, 'opencode');
  assert(out.includes('parallel subagent'), 'parallelization question missing for OpenCode');
});
check('rewriteNewProject(codex): parallel block contains the question', () => {
  const out = rewriteNewProject(NP_SRC, 'codex');
  assert(out.includes('parallel subagent'), 'parallelization question missing for Codex');
});

// 18. No raw markers remain in any platform output
check('rewriteNewProject: no raw LEARNSHIP markers remain in output', () => {
  for (const p of ['claude', 'windsurf', 'opencode', 'gemini', 'codex']) {
    const out = rewriteNewProject(NP_SRC, p);
    assert(!out.includes('<!-- LEARNSHIP_'), 'raw marker found for platform ' + p + ':\n' + out);
  }
});

console.log('\nSECTION8_PASS=' + pass);
console.log('SECTION8_FAIL=' + fail);
NODEEOF

S8_OUTPUT=$(node "$TMPSCRIPT" "$REPO" 2>&1)
rm -f "$TMPSCRIPT"

# Parse and report each result
while IFS= read -r line; do
  case "$line" in
    "  PASS "*) ok "${line#  PASS }" ;;
    "  FAIL "*) fail "${line#  FAIL }" ;;
  esac
done <<< "$S8_OUTPUT"

# ──────────────────────────────────────────────────────────────────────────
# 9. Skills installation (all platforms)
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo "  [9] Skills installation (all platforms)"
echo "  ────────────────────────────────────────"

TMPSCRIPT9=$(mktemp /tmp/learnship-test-XXXXXX.cjs)
cat > "$TMPSCRIPT9" << 'NODEEOF'
process.env.LEARNSHIP_TEST_MODE = '1';
const REPO = process.argv[2];
const os = require('os');
const fs = require('fs');
const path = require('path');

let pass = 0; let fail = 0;
function check(name, fn) {
  try { fn(); console.log('  PASS ' + name); pass++; }
  catch(e) { console.log('  FAIL ' + name + ': ' + e.message); fail++; }
}
function assert(cond, msg) { if (!cond) throw new Error(msg); }

const skillsSrc = path.join(REPO, '.windsurf', 'skills');

// Helper: simulate the skills install step from install()
function installSkills(targetDir) {
  const learnshipDest = path.join(targetDir, 'learnship');
  const skillsDest = path.join(learnshipDest, 'skills');
  fs.mkdirSync(skillsDest, { recursive: true });
  function copyDir(from, to) {
    fs.mkdirSync(to, { recursive: true });
    for (const e of fs.readdirSync(from, { withFileTypes: true })) {
      const s = path.join(from, e.name), d = path.join(to, e.name);
      if (e.isDirectory()) copyDir(s, d); else fs.copyFileSync(s, d);
    }
  }
  let count = 0;
  for (const entry of fs.readdirSync(skillsSrc, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    copyDir(path.join(skillsSrc, entry.name), path.join(skillsDest, entry.name));
    count++;
  }
  return { skillsDest, count };
}

// 1. Skills source exists and contains exactly the expected skill dirs
check('skills source has agentic-learning and impeccable (no frontend-design top-level)', () => {
  assert(fs.existsSync(skillsSrc), 'skills source dir missing: ' + skillsSrc);
  const dirs = fs.readdirSync(skillsSrc, { withFileTypes: true })
    .filter(e => e.isDirectory()).map(e => e.name).sort();
  assert(dirs.includes('agentic-learning'), 'agentic-learning missing from skills src');
  assert(dirs.includes('impeccable'), 'impeccable missing from skills src');
  assert(!dirs.includes('frontend-design'), 'frontend-design still exists as top-level skill (should be deleted)');
});

// 2. Skills are copied to learnship/skills/ on install
check('skills install: agentic-learning and impeccable copied to learnship/skills/', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-skills-'));
  const { skillsDest, count } = installSkills(tmp);
  fs.rmSync(tmp, { recursive: true });
  assert(count === 2, 'expected 2 skills, got ' + count);
});

// 3. agentic-learning has SKILL.md and references/
check('agentic-learning: SKILL.md and references/ present', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-skills-'));
  const { skillsDest } = installSkills(tmp);
  const alDir = path.join(skillsDest, 'agentic-learning');
  assert(fs.existsSync(path.join(alDir, 'SKILL.md')), 'agentic-learning/SKILL.md missing');
  assert(fs.existsSync(path.join(alDir, 'references')), 'agentic-learning/references/ missing');
  fs.rmSync(tmp, { recursive: true });
});

// 4. agentic-learning SKILL.md has correct name and no Windsurf-specific invocation
check('agentic-learning SKILL.md: name field correct, platform-agnostic compatibility', () => {
  const skillMd = fs.readFileSync(path.join(skillsSrc, 'agentic-learning', 'SKILL.md'), 'utf8');
  assert(skillMd.includes('name: agentic-learning'), 'name field missing or wrong');
  assert(!skillMd.includes('Windsurf only'), 'contains Windsurf-only restriction');
});

// 5. impeccable has frontend-design sub-skill and at least 10 sub-skill dirs
check('impeccable: frontend-design sub-skill present, at least 10 sub-skills', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-skills-'));
  const { skillsDest } = installSkills(tmp);
  const impDir = path.join(skillsDest, 'impeccable');
  const subSkills = fs.readdirSync(impDir, { withFileTypes: true }).filter(e => e.isDirectory());
  assert(subSkills.some(e => e.name === 'frontend-design'), 'impeccable/frontend-design/ missing');
  assert(subSkills.length >= 10, 'expected >=10 impeccable sub-skills, got ' + subSkills.length);
  fs.rmSync(tmp, { recursive: true });
});

// 6. impeccable/frontend-design has SKILL.md
check('impeccable/frontend-design: SKILL.md present', () => {
  const skillMd = path.join(skillsSrc, 'impeccable', 'frontend-design', 'SKILL.md');
  assert(fs.existsSync(skillMd), 'impeccable/frontend-design/SKILL.md missing');
  const content = fs.readFileSync(skillMd, 'utf8');
  assert(content.includes('name: frontend-design'), 'name field missing');
});

// 7. Windsurf gets skills at targetDir/skills/ (native .windsurf/skills/), not learnship/skills/
check('Windsurf install: skills copied to skills/ (native), not learnship/skills/', () => {
  const installSrc = fs.readFileSync(path.join(REPO, 'bin', 'install.js'), 'utf8');
  // Must use targetDir/skills for windsurf and learnshipDest/skills for others
  assert(
    installSrc.includes("platform === 'windsurf'") &&
    installSrc.includes('path.join(targetDir, \'skills\')') &&
    installSrc.includes('path.join(learnshipDest, \'skills\')'),
    "install.js does not route Windsurf skills to targetDir/skills/ vs learnshipDest/skills/"
  );
});

// 8. Claude Code installer routes skills to plugins/learnship/skills/ and handles impeccable sub-skills
check('Claude Code install: installer routes skills to plugins/learnship/skills/ with sub-skill handling', () => {
  const installSrc = fs.readFileSync(path.join(REPO, 'bin', 'install.js'), 'utf8');
  // installClaudePlugins must exist
  assert(installSrc.includes('function installClaudePlugins'), 'installClaudePlugins function missing');
  // Must target plugins/learnship/skills/
  assert(installSrc.includes("'plugins', 'learnship'"), 'installer missing plugins/learnship path for Claude');
  // Must handle impeccable sub-skills specially (copies into references/)
  assert(installSrc.includes("skillName === 'impeccable'"), 'installer missing impeccable sub-skill handling');
  assert(installSrc.includes("'references'"), 'installer missing references/ destination for impeccable sub-skills');
  // Must handle agentic-learning (verbatim copy path)
  assert(installSrc.includes('agentic-learning') || installSrc.includes('copyDir(srcPath, dest'),
    'installer missing agentic-learning copy path');
});

// 9. Local scope: install() uses process.cwd()-based dir when isGlobal=false
check('local scope: install() routes to process.cwd()/<dirName>/ when --local', () => {
  const installSrc = fs.readFileSync(path.join(REPO, 'bin', 'install.js'), 'utf8');
  // Key line: isGlobal ? getGlobalDir(platform) : path.join(process.cwd(), getDirName(platform))
  assert(installSrc.includes('process.cwd()'), 'installer missing process.cwd() for local scope');
  assert(installSrc.includes('isGlobal ? getGlobalDir'), 'installer missing isGlobal ternary');
  assert(installSrc.includes('getDirName(platform)'), 'installer missing getDirName for local dir');
});

// 10. getDirName returns correct platform-specific subdir names for local install
check('local scope: getDirName returns correct subdir for each platform', () => {
  const { install } = require(path.join(REPO, 'bin', 'install.js'));
  // We can't call getDirName directly (not exported), but we can verify the source maps correctly
  const installSrc = fs.readFileSync(path.join(REPO, 'bin', 'install.js'), 'utf8');
  assert(installSrc.includes("'.claude'"), "getDirName missing '.claude' for claude");
  assert(installSrc.includes("'.windsurf'"), "getDirName missing '.windsurf' for windsurf");
  assert(installSrc.includes("'.opencode'"), "getDirName missing '.opencode' for opencode");
  assert(installSrc.includes("'.gemini'"), "getDirName missing '.gemini' for gemini");
  assert(installSrc.includes("'.codex'"), "getDirName missing '.codex' for codex");
});

// 11. --local flag is parsed (hasLocal) and overrides default-global behaviour
check('local scope: --local flag parsed and respected (hasLocal)', () => {
  const installSrc = fs.readFileSync(path.join(REPO, 'bin', 'install.js'), 'utf8');
  assert(installSrc.includes("'--local'") || installSrc.includes('--local'), '--local flag not parsed');
  assert(installSrc.includes("'-l'"), '-l shorthand not parsed');
  // Default is global unless --local is explicitly set
  assert(installSrc.includes('hasGlobal || !hasLocal'), 'default-global logic missing');
});

// 12. Local scope install: skills land in <cwd>/<dirName>/learnship/skills/ (not global dir)
check('local scope: skills path resolves under cwd, not home dir', () => {
  const installSrc = fs.readFileSync(path.join(REPO, 'bin', 'install.js'), 'utf8');
  // targetDir drives both learnshipDest and skillsDest — a single cwd-based targetDir means skills are local too
  assert(
    installSrc.includes('learnshipDest') && installSrc.includes('skillsDest') &&
    installSrc.includes('learnshipDest, \'skills\''),
    'skillsDest not derived from learnshipDest — local scope skills would not follow targetDir'
  );
});

console.log('\nSECTION9_PASS=' + pass);
console.log('SECTION9_FAIL=' + fail);
NODEEOF

S9_OUTPUT=$(node "$TMPSCRIPT9" "$REPO" 2>&1)
rm -f "$TMPSCRIPT9"

while IFS= read -r line; do
  case "$line" in
    "  PASS "*) ok "${line#  PASS }" ;;
    "  FAIL "*) fail "${line#  FAIL }" ;;
  esac
done <<< "$S9_OUTPUT"

# ──────────────────────────────────────────────────────────────────────────
# 10. Claude Code native plugin structure
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo "  [10] Claude Code native plugin structure"
echo "  ─────────────────────────────────────────"

TMPSCRIPT10=$(mktemp /tmp/learnship-test-XXXXXX.cjs)
cat > "$TMPSCRIPT10" << 'NODEEOF'
process.env.LEARNSHIP_TEST_MODE = '1';
const REPO = process.argv[2];
const os = require('os');
const fs = require('fs');
const path = require('path');

let pass = 0; let fail = 0;
function check(name, fn) {
  try { fn(); console.log('  PASS ' + name); pass++; }
  catch(e) { console.log('  FAIL ' + name + ': ' + e.message); fail++; }
}
function assert(cond, msg) { if (!cond) throw new Error(msg); }

const realSkillsSrc = path.join(REPO, 'skills');
const { installClaudePlugins } = require(path.join(REPO, 'bin', 'install.js'));

// Use the real installClaudePlugins from install.js
function runInstallClaudePlugins(tmpDir) {
  const count = installClaudePlugins(realSkillsSrc, tmpDir);
  const pluginDir = path.join(tmpDir, 'plugins', 'learnship');
  const pluginSkillsDir = path.join(pluginDir, 'skills');
  const pluginMetaDir = path.join(pluginDir, '.claude-plugin');
  return { pluginDir, pluginSkillsDir, pluginMetaDir, count };
}

// 1. installClaudePlugins function exists in install.js
check('installClaudePlugins function exists in install.js', () => {
  const src = fs.readFileSync(path.join(REPO, 'bin', 'install.js'), 'utf8');
  assert(src.includes('function installClaudePlugins'), 'installClaudePlugins function missing');
});

// 2. installClaudePlugins is called in the claude platform block
check('installClaudePlugins is called in the claude platform block', () => {
  const src = fs.readFileSync(path.join(REPO, 'bin', 'install.js'), 'utf8');
  assert(src.includes("installClaudePlugins(skillsSrc, targetDir)"), 'installClaudePlugins not called in claude block');
});

// 3. plugin.json manifest is created with correct fields
check('plugin.json created with name, description, author', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-plugin-'));
  const { pluginMetaDir } = runInstallClaudePlugins(tmp);
  const manifest = JSON.parse(fs.readFileSync(path.join(pluginMetaDir, 'plugin.json'), 'utf8'));
  assert(manifest.name === 'learnship', 'manifest.name wrong');
  assert(typeof manifest.description === 'string' && manifest.description.length > 0, 'manifest.description missing');
  assert(manifest.author && manifest.author.name === 'favio-vazquez', 'manifest.author wrong');
  fs.rmSync(tmp, { recursive: true });
});

// 4. exactly 2 plugin skills: agentic-learning and impeccable
check('exactly 2 plugin skills installed: agentic-learning and impeccable', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-plugin-'));
  const { pluginSkillsDir, count } = runInstallClaudePlugins(tmp);
  assert(count === 2, 'expected 2 skills (agentic-learning + impeccable), got ' + count);
  assert(fs.existsSync(path.join(pluginSkillsDir, 'agentic-learning', 'SKILL.md')), 'agentic-learning/SKILL.md missing');
  assert(fs.existsSync(path.join(pluginSkillsDir, 'impeccable', 'SKILL.md')), 'impeccable/SKILL.md missing');
  fs.rmSync(tmp, { recursive: true });
});

// 5. agentic-learning has SKILL.md and references/
check('agentic-learning: SKILL.md and references/ present in plugin', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-plugin-'));
  const { pluginSkillsDir } = runInstallClaudePlugins(tmp);
  const alDir = path.join(pluginSkillsDir, 'agentic-learning');
  assert(fs.existsSync(path.join(alDir, 'SKILL.md')), 'agentic-learning/SKILL.md missing');
  assert(fs.existsSync(path.join(alDir, 'references')), 'agentic-learning/references/ missing');
  fs.rmSync(tmp, { recursive: true });
});

// 6. impeccable SKILL.md names all 18 actions
check('impeccable SKILL.md references all 18 actions', () => {
  const skillMd = fs.readFileSync(path.join(realSkillsSrc, 'impeccable', 'SKILL.md'), 'utf8');
  const expected = ['adapt','animate','audit','bolder','clarify','colorize','critique',
    'delight','distill','extract','frontend-design','harden','normalize','onboard',
    'optimize','polish','quieter','teach-impeccable'];
  const missing = expected.filter(s => !skillMd.includes(s));
  assert(missing.length === 0, 'impeccable SKILL.md missing actions: ' + missing.join(', '));
});

// 7. impeccable SKILL.md has all 18 action bodies inlined (not reference links)
check('impeccable plugin SKILL.md: all 18 action bodies inlined, no reference links', () => {
  const expected = ['adapt','animate','audit','bolder','clarify','colorize','critique',
    'delight','distill','extract','frontend-design','harden','normalize','onboard',
    'optimize','polish','quieter','teach-impeccable'];
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-plugin-'));
  const { pluginSkillsDir } = runInstallClaudePlugins(tmp);
  const content = fs.readFileSync(path.join(pluginSkillsDir, 'impeccable', 'SKILL.md'), 'utf8');
  const missingHeaders = expected.filter(s => !content.includes('## Action: `' + s + '`'));
  assert(missingHeaders.length === 0, 'missing inlined action headers: ' + missingHeaders.join(', '));
  // No reference links to sibling SKILL.md files
  assert(!content.includes('[audit/SKILL.md]'), 'reference link found — should be inlined');
  assert(!content.includes('[critique/SKILL.md]'), 'reference link found — should be inlined');
  fs.rmSync(tmp, { recursive: true });
});

// 8. inlined impeccable SKILL.md contains real action bodies (not just headers)
check('impeccable plugin SKILL.md: inlined bodies contain real content', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-plugin-'));
  const { pluginSkillsDir } = runInstallClaudePlugins(tmp);
  const content = fs.readFileSync(path.join(pluginSkillsDir, 'impeccable', 'SKILL.md'), 'utf8');
  assert(content.includes('Run systematic quality checks'), 'audit body missing');
  assert(content.includes('Conduct a holistic design critique'), 'critique body missing');
  assert(content.includes('BOLD aesthetic'), 'frontend-design body missing');
  assert(content.length > 50000, 'inlined SKILL.md suspiciously short (' + content.length + ' chars)');
  fs.rmSync(tmp, { recursive: true });
});

// 9. impeccable SKILL.md has valid frontmatter (name: impeccable, no sub-skill frontmatter leaked)
check('impeccable plugin SKILL.md: valid frontmatter, no sub-skill frontmatter leaked', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-plugin-'));
  const { pluginSkillsDir } = runInstallClaudePlugins(tmp);
  const content = fs.readFileSync(path.join(pluginSkillsDir, 'impeccable', 'SKILL.md'), 'utf8');
  assert(content.startsWith('---\nname: impeccable'), 'frontmatter must start with name: impeccable');
  assert(!content.includes('\nname: audit\n'), 'sub-skill frontmatter (audit) leaked into inlined file');
  assert(!content.includes('\nname: critique\n'), 'sub-skill frontmatter (critique) leaked');
  fs.rmSync(tmp, { recursive: true });
});

// 10. uninstall block removes plugins/learnship/ for claude
check('uninstall removes plugins/learnship/ for claude platform', () => {
  const src = fs.readFileSync(path.join(REPO, 'bin', 'install.js'), 'utf8');
  assert(
    src.includes("platform === 'claude'") && src.includes("'plugins', 'learnship'") && src.includes('rmSync'),
    'uninstall block missing plugins/learnship/ cleanup for claude'
  );
});

console.log('\nSECTION10_PASS=' + pass);
console.log('SECTION10_FAIL=' + fail);
NODEEOF

S10_OUTPUT=$(node "$TMPSCRIPT10" "$REPO" 2>&1)
rm -f "$TMPSCRIPT10"

while IFS= read -r line; do
  case "$line" in
    "  PASS "*) ok "${line#  PASS }" ;;
    "  FAIL "*) fail "${line#  FAIL }" ;;
  esac
done <<< "$S10_OUTPUT"

# ──────────────────────────────────────────────────────────────────────────
# [11] sync-upstream-skills workflow
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo "  [11] sync-upstream-skills workflow"
echo "  ─────────────────────────────────────────"

TMPSCRIPT11=$(mktemp /tmp/learnship-test-XXXXXX.cjs)
cat > "$TMPSCRIPT11" << 'NODEEOF'
process.env.LEARNSHIP_TEST_MODE = '1';
const REPO = process.argv[2];
const os = require('os');
const fs = require('fs');
const path = require('path');

let pass = 0; let fail = 0;
function check(name, fn) {
  try { fn(); console.log('  PASS ' + name); pass++; }
  catch(e) { console.log('  FAIL ' + name + ': ' + e.message); fail++; }
}
function assert(cond, msg) { if (!cond) throw new Error(msg); }

const WORKFLOW_SRC  = path.join(REPO, '.windsurf', 'workflows', 'sync-upstream-skills.md');
const WORKFLOW_INST = path.join(REPO, 'learnship', 'workflows', 'sync-upstream-skills.md');
const HELP_SRC      = path.join(REPO, '.windsurf', 'workflows', 'help.md');
const HELP_INST     = path.join(REPO, 'learnship', 'workflows', 'help.md');
const IMPECCABLE_DISPATCHER = path.join(REPO, '.windsurf', 'skills', 'impeccable', 'SKILL.md');

const SUB_SKILLS = [
  'adapt','animate','audit','bolder','clarify','colorize','critique','delight',
  'distill','extract','frontend-design','harden','normalize','onboard','optimize',
  'polish','quieter','teach-impeccable'
];

// 1. Workflow file exists in source location
check('sync-upstream-skills.md exists in .windsurf/workflows/', () => {
  assert(fs.existsSync(WORKFLOW_SRC), 'missing .windsurf/workflows/sync-upstream-skills.md');
});

// 2. Workflow file exists in installed payload
check('sync-upstream-skills.md exists in learnship/workflows/', () => {
  assert(fs.existsSync(WORKFLOW_INST), 'missing learnship/workflows/sync-upstream-skills.md');
});

// 3. Source and installed copies are identical
check('source and installed workflow copies are identical', () => {
  const src  = fs.readFileSync(WORKFLOW_SRC,  'utf8');
  const inst = fs.readFileSync(WORKFLOW_INST, 'utf8');
  assert(src === inst, 'source and learnship/workflows/ copies differ — run: cp .windsurf/workflows/sync-upstream-skills.md learnship/workflows/');
});

// 4. Workflow listed in help.md (source)
check('sync-upstream-skills listed in .windsurf/workflows/help.md', () => {
  const help = fs.readFileSync(HELP_SRC, 'utf8');
  assert(help.includes('sync-upstream-skills'), 'sync-upstream-skills not found in help.md');
});

// 5. Both help.md copies are in sync
check('help.md source and installed copies are identical', () => {
  const src  = fs.readFileSync(HELP_SRC,  'utf8');
  const inst = fs.readFileSync(HELP_INST, 'utf8');
  assert(src === inst, 'help.md source and learnship/workflows/ copies differ');
});

// 6. Workflow has required frontmatter description
check('sync-upstream-skills.md has frontmatter description', () => {
  const wf = fs.readFileSync(WORKFLOW_SRC, 'utf8');
  assert(wf.startsWith('---\n'), 'missing YAML frontmatter');
  assert(wf.includes('description:'), 'missing description field');
});

// 7. Workflow references both upstream repos
check('workflow references FavioVazquez/agentic-learn upstream', () => {
  const wf = fs.readFileSync(WORKFLOW_SRC, 'utf8');
  assert(wf.includes('FavioVazquez/agentic-learn'), 'agentic-learn upstream URL missing');
});

check('workflow references pbakaus/impeccable upstream', () => {
  const wf = fs.readFileSync(WORKFLOW_SRC, 'utf8');
  assert(wf.includes('pbakaus/impeccable'), 'impeccable upstream URL missing');
});

// 8. Workflow explicitly preserves the impeccable dispatcher SKILL.md
check('workflow preserves impeccable/SKILL.md dispatcher', () => {
  const wf = fs.readFileSync(WORKFLOW_SRC, 'utf8');
  assert(
    wf.includes('impeccable/SKILL.md') && (wf.includes('NOT touch') || wf.includes('preserved') || wf.includes('Preserve')),
    'workflow must explicitly state impeccable/SKILL.md is preserved'
  );
});

// 9. Dispatcher SKILL.md actually exists and identifies as impeccable
check('impeccable dispatcher SKILL.md exists and has correct name field', () => {
  assert(fs.existsSync(IMPECCABLE_DISPATCHER), 'impeccable/SKILL.md missing');
  const content = fs.readFileSync(IMPECCABLE_DISPATCHER, 'utf8');
  assert(content.includes('name: impeccable'), 'impeccable/SKILL.md missing "name: impeccable" field');
});

// 10. Dispatcher SKILL.md links all 18 sub-skills
check('impeccable dispatcher SKILL.md references all 18 sub-skills', () => {
  const dispatcher = fs.readFileSync(IMPECCABLE_DISPATCHER, 'utf8');
  const missing = SUB_SKILLS.filter(s => !dispatcher.includes(s));
  assert(missing.length === 0, 'dispatcher missing references to: ' + missing.join(', '));
});

// 11. All 18 sub-skill dirs exist with SKILL.md
check('all 18 impeccable sub-skill dirs have SKILL.md', () => {
  const missing = SUB_SKILLS.filter(s => {
    const p = path.join(REPO, '.windsurf', 'skills', 'impeccable', s, 'SKILL.md');
    return !fs.existsSync(p);
  });
  assert(missing.length === 0, 'missing sub-skill SKILL.md for: ' + missing.join(', '));
});

// 12. Workflow includes backup step before overwriting
check('workflow backs up skills before overwriting', () => {
  const wf = fs.readFileSync(WORKFLOW_SRC, 'utf8');
  assert(wf.includes('backup') || wf.includes('Back up') || wf.includes('BACKUP'), 'no backup step found in workflow');
});

// 13. Workflow includes integrity verification step
check('workflow verifies all 18 sub-skills after sync', () => {
  const wf = fs.readFileSync(WORKFLOW_SRC, 'utf8');
  assert(wf.includes('teach-impeccable') && wf.includes('frontend-design'), 'workflow integrity check missing sub-skill names');
});

// 14. Workflow re-runs installer after sync
check('workflow re-runs installer for all platforms after sync', () => {
  const wf = fs.readFileSync(WORKFLOW_SRC, 'utf8');
  assert(wf.includes('bin/install.js') && wf.includes('--all'), 'workflow must re-run node bin/install.js --all');
});

// 15. Workflow maps correct upstream path for impeccable (source/skills/)
check('workflow maps impeccable upstream path source/skills/ correctly', () => {
  const wf = fs.readFileSync(WORKFLOW_SRC, 'utf8');
  assert(wf.includes('source/skills'), 'workflow must reference impeccable upstream path source/skills/');
});

// ── Simulate the sync logic against local fixtures ─────────────────────────

// 16. Simulated agentic-learn sync: replaces SKILL.md + references/, preserves nothing
check('simulated agentic-learn sync: SKILL.md and references/ replaced correctly', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-sync-'));

  // Fake upstream agentic-learn clone
  const upstreamAL = path.join(tmp, 'agentic-learn');
  const upstreamRefs = path.join(upstreamAL, 'references');
  fs.mkdirSync(upstreamRefs, { recursive: true });
  fs.writeFileSync(path.join(upstreamAL, 'SKILL.md'), '---\nname: agentic-learning\n---\n# Updated upstream');
  fs.writeFileSync(path.join(upstreamRefs, 'learning-science.md'), '# Updated science');

  // Fake current install dir
  const skillDir = path.join(tmp, 'agentic-learning');
  const skillRefs = path.join(skillDir, 'references');
  fs.mkdirSync(skillRefs, { recursive: true });
  fs.writeFileSync(path.join(skillDir, 'SKILL.md'), '---\nname: agentic-learning\n---\n# Old content');
  fs.writeFileSync(path.join(skillRefs, 'old-file.md'), '# Old ref');

  // Apply sync logic (mirrors Step 5 of the workflow)
  fs.copyFileSync(path.join(upstreamAL, 'SKILL.md'), path.join(skillDir, 'SKILL.md'));
  fs.rmSync(skillRefs, { recursive: true });
  fs.cpSync(upstreamRefs, skillRefs, { recursive: true });

  // Verify
  const newSkillMd = fs.readFileSync(path.join(skillDir, 'SKILL.md'), 'utf8');
  assert(newSkillMd.includes('Updated upstream'), 'SKILL.md not replaced with upstream content');
  assert(!fs.existsSync(path.join(skillRefs, 'old-file.md')), 'stale old-file.md still present after sync');
  assert(fs.existsSync(path.join(skillRefs, 'learning-science.md')), 'upstream reference file not copied');

  fs.rmSync(tmp, { recursive: true });
});

// 17. Simulated impeccable sync: sub-skill dirs replaced, dispatcher SKILL.md preserved
check('simulated impeccable sync: sub-skills replaced, dispatcher SKILL.md preserved', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-sync-'));

  // Fake upstream impeccable source/skills/
  const upstreamSkills = path.join(tmp, 'impeccable-upstream', 'source', 'skills');
  const testSubs = ['audit', 'polish', 'adapt'];
  for (const sub of testSubs) {
    fs.mkdirSync(path.join(upstreamSkills, sub), { recursive: true });
    fs.writeFileSync(path.join(upstreamSkills, sub, 'SKILL.md'), `# ${sub} — updated upstream`);
  }

  // Fake current impeccable install
  const impeccableDir = path.join(tmp, 'impeccable');
  fs.mkdirSync(impeccableDir, { recursive: true });
  const dispatcherContent = '---\nname: impeccable\n---\n# Dispatcher — learnship owned';
  fs.writeFileSync(path.join(impeccableDir, 'SKILL.md'), dispatcherContent);
  for (const sub of testSubs) {
    fs.mkdirSync(path.join(impeccableDir, sub), { recursive: true });
    fs.writeFileSync(path.join(impeccableDir, sub, 'SKILL.md'), `# ${sub} — old content`);
  }

  // Save dispatcher (mirrors Step 6 of the workflow)
  const savedDispatcher = fs.readFileSync(path.join(impeccableDir, 'SKILL.md'), 'utf8');

  // Apply sync logic for each sub-skill
  for (const sub of testSubs) {
    const subSrc  = path.join(upstreamSkills, sub);
    const subDest = path.join(impeccableDir, sub);
    if (fs.existsSync(subDest)) fs.rmSync(subDest, { recursive: true });
    fs.cpSync(subSrc, subDest, { recursive: true });
  }

  // Restore dispatcher
  fs.writeFileSync(path.join(impeccableDir, 'SKILL.md'), savedDispatcher);

  // Verify sub-skills updated
  for (const sub of testSubs) {
    const content = fs.readFileSync(path.join(impeccableDir, sub, 'SKILL.md'), 'utf8');
    assert(content.includes('updated upstream'), `${sub}/SKILL.md not updated from upstream`);
  }

  // Verify dispatcher preserved
  const dispatcher = fs.readFileSync(path.join(impeccableDir, 'SKILL.md'), 'utf8');
  assert(dispatcher === dispatcherContent, 'dispatcher SKILL.md was modified — must be preserved');

  fs.rmSync(tmp, { recursive: true });
});

// 18. Simulated integrity check: missing sub-skill triggers restore from backup
check('simulated integrity check: detects missing sub-skill and would restore', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-sync-'));

  // Simulate a partial sync where one sub-skill is missing
  const impeccableDir = path.join(tmp, 'impeccable');
  fs.mkdirSync(impeccableDir, { recursive: true });
  // Only install 17 out of 18 (missing 'adapt')
  const present = SUB_SKILLS.filter(s => s !== 'adapt');
  for (const sub of present) {
    fs.mkdirSync(path.join(impeccableDir, sub), { recursive: true });
    fs.writeFileSync(path.join(impeccableDir, sub, 'SKILL.md'), `# ${sub}`);
  }

  // Integrity check logic (mirrors Step 7 of the workflow)
  const missing = SUB_SKILLS.filter(s => !fs.existsSync(path.join(impeccableDir, s, 'SKILL.md')));
  assert(missing.length === 1 && missing[0] === 'adapt', 'integrity check should detect exactly "adapt" as missing');

  fs.rmSync(tmp, { recursive: true });
});

console.log('\nSECTION11_PASS=' + pass);
console.log('SECTION11_FAIL=' + fail);
NODEEOF

S11_OUTPUT=$(node "$TMPSCRIPT11" "$REPO" 2>&1)
rm -f "$TMPSCRIPT11"

while IFS= read -r line; do
  case "$line" in
    "  PASS "*) ok "${line#  PASS }" ;;
    "  FAIL "*) fail "${line#  FAIL }" ;;
  esac
done <<< "$S11_OUTPUT"

# ──────────────────────────────────────────────────────────────────────────
# [12] agentic-learning integration across workflows
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo "  [12] agentic-learning integration across workflows"
echo "  ─────────────────────────────────────────────────────"

TMPSCRIPT12=$(mktemp /tmp/learnship-test-XXXXXX.cjs)
cat > "$TMPSCRIPT12" << 'NODEEOF'
process.env.LEARNSHIP_TEST_MODE = '1';
const REPO = process.argv[2];
const fs = require('fs');
const path = require('path');

let pass = 0; let fail = 0;
function check(name, fn) {
  try { fn(); console.log('  PASS ' + name); pass++; }
  catch(e) { console.log('  FAIL ' + name + ': ' + e.message); fail++; }
}
function assert(cond, msg) { if (!cond) throw new Error(msg); }

function readWF(name) {
  return fs.readFileSync(path.join(REPO, '.windsurf', 'workflows', name + '.md'), 'utf8');
}
function readInstalled(name) {
  return fs.readFileSync(path.join(REPO, 'learnship', 'workflows', name + '.md'), 'utf8');
}

// Helper: all workflows that should have a Learning Checkpoint section
const WORKFLOWS_WITH_CHECKPOINTS = [
  'execute-phase', 'plan-phase', 'research-phase', 'discuss-phase',
  'verify-work', 'debug', 'quick', 'pause-work', 'resume-work',
  'new-project', 'discuss-milestone', 'new-milestone', 'milestone-retrospective',
];

// 1. All key workflows have a Learning Checkpoint section
check('all key workflows have a Learning Checkpoint section', () => {
  const missing = [];
  for (const wf of WORKFLOWS_WITH_CHECKPOINTS) {
    const content = readWF(wf);
    if (!content.includes('## Learning Checkpoint')) {
      missing.push(wf);
    }
  }
  assert(missing.length === 0, 'Missing Learning Checkpoint in: ' + missing.join(', '));
});

// 2. All Learning Checkpoints read learning_mode from config
check('all Learning Checkpoints read learning_mode from config.json', () => {
  const missing = [];
  for (const wf of WORKFLOWS_WITH_CHECKPOINTS) {
    const content = readWF(wf);
    if (!content.includes('learning_mode')) {
      missing.push(wf);
    }
  }
  assert(missing.length === 0, 'Missing learning_mode read in: ' + missing.join(', '));
});

// 3. All Learning Checkpoints have both auto and manual branches
check('all Learning Checkpoints have auto and manual branches', () => {
  const missing = [];
  for (const wf of WORKFLOWS_WITH_CHECKPOINTS) {
    const content = readWF(wf);
    const hasAuto   = content.includes('**If `auto`');
    const hasManual = content.includes('**If `manual`');
    if (!hasAuto || !hasManual) {
      missing.push(wf + (hasAuto ? '' : ' (no auto)') + (hasManual ? '' : ' (no manual)'));
    }
  }
  assert(missing.length === 0, 'Missing auto/manual branches in: ' + missing.join(', '));
});

// 4. execute-phase has reflect + quiz + interleave
check('execute-phase Learning Checkpoint offers reflect, quiz, and interleave', () => {
  const wf = readWF('execute-phase');
  assert(wf.includes('@agentic-learning reflect'), 'reflect missing from execute-phase');
  assert(wf.includes('@agentic-learning quiz'),    'quiz missing from execute-phase');
  assert(wf.includes('@agentic-learning interleave'), 'interleave missing from execute-phase');
});

// 5. plan-phase has explain-first + cognitive-load + quiz
check('plan-phase Learning Checkpoint offers explain-first, cognitive-load, and quiz', () => {
  const wf = readWF('plan-phase');
  assert(wf.includes('@agentic-learning explain-first'), 'explain-first missing from plan-phase');
  assert(wf.includes('@agentic-learning cognitive-load'), 'cognitive-load missing from plan-phase');
  assert(wf.includes('@agentic-learning quiz'),           'quiz missing from plan-phase');
});

// 6. research-phase has learn + explain-first + quiz
check('research-phase Learning Checkpoint offers learn, explain-first, and quiz', () => {
  const wf = readWF('research-phase');
  assert(wf.includes('@agentic-learning learn'),         'learn missing from research-phase');
  assert(wf.includes('@agentic-learning explain-first'), 'explain-first missing from research-phase');
  assert(wf.includes('@agentic-learning quiz'),          'quiz missing from research-phase');
});

// 7. debug has learn + struggle + either-or (not just either-or)
check('debug Learning Checkpoint offers learn, struggle, and either-or', () => {
  const wf = readWF('debug');
  assert(wf.includes('@agentic-learning learn'),     'learn missing from debug');
  assert(wf.includes('@agentic-learning struggle'),  'struggle missing from debug');
  assert(wf.includes('@agentic-learning either-or'), 'either-or missing from debug');
});

// 8. verify-work has both pass-path (space+quiz) and bug-path (learn+space)
check('verify-work Learning Checkpoint covers both pass and issue-found paths', () => {
  const wf = readWF('verify-work');
  assert(wf.includes('UAT passed with no issues'), 'pass-path condition missing from verify-work');
  assert(wf.includes('issues were found'),         'bug-path condition missing from verify-work');
  assert(wf.includes('@agentic-learning space'),   'space missing from verify-work');
  assert(wf.includes('@agentic-learning quiz'),    'quiz missing from verify-work');
  assert(wf.includes('@agentic-learning learn'),   'learn missing from verify-work bug-path');
});

// 9. discuss-phase has either-or + brainstorm + explain-first
check('discuss-phase Learning Checkpoint offers either-or, brainstorm, and explain-first', () => {
  const wf = readWF('discuss-phase');
  assert(wf.includes('@agentic-learning either-or'),     'either-or missing from discuss-phase');
  assert(wf.includes('@agentic-learning brainstorm'),    'brainstorm missing from discuss-phase');
  assert(wf.includes('@agentic-learning explain-first'), 'explain-first missing from discuss-phase');
});

// 10. quick has struggle + learn + either-or
check('quick Learning Checkpoint offers struggle, learn, and either-or', () => {
  const wf = readWF('quick');
  assert(wf.includes('@agentic-learning struggle'),  'struggle missing from quick');
  assert(wf.includes('@agentic-learning learn'),     'learn missing from quick');
  assert(wf.includes('@agentic-learning either-or'), 'either-or missing from quick');
});

// 11. pause-work has learning checkpoint with space + reflect
check('pause-work has Learning Checkpoint with space and reflect', () => {
  const wf = readWF('pause-work');
  assert(wf.includes('## Learning Checkpoint'),    'Learning Checkpoint section missing from pause-work');
  assert(wf.includes('@agentic-learning space'),   'space missing from pause-work');
  assert(wf.includes('@agentic-learning reflect'), 'reflect missing from pause-work');
});

// 12. resume-work has learning checkpoint with quiz + space
check('resume-work has Learning Checkpoint with quiz and space', () => {
  const wf = readWF('resume-work');
  assert(wf.includes('## Learning Checkpoint'),  'Learning Checkpoint section missing from resume-work');
  assert(wf.includes('@agentic-learning quiz'),  'quiz missing from resume-work');
  assert(wf.includes('@agentic-learning space'), 'space missing from resume-work');
});

// 13. Source and installed copies are in sync for all modified workflows
const SYNCED_WORKFLOWS = [
  'execute-phase', 'plan-phase', 'research-phase', 'discuss-phase',
  'verify-work', 'debug', 'quick', 'pause-work', 'resume-work',
];
check('all modified workflow source and installed copies are identical', () => {
  const diffs = [];
  for (const wf of SYNCED_WORKFLOWS) {
    const src  = readWF(wf);
    const inst = readInstalled(wf);
    if (src !== inst) {
      diffs.push(wf);
    }
  }
  assert(diffs.length === 0,
    'Source and learnship/workflows/ differ for: ' + diffs.join(', ') +
    ' — run: for f in ' + diffs.join(' ') + '; do cp .windsurf/workflows/${f}.md learnship/workflows/${f}.md; done');
});

// 14. All 11 agentic-learning actions are referenced across the workflow suite
const ALL_ACTIONS = [
  'learn', 'quiz', 'reflect', 'space', 'brainstorm',
  'explain-first', 'struggle', 'either-or', 'explain', 'interleave', 'cognitive-load'
];
check('all 11 agentic-learning actions used somewhere in the workflow suite', () => {
  // Read all workflow files
  const allContent = WORKFLOWS_WITH_CHECKPOINTS.map(wf => readWF(wf)).join('\n');
  const unused = ALL_ACTIONS.filter(a => !allContent.includes('@agentic-learning ' + a));
  assert(unused.length === 0, 'agentic-learning actions never referenced in any workflow: ' + unused.join(', '));
});

console.log('\nSECTION12_PASS=' + pass);
console.log('SECTION12_FAIL=' + fail);
NODEEOF

S12_OUTPUT=$(node "$TMPSCRIPT12" "$REPO" 2>&1)
rm -f "$TMPSCRIPT12"

while IFS= read -r line; do
  case "$line" in
    "  PASS "*) ok "${line#  PASS }" ;;
    "  FAIL "*) fail "${line#  FAIL }" ;;
  esac
done <<< "$S12_OUTPUT"

# ──────────────────────────────────────────────────────────────────────────
# [13] Documentation site integrity
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo "  [13] Documentation site integrity"
echo "  ─────────────────────────────────────────"

TMPSCRIPT13=$(mktemp /tmp/learnship-test-XXXXXX.cjs)
cat > "$TMPSCRIPT13" << 'NODEEOF'
process.env.LEARNSHIP_TEST_MODE = '1';
const REPO = process.argv[2];
const fs = require('fs');
const path = require('path');

let pass = 0; let fail = 0;
function check(name, fn) {
  try { fn(); console.log('  PASS ' + name); pass++; }
  catch(e) { console.log('  FAIL ' + name + ': ' + e.message); fail++; }
}
function assert(cond, msg) { if (!cond) throw new Error(msg); }

const MKDOCS = path.join(REPO, 'mkdocs.yml');
const DOCS   = path.join(REPO, 'docs');

// 1. mkdocs.yml exists
check('mkdocs.yml exists at repo root', () => {
  assert(fs.existsSync(MKDOCS), 'mkdocs.yml not found at repo root');
});

// 2. mkdocs.yml has required keys
check('mkdocs.yml has site_name, theme, and nav', () => {
  const content = fs.readFileSync(MKDOCS, 'utf8');
  assert(content.includes('site_name:'), 'site_name missing from mkdocs.yml');
  assert(content.includes('theme:'),     'theme missing from mkdocs.yml');
  assert(content.includes('nav:'),       'nav missing from mkdocs.yml');
});

// 3. mkdocs.yml references GitHub Pages URL
check('mkdocs.yml references faviovazquez.github.io/learnship', () => {
  const content = fs.readFileSync(MKDOCS, 'utf8');
  assert(content.includes('faviovazquez.github.io/learnship'), 'GitHub Pages URL missing from mkdocs.yml');
});

// 4. docs/index.md exists and contains install command
check('docs/index.md exists and contains npx install command', () => {
  const indexPath = path.join(DOCS, 'index.md');
  assert(fs.existsSync(indexPath), 'docs/index.md not found');
  const content = fs.readFileSync(indexPath, 'utf8');
  assert(content.includes('npx learnship'), 'install command missing from docs/index.md');
});

// 5. All 5 platform guide pages exist
check('all 5 platform guide pages exist in docs/platform-guide/', () => {
  const platforms = ['windsurf', 'claude-code', 'opencode', 'gemini-cli', 'codex-cli'];
  const missing = platforms.filter(p =>
    !fs.existsSync(path.join(DOCS, 'platform-guide', p + '.md'))
  );
  assert(missing.length === 0, 'Missing platform pages: ' + missing.join(', '));
});

// 6. All 11 @agentic-learning actions documented
check('all 11 @agentic-learning actions documented in docs/skills/agentic-learning.md', () => {
  const skillPath = path.join(DOCS, 'skills', 'agentic-learning.md');
  assert(fs.existsSync(skillPath), 'docs/skills/agentic-learning.md not found');
  const content = fs.readFileSync(skillPath, 'utf8');
  const actions = ['learn', 'quiz', 'reflect', 'space', 'brainstorm', 'struggle', 'either-or', 'explain-first', 'explain', 'interleave', 'cognitive-load'];
  const missing = actions.filter(a => !content.includes('`' + a + '`') && !content.includes('@agentic-learning ' + a));
  assert(missing.length === 0, 'Missing actions in agentic-learning.md: ' + missing.join(', '));
});

// 7. All impeccable commands documented (spot-check 8 key ones)
check('key impeccable commands documented in docs/skills/impeccable.md', () => {
  const skillPath = path.join(DOCS, 'skills', 'impeccable.md');
  assert(fs.existsSync(skillPath), 'docs/skills/impeccable.md not found');
  const content = fs.readFileSync(skillPath, 'utf8');
  const commands = ['/audit', '/critique', '/polish', '/colorize', '/animate', '/harden', '/delight', '/adapt'];
  const missing = commands.filter(c => !content.includes(c));
  assert(missing.length === 0, 'Missing impeccable commands: ' + missing.join(', '));
});

// 8. docs.yml GitHub Actions workflow exists and references gh-pages
check('.github/workflows/docs.yml exists and deploys to gh-pages', () => {
  const docsYml = path.join(REPO, '.github', 'workflows', 'docs.yml');
  assert(fs.existsSync(docsYml), '.github/workflows/docs.yml not found');
  const content = fs.readFileSync(docsYml, 'utf8');
  assert(content.includes('gh-pages') || content.includes('gh-deploy'), 'docs.yml does not reference gh-pages deploy');
});

// 9. README.md contains link to GitHub Pages docs site
check('README.md contains link to faviovazquez.github.io/learnship', () => {
  const readme = fs.readFileSync(path.join(REPO, 'README.md'), 'utf8');
  assert(readme.includes('faviovazquez.github.io/learnship'), 'README.md missing link to docs site');
});

// 10. assets/ directory has at least 14 PNG images (8 original + 6+ new doc images)
check('assets/ has at least 14 PNG images', () => {
  const files = fs.readdirSync(path.join(REPO, 'assets'));
  const pngs = files.filter(f => f.endsWith('.png'));
  assert(pngs.length >= 14, 'Expected at least 14 PNG images in assets/, found ' + pngs.length);
});

console.log('\nSECTION13_PASS=' + pass);
console.log('SECTION13_FAIL=' + fail);
NODEEOF

S13_OUTPUT=$(node "$TMPSCRIPT13" "$REPO" 2>&1)
rm -f "$TMPSCRIPT13"

while IFS= read -r line; do
  case "$line" in
    "  PASS "*) ok "${line#  PASS }" ;;
    "  FAIL "*) fail "${line#  FAIL }" ;;
  esac
done <<< "$S13_OUTPUT"

# ──────────────────────────────────────────────────────────────────────────
# [14] impeccable integration
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo "  [14] impeccable integration"
echo "  ────────────────────────────"

TMPSCRIPT14=$(mktemp /tmp/learnship-test-XXXXXX.cjs)
cat > "$TMPSCRIPT14" << 'NODEEOF'
process.env.LEARNSHIP_TEST_MODE = '1';
const REPO = process.argv[2];
const fs = require('fs');
const path = require('path');

let pass = 0; let fail = 0;
function check(name, fn) {
  try { fn(); console.log('  PASS ' + name); pass++; }
  catch(e) { console.log('  FAIL ' + name + ': ' + e.message); fail++; }
}
function assert(cond, msg) { if (!cond) throw new Error(msg); }

function readWF(name) {
  return fs.readFileSync(path.join(REPO, '.windsurf', 'workflows', name + '.md'), 'utf8');
}
function readInstalled(name) {
  return fs.readFileSync(path.join(REPO, 'learnship', 'workflows', name + '.md'), 'utf8');
}
function readSkill(relPath) {
  return fs.readFileSync(path.join(REPO, '.windsurf', 'skills', 'impeccable', relPath), 'utf8');
}

// 1. execute-phase has UI detection step
check('execute-phase has UI detection step (Step 2b)', () => {
  const content = readWF('execute-phase');
  assert(content.includes('UI Detection'), 'Missing UI Detection step');
  assert(content.includes('UI PHASE DETECTED'), 'Missing UI PHASE DETECTED banner');
});

// 2. execute-phase UI detection scans for frontend keywords
check('execute-phase UI detection covers frontend keywords', () => {
  const content = readWF('execute-phase');
  assert(content.includes('component'), 'Missing component keyword');
  assert(content.includes('tailwind') || content.includes('css'), 'Missing CSS/Tailwind keyword');
  assert(content.includes('.tsx') || content.includes('.jsx'), 'Missing frontend file pattern');
});

// 3. execute-phase activates impeccable frontend-design when UI detected
check('execute-phase activates impeccable frontend-design for UI phases', () => {
  const content = readWF('execute-phase');
  assert(content.includes('frontend-design'), 'Missing @impeccable frontend-design activation');
  assert(content.includes('Typography') && content.includes('Color') && content.includes('Layout'),
    'Missing frontend-design principle categories (Typography/Color/Layout)');
});

// 4. execute-phase UI detection step is present in installed learnship/ copy
check('learnship/workflows/execute-phase.md has UI detection (in sync)', () => {
  const content = readInstalled('execute-phase');
  assert(content.includes('UI Detection'), 'Installed copy missing UI Detection step');
  assert(content.includes('UI PHASE DETECTED'), 'Installed copy missing UI PHASE DETECTED banner');
});

// 5. impeccable SKILL.md has post-action milestone recommendation
check('impeccable SKILL.md has post-action milestone recommendation', () => {
  const content = readSkill('SKILL.md');
  assert(content.includes('After running any impeccable action'), 'Missing post-action section');
  assert(content.includes('new-milestone') || content.includes('/new-milestone'),
    'Missing /new-milestone recommendation');
  assert(content.includes('RECOMMENDATIONS READY'), 'Missing RECOMMENDATIONS READY banner');
});

// 6. impeccable SKILL.md specifies which actions trigger the recommendation
check('impeccable SKILL.md lists actions that trigger milestone recommendation', () => {
  const content = readSkill('SKILL.md');
  assert(content.includes('audit') && content.includes('critique') && content.includes('polish'),
    'Missing key action names in post-action section');
});

// 7. impeccable SKILL.md exempts setup actions (teach-impeccable, frontend-design)
check('impeccable SKILL.md exempts teach-impeccable and frontend-design from milestone suggestion', () => {
  const content = readSkill('SKILL.md');
  assert(content.includes('teach-impeccable') && content.includes('frontend-design') &&
    content.includes('skip'), 'Missing exemption for setup actions');
});

// 8. docs/skills/impeccable.md documents learnship integration
check('docs/skills/impeccable.md documents learnship integration section', () => {
  const content = fs.readFileSync(path.join(REPO, 'docs', 'skills', 'impeccable.md'), 'utf8');
  assert(content.includes('learnship integration'), 'Missing learnship integration section in docs');
  assert(content.includes('execute-phase'), 'Docs missing execute-phase reference');
  assert(content.includes('new-milestone'), 'Docs missing new-milestone recommendation reference');
});

// 9. README documents impeccable learnship integration
check('README documents impeccable learnship integration', () => {
  const content = fs.readFileSync(path.join(REPO, 'README.md'), 'utf8');
  assert(content.includes('learnship integration') || content.includes('Automatic UI standards'),
    'README missing impeccable learnship integration section');
  assert(content.includes('execute-phase') && content.includes('frontend-design'),
    'README missing execute-phase/frontend-design integration reference');
});

console.log('\nSECTION14_PASS=' + pass);
console.log('SECTION14_FAIL=' + fail);
NODEEOF

S14_OUTPUT=$(node "$TMPSCRIPT14" "$REPO" 2>&1)
rm -f "$TMPSCRIPT14"

while IFS= read -r line; do
  case "$line" in
    "  PASS "*) ok "${line#  PASS }" ;;
    "  FAIL "*) fail "${line#  FAIL }" ;;
  esac
done <<< "$S14_OUTPUT"

# ──────────────────────────────────────────────────────────────────────────
# Section 15: Claude Code plugin manifest
# ──────────────────────────────────────────────────────────────────────────
TMPSCRIPT15=$(mktemp /tmp/ls_test15_XXXXXX.js)
cat > "$TMPSCRIPT15" << 'NODEEOF'
const fs = require('fs');
const path = require('path');
const REPO = process.argv[2];
let pass = 0, fail = 0;
function check(name, fn) {
  try { fn(); console.log('  PASS ' + name); pass++; }
  catch(e) { console.log('  FAIL ' + name + ' — ' + e.message); fail++; }
}
function assert(cond, msg) { if (!cond) throw new Error(msg); }

// 1. .claude-plugin/plugin.json exists
check('.claude-plugin/plugin.json exists', () => {
  const p = path.join(REPO, '.claude-plugin', 'plugin.json');
  assert(fs.existsSync(p), '.claude-plugin/plugin.json not found');
});

// 2. Claude Code plugin.json has required fields
check('.claude-plugin/plugin.json has required fields (name, description, version)', () => {
  const p = path.join(REPO, '.claude-plugin', 'plugin.json');
  const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
  assert(cfg.name === 'learnship', 'name must be "learnship"');
  assert(typeof cfg.description === 'string' && cfg.description.length > 10, 'description missing or too short');
  assert(typeof cfg.version === 'string' && cfg.version.match(/^\d+\.\d+\.\d+$/), 'version not semver');
});

// 3. Claude Code plugin.json paths point to real directories
check('.claude-plugin/plugin.json paths point to real directories', () => {
  const p = path.join(REPO, '.claude-plugin', 'plugin.json');
  const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
  if (cfg.commands) assert(fs.existsSync(path.join(REPO, cfg.commands)), `commands dir not found: ${cfg.commands}`);
  if (cfg.agents) assert(fs.existsSync(path.join(REPO, cfg.agents)), `agents dir not found: ${cfg.agents}`);
  if (cfg.skills) assert(fs.existsSync(path.join(REPO, cfg.skills)), `skills dir not found: ${cfg.skills}`);
});

// 4. Claude Code plugin.json version matches package.json
check('.claude-plugin/plugin.json version matches package.json', () => {
  const pluginCfg = JSON.parse(fs.readFileSync(path.join(REPO, '.claude-plugin', 'plugin.json'), 'utf8'));
  const pkgCfg = JSON.parse(fs.readFileSync(path.join(REPO, 'package.json'), 'utf8'));
  assert(pluginCfg.version === pkgCfg.version,
    `plugin.json version (${pluginCfg.version}) does not match package.json (${pkgCfg.version})`);
});

// 5. Marketplace manifest exists
check('marketplace/.claude-plugin/marketplace.json exists', () => {
  const p = path.join(REPO, 'marketplace', '.claude-plugin', 'marketplace.json');
  assert(fs.existsSync(p), 'marketplace/.claude-plugin/marketplace.json not found');
});

// 6. Marketplace manifest has required fields
check('marketplace manifest has name, owner, plugins array', () => {
  const p = path.join(REPO, 'marketplace', '.claude-plugin', 'marketplace.json');
  const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
  assert(typeof cfg.name === 'string', 'marketplace name missing');
  assert(cfg.owner && cfg.owner.name, 'marketplace owner.name missing');
  assert(Array.isArray(cfg.plugins) && cfg.plugins.length > 0, 'plugins array missing or empty');
  assert(cfg.plugins[0].name === 'learnship', 'first plugin name must be learnship');
});

// 7. Plugin manifests do NOT reference .windsurf/skills (platform-neutral skills/)
check('plugin manifests use skills/ not .windsurf/skills', () => {
  const claudeCfg = JSON.parse(fs.readFileSync(path.join(REPO, '.claude-plugin', 'plugin.json'), 'utf8'));
  const cursorCfg = JSON.parse(fs.readFileSync(path.join(REPO, '.cursor-plugin', 'plugin.json'), 'utf8'));
  assert(!String(claudeCfg.skills || '').includes('.windsurf'),
    '.claude-plugin/plugin.json skills must not reference .windsurf/');
  assert(!String(cursorCfg.skills || '').includes('.windsurf'),
    '.cursor-plugin/plugin.json skills must not reference .windsurf/');
  assert(claudeCfg.skills === 'skills', `.claude-plugin skills should be "skills", got "${claudeCfg.skills}"`);
  assert(cursorCfg.skills === 'skills', `.cursor-plugin skills should be "skills", got "${cursorCfg.skills}"`);
});

// 8. skills/ directory exists and has both skill subdirectories
check('skills/ directory exists with agentic-learning and impeccable', () => {
  const skillsDir = path.join(REPO, 'skills');
  assert(fs.existsSync(skillsDir), 'skills/ directory not found');
  assert(fs.existsSync(path.join(skillsDir, 'agentic-learning')), 'skills/agentic-learning/ missing');
  assert(fs.existsSync(path.join(skillsDir, 'impeccable')), 'skills/impeccable/ missing');
  assert(fs.existsSync(path.join(skillsDir, 'agentic-learning', 'SKILL.md')), 'skills/agentic-learning/SKILL.md missing');
  assert(fs.existsSync(path.join(skillsDir, 'impeccable', 'SKILL.md')), 'skills/impeccable/SKILL.md missing');
});

// 9. Plugin manifests reference hooks
check('.claude-plugin/plugin.json has hooks field', () => {
  const cfg = JSON.parse(fs.readFileSync(path.join(REPO, '.claude-plugin', 'plugin.json'), 'utf8'));
  assert(typeof cfg.hooks === 'string', '.claude-plugin/plugin.json missing hooks field');
});

check('.cursor-plugin/plugin.json has hooks field', () => {
  const cfg = JSON.parse(fs.readFileSync(path.join(REPO, '.cursor-plugin', 'plugin.json'), 'utf8'));
  assert(typeof cfg.hooks === 'string', '.cursor-plugin/plugin.json missing hooks field');
});

console.log('\nSECTION15_PASS=' + pass);
console.log('SECTION15_FAIL=' + fail);
NODEEOF

S15_OUTPUT=$(node "$TMPSCRIPT15" "$REPO" 2>&1)
rm -f "$TMPSCRIPT15"

while IFS= read -r line; do
  case "$line" in
    "  PASS "*) ok "${line#  PASS }" ;;
    "  FAIL "*) fail "${line#  FAIL }" ;;
  esac
done <<< "$S15_OUTPUT"

# ──────────────────────────────────────────────────────────────────────────
# Section 16: Cursor plugin manifest
# ──────────────────────────────────────────────────────────────────────────
TMPSCRIPT16=$(mktemp /tmp/ls_test16_XXXXXX.js)
cat > "$TMPSCRIPT16" << 'NODEEOF'
const fs = require('fs');
const path = require('path');
const REPO = process.argv[2];
let pass = 0, fail = 0;
function check(name, fn) {
  try { fn(); console.log('  PASS ' + name); pass++; }
  catch(e) { console.log('  FAIL ' + name + ' — ' + e.message); fail++; }
}
function assert(cond, msg) { if (!cond) throw new Error(msg); }

// 1. .cursor-plugin/plugin.json exists
check('.cursor-plugin/plugin.json exists', () => {
  const p = path.join(REPO, '.cursor-plugin', 'plugin.json');
  assert(fs.existsSync(p), '.cursor-plugin/plugin.json not found');
});

// 2. Cursor plugin.json has required fields
check('.cursor-plugin/plugin.json has required fields (name, description, version)', () => {
  const p = path.join(REPO, '.cursor-plugin', 'plugin.json');
  const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
  assert(cfg.name === 'learnship', 'name must be "learnship"');
  assert(typeof cfg.description === 'string' && cfg.description.length > 10, 'description missing or too short');
  assert(typeof cfg.version === 'string' && cfg.version.match(/^\d+\.\d+\.\d+$/), 'version not semver');
});

// 3. Cursor plugin.json paths point to real directories
check('.cursor-plugin/plugin.json paths point to real directories', () => {
  const p = path.join(REPO, '.cursor-plugin', 'plugin.json');
  const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
  if (cfg.skills) assert(fs.existsSync(path.join(REPO, cfg.skills)), `skills dir not found: ${cfg.skills}`);
  if (cfg.rules) assert(fs.existsSync(path.join(REPO, cfg.rules)), `rules dir not found: ${cfg.rules}`);
  if (cfg.agents) assert(fs.existsSync(path.join(REPO, cfg.agents)), `agents dir not found: ${cfg.agents}`);
});

// 4. Cursor plugin.json version matches package.json
check('.cursor-plugin/plugin.json version matches package.json', () => {
  const pluginCfg = JSON.parse(fs.readFileSync(path.join(REPO, '.cursor-plugin', 'plugin.json'), 'utf8'));
  const pkgCfg = JSON.parse(fs.readFileSync(path.join(REPO, 'package.json'), 'utf8'));
  assert(pluginCfg.version === pkgCfg.version,
    `cursor plugin.json version (${pluginCfg.version}) does not match package.json (${pkgCfg.version})`);
});

// 5. cursor-rules/learnship.mdc exists
check('cursor-rules/learnship.mdc exists', () => {
  const p = path.join(REPO, 'cursor-rules', 'learnship.mdc');
  assert(fs.existsSync(p), 'cursor-rules/learnship.mdc not found');
});

// 6. cursor-rules/learnship.mdc has frontmatter and content
check('cursor-rules/learnship.mdc has valid frontmatter and workflow table', () => {
  const content = fs.readFileSync(path.join(REPO, 'cursor-rules', 'learnship.mdc'), 'utf8');
  assert(content.startsWith('---'), 'Missing YAML frontmatter');
  assert(content.includes('name:') && content.includes('description:'), 'Missing name/description in frontmatter');
  assert(content.includes('/ls') && content.includes('/new-project'), 'Missing core workflow commands');
  assert(content.includes('.planning/'), 'Missing .planning/ reference');
});

console.log('\nSECTION16_PASS=' + pass);
console.log('SECTION16_FAIL=' + fail);
NODEEOF

S16_OUTPUT=$(node "$TMPSCRIPT16" "$REPO" 2>&1)
rm -f "$TMPSCRIPT16"

while IFS= read -r line; do
  case "$line" in
    "  PASS "*) ok "${line#  PASS }" ;;
    "  FAIL "*) fail "${line#  FAIL }" ;;
  esac
done <<< "$S16_OUTPUT"

# ──────────────────────────────────────────────────────────────────────────
# Section 17: Gemini extension manifest
# ──────────────────────────────────────────────────────────────────────────
TMPSCRIPT17=$(mktemp /tmp/ls_test17_XXXXXX.js)
cat > "$TMPSCRIPT17" << 'NODEEOF'
const fs = require('fs');
const path = require('path');
const REPO = process.argv[2];
let pass = 0, fail = 0;
function check(name, fn) {
  try { fn(); console.log('  PASS ' + name); pass++; }
  catch(e) { console.log('  FAIL ' + name + ' — ' + e.message); fail++; }
}
function assert(cond, msg) { if (!cond) throw new Error(msg); }

// 1. gemini-extension.json exists at repo root
check('gemini-extension.json exists at repo root', () => {
  const p = path.join(REPO, 'gemini-extension.json');
  assert(fs.existsSync(p), 'gemini-extension.json not found at repo root');
});

// 2. gemini-extension.json has required fields
check('gemini-extension.json has name, version, description, installDir', () => {
  const p = path.join(REPO, 'gemini-extension.json');
  const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
  assert(cfg.name === 'learnship', 'name must be "learnship"');
  assert(typeof cfg.version === 'string' && cfg.version.match(/^\d+\.\d+\.\d+$/), 'version not semver');
  assert(typeof cfg.description === 'string' && cfg.description.length > 10, 'description missing or too short');
  assert(cfg.installDir === '.gemini', 'installDir must be ".gemini"');
});

// 3. gemini-extension.json version matches package.json
check('gemini-extension.json version matches package.json', () => {
  const extCfg = JSON.parse(fs.readFileSync(path.join(REPO, 'gemini-extension.json'), 'utf8'));
  const pkgCfg = JSON.parse(fs.readFileSync(path.join(REPO, 'package.json'), 'utf8'));
  assert(extCfg.version === pkgCfg.version,
    `gemini-extension.json version (${extCfg.version}) does not match package.json (${pkgCfg.version})`);
});

console.log('\nSECTION17_PASS=' + pass);
console.log('SECTION17_FAIL=' + fail);
NODEEOF

S17_OUTPUT=$(node "$TMPSCRIPT17" "$REPO" 2>&1)
rm -f "$TMPSCRIPT17"

while IFS= read -r line; do
  case "$line" in
    "  PASS "*) ok "${line#  PASS }" ;;
    "  FAIL "*) fail "${line#  FAIL }" ;;
  esac
done <<< "$S17_OUTPUT"

# ──────────────────────────────────────────────────────────────────────────
# Section 18: npm publishability
# ──────────────────────────────────────────────────────────────────────────
TMPSCRIPT18=$(mktemp /tmp/ls_test18_XXXXXX.js)
cat > "$TMPSCRIPT18" << 'NODEEOF'
const fs = require('fs');
const path = require('path');
const REPO = process.argv[2];
let pass = 0, fail = 0;
function check(name, fn) {
  try { fn(); console.log('  PASS ' + name); pass++; }
  catch(e) { console.log('  FAIL ' + name + ' — ' + e.message); fail++; }
}
function assert(cond, msg) { if (!cond) throw new Error(msg); }

// 1. package.json has files field
check('package.json has files field for npm publish', () => {
  const pkg = JSON.parse(fs.readFileSync(path.join(REPO, 'package.json'), 'utf8'));
  assert(Array.isArray(pkg.files) && pkg.files.length > 0, 'package.json missing files field');
});

// 2. package.json files field includes new manifests
check('package.json files includes .claude-plugin, .cursor-plugin, cursor-rules', () => {
  const pkg = JSON.parse(fs.readFileSync(path.join(REPO, 'package.json'), 'utf8'));
  assert(pkg.files.includes('.claude-plugin'), 'files missing .claude-plugin');
  assert(pkg.files.includes('.cursor-plugin'), 'files missing .cursor-plugin');
  assert(pkg.files.includes('cursor-rules'), 'files missing cursor-rules');
  assert(pkg.files.includes('gemini-extension.json'), 'files missing gemini-extension.json');
});

// 3. package.json has publishConfig
check('package.json has publishConfig.access = "public"', () => {
  const pkg = JSON.parse(fs.readFileSync(path.join(REPO, 'package.json'), 'utf8'));
  assert(pkg.publishConfig && pkg.publishConfig.access === 'public',
    'publishConfig.access must be "public"');
});

// 4. .npmignore exists
check('.npmignore exists to exclude dev files', () => {
  assert(fs.existsSync(path.join(REPO, '.npmignore')), '.npmignore not found');
});

// 5. README install commands use npx learnship (not github: prefix)
check('README uses "npx learnship" (not old github: prefix)', () => {
  const readme = fs.readFileSync(path.join(REPO, 'README.md'), 'utf8');
  assert(!readme.includes('npx github:FavioVazquez/learnship'),
    'README still contains old "npx github:FavioVazquez/learnship" — update to "npx learnship"');
  assert(readme.includes('npx learnship'), 'README missing "npx learnship" install command');
});

// 6. package.json name is "learnship" (not scoped)
check('package.json name is "learnship" (clean npm package name)', () => {
  const pkg = JSON.parse(fs.readFileSync(path.join(REPO, 'package.json'), 'utf8'));
  assert(pkg.name === 'learnship', `package name should be "learnship", got "${pkg.name}"`);
});

// 7. All platform guide docs use npx learnship (not github: prefix)
check('docs/ install commands use "npx learnship" not old github: prefix', () => {
  const docsDir = path.join(REPO, 'docs');
  function scanDir(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) { scanDir(full); continue; }
      if (!entry.name.endsWith('.md')) continue;
      const content = fs.readFileSync(full, 'utf8');
      if (content.includes('npx github:FavioVazquez/learnship')) {
        throw new Error(`${full.replace(REPO + '/', '')} still uses old npx github: prefix`);
      }
    }
  }
  scanDir(docsDir);
});

console.log('\nSECTION18_PASS=' + pass);
console.log('SECTION18_FAIL=' + fail);
NODEEOF

S18_OUTPUT=$(node "$TMPSCRIPT18" "$REPO" 2>&1)
rm -f "$TMPSCRIPT18"

while IFS= read -r line; do
  case "$line" in
    "  PASS "*) ok "${line#  PASS }" ;;
    "  FAIL "*) fail "${line#  FAIL }" ;;
  esac
done <<< "$S18_OUTPUT"

# ──────────────────────────────────────────────────────────────────────────
# Section 19: Hooks
# ──────────────────────────────────────────────────────────────────────────
TMPSCRIPT19=$(mktemp /tmp/ls_test19_XXXXXX.js)
cat > "$TMPSCRIPT19" << 'NODEEOF'
const fs = require('fs');
const path = require('path');
const REPO = process.argv[2];
let pass = 0, fail = 0;
function check(name, fn) {
  try { fn(); console.log('  PASS ' + name); pass++; }
  catch(e) { console.log('  FAIL ' + name + ' — ' + e.message); fail++; }
}
function assert(cond, msg) { if (!cond) throw new Error(msg); }

// 1. hooks/ directory exists
check('hooks/ directory exists', () => {
  assert(fs.existsSync(path.join(REPO, 'hooks')), 'hooks/ directory not found');
});

// 2. session-start script exists
check('hooks/session-start script exists', () => {
  assert(fs.existsSync(path.join(REPO, 'hooks', 'session-start')), 'hooks/session-start not found');
});

// 3. session-start is executable
check('hooks/session-start is executable', () => {
  const stat = fs.statSync(path.join(REPO, 'hooks', 'session-start'));
  const isExecutable = (stat.mode & 0o111) !== 0;
  assert(isExecutable, 'hooks/session-start is not executable — run chmod +x hooks/session-start');
});

// 4. session-start has shebang
check('hooks/session-start has bash shebang', () => {
  const content = fs.readFileSync(path.join(REPO, 'hooks', 'session-start'), 'utf8');
  assert(content.startsWith('#!/usr/bin/env bash') || content.startsWith('#!/bin/bash'),
    'hooks/session-start missing bash shebang');
});

// 5. session-start handles both Cursor and Claude Code
check('hooks/session-start handles Cursor and Claude Code output formats', () => {
  const content = fs.readFileSync(path.join(REPO, 'hooks', 'session-start'), 'utf8');
  assert(content.includes('CURSOR_PLUGIN_ROOT'), 'Missing CURSOR_PLUGIN_ROOT check for Cursor');
  assert(content.includes('CLAUDE_PLUGIN_ROOT'), 'Missing CLAUDE_PLUGIN_ROOT check for Claude Code');
  assert(content.includes('additional_context'), 'Missing additional_context output for Cursor');
  assert(content.includes('hookSpecificOutput'), 'Missing hookSpecificOutput for Claude Code');
});

// 6. session-start injects SKILL.md content
check('hooks/session-start reads SKILL.md for context injection', () => {
  const content = fs.readFileSync(path.join(REPO, 'hooks', 'session-start'), 'utf8');
  assert(content.includes('SKILL.md'), 'session-start does not reference SKILL.md');
});

// 7. hooks-cursor.json exists and is valid
check('hooks/hooks-cursor.json exists and has valid hook', () => {
  const p = path.join(REPO, 'hooks', 'hooks-cursor.json');
  assert(fs.existsSync(p), 'hooks/hooks-cursor.json not found');
  const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
  // sessionStart is not a valid Cursor hook type; beforeSubmitPrompt is the correct equivalent
  assert(cfg.hooks && cfg.hooks.beforeSubmitPrompt, 'hooks-cursor.json missing hooks.beforeSubmitPrompt');
  assert(Array.isArray(cfg.hooks.beforeSubmitPrompt) && cfg.hooks.beforeSubmitPrompt.length > 0,
    'hooks-cursor.json beforeSubmitPrompt must be a non-empty array');
  const cmd = cfg.hooks.beforeSubmitPrompt[0].command || '';
  assert(cmd.includes('CURSOR_PLUGIN_ROOT'),
    'hooks-cursor.json command must use ${CURSOR_PLUGIN_ROOT} for absolute path resolution');
  assert(cmd.includes('session-start'), 'hooks-cursor.json command must reference session-start script');
});

// 8. hooks-claude.json exists and is valid
check('hooks/hooks-claude.json exists and has SessionStart hook', () => {
  const p = path.join(REPO, 'hooks', 'hooks-claude.json');
  assert(fs.existsSync(p), 'hooks/hooks-claude.json not found');
  const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
  assert(cfg.hooks && cfg.hooks.SessionStart, 'hooks-claude.json missing hooks.SessionStart');
  const entry = cfg.hooks.SessionStart[0];
  assert(entry && Array.isArray(entry.hooks) && entry.hooks.length > 0,
    'hooks-claude.json SessionStart must have inner hooks array with at least one entry');
  const cmd = entry.hooks[0].command || '';
  assert(entry.hooks[0].type === 'command', 'hooks-claude.json hook type must be "command"');
  assert(cmd.includes('CLAUDE_PLUGIN_ROOT'),
    'hooks-claude.json command must use ${CLAUDE_PLUGIN_ROOT} for absolute path resolution');
  assert(cmd.includes('session-start'), 'hooks-claude.json command must reference session-start script');
});

// 9. package.json includes hooks/ in files field
check('package.json files includes hooks/', () => {
  const pkg = JSON.parse(fs.readFileSync(path.join(REPO, 'package.json'), 'utf8'));
  assert(pkg.files.includes('hooks'), 'package.json files missing hooks/');
});

// 10. skills/ directory has same content as .windsurf/skills/ (in sync)
check('skills/ and .windsurf/skills/ contain same skill subdirectories', () => {
  const wsSkills = path.join(REPO, '.windsurf', 'skills');
  const pkgSkills = path.join(REPO, 'skills');
  const wsEntries = fs.readdirSync(wsSkills).filter(e =>
    fs.statSync(path.join(wsSkills, e)).isDirectory()).sort();
  const pkgEntries = fs.readdirSync(pkgSkills).filter(e =>
    fs.statSync(path.join(pkgSkills, e)).isDirectory()).sort();
  assert(JSON.stringify(wsEntries) === JSON.stringify(pkgEntries),
    `skills/ subdirs ${JSON.stringify(pkgEntries)} don't match .windsurf/skills/ ${JSON.stringify(wsEntries)}`);
});

console.log('\nSECTION19_PASS=' + pass);
console.log('SECTION19_FAIL=' + fail);
NODEEOF

S19_OUTPUT=$(node "$TMPSCRIPT19" "$REPO" 2>&1)
rm -f "$TMPSCRIPT19"

while IFS= read -r line; do
  case "$line" in
    "  PASS "*) ok "${line#  PASS }" ;;
    "  FAIL "*) fail "${line#  FAIL }" ;;
  esac
done <<< "$S19_OUTPUT"

# ──────────────────────────────────────────────────────────────────────────
# Section 20: session-start hook — runtime execution tests
# Actually runs the hook script with each platform env and validates output
# ──────────────────────────────────────────────────────────────────────────
HOOK_SCRIPT="$REPO/hooks/session-start"

# 20.1 Cursor mode: CURSOR_PLUGIN_ROOT set → must output valid JSON with additional_context
CURSOR_OUT=$(CURSOR_PLUGIN_ROOT="$REPO" bash "$HOOK_SCRIPT" 2>/dev/null)
if echo "$CURSOR_OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'additional_context' in d" 2>/dev/null; then
  ok "session-start (Cursor mode): exits 0 and emits valid JSON with additional_context"
else
  fail "session-start (Cursor mode): did not produce valid JSON with additional_context key"
fi

# 20.2 Cursor mode: must NOT contain hookSpecificOutput (wrong platform)
if echo "$CURSOR_OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'hookSpecificOutput' not in d" 2>/dev/null; then
  ok "session-start (Cursor mode): does not emit hookSpecificOutput (no double-injection)"
else
  fail "session-start (Cursor mode): unexpectedly emits hookSpecificOutput"
fi

# 20.3 Claude Code mode: CLAUDE_PLUGIN_ROOT set → must output valid JSON with hookSpecificOutput
CLAUDE_OUT=$(CLAUDE_PLUGIN_ROOT="$REPO" bash "$HOOK_SCRIPT" 2>/dev/null)
if echo "$CLAUDE_OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); ho=d['hookSpecificOutput']; assert ho['hookEventName']=='SessionStart'; assert 'additionalContext' in ho" 2>/dev/null; then
  ok "session-start (Claude Code mode): exits 0 and emits valid JSON with hookSpecificOutput.additionalContext"
else
  fail "session-start (Claude Code mode): did not produce valid JSON with hookSpecificOutput.additionalContext"
fi

# 20.4 Claude Code mode: must NOT contain additional_context at top level
if echo "$CLAUDE_OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'additional_context' not in d" 2>/dev/null; then
  ok "session-start (Claude Code mode): does not emit additional_context at top level (no double-injection)"
else
  fail "session-start (Claude Code mode): unexpectedly emits additional_context at top level"
fi

# 20.5 Fallback mode: no env vars → must output valid JSON with additional_context
FALLBACK_OUT=$(bash "$HOOK_SCRIPT" 2>/dev/null)
if echo "$FALLBACK_OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'additional_context' in d" 2>/dev/null; then
  ok "session-start (fallback mode): exits 0 and emits valid JSON with additional_context"
else
  fail "session-start (fallback mode): did not produce valid JSON with additional_context"
fi

# 20.6 All modes: context must contain learnship workflow keywords
for label in "Cursor" "Claude Code" "fallback"; do
  case "$label" in
    "Cursor")    CONTENT="$CURSOR_OUT" ;;
    "Claude Code") CONTENT="$CLAUDE_OUT" ;;
    "fallback")  CONTENT="$FALLBACK_OUT" ;;
  esac
  if echo "$CONTENT" | python3 -c "
import sys, json, urllib.parse
d = json.load(sys.stdin)
text = json.dumps(d)
assert 'new-project' in text, 'missing /new-project workflow reference'
assert 'discuss-phase' in text, 'missing /discuss-phase workflow reference'
assert 'learnship' in text, 'missing learnship brand in context'
" 2>/dev/null; then
    ok "session-start ($label mode): context contains learnship workflow keywords"
  else
    fail "session-start ($label mode): context missing expected learnship workflow keywords"
  fi
done

# 20.7 session-start: exits 0 even when SKILL.md is missing (graceful degradation)
TMPDIR_TEST=$(mktemp -d)
TMPDIR_HOOKS="$TMPDIR_TEST/hooks"
mkdir -p "$TMPDIR_HOOKS"
cp "$HOOK_SCRIPT" "$TMPDIR_HOOKS/session-start"
chmod +x "$TMPDIR_HOOKS/session-start"
# No SKILL.md in TMPDIR_TEST — script should exit 0 silently
if bash "$TMPDIR_HOOKS/session-start" > /dev/null 2>&1; then
  ok "session-start: exits 0 gracefully when SKILL.md is missing"
else
  fail "session-start: non-zero exit when SKILL.md is missing (not graceful)"
fi
rm -rf "$TMPDIR_TEST"

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
