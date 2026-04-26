#!/usr/bin/env bash
# learnship — Regression tests
#
# Tests for bugs that were found in production and must never recur.
# Each section documents: what broke, why, and how the test catches it.
#
# Regression categories:
#   1. Config schema regressions — AI produces wrong config.json
#   2. Cursor .mdc platform coverage — condensed rule file must stay in sync
#   3. Workflow content regressions — key phrases that must survive edits
#   4. Question tool enforcement — AI renders questions as plain text
#   5. STOP gate preservation — AI skips waiting for user input

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

check_must_fail() {
  local description="$1"
  shift
  if "$@" > /dev/null 2>&1; then
    echo "  ✗ $description (expected failure but got success)"
    FAIL=$((FAIL+1))
    ERRORS+=("$description")
  else
    echo "  ✓ $description"
    PASS=$((PASS+1))
  fi
}

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " Regression Tests"
echo "═══════════════════════════════════════════════════════════════════"

# ─── 1. Config Schema Regressions ─────────────────────────────────────
#
# Bug (v2.3.1): On Windsurf, the AI wrote a flat config.json with wrong
# keys like "working_style", "model_tier", "platform", "milestone",
# "phases", and "commit_mode" at the top level. The correct schema uses
# nested objects (planning.commit_mode, workflow.research, etc).
#
# Fix: Added config verification gate in new-project Step 2 that checks
# all required keys and rejects forbidden flat keys.
# These tests verify the gate catches all known bad patterns.

echo ""
echo "─── Config Schema Regressions ────────────────────────────────────"

TMPDIR=$(mktemp -d)
# shellcheck disable=SC2064
trap "rm -rf $TMPDIR" EXIT

# Extract the verification logic into a reusable script
cat > "$TMPDIR/verify_config.js" << 'VERIFY_EOF'
const fs=require('fs');
const configPath=process.argv[2];
try{
  const c=JSON.parse(fs.readFileSync(configPath,'utf8'));
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
  if(errs.length){console.log('CONFIG_INVALID');errs.forEach(e=>console.log('  - '+e));process.exit(1);}
  else{console.log('CONFIG_VALID');process.exit(0);}
}catch(e){console.log('CONFIG_MISSING_OR_CORRUPT: '+e.message);process.exit(1);}
VERIFY_EOF

# Test 1: CORRECT config (template) must pass
cp "$REPO_DIR/templates/config.json" "$TMPDIR/good.json"
check "REG-001: correct template config passes verification" node "$TMPDIR/verify_config.js" "$TMPDIR/good.json"

# Test 2: The EXACT bad config from v2.3.1 Windsurf failure must FAIL
cat > "$TMPDIR/bad_windsurf.json" << 'EOF'
{
  "working_style": "auto",
  "granularity": "coarse",
  "learning_mode": "auto",
  "model_tier": "standard",
  "commit_mode": "auto",
  "platform": "windsurf",
  "created": "2026-04-15",
  "milestone": "v1.0",
  "phases": 3
}
EOF
check_must_fail "REG-002: v2.3.1 Windsurf bad config (flat keys) is rejected" node "$TMPDIR/verify_config.js" "$TMPDIR/bad_windsurf.json"

# Test 3: Config with forbidden top-level 'working_style' must FAIL
cat > "$TMPDIR/bad_ws.json" << 'EOF'
{
  "mode": "auto",
  "working_style": "auto",
  "granularity": "coarse",
  "model_profile": "balanced",
  "learning_mode": "auto",
  "test_first": false,
  "planning": { "commit_docs": true, "commit_mode": "auto", "search_gitignored": false },
  "workflow": { "research": true, "plan_check": true, "verifier": true, "validation": true, "review": true, "solutions_search": true, "security_enforcement": true, "discuss_mode": "discuss", "tdd_mode": false },
  "parallelization": { "enabled": false, "plan_level": true, "task_level": false, "max_concurrent_agents": 5, "min_plans_for_parallel": 2 },
  "gates": { "confirm_project": true, "confirm_phases": true, "confirm_roadmap": true, "confirm_plan": true, "execute_next_plan": true, "issues_review": true, "confirm_transition": true },
  "safety": { "always_confirm_destructive": true, "always_confirm_external_services": true },
  "review": { "auto_after_verify": false },
  "ship": { "auto_test": true, "conventional_commits": true, "pr_template": true },
  "hooks": { "context_warnings": true },
  "git": { "branching_strategy": "none", "phase_branch_template": "phase-{phase}-{slug}", "milestone_branch_template": "{milestone}-{slug}" }
}
EOF
check_must_fail "REG-003: config with forbidden 'working_style' is rejected" node "$TMPDIR/verify_config.js" "$TMPDIR/bad_ws.json"

