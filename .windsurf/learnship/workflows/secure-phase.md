---
description: Per-phase security verification — STRIDE threat register, mitigation check, SECURITY.md generation
---

# Secure Phase

Verify threat mitigations for a completed phase. Reads PLAN.md threat data if present, analyzes the codebase for security concerns, classifies threats, and generates a per-phase SECURITY.md using `@./templates/security.md`.

**Usage:** `secure-phase [N]`

**Sequencing:** Run after `execute-phase [N]` and before or alongside `verify-work [N]`.

## Step 1: Initialize

Read `.planning/config.json` for `workflow.security_enforcement` (defaults to `true`).

If `security_enforcement` is `false`: exit with "Security enforcement disabled. Enable via `/settings`."

Find the phase directory and verify it has been executed (SUMMARY.md exists):

```bash
ls ".planning/phases/[padded_phase]-[phase_slug]/"*-SUMMARY.md 2>/dev/null
```

If no SUMMARY.md: "Phase [N] not executed yet. Run `execute-phase [N]` first."

Display:
```
learnship > SECURE PHASE [N]: [name]
```

## Step 2: Discovery

### 2a. Read Phase Artifacts

Read all PLAN.md files for this phase. Look for `<threat_model>` blocks or security-related task descriptions (auth, encryption, input validation, access control, etc.).

### 2b. Read Summary Threat Flags

Read SUMMARY.md files. Look for any security-related notes, deviations, or flags.

### 2c. Analyze Codebase

Scan files modified in this phase for common security patterns:

```bash
git log --name-only --format="" --grep="([padded_phase]" | sort -u
```

For each file, check for:
- Input validation (or lack thereof)
- Authentication/authorization checks
- Sensitive data handling (secrets, PII, tokens)
- SQL/command injection vectors
- Hardcoded credentials
- Insecure defaults

## Step 3: Build Threat Register

For each identified concern, create a threat entry:

| Field | Value |
|-------|-------|
| Threat ID | T-{phase}-{NN} |
| Category | STRIDE category (Spoofing/Tampering/Repudiation/Info Disclosure/DoS/Elevation) |
| Component | Which file or module |
| Disposition | mitigate / accept / transfer |
| Status | open / closed |

Classify each threat:
- **CLOSED** — mitigation found in code OR accepted risk documented OR transferred to third-party
- **OPEN** — none of the above

## Step 4: Present Threat Plan

If all threats are CLOSED: skip to Step 6.

If open threats exist, present them with a structured question:

Display the threat table first, then:

```
ask_user_question([
  {
    header: "Open Threats",
    question: "[N] open threat(s) found. How do you want to handle them?",
    multiSelect: false,
    options: [
      { label: "Verify all", description: "Investigate and resolve each open threat against the codebase" },
      { label: "Accept all", description: "Document all as accepted risks with rationale" },
      { label: "Review individually", description: "Decide per threat: verify, accept, or skip" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's reply before continuing.

## Step 5: Resolve Open Threats

Read `parallelization` from `.planning/config.json` (defaults to `false`).

**For "Verify all":**

**If `parallelization.enabled` is `true`:**
```
Task(
  subagent_type="learnship-security-auditor",
  description="Security audit phase [N]",
  prompt="
    <agent_definition>
    You are a learnship security auditor. Verify threats against the actual codebase using STRIDE methodology.
    Check each open threat: if mitigation is found in code, mark CLOSED with evidence. If missing, document what's needed.
    Be thorough — check actual code, not just file names. False negatives are worse than false positives.
    </agent_definition>

    <objective>
    Verify all open threats in the threat register for phase [N].
    Check each threat against the actual codebase. Update status to
    CLOSED if mitigation found, or document what's missing.
    </objective>

    <files_to_read>
    - [phase SECURITY.md or threat register]
    </files_to_read>
  "
)
```

**If `parallelization.enabled` is `false`:**
<persona_context>
You are now the **learnship security auditor**. Run STRIDE threat analysis against the codebase.
Check each open threat. Verify mitigations are implemented correctly. Update status based on findings.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[31m  learnship-security-auditor(Run STRIDE threat analysis against the codebase)\033[0m\n\n"
> ```

Read `@./agents/security-auditor.md` for the full persona definition. Check each open threat against the codebase. Update status based on findings.

**For "Accept all":** Add each to the Accepted Risks Log with user's rationale.

**For "Review individually":** Present each threat one at a time:

```
ask_user_question([
  {
    header: "Threat [ID]",
    question: "[Category]: [Description] in [Component]",
    multiSelect: false,
    options: [
      { label: "Verify", description: "Investigate this threat against the codebase" },
      { label: "Accept", description: "Document as accepted risk" },
      { label: "Skip", description: "Leave open for now" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's reply before continuing.

## Step 6: Write SECURITY.md

Write `.planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-SECURITY.md` using `@./templates/security.md`:

- Fill in trust boundaries from the analysis
- Fill in the complete threat register
- Fill in accepted risks log
- Fill in audit trail
- Update frontmatter: `threats_open` count, `status` (draft/verified)

If `threats_open` is 0: set `status: verified`.

Commit:
```bash
git add ".planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-SECURITY.md"
git commit -m "security([padded_phase]): phase security verification"
```

## Step 7: Report

```
learnship > SECURE PHASE [N] COMPLETE

Threats found: [total]
Closed: [N]  |  Accepted: [N]  |  Open: [N]

Status: [verified / needs attention]
Report: [path to SECURITY.md]
```

If open threats remain: warn that the phase has unresolved security concerns.

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:**

> **Learning moment:** Security verification surfaces patterns worth internalizing:
>
> `@agentic-learning learn [security topic]` — Active retrieval on the security concepts encountered. STRIDE categories, common vulnerability patterns, and mitigation strategies build lasting defensive instincts.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning learn [topic]` to deepen security knowledge from this verification."*
