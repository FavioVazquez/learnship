---
description: Restore local workflow customizations after updating the platform
---

# Reapply Patches

Restore local modifications to platform workflows after running `/update`. The update workflow backs up locally modified files before overwriting — this workflow merges your changes back.

**Usage:** `reapply-patches`

**Use after:** `/update` reports that local changes were backed up.

## Step 1: Find Backed-Up Patches

Check for the local patches directory:
```bash
ls .windsurf/local-patches/ 2>/dev/null || ls ~/.codeium/windsurf/local-patches/ 2>/dev/null
```

Also check for a patches manifest:
```bash
cat .windsurf/local-patches/PATCHES.md 2>/dev/null
```

If no patches directory found:
```
No local patches found. Nothing to reapply.

If you expected patches, check:
- .windsurf/local-patches/
- ~/.codeium/windsurf/local-patches/
```

Stop.

## Step 2: Inventory Patches

Read the patches directory and list what was backed up:

```bash
find .windsurf/local-patches/ -name "*.md" -o -name "*.json" 2>/dev/null | sort
```

Display:
```
Found [N] backed-up local modification(s):

- [filename] — [last modified date]
- [filename] — [last modified date]
```

## Step 3: Review Each Patch

For each backed-up file, compare it with the current installed version:

Read the backed-up file and the current installed file. Identify:
- Lines only in your local version (customizations)
- Lines only in the new version (upstream changes)
- Lines in both (unchanged)

Display a summary for each file:
```
## [filename]

Your local changes:
- [Line/section you added or modified]
- [Another change]

New upstream content:
- [What the update added or changed]

Conflict? [Yes/No — if yes, describe what overlaps]
```

## Step 4: Merge Strategy

For each file, choose the merge approach:

**Non-conflicting changes** (your edits and upstream edits touch different sections):
→ Auto-merge: apply your changes on top of the new version

**Conflicting changes** (same section modified by both):
→ Show the conflict, ask:
```
Conflict in [filename]:

Your version:
[your text]

Upstream version:
[upstream text]

Choose:
1. Keep yours (discard upstream change)
2. Keep upstream (discard your change)
3. Merge manually — I'll show you both and you edit
```

Wait for choice.

## Step 5: Apply Merged Files

Write each merged file to its target location. Verify the write succeeded.

## Step 6: Clean Up Patches

After successfully reapplying all patches:
```bash
rm -rf .windsurf/local-patches/
```

Or if the user wants to keep the backup:
```bash
mv .windsurf/local-patches/ .windsurf/local-patches-$(date +%Y%m%d)/
```

## Step 7: Confirm

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► PATCHES REAPPLIED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[N] local modification(s) restored:
- [file]: [brief description of what was restored]

Local patches directory cleared.

Your customizations are now active on top of the updated platform.
```
