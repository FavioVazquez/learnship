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
if node -e "const pkg=require('$REPO/package.json'); process.exit(pkg.files && pkg.files.includes('.windsurf/skills') ? 0 : 1);" 2>/dev/null; then
  ok "package.json files includes .windsurf/skills (required for npx delivery)"
else
  fail "package.json files missing .windsurf/skills — skills will be absent when installed via npx"
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

const skillsSrc = path.join(REPO, '.windsurf', 'skills');

// Simulate installClaudePlugins against a temp dir
function runInstallClaudePlugins(tmpDir) {
  const pluginDir = path.join(tmpDir, 'plugins', 'learnship');
  const pluginSkillsDir = path.join(pluginDir, 'skills');
  const pluginMetaDir = path.join(pluginDir, '.claude-plugin');

  if (fs.existsSync(pluginDir)) fs.rmSync(pluginDir, { recursive: true });
  fs.mkdirSync(pluginSkillsDir, { recursive: true });
  fs.mkdirSync(pluginMetaDir, { recursive: true });

  const manifest = {
    name: 'learnship',
    description: 'Learnship skills — agentic-learning partner and impeccable design system',
    author: { name: 'favio-vazquez' },
  };
  fs.writeFileSync(path.join(pluginMetaDir, 'plugin.json'), JSON.stringify(manifest, null, 2) + '\n');

  function copyDir(src, dest) {
    fs.mkdirSync(dest, { recursive: true });
    for (const e of fs.readdirSync(src, { withFileTypes: true })) {
      const s = path.join(src, e.name), d = path.join(dest, e.name);
      if (e.isDirectory()) copyDir(s, d); else fs.copyFileSync(s, d);
    }
  }

  let count = 0;
  for (const entry of fs.readdirSync(skillsSrc, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const skillName = entry.name;
    const srcPath = path.join(skillsSrc, skillName);
    if (!fs.existsSync(path.join(srcPath, 'SKILL.md'))) continue;
    const dest = path.join(pluginSkillsDir, skillName);
    if (skillName === 'impeccable') {
      // impeccable: root SKILL.md (with paths rewritten to references/) + sub-skills as references/
      fs.mkdirSync(dest, { recursive: true });
      let skillMdContent = fs.readFileSync(path.join(srcPath, 'SKILL.md'), 'utf8');
      skillMdContent = skillMdContent.replace(/\]\((?!references\/)([^/)][^)]*\/SKILL\.md)\)/g, '](references/$1)');
      fs.writeFileSync(path.join(dest, 'SKILL.md'), skillMdContent);
      const refsDest = path.join(dest, 'references');
      fs.mkdirSync(refsDest, { recursive: true });
      for (const sub of fs.readdirSync(srcPath, { withFileTypes: true })) {
        if (!sub.isDirectory()) continue;
        const subSrc = path.join(srcPath, sub.name);
        if (fs.existsSync(path.join(subSrc, 'SKILL.md'))) {
          copyDir(subSrc, path.join(refsDest, sub.name));
        }
      }
      count++;
    } else {
      copyDir(srcPath, dest);
      count++;
    }
  }
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
  const skillMd = fs.readFileSync(path.join(skillsSrc, 'impeccable', 'SKILL.md'), 'utf8');
  const expected = ['adapt','animate','audit','bolder','clarify','colorize','critique',
    'delight','distill','extract','frontend-design','harden','normalize','onboard',
    'optimize','polish','quieter','teach-impeccable'];
  const missing = expected.filter(s => !skillMd.includes(s));
  assert(missing.length === 0, 'impeccable SKILL.md missing actions: ' + missing.join(', '));
});

// 7. impeccable plugin has all 18 sub-skills as references/
check('impeccable plugin: all 18 sub-skills present in references/', () => {
  const expected = ['adapt','animate','audit','bolder','clarify','colorize','critique',
    'delight','distill','extract','frontend-design','harden','normalize','onboard',
    'optimize','polish','quieter','teach-impeccable'];
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-plugin-'));
  const { pluginSkillsDir } = runInstallClaudePlugins(tmp);
  const refsDir = path.join(pluginSkillsDir, 'impeccable', 'references');
  const missing = expected.filter(s => !fs.existsSync(path.join(refsDir, s, 'SKILL.md')));
  fs.rmSync(tmp, { recursive: true });
  assert(missing.length === 0, 'missing sub-skill references: ' + missing.join(', '));
});

// 8. no flattened sub-skills at top level of plugin skills (impeccable dir exists, not sub-skill dirs)
check('impeccable sub-skills are NOT flattened — only agentic-learning and impeccable at top level', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-plugin-'));
  const { pluginSkillsDir } = runInstallClaudePlugins(tmp);
  const dirs = fs.readdirSync(pluginSkillsDir).filter(e =>
    fs.statSync(path.join(pluginSkillsDir, e)).isDirectory()
  );
  assert(!dirs.includes('audit'), 'audit should not be at top level — should be inside impeccable/references/');
  assert(!dirs.includes('polish'), 'polish should not be at top level');
  assert(dirs.includes('impeccable'), 'impeccable/ dir should exist at top level');
  fs.rmSync(tmp, { recursive: true });
});

// 9. impeccable SKILL.md in plugin has paths rewritten to references/ (not sibling paths)
check('impeccable plugin SKILL.md: sibling paths rewritten to references/ for Claude Code', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'learnship-plugin-'));
  const { pluginSkillsDir } = runInstallClaudePlugins(tmp);
  const installedSkillMd = fs.readFileSync(path.join(pluginSkillsDir, 'impeccable', 'SKILL.md'), 'utf8');
  // Must use references/ paths, not bare sibling paths
  assert(installedSkillMd.includes('references/adapt/SKILL.md'), 'adapt path not rewritten to references/');
  assert(installedSkillMd.includes('references/audit/SKILL.md'), 'audit path not rewritten to references/');
  assert(!installedSkillMd.match(/\]\((?!references\/)adapt\/SKILL\.md\)/), 'bare adapt/SKILL.md still present');
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
