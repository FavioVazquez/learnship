---
title: Maintenance
description: Reference for maintenance workflows — settings, health, update, cleanup, sync-upstream-skills.
---

# Maintenance

These workflows keep your learnship installation and project in good shape.

---

## `/settings`

Interactive configuration editor for `.planning/config.json`.

```
/settings
```

Walks you through each setting with explanations and current values. Safer than editing `config.json` directly — validates values before writing.

See [Configuration](../configuration.md) for the full schema reference.

---

## `/set-profile [quality|balanced|budget]`

One-step model profile switch — the fastest way to adjust cost vs. quality.

```
/set-profile quality    # all agents use large models
/set-profile balanced   # mix of large and medium (default)
/set-profile budget     # all agents use smallest viable models
```

Only changes `model_profile` in `config.json`. For full preset changes (mode, granularity, toggles) use `/settings`.

---

## `/health`

Project health check — surfaces issues before they become blockers.

**What it checks:**
- Stale planning files (last modified > 30 days with no activity)
- Uncommitted changes to planning artifacts
- Missing artifacts (phase with PLAN but no SUMMARY)
- Config drift (settings that contradict each other)
- `AGENTS.md` is up to date with current phase

Run this any time you feel the project state might be inconsistent.

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

- Pulls latest `agentic-learn` from `github.com/FavioVazquez/agentic-learn`
- Pulls latest `impeccable` from `github.com/pbakaus/impeccable`
- Preserves local customizations (impeccable dispatcher `SKILL.md`)
- Runs the installer to update all platform copies

**When to use:** When upstream skills have been updated and you want the latest learning techniques or design commands.

---

## `/release`

Cuts a new learnship release — bumps version, updates changelog, pushes tag, creates GitHub release.

**When to use:** When you're developing learnship itself and want to publish a new version. Not needed for normal project work.
