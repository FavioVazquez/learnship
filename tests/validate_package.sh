#!/usr/bin/env bash
# learnship — Package & installer validation tests

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
echo "─── Package Structure ──────────────────────────────────────────────────"

# Required files exist
REQUIRED_FILES=(
  "package.json"
  "install.sh"
  "bin/learnship.js"
  "README.md"
  "LICENSE"
  "CHANGELOG.md"
  "CONTRIBUTING.md"
  "SKILL.md"
)

for f in "${REQUIRED_FILES[@]}"; do
  if [ -f "$REPO_DIR/$f" ]; then
    echo "  ✓ $f"
    PASS=$((PASS+1))
  else
    echo "  ✗ MISSING: $f"
    FAIL=$((FAIL+1))
    ERRORS+=("Missing required file: $f")
  fi
done

echo ""
echo "─── package.json Validation ────────────────────────────────────────────"

PKG="$REPO_DIR/package.json"

# Valid JSON
if node -e "JSON.parse(require('fs').readFileSync('$PKG','utf8'))" 2>/dev/null; then
  check "package.json is valid JSON" "0"
else
  check "package.json is valid JSON" "1"
fi

# Required fields
for field in name version description license bin; do
  if node -e "const p=JSON.parse(require('fs').readFileSync('$PKG','utf8')); if(!p['$field']) process.exit(1)" 2>/dev/null; then
    check "package.json has '$field' field" "0"
  else
    check "package.json has '$field' field" "1"
  fi
done

# Name matches learnship
PKG_NAME=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$PKG','utf8')).name)" 2>/dev/null)
if [ "$PKG_NAME" = "learnship" ]; then
  check "package name is 'learnship'" "0"
else
  check "package name is 'learnship' (got: $PKG_NAME)" "1"
fi

echo ""
echo "─── install.sh Validation ──────────────────────────────────────────────"

INSTALL="$REPO_DIR/install.sh"

# Bash syntax check
if bash -n "$INSTALL" 2>/dev/null; then
  check "install.sh passes bash syntax check" "0"
else
  check "install.sh passes bash syntax check" "1"
fi

# Has --local flag handling
if grep -qF -- "--local" "$INSTALL"; then
  check "install.sh handles --local flag" "0"
else
  check "install.sh handles --local flag" "1"
fi

# Has --global flag handling
if grep -qF -- "--global" "$INSTALL"; then
  check "install.sh handles --global flag" "0"
else
  check "install.sh handles --global flag" "1"
fi

# Has --uninstall flag handling
if grep -qF -- "--uninstall" "$INSTALL"; then
  check "install.sh handles --uninstall flag" "0"
else
  check "install.sh handles --uninstall flag" "1"
fi

echo ""
echo "─── bin/learnship.js Validation ────────────────────────────────────────"

BIN="$REPO_DIR/bin/learnship.js"

# Node syntax check
if node --check "$BIN" 2>/dev/null; then
  check "bin/learnship.js passes Node.js syntax check" "0"
else
  check "bin/learnship.js passes Node.js syntax check" "1"
fi

# Has shebang
if head -1 "$BIN" | grep -q "^#!/usr/bin/env node"; then
  check "bin/learnship.js has correct shebang" "0"
else
  check "bin/learnship.js has correct shebang" "1"
fi

echo ""
echo "─── Assets ─────────────────────────────────────────────────────────────"

REQUIRED_ASSETS=(
  "assets/banner.png"
  "assets/how-it-works.png"
  "assets/phase-loop.png"
  "assets/agents-md.png"
  "assets/install.png"
  "assets/context-engineering.png"
  "assets/vibe-vs-agentic.png"
  "assets/quick-start-flow.png"
)

for asset in "${REQUIRED_ASSETS[@]}"; do
  if [ -f "$REPO_DIR/$asset" ]; then
    check "$asset present" "0"
  else
    check "$asset present" "1"
  fi
done

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