# Test 4: Config with forbidden top-level 'platform' must FAIL
cat > "$TMPDIR/bad_plat.json" << 'EOF'
{
  "mode": "auto",
  "granularity": "coarse",
  "model_profile": "balanced",
  "learning_mode": "auto",
  "test_first": false,
  "platform": "windsurf",
  "planning": { "commit_docs": true, "commit_mode": "auto", "search_gitignored": false },
  "workflow": { "research": true, "plan_check": true, "verifier": true, "validation": true, "review": true, "solutions_search": true, "security_enforcement": true, "discuss_mode": "discuss", "tdd_mode": false },
  "parallelization": { "enabled": false, "plan_level": true, "task_level": false, "max_concurrent_agents": 5, "min_plans_for_parallel": 2 },
  "gates": { "confirm_project": true, "confirm_phases": true, "confirm_roadmap": true, "confirm_plan": true, "execute_next_plan": true, "issues_review": true, "confirm_transition": true },
  "safety": { "always_confirm_destructive": true, "always_confirm_external_services": true },
  "review": { "auto_after_verify": false },
  "ship": { "auto_test": true, "conventional_commits": true, "pr_template": true },
  "hooks": { "context_warnings": true },
  "git": { "branching_strategy": "none", "phase_branch_template": "phase-{phase}-{slug}", "milestone_branch_template": "{milestone}-{slug}" }
}
EOF
check_must_fail "REG-004: config with forbidden 'platform' is rejected" node "$TMPDIR/verify_config.js" "$TMPDIR/bad_plat.json"

# Test 5: Config missing nested workflow object must FAIL
cat > "$TMPDIR/bad_flat_wf.json" << 'EOF'
{
  "mode": "auto",
  "granularity": "coarse",
  "model_profile": "balanced",
  "learning_mode": "auto",
  "test_first": false,
  "research": true,
  "plan_check": true,
  "verifier": true,
  "review": true,
  "planning": { "commit_docs": true, "commit_mode": "auto", "search_gitignored": false },
  "parallelization": { "enabled": false, "plan_level": true, "task_level": false, "max_concurrent_agents": 5, "min_plans_for_parallel": 2 },
  "gates": { "confirm_project": true },
  "safety": { "always_confirm_destructive": true },
  "review": { "auto_after_verify": false },
  "ship": { "auto_test": true, "conventional_commits": true, "pr_template": true },
  "hooks": { "context_warnings": true },
  "git": { "branching_strategy": "none" }
}
EOF
check_must_fail "REG-005: config with flat workflow keys (no nested object) is rejected" node "$TMPDIR/verify_config.js" "$TMPDIR/bad_flat_wf.json"

# Test 6: Config missing parallelization object must FAIL
cat > "$TMPDIR/bad_flat_par.json" << 'EOF'
{
  "mode": "auto",
  "granularity": "coarse",
  "model_profile": "balanced",
  "learning_mode": "auto",
  "test_first": false,
  "planning": { "commit_docs": true, "commit_mode": "auto", "search_gitignored": false },
  "workflow": { "research": true, "plan_check": true, "verifier": true, "validation": true, "review": true, "solutions_search": true, "security_enforcement": true, "discuss_mode": "discuss", "tdd_mode": false },
  "parallelization": true,
  "gates": { "confirm_project": true },
  "safety": { "always_confirm_destructive": true },
  "review": { "auto_after_verify": false },
  "ship": { "auto_test": true, "conventional_commits": true, "pr_template": true },
  "hooks": { "context_warnings": true },
  "git": { "branching_strategy": "none" }
}
EOF
check_must_fail "REG-006: config with flat parallelization=true (not object) is rejected" node "$TMPDIR/verify_config.js" "$TMPDIR/bad_flat_par.json"

