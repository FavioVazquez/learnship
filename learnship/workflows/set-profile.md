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
  quality   — Opus for all agents (highest quality, highest cost)
  balanced  — Opus for planning, Sonnet for execution (recommended)
  budget    — Sonnet for writing, Haiku for research/verification (lowest cost)

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
python3 -c "
import json
cfg = json.load(open('.planning/config.json'))
cfg['model_profile'] = '[profile]'
json.dump(cfg, open('.planning/config.json', 'w'), indent=2)
print('Updated.')
"
```

## Step 5: Confirm

```bash
git add .planning/config.json
git commit -m "chore(config): set model profile to [profile]"
```

```
Profile updated: [old] → [profile]

[quality]  — Opus agents for all tasks. Use for production milestones.
[balanced] — Opus for planning, Sonnet for execution. Best default.
[budget]   — Sonnet/Haiku. Use for prototyping or exploration.

Takes effect immediately on the next workflow run.
```
