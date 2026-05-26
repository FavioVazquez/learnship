---
title: Maintenance
description: "Reference for maintenance workflows: settings, health, update, cleanup, sync-upstream-skills."
---

# Maintenance

These workflows keep your learnship installation and project in good shape.

---

## `/settings`

Interactive configuration editor for `.planning/config.json`.

```
/settings
```

Walks you through each setting with explanations and current values. Safer than editing `config.json` directly: validates values before writing.

See [Configuration](../configuration.md) for the full schema reference.

---

## `/set-profile [quality|balanced|budget]`

One-step model profile switch: the fastest way to adjust cost vs. quality.

```
/set-profile quality    # all agents use large models
/set-profile balanced   # mix of large and medium (default)
/set-profile budget     # all agents use smallest viable models
```

Only changes `model_profile` in `config.json`. For full preset changes (mode, granularity, toggles) use `/settings`.

---

## `/health`

Project health check with numeric score — surfaces issues before they become blockers.

```
/health           # check and report
/health --repair  # check and auto-fix repairable issues
```

**What it checks:**
- Required planning files (PROJECT.md, ROADMAP.md, STATE.md, config.json)
- Config validity and completeness
- State/roadmap consistency (current phase exists in roadmap)
- Phase directories match roadmap phases
- Plans without summaries
- Uncommitted changes to planning artifacts

**Numeric score (0–100):**

Health computes a deterministic score. Start at 100, then deduct per issue:

| Issue | Deduction |
|-------|-----------|
| PROJECT.md missing | −25 |
| ROADMAP.md missing | −20 |
| config.json missing | −10 |
| config.json parse error | −15 |
| STATE.md missing | −10 |
| State/roadmap mismatch | −5 |
| Missing config fields | −2/field (max −10) |
| Phase dir missing | −4/phase (max −12) |
| Plan without summary | −1/plan (max −5) |
| Uncommitted .planning/ changes | −5 |

**Status bands:**
- **HEALTHY** (90–100) ✓ — project artifacts are clean
- **DEGRADED** (70–89) ⚠ — issues present but project is functional
- **BROKEN** (0–69) ✗ — critical artifacts missing or inconsistent

The repair footer shows `[N] issue(s) can be auto-repaired (+N points). Run: health --repair`.

**Auto-repairable issues:**
- STATE.md missing → regenerate from ROADMAP.md
- config.json missing or parse error → reset to defaults
- config.json missing fields → add missing fields with defaults

Run this any time you feel the project state might be inconsistent. It's also suggested automatically by `/ls` when planning artifacts drift.

---

## `/cleanup`

Archives completed milestone phase directories to keep `.planning/phases/` clean.

```
/cleanup
```

Moves completed phase directories to `.planning/milestones/[version]/phases/`. Run this after `/complete-milestone` if you want a cleaner working directory.

---

## `/update`

Updates the learnship platform itself to the latest version.

```
/update
```

Downloads the latest workflows from `github.com/FavioVazquez/learnship` and installs them, replacing the current workflow files.

!!! warning "Local customizations"
    If you've edited any workflow files, run `/reapply-patches` after updating to restore your changes.

---

## `/reapply-patches`

Restores local workflow customizations after running `/update`.

**When to use:** After `/update` if you had local modifications to workflow files. Works by re-applying a stored patch diff.

---

## `/sync-upstream-skills`

Syncs `@agentic-learning` and `@impeccable` skills from their upstream repositories.

```
/sync-upstream-skills
```

- Pulls latest `agentic-learning` from `github.com/FavioVazquez/agentic-learning`
- Pulls latest `impeccable` from `github.com/pbakaus/impeccable`
- Preserves local customizations (impeccable dispatcher `SKILL.md`)
- Runs the installer to update all platform copies

**When to use:** When upstream skills have been updated and you want the latest learning techniques or design commands.

---

## `/release`

Cuts a new learnship release: bumps version, updates changelog, pushes tag, creates GitHub release.

**When to use:** When you're developing learnship itself and want to publish a new version. Not needed for normal project work.
