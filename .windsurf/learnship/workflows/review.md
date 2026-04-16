---
description: Multi-persona code review — correctness, testing, security, performance, maintainability
---

# Review

Multi-persona code review that examines changes through six lenses: correctness, testing, security, performance, maintainability, and adversarial. Produces a severity-ranked findings report with confidence scores.

**Usage:** `review` — review current branch changes
**Usage:** `review [mode]` — modes: `interactive` (default), `report-only`, `autofix`

**Sequencing:** Run after `verify-work` (spec compliance) and before `/ship` (deploy pipeline).

## Step 1: Determine Scope

Compute the diff:

```bash
# Detect base branch
BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
[ -z "$BASE_BRANCH" ] && BASE_BRANCH="main"

# Get current branch
CURRENT=$(git rev-parse --abbrev-ref HEAD)

# Compute diff
git fetch origin "$BASE_BRANCH" --quiet 2>/dev/null
BASE=$(git merge-base "origin/$BASE_BRANCH" HEAD 2>/dev/null || echo "origin/$BASE_BRANCH")
echo "FILES:" && git diff --name-only $BASE
echo "DIFF:" && git diff -U10 $BASE
echo "STATS:" && git diff --stat $BASE
```

If no diff found: "Nothing to review — no changes against $BASE_BRANCH." Stop.

## Step 2: Discover Intent

Understand what the change is trying to accomplish:

```bash
echo "BRANCH:" && git rev-parse --abbrev-ref HEAD
echo "COMMITS:" && git log --oneline ${BASE}..HEAD
```

Combined with conversation context and any SUMMARY.md files from the current phase, write a 2-3 line intent summary:

```
Intent: [what the changes are trying to accomplish]
```

## Step 3: Select Personas

Read the diff and file list. Select which review personas to activate:

**Always-on (every review):**

| Persona | Focus |
|---------|-------|
| **correctness** | Logic errors, edge cases, state bugs, error propagation |
| **testing** | Coverage gaps, weak assertions, brittle tests |
| **maintainability** | Coupling, complexity, naming, dead code, abstraction debt |

**Conditional (selected per diff):**

| Persona | Select when diff touches... |
|---------|---------------------------|
| **security** | Auth, public endpoints, user input, permissions, secrets |
| **performance** | DB queries, data transforms, caching, async, loops |
| **adversarial** | Diff ≥50 changed non-test lines, or auth/payments/data mutations |

**Brownfield enhancement:** If `.planning/codebase/CONVENTIONS.md` exists, the maintainability persona reads it for project-specific patterns.

Announce the review team:
```
Review team:
- correctness (always)
- testing (always)
- maintainability (always)
- security — [justification if selected]
- performance — [justification if selected]
- adversarial — [justification if selected]
```

## Step 4: Run Review

Read `parallelization` from `.planning/config.json` (defaults to `false`).

**If `parallelization` is `true` (subagent mode — Claude Code, OpenCode, Codex):**

Spawn a dedicated code-reviewer agent for each selected persona:

```
Task(
  subagent_type="learnship-code-reviewer",
  description="Review: [PERSONA]",
  prompt="
    <agent_definition>
    You are a learnship code reviewer running the [PERSONA] lens.
    Review the diff — do NOT edit any files. Read-only review.
    Return structured findings with severity (P0-P3) and confidence (0.0-1.0).
    Be specific: cite exact files and lines. Distinguish real issues from style preferences.
    </agent_definition>

    <objective>
    Review the following diff as the [PERSONA] reviewer.
    Focus: [persona-specific focus areas]
    Return findings as structured text with severity (P0-P3) and confidence (0.0-1.0).
    Do NOT edit any files. Read-only review.
    </objective>

    <context>
    Intent: [intent summary]
    Files: [file list]
    Diff: [diff content]
    [If maintainability + CONVENTIONS.md exists: include conventions]
    </context>
  "
)
```

Wait for all personas to complete.

**If `parallelization` is `false` (sequential mode):**

<persona_context>
You are now the **learnship code reviewer**. Review code for correctness, testing, security, and performance.
Be specific — cite file:line, explain the issue, propose the fix. Severity: critical/major/minor/nit.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[31m  learnship-code-reviewer(Review code for correctness, testing, security, and performance)\033[0m\n\n"
> ```

Read `@./agents/code-reviewer.md` for the full persona definition. Run each selected persona sequentially. For each persona:

1. Adopt the persona's focus lens
2. Read the diff through that lens
3. Record findings with severity and confidence

## Step 5: Merge & Deduplicate Findings

Combine findings from all personas:

1. **Confidence gate** — suppress findings below 0.60 confidence. Exception: P0 findings at 0.50+ survive.
2. **Deduplicate** — when multiple personas flag the same issue (same file + nearby lines + similar title), merge: keep highest severity, keep highest confidence, note which personas flagged it.
3. **Cross-persona agreement** — when 2+ personas flag the same issue, boost confidence by 0.10 (capped at 1.0).
4. **Sort** — order by severity (P0 first) → confidence (descending) → file path → line number.

## Step 6: Present Report

### Severity Scale

| Level | Meaning | Action |
|-------|---------|--------|
| **P0** | Critical breakage, exploitable vulnerability, data loss | Must fix before merge |
| **P1** | High-impact defect likely hit in normal usage | Should fix |
| **P2** | Moderate issue — edge case, perf regression, maintainability trap | Fix if straightforward |
| **P3** | Low-impact, minor improvement | Discretion |

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► CODE REVIEW COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Intent: [intent summary]
Reviewers: [list]
Mode: [interactive | report-only | autofix]

## Findings

### P0 — Critical
| # | File | Issue | Reviewer(s) | Confidence |
|---|------|-------|-------------|------------|
| 1 | [file:line] | [issue] | [personas] | [0.XX] |

### P1 — High
[table or "None"]

### P2 — Moderate
[table or "None"]

### P3 — Low
[table or "None"]

---

## Verdict

[PASS — no P0/P1 findings]
[PASS WITH CONCERNS — P1 findings present but manageable]
[FAIL — P0 findings must be resolved before merge]

Total: [N] findings ([P0 count] critical, [P1 count] high, [P2 count] moderate, [P3 count] low)
```

## Step 7: Handle Mode

**Interactive (default):**
For each P0/P1 finding, ask: "Fix this now, or defer?"
- **Fix now** → apply the fix, commit
- **Defer** → note in report

**Report-only:**
Display the report. No edits, no commits. Stop.

**Autofix:**
Apply fixes for P0/P1 findings automatically where the fix is deterministic and safe. Commit each fix:
```bash
git add [files]
git commit -m "fix([scope]): [description from finding]"
```

## Step 8: Suggest Next Steps

```
▶ Next steps:
- /secure-phase [N] — STRIDE security verification before shipping
- /ship — run the ship pipeline (test → lint → commit → push → PR)
- /compound — capture any notable patterns from the review
```

---

## Config Options

- `"workflow.review": true` — enable/disable the review workflow
- `"review.auto_after_verify": false` — automatically run review after verify-work passes

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** After review, offer:

> 💡 **Learning moment:** Code review is one of the highest-signal learning activities:
>
> `@agentic-learning learn [finding domain]` — Active retrieval on the concept behind the most significant finding. Why did it happen? How would you catch it earlier?
>
> `@agentic-learning quiz [codebase area]` — Test your understanding of the code area that had the most findings. Gaps in recall predict future bugs.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning learn [domain]` to turn review findings into lasting patterns."*