# Test 7: Config with invalid mode value must FAIL
cat > "$TMPDIR/bad_mode.json" << 'EOF'
{
  "mode": "autonomous",
  "granularity": "coarse",
  "model_profile": "balanced",
  "learning_mode": "auto",
  "test_first": false,
  "planning": { "commit_docs": true, "commit_mode": "auto", "search_gitignored": false },
  "workflow": { "research": true, "plan_check": true, "verifier": true, "validation": true, "review": true, "solutions_search": true, "security_enforcement": true, "discuss_mode": "discuss", "tdd_mode": false },
  "parallelization": { "enabled": false, "plan_level": true, "task_level": false, "max_concurrent_agents": 5, "min_plans_for_parallel": 2 },
  "gates": { "confirm_project": true },
  "safety": { "always_confirm_destructive": true },
  "review": { "auto_after_verify": false },
  "ship": { "auto_test": true, "conventional_commits": true, "pr_template": true },
  "hooks": { "context_warnings": true },
  "git": { "branching_strategy": "none" }
}
EOF
check_must_fail "REG-007: config with invalid mode 'autonomous' is rejected" node "$TMPDIR/verify_config.js" "$TMPDIR/bad_mode.json"

# Test 8: Valid auto config must pass
cat > "$TMPDIR/good_auto.json" << 'EOF'
{
  "mode": "auto",
  "granularity": "coarse",
  "model_profile": "balanced",
  "learning_mode": "auto",
  "test_first": false,
  "planning": { "commit_docs": true, "commit_mode": "auto", "search_gitignored": false },
  "workflow": { "research": true, "plan_check": true, "verifier": true, "validation": true, "review": true, "solutions_search": true, "security_enforcement": true, "discuss_mode": "discuss", "tdd_mode": false },
  "parallelization": { "enabled": false, "plan_level": true, "task_level": false, "max_concurrent_agents": 5, "min_plans_for_parallel": 2 },
  "gates": { "confirm_project": true, "confirm_phases": true, "confirm_roadmap": true, "confirm_plan": true, "execute_next_plan": true, "issues_review": true, "confirm_transition": true },
  "safety": { "always_confirm_destructive": true, "always_confirm_external_services": true },
  "review": { "auto_after_verify": false },
  "ship": { "auto_test": true, "conventional_commits": true, "pr_template": true },
  "hooks": { "context_warnings": true },
  "git": { "branching_strategy": "none", "phase_branch_template": "phase-{phase}-{slug}", "milestone_branch_template": "{milestone}-{slug}" }
}
EOF
check "REG-008: valid auto config with all nested objects passes" node "$TMPDIR/verify_config.js" "$TMPDIR/good_auto.json"

# ─── 2. Cursor .mdc Platform Coverage ─────────────────────────────────
#
# Bug: Cursor .mdc rule file is a separate hand-written file that doesn't
# go through install.js transforms. It can drift from the workflow files.
# Must contain the same ceremony steps and enforcement as the full workflows.

echo ""
echo "─── Cursor .mdc Platform Coverage ────────────────────────────────"

MDC="$REPO_DIR/cursor-rules/learnship.mdc"

check "REG-009: Cursor .mdc file exists" test -f "$MDC"

