---
description: Update the learnship platform itself to the latest version
---

# Update

Update the platform workflows and skills to the latest version. Backs up any locally modified files before overwriting so you don't lose customizations.

**Usage:** `update`

## Step 1: Detect Install Location

Find where the platform is installed:

```bash
# Check local install
test -d "$(pwd)/.windsurf/workflows" && LOCAL_WF="$(pwd)/.windsurf" || LOCAL_WF=""

# Check global install
test -d "$HOME/.codeium/windsurf/workflows" && GLOBAL_WF="$HOME/.codeium/windsurf" || GLOBAL_WF=""
```

If both exist, ask: "Update local install, global install, or both?"

If neither found: "Could not detect install location. Run `bash install.sh` to reinstall."
Stop.

## Step 2: Find Platform Source

Locate the platform source repository:

```bash
# Common locations
for loc in \
  "$HOME/favio/learnship" \
  "$HOME/learnship" \
  "$(find $HOME -name "install.sh" -path "*/learnship/*" 2>/dev/null | head -1 | xargs dirname 2>/dev/null)"; do
  test -d "$loc/.windsurf/workflows" && SOURCE_DIR="$loc" && break
done
```

If source not found:
```
Platform source directory not found.

To update, either:
1. Clone the latest version and run: bash install.sh
2. Specify the source path manually
```
Stop.

## Step 3: Check for Updates

Compare installed workflow files to source:

```bash
# Check modification times and content
for wf in "$SOURCE_DIR/.windsurf/workflows/"*.md; do
  name=$(basename "$wf")
  target="$INSTALL_DIR/workflows/$name"
  if [ -f "$target" ] && ! diff -q "$wf" "$target" > /dev/null 2>&1; then
    echo "CHANGED: $name"
  elif [ ! -f "$target" ]; then
    echo "NEW: $name"
  fi
done
```

Display:
```
Update check:

New workflows available ([N]):
- [workflow name]: [description from frontmatter]

Updated workflows ([M]):
- [workflow name]: content changed

Your local modifications ([K]):
- [workflow name]: locally modified (will be backed up)

No changes: [N] workflows already up to date
```

If nothing to update:
```
Platform is up to date. All [N] workflows match the source.
```
Stop.

## Step 4: Back Up Local Modifications

For any workflow file that exists in install dir AND differs from source AND differs from the current source (meaning you modified it):

```bash
mkdir -p "$INSTALL_DIR/local-patches"
```

For each locally modified file:
```bash
cp "$INSTALL_DIR/workflows/$name" "$INSTALL_DIR/local-patches/$name"
```

Write a manifest:
```bash
cat > "$INSTALL_DIR/local-patches/PATCHES.md" << EOF
# Local Patches Backup
Created: $(date)

Files backed up before update:
$(for f in "$INSTALL_DIR/local-patches/"*.md; do echo "- $(basename $f)"; done)

To restore: run reapply-patches
EOF
```

Display:
```
[K] locally modified file(s) backed up to .windsurf/local-patches/
Run reapply-patches after update to merge your changes back.
```

## Step 5: Confirm Update

```
Ready to update:
- [N] new workflows will be added
- [M] existing workflows will be updated
- [K] local modifications backed up

Proceed? (yes/no)
```

Wait for confirmation.

## Step 6: Apply Update

Copy updated workflows:
```bash
for wf in "$SOURCE_DIR/.windsurf/workflows/"*.md; do
  cp "$wf" "$INSTALL_DIR/workflows/"
done
```

Update skills:
```bash
cp -r "$SOURCE_DIR/.windsurf/skills/agentic-learning/." "$INSTALL_DIR/skills/agentic-learning/"
cp -r "$SOURCE_DIR/.windsurf/skills/frontend-design/." "$INSTALL_DIR/skills/frontend-design/"
```

## Step 7: Confirm

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► UPDATE COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Added: [N] new workflows
Updated: [M] workflows
Skills: updated

[If local patches were backed up:]
⚠️  [K] local modification(s) backed up. Run reapply-patches to restore.

Platform is now up to date.
```
