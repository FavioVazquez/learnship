---
description: Cut a new learnship release — bump version, update changelog, push to public-main, tag, create GitHub release
---

# Release — learnship

Ships a new version to the public GitHub repo and creates a GitHub release with changelog notes.

> **Private workflow** — gitignored, never shipped with the product.
> Requires a GitHub PAT with `repo` scope in the environment or entered at runtime.

---

## Step 1: Confirm you are on main and clean

```bash
cd /home/ec2-user/favio/agentic-development
git status
git log --oneline -5
```

Everything must be clean. If not, commit or stash first.

---

## Step 2: Decide the version bump

Ask the user: "What kind of release is this?"

- **patch** — bug fixes only (e.g. `1.1.0` → `1.1.1`)
- **minor** — new workflows, skills, or agent personas (e.g. `1.1.0` → `1.2.0`)
- **major** — breaking changes or major new capability layers (e.g. `1.1.0` → `2.0.0`)

Read the current version:
```bash
node -e "console.log(JSON.parse(require('fs').readFileSync('package.json','utf8')).version)"
```

Calculate the new version based on the bump type.

Ask the user: "Releasing as vX.Y.Z — confirm?"

---

## Step 3: Collect release notes

Ask the user: "What changed in this release? List the highlights."

Wait for their input. Then organize into:
- `### Added` — new workflows, skills, features
- `### Changed` — behaviour changes, improvements
- `### Fixed` — bugs resolved

If any section has no entries, omit it.

---

## Step 4: Update CHANGELOG.md

Prepend a new entry above the current latest version in `CHANGELOG.md`:

```markdown
## [vX.Y.Z] — [Short title]

**Released:** YYYY-MM-DD

### Added
- ...

### Fixed
- ...
```

Use today's date (run `date +%Y-%m-%d` to get it).

---

## Step 5: Bump version in package.json

Edit `package.json` — change the `"version"` field to the new version string.

---

## Step 6: Run tests to verify nothing is broken

```bash
bash tests/run_all.sh
```

If any test fails, stop and fix before proceeding.

---

## Step 7: Commit on main

```bash
git add CHANGELOG.md package.json
git commit -m "chore: release vX.Y.Z — [short title]"
```

---

## Step 8: Set remote URL with PAT

Ask the user for their GitHub PAT if not already set, or check if it's in `.env`:

```bash
source .env 2>/dev/null && echo "PAT found: ${GITHUB_PAT:0:8}..." || echo "PAT not in .env — will prompt"
```

If not in `.env`, ask: "Please provide your GitHub PAT."

Set the remote:
```bash
git remote set-url origin https://<PAT>@github.com/FavioVazquez/learnship.git
```

---

## Step 9: Cherry-pick release commit onto public-main

```bash
git checkout public-main

# Bring over CHANGELOG.md and package.json from main
git checkout main -- CHANGELOG.md package.json
git add CHANGELOG.md package.json
git commit -m "chore: release vX.Y.Z — [short title]"

# Push to GitHub main
git push origin public-main:main
```

---

## Step 10: Tag the release

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

---

## Step 11: Create GitHub release via API

```bash
RELEASE_NOTES="$(cat <<'NOTES'
## What's new in vX.Y.Z

[paste formatted release notes here]

## Install

\`\`\`bash
npx github:FavioVazquez/learnship
\`\`\`

See [CHANGELOG.md](https://github.com/FavioVazquez/learnship/blob/main/CHANGELOG.md) for full details.
NOTES
)"

curl -s -X POST \
  -H "Authorization: token <PAT>" \
  -H "Content-Type: application/json" \
  https://api.github.com/repos/FavioVazquez/learnship/releases \
  -d "{
    \"tag_name\": \"vX.Y.Z\",
    \"target_commitish\": \"main\",
    \"name\": \"vX.Y.Z — [Short title]\",
    \"body\": $(echo "$RELEASE_NOTES" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))'),
    \"draft\": false,
    \"prerelease\": false
  }" | python3 -c "import sys,json; r=json.load(sys.stdin); print(r.get('html_url', r.get('message','ERROR')))"
```

If successful, the release URL is printed.

---

## Step 12: Switch back to main and strip the PAT

```bash
git checkout main
git remote set-url origin https://github.com/FavioVazquez/learnship.git
```

Verify the token is gone:
```bash
git remote -v
# Must show plain HTTPS — no token visible
```

---

## Step 13: Verify

```bash
git log --oneline public-main -3   # new release commit at top
git tag --sort=-version:refname | head -5   # new tag at top
```

Open the release URL printed in Step 11 to confirm it looks correct on GitHub.

---

## Done

```
✓ vX.Y.Z tagged and pushed
✓ GitHub release created with notes
✓ CHANGELOG.md and package.json updated
✓ PAT stripped from remote URL
✓ Back on local main
```

Next release: repeat from Step 1.
