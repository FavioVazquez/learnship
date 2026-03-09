---
phase: [N]
status: pending
created: [YYYY-MM-DD]
---

# Phase [N] UAT: [Phase Name]

User acceptance test session for Phase [N]. Each scenario is walked through manually, issues logged with severity, and fix plans created for any blockers or majors.

---

## Test Scenarios

### Scenario 1: [Scenario Name]

**Expected behavior:**
[What should happen when the user does X]

**Steps:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Result:** [ ] Pass  [ ] Skip  [ ] Issue

**Notes:** _

---

### Scenario 2: [Scenario Name]

**Expected behavior:**
[What should happen]

**Steps:**
1. [Step 1]
2. [Step 2]

**Result:** [ ] Pass  [ ] Skip  [ ] Issue

**Notes:** _

---

## Issues Found

### Issue 1: [Short description]

**Severity:** blocker | major | minor | polish

**Scenario:** [Which scenario]

**What happened:** [Actual behavior observed]

**Expected:** [What should have happened]

**Root cause:**
```yaml
root_cause: "[description]"
affected_files:
  - "[file path]"
fix_approach: "[description of fix]"
confidence: high | medium | low
```

**Status:** open | fixed | deferred

---

## Summary

**Scenarios tested:** [N]
**Passed:** [N]
**Skipped:** [N]
**Issues:** [N] ([X] blockers, [Y] majors, [Z] minors)

**Overall verdict:** passed | issues_found | blocked

**Fix phases needed:** [yes/no — list if yes]
