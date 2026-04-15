<universal_anti_patterns>

Rules that apply to ALL workflows and agents. Individual workflows may have additional specific anti-patterns.

---

## Context Budget Rules

1. **Never** read agent definition files (`agents/*.md`) when spawning subagents — `subagent_type` auto-loads them. Reading agent definitions into the orchestrator wastes context for content automatically injected into subagent sessions.
2. **Never** inline large files into subagent prompts — tell agents to read files from disk instead. Agents have their own context windows.
3. **Read depth scales with context window** — check `context_window` in `.planning/config.json`. At < 500000: read only frontmatter, status fields, or summaries. At >= 500000: full body reads permitted when content is needed for inline decisions. See `references/context-budget.md` for the complete table.
4. **Delegate** heavy work to subagents — the orchestrator routes, it does not build, analyze, research, investigate, or verify.
5. **Proactive pause warning**: If you have already consumed significant context (large file reads, multiple subagent results), warn the user: "Context budget is getting heavy. Consider checkpointing progress."

## File Reading Rules

6. **SUMMARY.md read depth scales with context window** — at context_window < 500000: read frontmatter only from prior phase SUMMARYs. At >= 500000: full body reads permitted for direct-dependency phases. Transitive dependencies (2+ phases back) remain frontmatter-only regardless.
7. **Never** read full PLAN.md files from other phases — only current phase plans.
8. **Do not** re-read full file contents when frontmatter is sufficient — frontmatter contains status, key_files, commits, and provides fields.

## Subagent Rules

9. **Always use learnship agent types** (`learnship-executor`, `learnship-planner`, `learnship-phase-researcher`, etc.) — never fall back to generic or built-in agent types. Learnship agents have project-aware prompts and workflow context.
10. **Do not** re-litigate decisions that are already locked in CONTEXT.md — respect locked decisions unconditionally.

## Questioning Anti-Patterns

11. **Do not** walk through checklists — checklist walking (asking items one by one from a list) is the #1 anti-pattern. Instead, use progressive depth: start broad, dig where interesting.
12. **Do not** use corporate speak — avoid jargon like "stakeholder alignment", "synergize", "deliverables". Use plain language.
13. **Do not** apply premature constraints — don't narrow the solution space before understanding the problem. Ask about the problem first, then constrain.

## State Management Anti-Patterns

14. **Always use atomic file writes for STATE.md and ROADMAP.md.** Read the current content, modify, write the whole file. Do not use append-only operations that could corrupt the file on interruption.
15. **Never** skip STATE.md updates after completing work — downstream workflows depend on accurate state.

## Behavioral Rules

16. **Do not** create artifacts the user did not approve — always confirm before writing new planning documents.
17. **Do not** modify files outside the workflow's stated scope — check the plan's files_modified list.
18. **Do not** suggest multiple next actions without clear priority — one primary suggestion, alternatives listed secondary.
19. **Do not** use `git add .` or `git add -A` — stage specific files only.
20. **Do not** include sensitive information (API keys, passwords, tokens) in planning documents or commits.

## Error Recovery Rules

21. **Git lock detection**: Before any git operation, if it fails with "Unable to create lock file", check for stale `.git/index.lock` and advise the user to remove it (do not remove automatically).
22. **Config fallback awareness**: Config loading returns `null` silently on invalid JSON. If your workflow depends on config values, check for null and warn the user: "config.json is invalid or missing — running with defaults."
23. **Partial state recovery**: If STATE.md references a phase directory that doesn't exist, do not proceed silently. Warn the user and suggest diagnosing the mismatch.

</universal_anti_patterns>