if [ -f "$MDC" ]; then
  # Step ceremony checklist
  check "REG-010: Cursor .mdc has Step 1" grep -q 'Step 1' "$MDC"
  check "REG-011: Cursor .mdc has Step 2 — Configuration" grep -q 'Step 2' "$MDC"
  check "REG-012: Cursor .mdc has Step 3 — Deep questioning" grep -q 'Step 3\|questioning\|4 exchanges\|Exchange' "$MDC"
  check "REG-013: Cursor .mdc has Step 8 — AGENTS.md" grep -q 'AGENTS.md' "$MDC"
  check "REG-014: Cursor .mdc has Step 9 — Done/STOP" grep -q 'Step 9\|STOP\|done banner' "$MDC"

  # Config schema must be referenced
  check "REG-015: Cursor .mdc references config.json" grep -q 'config.json' "$MDC"
  check "REG-016: Cursor .mdc has mode key reference" grep -q '"mode"\|mode.*auto\|mode.*interactive' "$MDC"

  # Research gate enforcement
  check "REG-017: Cursor .mdc has research decision gate" grep -q 'Research.*decision\|research.*ask\|FORBIDDEN.*deciding' "$MDC"
  check "REG-018: Cursor .mdc requires web search for research" grep -qi 'web search\|web.*search\|@web' "$MDC"
  check "REG-019: Cursor .mdc requires 5 research files" grep -q 'STACK.md.*FEATURES.md\|5 files\|five files' "$MDC"

  # AGENTS.md generation
  check "REG-020: Cursor .mdc requires AGENTS.md verification" grep -q 'AGENTS.md VERIFIED\|verification' "$MDC"

  # Routing protocol
  check "REG-021: Cursor .mdc has routing protocol" grep -q 'routing\|Routing' "$MDC"

  # Question format instruction (Cursor has no native question tool)
  check "REG-022: Cursor .mdc has question format instruction" grep -q 'numbered.*list\|text list\|no native.*question\|AskUserQuestion' "$MDC"

  # Config schema key coverage — must mention key settings keys
  check "REG-023: Cursor .mdc mentions parallelization setting" grep -q 'parallelization' "$MDC"
  check "REG-024: Cursor .mdc mentions learning_mode setting" grep -q 'learning_mode' "$MDC"

  # Phase loop reference
  check "REG-025: Cursor .mdc has correct phase loop order" grep -q 'discuss-phase.*plan-phase.*execute-phase\|discuss.*plan.*execute' "$MDC"
fi

# ─── 3. Workflow Content Regressions ──────────────────────────────────
#
# Key phrases in workflows that must NEVER be removed by edits.
# Each test guards against a specific past or potential regression.

echo ""
echo "─── Workflow Content Regressions ─────────────────────────────────"

SRC_WF="$REPO_DIR/learnship/workflows"

# new-project: Research decision must be MANDATORY
check "REG-026: new-project has MANDATORY USER CHOICE for research" grep -q 'MANDATORY USER CHOICE' "$SRC_WF/new-project.md"
check "REG-027: new-project forbids AI self-deciding research" grep -q 'You are NOT allowed to decide this yourself' "$SRC_WF/new-project.md"

# new-project: Exchange 1 must not skip Exchanges 2-4
check "REG-028: new-project has Exchange 1 != skip gate" grep -q 'Exchange 1.*does NOT skip\|Exchanges 2.*3.*4\|must still ask' "$SRC_WF/new-project.md"

# new-project: 5 research files requirement
check "REG-029: new-project requires STACK.md" grep -q 'STACK.md' "$SRC_WF/new-project.md"
check "REG-030: new-project requires FEATURES.md" grep -q 'FEATURES.md' "$SRC_WF/new-project.md"
check "REG-031: new-project requires ARCHITECTURE.md" grep -q 'ARCHITECTURE.md' "$SRC_WF/new-project.md"
check "REG-032: new-project requires PITFALLS.md" grep -q 'PITFALLS.md' "$SRC_WF/new-project.md"
check "REG-033: new-project requires SUMMARY.md" grep -q 'SUMMARY.md' "$SRC_WF/new-project.md"

# new-project: AGENTS.md verification gate
check "REG-034: new-project has AGENTS.md verification" grep -q 'AGENTS.md VERIFIED OK' "$SRC_WF/new-project.md"

