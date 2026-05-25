<planning_config>

Configuration options for `.planning/` directory behavior.

<config_schema>
```json
"planning": {
  "commit_docs": true,
  "search_gitignored": false
},
"git": {
  "branching_strategy": "none",
  "phase_branch_template": "phase-{phase}-{slug}",
  "milestone_branch_template": "{milestone}-{slug}"
}
```

| Option | Default | Description |
|--------|---------|-------------|
| `commit_docs` | `true` | Whether to commit planning artifacts to git |
| `search_gitignored` | `false` | Add `--no-ignore` to broad rg searches |
| `git.branching_strategy` | `"none"` | Git branching approach: `"none"`, `"phase"`, or `"milestone"` |
| `git.phase_branch_template` | `"phase-{phase}-{slug}"` | Branch template for phase strategy |
| `git.milestone_branch_template` | `"{milestone}-{slug}"` | Branch template for milestone strategy |
</config_schema>

<commit_docs_behavior>

**When `commit_docs: true` (default):**
- Planning files committed normally
- SUMMARY.md, STATE.md, ROADMAP.md tracked in git
- Full history of planning decisions preserved

**When `commit_docs: false`:**
- Skip all `git add`/`git commit` for `.planning/` files
- User must add `.planning/` to `.gitignore`
- Useful for: OSS contributions, client projects, keeping planning private

**Reading `commit_docs` from config:**

```bash
# Read commit_docs from config.json
COMMIT_DOCS=$(node -e "try{const c=JSON.parse(require('fs').readFileSync('.planning/config.json','utf8'));process.stdout.write(String((c.planning||{}).commit_docs??'true'));}catch(e){process.stdout.write('true');}" 2>/dev/null || echo 'true')
```

**Auto-detection:** If `.planning/` is gitignored, treat `commit_docs` as `false` regardless of config.json. This prevents git errors.

```bash
# Check if .planning/ is gitignored
git check-ignore -q .planning && COMMIT_DOCS=false
```

**Committing planning docs (when commit_docs is true):**

```bash
git add .planning/STATE.md && git commit -m "docs: update state"
```

</commit_docs_behavior>

<search_behavior>

**When `search_gitignored: false` (default):**
- Standard rg behavior (respects .gitignore)
- Direct path searches work: `rg "pattern" .planning/` finds files
- Broad searches skip gitignored: `rg "pattern"` skips `.planning/`

**When `search_gitignored: true`:**
- Add `--no-ignore` to broad rg searches that should include `.planning/`
- Only needed when searching entire repo and expecting `.planning/` matches

**Note:** Most learnship operations use direct file reads or explicit paths, which work regardless of gitignore status.

</search_behavior>

<setup_uncommitted_mode>

To use uncommitted mode:

1. **Set config:**
   ```json
   "planning": {
     "commit_docs": false,
     "search_gitignored": true
   }
   ```

2. **Add to .gitignore:**
   ```
   .planning/
   ```

3. **Existing tracked files:** If `.planning/` was previously tracked:
   ```bash
   git rm -r --cached .planning/
   git commit -m "chore: stop tracking planning docs"
   ```

4. **Branch merges:** When using `branching_strategy: phase` or `milestone`, the `complete-milestone` workflow automatically strips `.planning/` files from staging before merge commits when `commit_docs: false`.

</setup_uncommitted_mode>

<branching_strategy_behavior>

**Branching Strategies:**

| Strategy | When branch created | Branch scope | Merge point |
|----------|---------------------|--------------|-------------|
| `none` | Never | N/A | N/A |
| `phase` | At `execute-phase` start | Single phase | User merges after phase |
| `milestone` | At first `execute-phase` of milestone | Entire milestone | At `complete-milestone` |

**When `git.branching_strategy: "none"` (default):**
- All work commits to current branch
- **Standard learnship behavior**

