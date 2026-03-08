#!/usr/bin/env bash
# learnship — Run all tests

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERALL_PASS=0
OVERALL_FAIL=0

run_suite() {
  local name="$1"
  local script="$2"

  echo ""
  echo "════════════════════════════════════════════════════════════════════════"
  echo "  Suite: $name"
  echo "════════════════════════════════════════════════════════════════════════"

  if bash "$script"; then
    OVERALL_PASS=$((OVERALL_PASS+1))
  else
    OVERALL_FAIL=$((OVERALL_FAIL+1))
  fi
}

run_suite "Package & Installer"  "$TESTS_DIR/validate_package.sh"
run_suite "Workflow Files"        "$TESTS_DIR/validate_workflows.sh"
run_suite "Skills Structure"      "$TESTS_DIR/validate_skills.sh"

echo ""
echo "════════════════════════════════════════════════════════════════════════"
echo "  OVERALL RESULTS"
echo "════════════════════════════════════════════════════════════════════════"
echo "  Suites passed: $OVERALL_PASS"
echo "  Suites failed: $OVERALL_FAIL"
echo ""

if [ "$OVERALL_FAIL" -eq 0 ]; then
  echo "  ✓ All test suites passed"
  exit 0
else
  echo "  ✗ $OVERALL_FAIL test suite(s) failed"
  exit 1
fi