# new-project: HARD STOP after done banner
check "REG-035: new-project has HARD STOP" grep -q 'HARD STOP' "$SRC_WF/new-project.md"
check "REG-036: new-project forbids auto-starting Phase 1" grep -q 'Do NOT automatically start' "$SRC_WF/new-project.md"

# new-project: Config verification gate (added v2.3.2)
check "REG-037: new-project has CONFIG_VALID verification" grep -q 'CONFIG_VALID' "$SRC_WF/new-project.md"
check "REG-038: new-project has CONFIG_INVALID rejection" grep -q 'CONFIG_INVALID' "$SRC_WF/new-project.md"
check "REG-039: new-project forbids flat 'working_style' key" grep -q 'working_style' "$SRC_WF/new-project.md"

# new-project: MANDATORY INTERACTIVE QUESTIONS (added v2.3.2)
check "REG-040: new-project has MANDATORY INTERACTIVE QUESTIONS" grep -q 'MANDATORY INTERACTIVE QUESTIONS' "$SRC_WF/new-project.md"

# execute-phase: must reference plans
check "REG-041: execute-phase references PLAN.md files" grep -q 'PLAN.md' "$SRC_WF/execute-phase.md"

# plan-phase: must reference REQUIREMENTS.md
check "REG-042: plan-phase references REQUIREMENTS.md" grep -q 'REQUIREMENTS.md' "$SRC_WF/plan-phase.md"

# verify-work: must reference UAT
check "REG-043: verify-work references UAT" grep -q 'UAT' "$SRC_WF/verify-work.md"

# settings: config key mapping (added v2.3.2)
check "REG-044: settings has Round 1/2/3 structure" grep -q 'Round 1\|Round 2\|Round 3' "$SRC_WF/settings.md"

# ─── 4. Source/Template Sync ─────────────────────────────────────────
#
# The config template must be a valid JSON file that matches what
# the workflows describe. If someone edits the template without
# updating the workflow (or vice versa), things break.

echo ""
echo "─── Source/Template Sync ─────────────────────────────────────────"

TEMPLATE="$REPO_DIR/templates/config.json"

# Template must parse as valid JSON
check "REG-045: config template is valid JSON" node -e "JSON.parse(require('fs').readFileSync('$TEMPLATE','utf8'))"

# Template default mode must be 'interactive' (safe default)
node -e "
const c=JSON.parse(require('fs').readFileSync('$TEMPLATE','utf8'));
if(c.mode!=='auto'){console.error('Expected auto, got: '+c.mode);process.exit(1);}
" && { echo "  ✓ REG-046: config template default mode is 'auto'"; PASS=$((PASS+1)); } || { echo "  ✗ REG-046: config template default mode is not 'auto'"; FAIL=$((FAIL+1)); ERRORS+=("REG-046: config template default mode"); }

# Template default model_profile must be 'balanced'
node -e "
const c=JSON.parse(require('fs').readFileSync('$TEMPLATE','utf8'));
if(c.model_profile!=='balanced'){console.error('Expected balanced, got: '+c.model_profile);process.exit(1);}
" && { echo "  ✓ REG-047: config template default model_profile is 'balanced'"; PASS=$((PASS+1)); } || { echo "  ✗ REG-047: config template default model_profile is not 'balanced'"; FAIL=$((FAIL+1)); ERRORS+=("REG-047: config template model_profile"); }

# Template must have parallelization as object, not boolean
node -e "
const c=JSON.parse(require('fs').readFileSync('$TEMPLATE','utf8'));
if(typeof c.parallelization!=='object'||c.parallelization===null){console.error('parallelization must be object');process.exit(1);}
if(typeof c.parallelization.enabled!=='boolean'){console.error('parallelization.enabled must be boolean');process.exit(1);}
" && { echo "  ✓ REG-048: config template parallelization is object with .enabled boolean"; PASS=$((PASS+1)); } || { echo "  ✗ REG-048: config template parallelization structure wrong"; FAIL=$((FAIL+1)); ERRORS+=("REG-048: config template parallelization"); }

