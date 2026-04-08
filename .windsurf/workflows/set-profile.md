---
description: Quick model profile switch without opening full settings
---

# Set Profile

One-step model profile switch. Edits `.planning/config.json` without opening the full settings menu.

**Usage:** `set-profile [quality|balanced|budget]`

## Step 1: Parse Argument

If no argument provided:
```
Usage: set-profile [profile]

Profiles:
  quality   — large-tier models for all agents (highest quality, highest cost)
  balanced  — large for planning, medium for execution (recommended)
  budget    — medium for writing, small for research/verification (lowest cost)

Current profile: [read from .planning/config.json]
```
Stop.

## Step 2: Validate

If argument is not one of `quality`, `balanced`, `budget`:
```
Unknown profile: [argument]
Valid options: quality, balanced, budget
```
Stop.

## Step 3: Read Current Config

```bash
cat .planning/config.json
```

Note the current `model_profile` value.

If already set to the requested profile:
```
Profile is already set to [profile]. No change needed.
```
Stop.

## Step 4: Update Config

Update the `model_profile` field in `.planning/config.json`:

```bash
node -e "
const fs=require('fs');
const cfg=JSON.parse(fs.readFileSync('.planning/config.json','utf8'));
cfg.model_profile='[profile]';
fs.writeFileSync('.planning/config.json',JSON.stringify(cfg,null,2));
console.log('Updated.');
"
```

## Step 5: Confirm

```bash
git add .planning/config.json
git commit -m "chore(config): set model profile to [profile]"
```

```
Profile updated: [old] → [profile]

[quality]  — Large-tier agents for all tasks. Use for production milestones.
[balanced] — Large for planning, medium for execution. Best default.
[budget]   — Medium/small tier. Use for prototyping or exploration.

Takes effect immediately on the next workflow run.
```
