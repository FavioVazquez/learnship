#!/usr/bin/env bash
# learnship — UX surface validation tests
# Checks that the simplified entry-point commands are correctly defined and documented

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOWS_DIR="$REPO_DIR/.windsurf/workflows"
README="$REPO_DIR/README.md"
SKILL="$REPO_DIR/SKILL.md"
PASS=0
FAIL=0
ERRORS=()

check() {
  local description="$1"
  local result="$2"
  if [ "$result" = "0" ]; then
    echo "  ✓ $description"
    PASS=$((PASS+1))
  else
    echo "  ✗ $description"
    FAIL=$((FAIL+1))
    ERRORS+=("$description")
  fi
}

echo ""
echo "─── UX Entry-Point Workflows ───────────────────────────────────────────"

# ls.md exists
echo ""
echo "  Checking ls.md"
[ -f "$WORKFLOWS_DIR/ls.md" ] && r=0 || r=1
check "ls.md exists" "$r"

if [ -f "$WORKFLOWS_DIR/ls.md" ]; then
  # Has frontmatter
  head -1 "$WORKFLOWS_DIR/ls.md" | grep -q "^---" && r=0 || r=1
  check "ls.md has YAML frontmatter" "$r"

  # Description is meaningful
  grep -q "^description:" "$WORKFLOWS_DIR/ls.md" && r=0 || r=1
  check "ls.md has description field" "$r"

  # Contains routing logic (Step 5 or "Run it now")
  grep -qi "run it now\|proceed\|route" "$WORKFLOWS_DIR/ls.md" && r=0 || r=1
  check "ls.md contains routing/run-now logic" "$r"

  # References /new-project for new users
  grep -q "new-project" "$WORKFLOWS_DIR/ls.md" && r=0 || r=1
  check "ls.md handles new-user bootstrap to /new-project" "$r"

  # No unresolved placeholders
  grep -q '{{' "$WORKFLOWS_DIR/ls.md" && r=1 || r=0
  check "ls.md has no unresolved {{placeholders}}" "$r"
fi

echo ""
echo "  Checking next.md"
[ -f "$WORKFLOWS_DIR/next.md" ] && r=0 || r=1
check "next.md exists" "$r"

if [ -f "$WORKFLOWS_DIR/next.md" ]; then
  # Has frontmatter
  head -1 "$WORKFLOWS_DIR/next.md" | grep -q "^---" && r=0 || r=1
  check "next.md has YAML frontmatter" "$r"

  # Description is meaningful
  grep -q "^description:" "$WORKFLOWS_DIR/next.md" && r=0 || r=1
  check "next.md has description field" "$r"

  # Contains auto-routing decision table
  grep -qi "auto\|determine\|automatically\|workflow" "$WORKFLOWS_DIR/next.md" && r=0 || r=1
  check "next.md contains auto-routing logic" "$r"

  # Covers key routing cases
  grep -q "execute-phase\|discuss-phase\|new-project\|audit-milestone" "$WORKFLOWS_DIR/next.md" && r=0 || r=1
  check "next.md covers key routing cases" "$r"

  # No unresolved placeholders
  grep -q '{{' "$WORKFLOWS_DIR/next.md" && r=1 || r=0
  check "next.md has no unresolved {{placeholders}}" "$r"
fi

echo ""
echo "─── README UX Documentation ────────────────────────────────────────────"
echo ""

# README has the 5 commands section
grep -q "5 Commands\|5 commands" "$README" && r=0 || r=1
check "README has '5 commands' section" "$r"

# README mentions /ls
grep -q '`/ls`\|`ls`' "$README" && r=0 || r=1
check "README mentions /ls" "$r"

# README mentions /next
grep -q '`/next`\|`next`' "$README" && r=0 || r=1
check "README mentions /next" "$r"

# README has Mermaid diagram for simple entry surface
grep -q "flowchart LR" "$README" && r=0 || r=1
check "README has Mermaid flowchart (entry surface diagram)" "$r"

# README's Workflow Reference is labelled as advanced
grep -qi "workflow reference.*advanced\|advanced.*workflow reference" "$README" && r=0 || r=1
check "README labels Workflow Reference as Advanced" "$r"

echo ""
echo "─── help.md UX Documentation ───────────────────────────────────────────"
echo ""

# help.md has a Start Here section
grep -qi "## Start Here\|## start here" "$WORKFLOWS_DIR/help.md" && r=0 || r=1
check "help.md has 'Start Here' section" "$r"

# help.md mentions /ls in Start Here table
grep -q '`/ls`' "$WORKFLOWS_DIR/help.md" && r=0 || r=1
check "help.md lists /ls in Start Here table" "$r"

# help.md mentions /next in Start Here table
grep -q '`/next`' "$WORKFLOWS_DIR/help.md" && r=0 || r=1
check "help.md lists /next in Start Here table" "$r"

echo ""
echo "─── progress.md Routing Upgrade ────────────────────────────────────────"
echo ""

# progress.md offers to run next step
grep -qi "run it now\|proceed\|invoke that workflow" "$WORKFLOWS_DIR/progress.md" && r=0 || r=1
check "progress.md offers to run next workflow immediately" "$r"

# progress.md references /next for auto-pilot
grep -q "next" "$WORKFLOWS_DIR/progress.md" && r=0 || r=1
check "progress.md references /next for auto-pilot" "$r"

echo ""
echo "─── SKILL.md UX References ─────────────────────────────────────────────"
echo ""

# SKILL.md references /ls
grep -q '`/ls`\|/ls' "$SKILL" && r=0 || r=1
check "SKILL.md references /ls as primary entry point" "$r"

# SKILL.md references /next
grep -q '`/next`\|/next' "$SKILL" && r=0 || r=1
check "SKILL.md references /next" "$r"

echo ""
echo "─── Results ────────────────────────────────────────────────────────────"
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
