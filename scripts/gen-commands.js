#!/usr/bin/env node
/**
 * Generate commands/learnship/*.md — Claude Code format wrappers for all 42 workflows.
 * Run: node scripts/gen-commands.js
 */

const fs = require('fs');
const path = require('path');

const COMMANDS_DIR = path.join(__dirname, '..', 'commands', 'learnship');
fs.mkdirSync(COMMANDS_DIR, { recursive: true });

// Each entry: [filename, description, argument-hint, allowed-tools]
const WORKFLOWS = [
  // Navigation / entry points
  ['ls', 'Show project status, next step, and offer to run it — start every session here', null,
    ['Read', 'Bash']],
  ['next', 'Auto-pilot — reads project state and runs the correct next workflow automatically', null,
    ['Read', 'Bash', 'Write', 'AskUserQuestion']],
  ['progress', 'Show project progress, current position, and what to do next', null,
    ['Read', 'Bash']],
  ['help', 'Show all available learnship workflows with descriptions and when to use them', null,
    ['Read']],
  ['resume-work', 'Restore full project context and continue from where you left off', null,
    ['Read', 'Bash', 'Write']],
  ['pause-work', 'Save a handoff file when stopping mid-phase so you can resume seamlessly later', null,
    ['Read', 'Bash', 'Write']],

  // Core project lifecycle
  ['new-project', 'Initialize a new project — questioning → research → requirements → roadmap', '[--auto]',
    ['Read', 'Bash', 'Write', 'Task', 'AskUserQuestion']],
  ['discuss-milestone', 'Capture milestone-level goals, constraints, and anti-goals before new-milestone starts', '[version]',
    ['Read', 'Bash', 'Write', 'AskUserQuestion']],
  ['new-milestone', 'Start a new milestone cycle on an existing project after a prior milestone is complete', '[name]',
    ['Read', 'Bash', 'Write', 'AskUserQuestion']],
  ['complete-milestone', 'Archive a completed milestone, tag the release, and prepare for the next version', null,
    ['Read', 'Bash', 'Write', 'AskUserQuestion']],
  ['audit-milestone', 'Verify milestone met its definition of done — requirement coverage, integration check, stub detection', null,
    ['Read', 'Bash', 'Write']],

  // Phase management
  ['discuss-phase', 'Capture implementation decisions for a phase before planning starts', '[N]',
    ['Read', 'Bash', 'Write', 'AskUserQuestion']],
  ['plan-phase', 'Research + create + verify plans for a phase — spawns specialist subagents where supported', '[N]',
    ['Read', 'Bash', 'Write', 'Task', 'AskUserQuestion']],
  ['execute-phase', 'Execute all plans in a phase with wave-based ordered execution, spawning subagents per plan where supported', '<phase-number>',
    ['Read', 'Bash', 'Write', 'Edit', 'Glob', 'Grep', 'Task', 'AskUserQuestion']],
  ['verify-work', 'Manual user acceptance testing — walk through what was built, log issues, create fix plans', '[N]',
    ['Read', 'Bash', 'Write', 'AskUserQuestion']],
  ['add-phase', 'Append a new phase to the current milestone roadmap when scope grows after initial planning', '[description]',
    ['Read', 'Bash', 'Write']],
  ['insert-phase', 'Insert a new phase between existing phases for urgent work discovered mid-milestone', '[N] [description]',
    ['Read', 'Bash', 'Write']],
  ['remove-phase', 'Remove a planned (not yet executed) phase and renumber subsequent phases', '[N]',
    ['Read', 'Bash', 'Write', 'AskUserQuestion']],
  ['research-phase', 'Deep-dive domain research for a phase without immediately creating plans', '[N]',
    ['Read', 'Bash', 'Write', 'Task']],
  ['list-phase-assumptions', 'Surface the intended approach for a phase before planning starts — validate direction early', '[N]',
    ['Read', 'Bash']],
  ['execute-plan', 'Run a single PLAN.md file in isolation — useful for re-running a failed plan', '<phase-number> <plan-id>',
    ['Read', 'Bash', 'Write', 'Edit', 'Glob', 'Grep', 'Task']],
  ['validate-phase', 'Retroactive test coverage audit for a completed phase — fill validation gaps without modifying implementation', '[N]',
    ['Read', 'Bash', 'Write']],

  // Discovery and debugging
  ['map-codebase', 'Analyze an existing codebase and produce structured reference docs before starting a new project on top of it', null,
    ['Read', 'Bash', 'Write', 'Glob', 'Grep']],
  ['discovery-phase', 'Structured codebase discovery before working on an unfamiliar area — reads code, maps dependencies, surfaces risks', '[N]',
    ['Read', 'Bash', 'Write', 'Glob', 'Grep']],
  ['debug', 'Systematic debugging with persistent state — triage, diagnose root cause, plan fix, execute', '[description]',
    ['Read', 'Bash', 'Write', 'Edit', 'Glob', 'Grep', 'Task', 'AskUserQuestion']],
  ['diagnose-issues', 'Batch-diagnose multiple UAT issues after verify-work — groups by root cause, proposes fix plan', '[N]',
    ['Read', 'Bash', 'Write', 'Task']],

  // Task management
  ['add-todo', 'Capture a todo/idea mid-session without interrupting flow', '[description]',
    ['Read', 'Write']],
  ['check-todos', 'Review and act on all pending todos captured with add-todo', null,
    ['Read', 'Write', 'Bash', 'AskUserQuestion']],
  ['add-tests', 'Generate and add test coverage for a specific plan or phase post-execution', '[N]',
    ['Read', 'Bash', 'Write', 'Edit', 'Task']],
  ['quick', 'Execute an ad-hoc task with full agentic guarantees — atomic commits, state tracking, no full planning ceremony', '"<task description>"',
    ['Read', 'Bash', 'Write', 'Edit', 'Glob', 'Grep', 'Task', 'AskUserQuestion']],

  // Decision intelligence
  ['decision-log', 'Capture an architectural or scope decision with its context, alternatives, and rationale into DECISIONS.md', '[description]',
    ['Read', 'Write', 'AskUserQuestion']],
  ['knowledge-base', 'Aggregate key learnings and decisions across all sessions into a searchable KNOWLEDGE.md', null,
    ['Read', 'Bash', 'Write']],

  // Milestone intelligence
  ['milestone-retrospective', 'Structured learning retrospective at end of milestone — 5 questions, produces RETROSPECTIVE.md', null,
    ['Read', 'Write', 'AskUserQuestion']],
  ['plan-milestone-gaps', 'Create fix phases for all gaps found by audit-milestone', null,
    ['Read', 'Bash', 'Write', 'Task']],
  ['transition', 'Hand off a project context to a new session or collaborator — writes a HANDOFF.md with full state snapshot', null,
    ['Read', 'Bash', 'Write']],

  // Maintenance
  ['settings', 'Interactive settings editor for .planning/config.json', null,
    ['Read', 'Write', 'AskUserQuestion']],
  ['set-profile', 'Quick model profile switch without opening full settings', '[quality|balanced|budget]',
    ['Read', 'Write']],
  ['health', 'Project health check — stale files, uncommitted changes, missing artifacts, config drift', null,
    ['Read', 'Bash']],
  ['cleanup', 'Archive completed milestone phase directories to keep .planning/phases/ clean', null,
    ['Read', 'Bash', 'Write', 'AskUserQuestion']],
  ['update', 'Update the learnship platform itself to the latest version', null,
    ['Read', 'Bash', 'Write']],
  ['reapply-patches', 'Restore local workflow customizations after updating the platform', null,
    ['Read', 'Bash', 'Write']],
];

let created = 0;
for (const [name, description, argHint, tools] of WORKFLOWS) {
  const argLine = argHint ? `argument-hint: "${argHint}"\n` : '';
  const toolsList = tools.map(t => `  - ${t}`).join('\n');

  const content = `---
name: learnship:${name}
description: ${description}
${argLine}allowed-tools:
${toolsList}
---

<execution_context>
@~/.claude/learnship/workflows/${name}.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship ${name} workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
`;

  const outPath = path.join(COMMANDS_DIR, `${name}.md`);
  fs.writeFileSync(outPath, content);
  created++;
  console.log(`  ✓ commands/learnship/${name}.md`);
}

console.log(`\nCreated ${created} command wrappers in commands/learnship/`);
