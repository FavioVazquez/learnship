---
description: Sync agentic-learning and impeccable skills from their upstream repos (FavioVazquez/agentic-learn + pbakaus/impeccable) — run this when upstream skills have been updated
---

# sync-upstream-skills

Pull the latest skill content from both upstream repositories into learnship's skill tree, then re-run the installer so all platforms receive the updated skills.

**Usage:** `/sync-upstream-skills`

**What this touches:**
- `.windsurf/skills/agentic-learning/SKILL.md` — replaced from upstream
- `.windsurf/skills/agentic-learning/references/` — replaced from upstream
- `.windsurf/skills/impeccable/<sub-skill>/` — each of 18 sub-skill dirs replaced from upstream
- `.windsurf/skills/impeccable/SKILL.md` — **NOT touched** (this is learnship's own dispatcher)

---

## Step 1: Verify prerequisites

```bash
command -v git >/dev/null 2>&1 && echo "git: OK" || echo "git: MISSING"
command -v node >/dev/null 2>&1 && echo "node: OK" || echo "node: MISSING"
test -f "$(pwd)/bin/install.js" && echo "installer: OK" || echo "installer: MISSING — run from learnship repo root"
```

If any check fails, stop and report what is missing.

---

## Step 2: Check current upstream state

Show the user what they're about to pull so there are no surprises:

```bash
# Latest commit on agentic-learn main
git ls-remote https://github.com/FavioVazquez/agentic-learn.git HEAD | awk '{print "agentic-learn HEAD: " $1}'

# Latest commit on impeccable main
git ls-remote https://github.com/pbakaus/impeccable.git HEAD | awk '{print "impeccable HEAD:    " $1}'
```

Also show current local state:
```bash
# What version of SKILL.md do we currently have for agentic-learning?
head -6 "$(pwd)/.windsurf/skills/agentic-learning/SKILL.md"
```

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► UPSTREAM SKILL SYNC
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Will pull from:
  agentic-learn  → github.com/FavioVazquez/agentic-learn (main)
  impeccable     → github.com/pbakaus/impeccable (main)

Files updated:
  .windsurf/skills/agentic-learning/SKILL.md
  .windsurf/skills/agentic-learning/references/   (full replace)
  .windsurf/skills/impeccable/<18 sub-skills>/    (full replace each)

Files preserved (learnship-owned):
  .windsurf/skills/impeccable/SKILL.md            (dispatcher — never touched)

Proceed? (yes/no)
```

Wait for confirmation.

---

## Step 3: Clone upstreams into temp dirs

```bash
TMPDIR=$(mktemp -d)
AGENTIC_LEARN_TMP="$TMPDIR/agentic-learn"
IMPECCABLE_TMP="$TMPDIR/impeccable"

echo "Cloning agentic-learn..."
git clone --depth 1 https://github.com/FavioVazquez/agentic-learn.git "$AGENTIC_LEARN_TMP"

echo "Cloning impeccable..."
git clone --depth 1 https://github.com/pbakaus/impeccable.git "$IMPECCABLE_TMP"

echo "Clone complete."
ls "$AGENTIC_LEARN_TMP"
ls "$IMPECCABLE_TMP/source/skills/"
```

Confirm both clones succeeded — `SKILL.md` must exist in `$AGENTIC_LEARN_TMP` and the 18 sub-skill dirs must exist under `$IMPECCABLE_TMP/source/skills/`. If either is missing, stop.

---

## Step 4: Back up current skills

```bash
BACKUP_DIR="$(pwd)/.windsurf/skills/.upstream-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

cp -r "$(pwd)/.windsurf/skills/agentic-learning" "$BACKUP_DIR/agentic-learning"
cp -r "$(pwd)/.windsurf/skills/impeccable" "$BACKUP_DIR/impeccable"

echo "Backup created at: $BACKUP_DIR"
```

---

## Step 5: Sync agentic-learning

Replace `SKILL.md` and `references/` verbatim from upstream. The upstream repo root IS the skill — `SKILL.md` lives at the repo root, references live in `references/`.

```bash
SKILL_DIR="$(pwd)/.windsurf/skills/agentic-learning"

# Replace SKILL.md
cp "$AGENTIC_LEARN_TMP/SKILL.md" "$SKILL_DIR/SKILL.md"

# Replace references/ entirely
rm -rf "$SKILL_DIR/references"
cp -r "$AGENTIC_LEARN_TMP/references" "$SKILL_DIR/references"

echo "agentic-learning synced:"
echo "  SKILL.md — replaced"
echo "  references/ — $(ls "$SKILL_DIR/references" | wc -l | tr -d ' ') files replaced"
```

---

## Step 6: Sync impeccable sub-skills

Upstream layout: `source/skills/<sub-skill>/SKILL.md` (+ any reference files).
Learnship layout: `.windsurf/skills/impeccable/<sub-skill>/SKILL.md`.

**Important:** Do NOT touch `.windsurf/skills/impeccable/SKILL.md` — that is learnship's own dispatcher file.

```bash
IMPECCABLE_SRC="$IMPECCABLE_TMP/source/skills"
IMPECCABLE_DEST="$(pwd)/.windsurf/skills/impeccable"

# Save learnship's dispatcher SKILL.md before any operations
DISPATCHER_CONTENT=$(cat "$IMPECCABLE_DEST/SKILL.md")

synced=0
for sub_dir in "$IMPECCABLE_SRC"/*/; do
  skill_name=$(basename "$sub_dir")

  # Verify it has a SKILL.md
  if [ ! -f "$sub_dir/SKILL.md" ]; then
    echo "  SKIP $skill_name — no SKILL.md found upstream"
    continue
  fi

  # Replace the sub-skill dir entirely
  rm -rf "$IMPECCABLE_DEST/$skill_name"
  cp -r "$sub_dir" "$IMPECCABLE_DEST/$skill_name"
  echo "  ✓ $skill_name"
  synced=$((synced + 1))
done

# Restore dispatcher SKILL.md (in case it was accidentally touched)
echo "$DISPATCHER_CONTENT" > "$IMPECCABLE_DEST/SKILL.md"

echo ""
echo "impeccable synced: $synced sub-skills replaced"
echo "impeccable/SKILL.md preserved (learnship dispatcher)"
```

---

## Step 7: Verify sync integrity

Check all 18 expected sub-skills are present and have a `SKILL.md`:

```bash
IMPECCABLE_DEST="$(pwd)/.windsurf/skills/impeccable"
expected="adapt animate audit bolder clarify colorize critique delight distill extract frontend-design harden normalize onboard optimize polish quieter teach-impeccable"
missing=""

for skill in $expected; do
  if [ ! -f "$IMPECCABLE_DEST/$skill/SKILL.md" ]; then
    missing="$missing $skill"
  fi
done

if [ -n "$missing" ]; then
  echo "WARNING: missing sub-skills after sync:$missing"
  echo "Restoring from backup..."
  cp -r "$BACKUP_DIR/impeccable/." "$IMPECCABLE_DEST/"
  echo "Restored. Check upstream structure manually."
else
  echo "All 18 impeccable sub-skills present ✓"
fi

# Verify dispatcher is still intact
if grep -q "name: impeccable" "$IMPECCABLE_DEST/SKILL.md"; then
  echo "impeccable/SKILL.md dispatcher intact ✓"
else
  echo "WARNING: dispatcher SKILL.md looks wrong — restoring"
  cp "$BACKUP_DIR/impeccable/SKILL.md" "$IMPECCABLE_DEST/SKILL.md"
fi

# Verify agentic-learning
if grep -q "name: agentic-learning" "$(pwd)/.windsurf/skills/agentic-learning/SKILL.md"; then
  echo "agentic-learning/SKILL.md present ✓"
else
  echo "WARNING: agentic-learning SKILL.md looks wrong — restoring"
  cp "$BACKUP_DIR/agentic-learning/SKILL.md" "$(pwd)/.windsurf/skills/agentic-learning/SKILL.md"
fi
```

---

## Step 8: Re-run installer for all platforms

Propagate updated skills to every installed platform (Claude Code plugins, Windsurf, OpenCode, Gemini CLI, Codex context files):

```bash
cd "$(pwd)"
node bin/install.js --all
```

This ensures:
- **Windsurf** — skills already live in `.windsurf/skills/` (updated in place above)
- **Claude Code** — `~/.claude/plugins/learnship/` rebuilt with updated skill content + rewritten `references/` paths
- **OpenCode / Gemini CLI / Codex** — `learnship/skills/` context files updated

---

## Step 9: Clean up temp dirs

```bash
rm -rf "$TMPDIR"
echo "Temp files cleaned up."
```

---

## Step 10: Done

Display summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► SKILL SYNC COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

agentic-learning:
  SKILL.md       ✓ synced from FavioVazquez/agentic-learn
  references/    ✓ synced ([N] files)

impeccable:
  18 sub-skills  ✓ synced from pbakaus/impeccable
  SKILL.md       ✓ preserved (learnship dispatcher)

All platforms updated (installer re-run):
  Windsurf       ✓ skills updated in place
  Claude Code    ✓ plugins/learnship/ rebuilt
  Other platforms ✓ learnship/skills/ context files updated

Backup saved at: .windsurf/skills/.upstream-backup-<timestamp>/
Run: git diff .windsurf/skills/ to review all changes before committing.
```

Remind the user:
> If upstream added new actions to `agentic-learning` (new entries in `SKILL.md`), update `.windsurf/skills/agentic-learning/SKILL.md`'s `description` frontmatter field to list them — it's what agents use to decide when to invoke the skill.
>
> If upstream added a new sub-skill to `impeccable`, also add it to `.windsurf/skills/impeccable/SKILL.md`'s Actions section and `references/` list.
