#!/usr/bin/env bash
# learnship — v2.4.0 feature validation tests
#
# Verifies the four new v2.4.0 features are properly implemented
# and in sync across all platforms:
#
#   1. Two-stage review (spec compliance + quality passes)
#   2. OWASP Top 10 in security-auditor
#   3. Numeric health score (0–100)
#   4. Playwright MCP guidance in verify-work + ship

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_WF="$REPO_DIR/learnship/workflows"
SRC_AG="$REPO_DIR/learnship/agents"
WS_WF="$REPO_DIR/.windsurf/workflows"
WS_AG="$REPO_DIR/.windsurf/learnship/agents"
CLAUDE_AG="$REPO_DIR/agents"
CURSOR_MDC="$REPO_DIR/cursor-rules/learnship.mdc"
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

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " v2.4.0 Feature Validation"
echo "═══════════════════════════════════════════════════════════════════"

# ─── 1. Two-Stage Review ──────────────────────────────────────────────
echo ""
echo "─── Two-Stage Review ─────────────────────────────────────────────"

check "review.md: has Pass 1 spec compliance section" \
  grep -q "Pass 1.*Spec Compliance" "$SRC_WF/review.md"

check "review.md: has --quality-only flag" \
  grep -q "\-\-quality-only" "$SRC_WF/review.md"

check "review.md: classifies deliverables as COVERED/PARTIAL/MISSING" \
  grep -q "COVERED\|PARTIAL\|MISSING" "$SRC_WF/review.md"

check "review.md: has spec compliance gate question (AskUserQuestion)" \
  grep -q "Spec Gap" "$SRC_WF/review.md"

check "review.md: Pass 2 quality review present" \
  grep -q "Pass 2" "$SRC_WF/review.md"

check "review.md: spec compliance shown in report header" \
  grep -q "Spec compliance:" "$SRC_WF/review.md"

check "review.md: step renumbering — Step 3 is spec compliance" \
  grep -q "## Step 3: Pass 1" "$SRC_WF/review.md"

check "review.md: step renumbering — Step 9 is suggest next steps" \
  grep -q "## Step 9" "$SRC_WF/review.md"

# Windsurf sync — windsurf uses ask_user_question (not AskUserQuestion), so not byte-identical
check "windsurf review.md: has spec compliance pass" \
  grep -q "Pass 1.*Spec Compliance\|Spec.*Compliance" "$WS_WF/review.md"
check "windsurf review.md: uses ask_user_question (not AskUserQuestion)" \
  bash -c '! grep -q "AskUserQuestion" "$1"' _ "$WS_WF/review.md"

# Cursor rules updated
check "cursor rules: review command description updated for spec compliance" \
  grep -q "spec compliance pass" "$CURSOR_MDC"

# Installed output — review.md must have two-stage content on all platforms
TMPREV=$(mktemp -d)
for platform in windsurf claude opencode gemini codex; do
  mkdir -p "$TMPREV/$platform"
  node "$REPO_DIR/bin/install.js" "--$platform" --target "$TMPREV/$platform" > /dev/null 2>&1
done

check "installed review.md (windsurf): has spec compliance pass" \
  grep -q "Spec Compliance" "$TMPREV/windsurf/workflows/review.md"
for platform in claude opencode gemini codex; do
  check "installed review.md ($platform): has spec compliance pass" \
    grep -rq "Spec Compliance" "$TMPREV/$platform/learnship/workflows/review.md" 2>/dev/null
done

rm -rf "$TMPREV"

# ─── 2. OWASP Top 10 ─────────────────────────────────────────────────
echo ""
echo "─── OWASP Top 10 in Security Auditor ────────────────────────────"

# All 10 OWASP categories must be present in security-auditor.md
for cat in A01 A02 A03 A04 A05 A06 A07 A08 A09 A10; do
  check "security-auditor.md: contains $cat" \
    grep -q "$cat" "$SRC_AG/security-auditor.md"