**When `git.branching_strategy: "phase"`:**
- `execute-phase` creates/switches to a branch before execution
- Branch name from `phase_branch_template` (e.g., `phase-03-authentication`)
- All plan commits go to that branch
- User merges branches manually after phase completion
- `complete-milestone` offers to merge all phase branches

**When `git.branching_strategy: "milestone"`:**
- First `execute-phase` of milestone creates the milestone branch
- Branch name from `milestone_branch_template` (e.g., `v1.0-mvp`)
- All phases in milestone commit to same branch
- `complete-milestone` offers to merge milestone branch to main

**Template variables:**

| Variable | Available in | Description |
|----------|--------------|-------------|
| `{phase}` | phase_branch_template | Zero-padded phase number (e.g., "03") |
| `{slug}` | Both | Lowercase, hyphenated name |
| `{milestone}` | milestone_branch_template | Milestone version (e.g., "v1.0") |

**Checking the config:**

Read config directly:
```bash
node -e "const c=JSON.parse(require('fs').readFileSync('.planning/config.json','utf8')),g=c.git||{};console.log(g.branching_strategy||'none',g.phase_branch_template||'phase-{phase}-{slug}',g.milestone_branch_template||'{milestone}-{slug}')"
```

**Branch creation:**

```bash
# For phase strategy
if [ "$BRANCHING_STRATEGY" = "phase" ]; then
  PHASE_SLUG=$(echo "$PHASE_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
  BRANCH_NAME=$(echo "$PHASE_BRANCH_TEMPLATE" | sed "s/{phase}/$PADDED_PHASE/g" | sed "s/{slug}/$PHASE_SLUG/g")
  git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME"
fi

# For milestone strategy
if [ "$BRANCHING_STRATEGY" = "milestone" ]; then
  MILESTONE_SLUG=$(echo "$MILESTONE_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
  BRANCH_NAME=$(echo "$MILESTONE_BRANCH_TEMPLATE" | sed "s/{milestone}/$MILESTONE_VERSION/g" | sed "s/{slug}/$MILESTONE_SLUG/g")
  git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME"
fi
```

**Merge options at complete-milestone:**

| Option | Git command | Result |
|--------|-------------|--------|
| Squash merge (recommended) | `git merge --squash` | Single clean commit per branch |
| Merge with history | `git merge --no-ff` | Preserves all individual commits |
| Delete without merging | `git branch -D` | Discard branch work |
| Keep branches | (none) | Manual handling later |

Squash merge is recommended — keeps main branch history clean while preserving the full development history in the branch (until deleted).

**Use cases:**

| Strategy | Best for |
|----------|----------|
| `none` | Solo development, simple projects |
| `phase` | Code review per phase, granular rollback, team collaboration |
| `milestone` | Release branches, staging environments, PR per version |

</branching_strategy_behavior>

<v2_config_options>

## v2.0.0 Configuration Options

These options were added in v2.0.0 to support the new compounding, review, ship, and safety workflows.

| Option | Default | Description |
|--------|---------|-------------|
| `test_first` | `false` | Enable TDD mode — red-green-refactor cycle in executor |
| `workflow.review` | `true` | Enable the `/review` code review workflow |
| `workflow.solutions_search` | `true` | Search `.planning/solutions/` for prior art during plan-phase |
| `review.auto_after_verify` | `false` | Automatically run `/review` after verify-work passes |
| `ship.auto_test` | `true` | Run tests before shipping |
| `ship.conventional_commits` | `true` | Use conventional commit format in `/ship` |
| `ship.pr_template` | `true` | Auto-generate PR description in `/ship` |

</v2_config_options>

<v21_config_options>

## v2.1.0 Configuration Options

New sections and fields added in v2.1.0 for security, parallelization control, gates, and safety.

### Workflow Section (new fields)