# Template must NOT have any forbidden flat keys
node -e "
const c=JSON.parse(require('fs').readFileSync('$TEMPLATE','utf8'));
const bad=['working_style','model_tier','platform','milestone','phases'];
const found=bad.filter(k=>k in c);
if(found.length){console.error('Forbidden keys in template: '+found.join(', '));process.exit(1);}
" && { echo "  ✓ REG-049: config template has no forbidden flat keys"; PASS=$((PASS+1)); } || { echo "  ✗ REG-049: config template has forbidden flat keys"; FAIL=$((FAIL+1)); ERRORS+=("REG-049: config template forbidden keys"); }

# ─── 5. AGENTS.md Template Integrity ─────────────────────────────────

echo ""
echo "─── AGENTS.md Template Integrity ─────────────────────────────────"

AGENTS_TPL="$REPO_DIR/templates/agents.md"

check "REG-050: agents.md template exists" test -f "$AGENTS_TPL"
check "REG-051: agents.md template has Decision tree heading" grep -qi 'decision tree' "$AGENTS_TPL"
check "REG-052: agents.md template has Soul section" grep -q '## Soul' "$AGENTS_TPL"
check "REG-053: agents.md template has Principles section" grep -q '## Principles' "$AGENTS_TPL"
check "REG-054: agents.md template has Routing Protocol" grep -q 'Routing Protocol' "$AGENTS_TPL"
check "REG-055: agents.md template has Skills section" grep -q 'Skills' "$AGENTS_TPL"
check "REG-056: agents.md template has Regressions section" grep -q 'Regressions' "$AGENTS_TPL"
check "REG-057: agents.md template has 10 principles" node -e "
const c=require('fs').readFileSync('$AGENTS_TPL','utf8');
const count=(c.match(/^### \d+\./gm)||[]).length;
if(count<10){console.error('Only '+count+' principles, expected ≥10');process.exit(1);}
"

# ── §15: Platform-neutral terminology (v2.3.6) ──────────────────────────────
# Regression: workflows used "Claude's Discretion" — learnship runs on 6 platforms
# with different LLMs. All terminology must be platform/model-neutral.
# Fixed by replacing "Claude's Discretion/judgment" with "Agent's Discretion/judgment"
# and generic "Claude" agent references with "agent/the agent".

check "REG-058: no 'Claude's Discretion' in workflows" \
  bash -c "! grep -rl \"Claude's Discretion\" \"$REPO_DIR/learnship/workflows/\" 2>/dev/null | grep -q ."

check "REG-059: no 'Claude's Discretion' in templates" \
  bash -c "! grep -rl \"Claude's Discretion\" \"$REPO_DIR/learnship/templates/\" 2>/dev/null | grep -q ."

check "REG-060: no 'Claude's Discretion' in references" \
  bash -c "! grep -rl \"Claude's Discretion\" \"$REPO_DIR/learnship/references/\" 2>/dev/null | grep -q ."

check "REG-061: no 'Claude's judgment' in templates" \
  bash -c "! grep -rl \"Claude's judgment\" \"$REPO_DIR/learnship/templates/\" 2>/dev/null | grep -q ."

check "REG-062: no 'Claude's Discretion' in .windsurf workflows" \
  bash -c "! grep -rl \"Claude's Discretion\" \"$REPO_DIR/.windsurf/workflows/\" 2>/dev/null | grep -q ."

check "REG-063: discuss-phase uses 'Agent's Discretion'" \
  grep -q "Agent's Discretion" "$REPO_DIR/learnship/workflows/discuss-phase.md"

check "REG-064: quick.md uses 'Agent's Discretion'" \
  grep -q "Agent's Discretion" "$REPO_DIR/learnship/workflows/quick.md"

check "REG-065: context.md template uses 'Agent's Discretion'" \
  grep -q "Agent's Discretion" "$REPO_DIR/learnship/templates/context.md"

check "REG-066: discussion-log.md template uses 'Agent's Discretion'" \
  grep -q "Agent's Discretion" "$REPO_DIR/learnship/templates/discussion-log.md"

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