done

check "security-auditor.md: has OWASP Top 10 (2021) heading" \
  grep -q "OWASP Top 10" "$SRC_AG/security-auditor.md"

check "security-auditor.md: maps OWASP to STRIDE" \
  grep -q "STRIDE" "$SRC_AG/security-auditor.md"

check "security-auditor.md: requires OWASP coverage table in output" \
  grep -q "OWASP coverage table" "$SRC_AG/security-auditor.md"

# Windsurf sync
check "windsurf security-auditor.md: contains OWASP" \
  grep -q "OWASP Top 10" "$WS_AG/security-auditor.md"

check "windsurf security-auditor.md: identical to source" \
  diff -q "$SRC_AG/security-auditor.md" "$WS_AG/security-auditor.md"

# Claude Code agent wrapper
check "agents/learnship-security-auditor.md: contains OWASP Top 10" \
  grep -q "OWASP Top 10" "$CLAUDE_AG/learnship-security-auditor.md"

for cat in A01 A02 A03 A04 A05 A06 A07 A08 A09 A10; do
  check "learnship-security-auditor.md wrapper: contains $cat" \
    grep -q "$cat" "$CLAUDE_AG/learnship-security-auditor.md"
done

# secure-phase workflow references OWASP
check "secure-phase.md: references OWASP" \
  grep -q "OWASP" "$SRC_WF/secure-phase.md"

check "windsurf secure-phase.md: references OWASP" \
  grep -q "OWASP" "$WS_WF/secure-phase.md"

# Installed output — security-auditor must have OWASP on all platforms
TMPSEC=$(mktemp -d)
for platform in windsurf claude opencode gemini codex; do
  mkdir -p "$TMPSEC/$platform"
  node "$REPO_DIR/bin/install.js" "--$platform" --target "$TMPSEC/$platform" > /dev/null 2>&1
done

check "installed security-auditor (windsurf): has OWASP" \
  grep -rq "OWASP" "$TMPSEC/windsurf/learnship/agents/security-auditor.md" 2>/dev/null
for platform in claude opencode gemini codex; do
  check "installed security-auditor ($platform): has OWASP" \
    grep -rq "OWASP" "$TMPSEC/$platform/learnship/agents/security-auditor.md" 2>/dev/null
done

# cursor rules updated for secure-phase
check "cursor rules: secure-phase updated to mention OWASP" \
  grep -q "OWASP" "$CURSOR_MDC"

rm -rf "$TMPSEC"

# ─── 3. Numeric Health Score ──────────────────────────────────────────
echo ""
echo "─── Numeric Health Score ─────────────────────────────────────────"

check "health.md: has Score computation step" \
  grep -q "Compute Health Score" "$SRC_WF/health.md"

check "health.md: starts at 100 points" \
  grep -q "Start at 100" "$SRC_WF/health.md"

check "health.md: has deduction table with error codes" \
  grep -q "E002\|E003\|E004" "$SRC_WF/health.md"

check "health.md: has W004 deduction" \
  grep -q "W004" "$SRC_WF/health.md"

check "health.md: has score formula (max 0)" \
  grep -q "max(0" "$SRC_WF/health.md"

check "health.md: has HEALTHY band (90-100)" \
  grep -q "90.*100.*HEALTHY\|90–100" "$SRC_WF/health.md"

check "health.md: has DEGRADED band (70-89)" \
  grep -q "70.*89.*DEGRADED\|70–89" "$SRC_WF/health.md"

check "health.md: has BROKEN band (0-69)" \
  grep -q "0.*69.*BROKEN\|0–69" "$SRC_WF/health.md"

check "health.md: output format shows Score: [N]/100" \
  grep -q "Score:.*100" "$SRC_WF/health.md"

check "health.md: repair footer shows score impact" \
  grep -q "points" "$SRC_WF/health.md"

# Windsurf sync
check "windsurf health.md: identical to source" \
  diff -q "$SRC_WF/health.md" "$WS_WF/health.md"

