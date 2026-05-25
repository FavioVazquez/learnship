---
title: Security & Documentation
description: "Per-phase STRIDE security verification and documentation generation pipeline."
---

# Security & Documentation

Workflows for verifying security posture per phase and generating/updating project documentation grounded in the live codebase.

![Security workflow](../assets/security-workflow.png)

**New in v2.1.0.**

---

## `/secure-phase`

Per-phase security verification using the STRIDE threat model.

```bash
/secure-phase 3             # verify security for phase 3
```

**What it does:**

1. Reads PLAN.md threat data and SUMMARY.md security flags
2. Scans files modified in the phase for common security patterns
3. Builds a STRIDE threat register AND cross-references OWASP Top 10 (A01–A10)
4. Classifies each threat as OPEN or CLOSED
5. Presents open threats for resolution (verify, accept, or review individually)
6. Writes SECURITY.md using the security template

**STRIDE categories:**

| Category | Question |
|----------|----------|
| **S**poofing | Can someone pretend to be someone else? |
| **T**ampering | Can someone modify data they shouldn't? |
| **R**epudiation | Can actions be denied after the fact? |
| **I**nfo Disclosure | Can sensitive data leak? |
| **D**enial of Service | Can the system be made unavailable? |
| **E**levation of Privilege | Can someone gain unauthorized access? |

**OWASP Top 10 (2021) cross-reference:**

Every `/secure-phase` audit now cross-maps STRIDE findings against the OWASP Top 10. The security-auditor agent checks each category for relevance to the phase's changes:

| # | Category | STRIDE mapping |
|---|----------|---------------|
| A01 | Broken Access Control | Elevation |
| A02 | Cryptographic Failures | Info Disclosure |
| A03 | Injection | Tampering |
| A04 | Insecure Design | Spoofing/Tampering/Elevation |
| A05 | Security Misconfiguration | Spoofing/Info Disclosure/Elevation |
| A06 | Vulnerable Components | Tampering/Info Disclosure/Elevation |
| A07 | Auth Failures | Spoofing |
| A08 | Software/Data Integrity | Tampering |
| A09 | Logging/Monitoring Failures | Repudiation |
| A10 | SSRF | Tampering/Info Disclosure |

**Output:** Every `SECURITY.md` now includes an OWASP coverage table marking each category as Relevant, N/A, or Found. This makes audits exhaustive and audit-trail-friendly — no category can be silently skipped.

**Threat dispositions:**

- **Mitigate** — implementation required to close the threat
- **Accept** — documented risk with rationale in the Accepted Risks Log
- **Transfer** — handled by a third-party service

**Output:** `.planning/phases/[phase]/[phase]-SECURITY.md`

**Agent:** `learnship-security-auditor` (read-only — does not modify source code)

**Config:** `workflow.security_enforcement` (default: `true`). Set to `false` to disable.

**Learning checkpoint:** `learn` — security patterns

---

## `/docs-update`

Generate, update, and verify project documentation against the live codebase.

```bash
/docs-update                # full documentation pipeline
/docs-update --force        # skip confirmations
```

**What it does:**

1. Detects project type (monorepo, CLI tool, SaaS, open-source library, generic)
2. Builds a documentation queue from always-on + conditional docs
3. For each doc: creates if new, updates stale sections if existing
4. Verifies all factual claims against the codebase (file paths, commands, config)
5. Commits all documentation

**Always-on docs (every project):**

1. README.md
2. ARCHITECTURE.md
3. GETTING-STARTED.md
4. DEVELOPMENT.md
5. TESTING.md
6. CONFIGURATION.md

**Conditional docs (if signal detected):**

| Signal | Doc |
|--------|-----|
| API routes detected | API.md |
| LICENSE file exists | CONTRIBUTING.md |
| Deploy config detected | DEPLOYMENT.md |

**CHANGELOG.md is never queued** — it's manually maintained.

**Agent:** `learnship-doc-writer` (verifies file paths exist, commands work, config matches schema)

**Learning checkpoint:** `explain` — articulate what was documented
