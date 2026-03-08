#!/usr/bin/env bash
# learnship — Workflow file validation tests
# Checks that every workflow file has valid YAML frontmatter and required fields


REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOWS_DIR="$REPO_DIR/.windsurf/workflows"
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
echo "─── Workflow File Validation ───────────────────────────────────────────"

# Check workflows directory exists
if [ ! -d "$WORKFLOWS_DIR" ]; then
  echo "FATAL: .windsurf/workflows/ directory not found"
  exit 1
fi

WORKFLOW_COUNT=$(find "$WORKFLOWS_DIR" -name "*.md" | wc -l | tr -d ' ')
echo "  Found $WORKFLOW_COUNT workflow files"
echo ""

# Each workflow must have a YAML frontmatter block with description
MISSING_FRONTMATTER=0
MISSING_DESCRIPTION=0

while IFS= read -r -d '' file; do
  name=$(basename "$file")

  # Check frontmatter opening
  if ! head -1 "$file" | grep -q "^---"; then
    echo "  ✗ Missing frontmatter in: $name"
    MISSING_FRONTMATTER=$((MISSING_FRONTMATTER+1))
    continue
  fi

  # Check description field
  if ! grep -q "^description:" "$file"; then
    echo "  ✗ Missing description: in: $name"
    MISSING_DESCRIPTION=$((MISSING_DESCRIPTION+1))
  fi

done < <(find "$WORKFLOWS_DIR" -name "*.md" -print0)

check "All workflows have YAML frontmatter" "$MISSING_FRONTMATTER"
check "All workflows have description field" "$MISSING_DESCRIPTION"

# Check required core workflows exist
REQUIRED_WORKFLOWS=(
  "new-project.md"
  "plan-phase.md"
  "execute-phase.md"
  "discuss-phase.md"
  "verify-work.md"
  "complete-milestone.md"
  "new-milestone.md"
  "debug.md"
  "quick.md"
  "progress.md"
  "ls.md"
  "next.md"
  "help.md"
  "update.md"
  "health.md"
)

echo ""
echo "─── Required Core Workflows ────────────────────────────────────────────"
MISSING_REQUIRED=0
for wf in "${REQUIRED_WORKFLOWS[@]}"; do
  if [ -f "$WORKFLOWS_DIR/$wf" ]; then
    echo "  ✓ $wf"
    PASS=$((PASS+1))
  else
    echo "  ✗ MISSING: $wf"
    MISSING_REQUIRED=$((MISSING_REQUIRED+1))
    FAIL=$((FAIL+1))
    ERRORS+=("Missing required workflow: $wf")
  fi
done

# Check workflow count is at least 30
echo ""
echo "─── Workflow Count ─────────────────────────────────────────────────────"
if [ "$WORKFLOW_COUNT" -ge 32 ]; then
  echo "  ✓ Workflow count ($WORKFLOW_COUNT) meets minimum (32)"
  PASS=$((PASS+1))
else
  echo "  ✗ Workflow count ($WORKFLOW_COUNT) below minimum (32)"
  FAIL=$((FAIL+1))
  ERRORS+=("Workflow count $WORKFLOW_COUNT < 32")
fi

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
