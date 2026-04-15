---
description: Ship pipeline — test, lint, commit, push, PR
---

# Ship

End-to-end ship pipeline: detect test runner → run tests → lint → stage → conventional commit → push → create PR with auto-description. Closes the loop from verified code to production-ready PR.

**Usage:** `ship` — run the full ship pipeline
**Usage:** `ship --skip-tests` — skip test execution (use when tests were just run)

**Sequencing:** Run after `/review` (code quality) and before `/compound` (capture learnings).

## Step 1: Pre-flight Check

```bash
# Current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Branch: $BRANCH"

# Check we're not on main/master
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  echo "ERROR: Cannot ship from $BRANCH. Create a feature branch first."
  exit 1
fi

# Check for uncommitted changes
git status --porcelain
```

If uncommitted changes exist, ask: "You have uncommitted changes. Stage and commit them as part of the ship, or stash first?"

## Step 2: Run Tests

**Skip if:** `--skip-tests` flag, or `ship.auto_test` is `false` in config.

Detect the test runner:

```bash
# Check for common test runners
[ -f "package.json" ] && grep -q '"test"' package.json && echo "npm test"
[ -f "Makefile" ] && grep -q '^test:' Makefile && echo "make test"
[ -f "pytest.ini" ] || [ -f "setup.cfg" ] && echo "pytest"
[ -f "Cargo.toml" ] && echo "cargo test"
[ -f "go.mod" ] && echo "go test ./..."
```

Run the detected test command:

```bash
[detected test command]
```

If tests fail:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► TESTS FAILED — SHIP ABORTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[test output]

Fix the failing tests, then run /ship again.
▶ Or: /debug [test failure description]
```

Stop. Do not proceed with a failing test suite.

## Step 3: Lint (Optional)

Detect and run the linter if available:

```bash
[ -f "package.json" ] && grep -q '"lint"' package.json && echo "npm run lint"
[ -f ".eslintrc" ] || [ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ] && echo "npx eslint ."
[ -f "pyproject.toml" ] && grep -q "ruff" pyproject.toml && echo "ruff check ."
[ -f ".rubocop.yml" ] && echo "rubocop"
```

If linter found, run it. Report warnings but don't block on them. Block on errors.

## Step 4: Stage Changes

```bash
# Show what will be committed
git diff --stat

# Stage all tracked changes
git add -u

# Check for untracked files that should be included
UNTRACKED=$(git ls-files --others --exclude-standard)
if [ -n "$UNTRACKED" ]; then
  echo "Untracked files found:"
  echo "$UNTRACKED"
fi
```

If untracked files exist, ask: "These files are new and untracked. Include them in the commit?"
- **Yes, include all** → `git add .`
- **Let me choose** → present list, user selects
- **No, skip them** → proceed with tracked only

## Step 5: Conventional Commit

**If `ship.conventional_commits` is `true` in config (default: `true`):**

Analyze the staged changes to determine the commit type:

| Type | When |
|------|------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `refactor` | Code restructuring, no behavior change |
| `test` | Adding or updating tests |
| `chore` | Build, config, tooling |

Generate the commit message:
```
[type]([scope]): [short description]

[optional body — what changed and why, max 3 lines]
```

Present the proposed commit message. Ask: "Use this commit message, or edit?"

```bash
git commit -m "[commit message]"
```

## Step 6: Push

```bash
git push origin $BRANCH
```

If this is the first push for the branch:
```bash
git push -u origin $BRANCH
```

## Step 7: Create PR

**If `ship.pr_template` is `true` in config (default: `true`):**

Auto-generate the PR description from:
- Commit messages on the branch
- SUMMARY.md files from the current phase (if exists)
- Test results from Step 2

```bash
# Get base branch
BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
[ -z "$BASE_BRANCH" ] && BASE_BRANCH="main"

# Get commit log for PR body
COMMITS=$(git log --oneline origin/$BASE_BRANCH..HEAD)
```

Create the PR using available tooling:

```bash
# GitHub CLI
gh pr create --base "$BASE_BRANCH" --head "$BRANCH" --title "[type]([scope]): [description]" --body "[auto-generated description]"

# Or if gh not available, output the PR URL
echo "Create PR: https://github.com/[org]/[repo]/compare/$BASE_BRANCH...$BRANCH"
```

## Step 8: Confirm

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► SHIPPED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Branch: [branch]
Tests: passed ✓
Lint: passed ✓ | skipped
Commit: [hash] [type]([scope]): [description]
PR: [URL]

💡 Compound this work? Run `/compound` to capture any notable solutions
or patterns while context is fresh.

▶ Next steps:
- Review the PR and request reviews
- /compound — capture learnings from this work
- /session-report — generate a session summary for stakeholders
- /extract-learnings [N] — capture decisions, lessons, patterns from this phase
```

---

## Config Options

- `"ship.auto_test": true` — run tests before shipping
- `"ship.conventional_commits": true` — use conventional commit format
- `"ship.pr_template": true` — auto-generate PR description

---

## Integration Points

- `verify-work` banner: "▶ Next: /ship" after UAT passes
- `complete-milestone`: "Did you /ship first?" if unshipped changes exist

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** After shipping, offer:

> 💡 **Learning moment:** Shipping is a natural reflection point:
>
> `@agentic-learning reflect` — What went well in this phase? What would you do differently? Reflection after shipping cements the lessons before context fades.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning reflect` to consolidate lessons from this shipping cycle."*