| Option | Default | Description |
|--------|---------|-------------|
| `workflow.security_enforcement` | `true` | Enable per-phase security verification via `/secure-phase` |
| `workflow.discuss_mode` | `"discuss"` | Discussion depth for `discuss-phase` and `new-project` questioning. `"discuss"` = standard (4 focused exchanges). `"deep"` = extended questioning, walks every decision branch until shared understanding — equivalent to passing `--deep` flag |
| `workflow.tdd_mode` | `false` | Instruct planner to apply `type: tdd` to eligible tasks |

### Parallelization Section (replaces flat boolean)

The `parallelization` field is now an object. Legacy flat `"parallelization": true` is still honored for backward compatibility.

| Option | Default | Description |
|--------|---------|-------------|
| `parallelization.enabled` | `false` | Enable parallel subagent execution on supported platforms |
| `parallelization.plan_level` | `true` | Parallelize at plan level (each plan gets its own agent) |
| `parallelization.task_level` | `false` | Parallelize at task level within a plan (experimental) |
| `parallelization.max_concurrent_agents` | `5` | Maximum number of concurrent subagents per wave |
| `parallelization.min_plans_for_parallel` | `2` | Minimum plans in a wave before parallelization activates |

**Why default 5?** Each subagent gets its own context window (~200k tokens). 5 agents is the sweet spot for cost vs. speed — most phases have 2-5 plans per wave. Going higher risks git lock contention and significant cost spikes without proportional speed gains. Configurable for power users.

### Gates Section

Controls which confirmation prompts are shown during workflows. Set to `false` to skip specific confirmations (useful for experienced users in auto mode).

| Option | Default | Description |
|--------|---------|-------------|
| `gates.confirm_project` | `true` | Confirm PROJECT.md before proceeding |
| `gates.confirm_phases` | `true` | Confirm phase breakdown |
| `gates.confirm_roadmap` | `true` | Confirm roadmap before proceeding |
| `gates.confirm_plan` | `true` | Confirm plans before execution |
| `gates.execute_next_plan` | `true` | Confirm before executing each plan |
| `gates.issues_review` | `true` | Confirm issue resolution approach |
| `gates.confirm_transition` | `true` | Confirm before phase transitions |

### Safety Section

| Option | Default | Description |
|--------|---------|-------------|
| `safety.always_confirm_destructive` | `true` | Always confirm before destructive operations (file deletion, git reset) |
| `safety.always_confirm_external_services` | `true` | Always confirm before calling external APIs or services |

### Hooks Section

| Option | Default | Description |
|--------|---------|-------------|
| `hooks.context_warnings` | `true` | Show context budget warnings when usage is high |

### Example config.json with all v2.1 options

```json
{
  "mode": "interactive",
  "granularity": "standard",
  "model_profile": "balanced",
  "learning_mode": "auto",
  "test_first": false,
  "planning": {
    "commit_docs": true,
    "commit_mode": "auto",
    "search_gitignored": false
  },
  "workflow": {
    "research": true,
    "plan_check": true,
    "verifier": true,
    "validation": true,
    "review": true,
    "solutions_search": true,
    "security_enforcement": true,
    "discuss_mode": "discuss",
    "tdd_mode": false
  },
  "parallelization": {
    "enabled": false,
    "plan_level": true,
    "task_level": false,
    "max_concurrent_agents": 5,
    "min_plans_for_parallel": 2
  },
  "gates": {
    "confirm_project": true,
    "confirm_phases": true,
    "confirm_roadmap": true,
    "confirm_plan": true,
    "execute_next_plan": true,
    "issues_review": true,
    "confirm_transition": true
  },
  "safety": {
    "always_confirm_destructive": true,
    "always_confirm_external_services": true
  },
  "review": {
    "auto_after_verify": false
  },
  "ship": {
    "auto_test": true,
    "conventional_commits": true,
    "pr_template": true
  },
  "hooks": {
    "context_warnings": true
  },
  "git": {
    "branching_strategy": "none",
    "phase_branch_template": "phase-{phase}-{slug}",
    "milestone_branch_template": "{milestone}-{slug}"
  }
}
```

</v21_config_options>

</planning_config>
