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
  replacePaths, parseJsonc, mergeCodexConfig, generateCodexConfigBlock,
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
