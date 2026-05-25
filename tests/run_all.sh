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
run_suite "UX Entry Points"       "$TESTS_DIR/validate_ux.sh"
run_suite "Multi-Platform"        "$TESTS_DIR/validate_multiplatform.sh"
run_suite "new-project Workflow"  "$TESTS_DIR/validate_new_project.sh"
run_suite "Cross-Platform Install" "$TESTS_DIR/validate_cross_platform.sh"
run_suite "Regressions"           "$TESTS_DIR/validate_regressions.sh"
run_suite "All-Workflows"         "$TESTS_DIR/validate_all_workflows.sh"
run_suite "Deep Integrity"        "$TESTS_DIR/validate_integrity.sh"
run_suite "Security"              "$TESTS_DIR/validate_security.sh"
run_suite "Learnship Features"   "$TESTS_DIR/validate_learnship_features.sh"
run_suite "Simulations"          "$TESTS_DIR/validate_simulations.sh"
run_suite "Hooks & Commands"     "$TESTS_DIR/validate_hooks_and_commands.sh"
run_suite "Platform-Specific"    "$TESTS_DIR/validate_platform_specific.sh"
run_suite "v2.4.0 Features"      "$TESTS_DIR/validate_v240_features.sh"

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