# Cursor rules updated
check "cursor rules: health command mentions numeric score" \
  grep -q "score\|0.*100" "$CURSOR_MDC"

# Installed output — health.md must have score on all platforms
TMPHEALTH=$(mktemp -d)
for platform in windsurf claude opencode gemini codex; do
  mkdir -p "$TMPHEALTH/$platform"
  node "$REPO_DIR/bin/install.js" "--$platform" --target "$TMPHEALTH/$platform" > /dev/null 2>&1
done

check "installed health.md (windsurf): has numeric score" \
  grep -q "Score:" "$TMPHEALTH/windsurf/workflows/health.md"
for platform in claude opencode gemini codex; do
  check "installed health.md ($platform): has numeric score" \
    grep -rq "Score:" "$TMPHEALTH/$platform/learnship/workflows/health.md" 2>/dev/null
done

rm -rf "$TMPHEALTH"

# ─── 4. Playwright MCP Guidance ──────────────────────────────────────
echo ""
echo "─── Playwright MCP Guidance ──────────────────────────────────────"

# verify-work.md
check "verify-work.md: has Playwright MCP section" \
  grep -q "Playwright MCP" "$SRC_WF/verify-work.md"

check "verify-work.md: references @playwright/mcp package" \
  grep -q "@playwright/mcp" "$SRC_WF/verify-work.md"

check "verify-work.md: references mcp__playwright__ tools" \
  grep -q "mcp__playwright__" "$SRC_WF/verify-work.md"

check "verify-work.md: has golden path step" \
  grep -q "golden path" "$SRC_WF/verify-work.md"

check "verify-work.md: has platform support note (all 6 platforms)" \
  grep -q "Claude Code, OpenCode, Cursor, Windsurf" "$SRC_WF/verify-work.md"

check "verify-work.md: explains how to configure MCP" \
  grep -q "claude mcp add" "$SRC_WF/verify-work.md"

# ship.md
check "ship.md: has Playwright smoke test section before PR" \
  grep -q "Playwright MCP\|Smoke Test" "$SRC_WF/ship.md"

check "ship.md: checks server is running before smoke test" \
  grep -q "curl.*http_code\|not-running" "$SRC_WF/ship.md"

check "ship.md: stops ship if smoke test fails" \
  grep -q "Stop the ship pipeline\|stop.*ship\|smoke test fails" "$SRC_WF/ship.md"

# Windsurf sync
check "windsurf verify-work.md: identical to source" \
  diff -q "$SRC_WF/verify-work.md" "$WS_WF/verify-work.md"

check "windsurf ship.md: identical to source" \
  diff -q "$SRC_WF/ship.md" "$WS_WF/ship.md"

# Installed output — Playwright guidance must appear on all platforms
TMPPLAY=$(mktemp -d)
for platform in windsurf claude opencode gemini codex; do
  mkdir -p "$TMPPLAY/$platform"
  node "$REPO_DIR/bin/install.js" "--$platform" --target "$TMPPLAY/$platform" > /dev/null 2>&1
done

check "installed verify-work.md (windsurf): has Playwright guidance" \
  grep -q "Playwright" "$TMPPLAY/windsurf/workflows/verify-work.md"
check "installed ship.md (windsurf): has smoke test guidance" \
  grep -q "Smoke Test\|smoke test" "$TMPPLAY/windsurf/workflows/ship.md"
for platform in claude opencode gemini codex; do
  check "installed verify-work.md ($platform): has Playwright guidance" \
    grep -rq "Playwright" "$TMPPLAY/$platform/learnship/workflows/verify-work.md" 2>/dev/null
  check "installed ship.md ($platform): has smoke test guidance" \
    grep -rq "Smoke Test\|smoke test" "$TMPPLAY/$platform/learnship/workflows/ship.md" 2>/dev/null
done

rm -rf "$TMPPLAY"

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
