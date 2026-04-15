---
title: learnship — Agentic Engineering Done Right
description: Learn as you build. Build with intent. Multi-platform agentic engineering for Windsurf, Claude Code, OpenCode, Gemini CLI, and Codex.
hide:
  - toc
---

<div class="ls-hero">
  <h1>learnship</h1>
  <p class="ls-tagline">Learn as you build. Build with intent.</p>
  <div class="ls-badges">
    <a href="https://github.com/FavioVazquez/learnship/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/FavioVazquez/learnship/ci.yml?branch=main&style=for-the-badge&label=CI&color=22c55e&labelColor=555555" alt="CI"></a>
    <a href="https://github.com/FavioVazquez/learnship/releases/latest"><img src="https://img.shields.io/github/v/release/FavioVazquez/learnship?style=for-the-badge&color=3b82f6&label=release&labelColor=555555" alt="Latest release"></a>
    <a href="platform-guide/windsurf/"><img src="https://img.shields.io/badge/platforms-6-0ea5e9?style=for-the-badge&labelColor=555555" alt="6 platforms"></a>
    <a href="workflow-reference/core/"><img src="https://img.shields.io/badge/workflows-57-3b82f6?style=for-the-badge&labelColor=555555" alt="57 workflows"></a>
    <a href="https://github.com/FavioVazquez/learnship/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge&labelColor=555555" alt="MIT License"></a>
  </div>
</div>

![learnship banner](assets/banner.png)

---

## What is learnship?

learnship is an **agent harness** for anyone who wants to build, learn, and ship real products using AI agents. It's the scaffolding that makes your AI coding agent actually reliable across real projects.

Every serious AI coding tool (Claude Code, Cursor, Manus, Devin) converges on the same architecture: a simple execution loop wraps the model, and the **harness** decides what information reaches the model, when, and how. The model is interchangeable. The harness is the product.

learnship gives you that harness as a portable, open-source layer that runs inside your existing AI tool and adds three things your agent doesn't have by default:

- **Persistent memory.** An `AGENTS.md` file is loaded into every session so the agent always knows the project, current phase, tech stack, and past decisions. No more repeating yourself.
- **Structured process.** A repeatable phase loop (Discuss → Plan → Execute → Verify → Review → Ship → Compound) with spec-driven plans, wave-ordered execution, and UAT-driven verification. The harness controls what context reaches the agent at each step.
- **Knowledge compounding.** v2.0 adds `/compound` to capture solved problems as searchable documentation, `/review` for multi-persona code review, `/challenge` to stress-test scope, `/ship` for end-to-end delivery, and `/ideate` for codebase-grounded idea generation.
- **Security, recovery, and session intelligence.** v2.1 adds `/secure-phase` for per-phase STRIDE threat verification, `/forensics` for post-mortem investigation, `/undo` for safe git revert, `/note` for zero-friction idea capture, `/session-report` for stakeholder summaries, `/docs-update` for documentation generation, and `/extract-learnings` for structured knowledge extraction.
- **Session hooks and structured interactivity.** v2.2 adds 4 Claude Code/Gemini CLI hooks (statusline, context monitor, prompt guard, session state), 14 workflows with platform-native interactive questions, 3 context profiles (dev/research/review), 5 research templates, and agent persona delegation via `Task()`.
- **17 specialist agent personas.** v2.3 adds 5 new personas (project-researcher, research-synthesizer, roadmapper, phase-researcher, doc-verifier), Windsurf-native `model_decision` rules for conditional persona adoption, and inline `<persona_context>` blocks across all 18 persona-aware workflows for cross-platform reliability.
- **Built-in learning.** Neuroscience-backed checkpoints at every phase transition so you understand what you shipped, not just that you shipped it.

---

## What problem does it solve?

If you've used AI coding assistants for more than a few sessions, you've hit this wall:

> The agent forgets everything. Each session starts from scratch. Decisions get repeated. Code quality drifts. You ship fast but understand less. The more you rely on the AI, the less you own the outcome.

This is a **harness problem**, not a model problem. Research shows the same model on the same benchmark scores 42% with one scaffold and 78% with another. Cursor's lazy context loading cuts token usage by 47%. Vercel deleted 80% of their agent's tools and watched it go from failing to completing tasks. Same model. The only variable is the harness.

learnship solves this with **progressive disclosure**, the pattern that separates working agents from impressive demos. Context is revealed incrementally, not dumped upfront. The right files, decisions, and phase context reach the agent exactly when needed, nothing more.

| Without learnship | With learnship |
|-------------------|----------------|
| Context resets every session | `AGENTS.md` loaded automatically every conversation |
| Ad-hoc prompts, unpredictable results | Spec-driven plans, verifiable deliverables |
| Architectural decisions get forgotten | `DECISIONS.md` tracked and honored by the agent |
| Everything dumped into context at once | Phase-scoped context: only what this step needs |
| You ship code you don't fully understand | Learning checkpoints build real understanding at every step |
| UI looks generic, AI-generated | `impeccable` design system prevents AI aesthetic slop |

---

## Who is it for?

learnship is built for **anyone who wants to build and ship real products with AI agents**, not just developers. If you're a founder, designer, researcher, or maker who uses AI tools to build things, this is for you.

It's the right tool if:

- You're **building a real project** (not just experimenting) and want the AI to stay aligned across sessions
- You're **learning while building** and want to actually understand what gets shipped
- You care about **code quality and UI quality** beyond "it works"
- You want **parallel agent execution** on Claude Code, OpenCode, or Gemini CLI to ship phases faster
- You've felt the frustration of **context loss**: repeating yourself every session while the agent forgets past decisions

It's probably overkill if you just need one-off scripts or quick fixes. Use `/quick` for that.

---

## Install in 30 seconds

```bash
npx learnship
```

The installer auto-detects your platform. Then open your AI agent and type:

```
/ls
```

That's it. `/ls` tells you where you are, what to do next, and offers to run it.

---

## Three layers that ship real products

<div class="ls-card-grid">
  <div class="ls-card">
    <div class="ls-card-title">⚙️ Workflow Engine</div>
    <p class="ls-card-desc">57 slash commands that take a project from idea to shipped. Spec-driven phases, context-engineered plans, wave-ordered execution, automated verification.</p>
    <span class="ls-card-command">/discuss → /plan → /execute → /verify → /review → /ship → /compound</span>
  </div>
  <div class="ls-card">
    <div class="ls-card-title">🧠 Learning Partner</div>
    <p class="ls-card-desc">Neuroscience-backed checkpoints woven into every phase transition. Active retrieval, spaced review, and structured reflection build real understanding, not just fluent answers.</p>
    <span class="ls-card-command">@agentic-learning learn · quiz · reflect · space · brainstorm</span>
  </div>
  <div class="ls-card">
    <div class="ls-card-title">🎨 Design System</div>
    <p class="ls-card-desc">21 impeccable steering commands for production-grade UI. Prevent generic AI aesthetics at the source. Based on @pbakaus/impeccable.</p>
    <span class="ls-card-command">/audit · /critique · /polish · /colorize · /animate</span>
  </div>
</div>

---

## Works on 6 platforms

![Platform comparison](assets/platform-comparison.png)

<div class="ls-platform-row">
  <a href="platform-guide/windsurf/" class="ls-platform-badge native">Windsurf</a>
  <a href="platform-guide/claude-code/" class="ls-platform-badge">Claude Code</a>
  <a href="platform-guide/cursor/" class="ls-platform-badge">Cursor</a>
  <a href="platform-guide/opencode/" class="ls-platform-badge">OpenCode</a>
  <a href="platform-guide/gemini-cli/" class="ls-platform-badge">Gemini CLI</a>
  <a href="platform-guide/codex-cli/" class="ls-platform-badge">Codex CLI</a>
</div>

```bash
npx learnship --all --global   # all CLI platforms at once
/add-plugin learnship           # Cursor marketplace
```

See the [Platform Guide](platform-guide/windsurf/) for platform-specific setup and capabilities.

---

## What makes this different

![Agentic vs vibe coding](assets/vibe-vs-agentic.png)

| | Vibe coding | learnship |
|-|------------|-----------|
| **Context** | Resets every session | Engineered into every agent call via `AGENTS.md` |
| **Plans** | Ad-hoc prompts | Spec-driven, verifiable, wave-ordered |
| **Decisions** | Implicit, forgotten | Tracked in `DECISIONS.md`, honored by the agent |
| **Learning** | Incidental | Woven in: retrieval, reflection, spacing at every step |
| **Outcome** | Code you shipped | Code you shipped **and understand** |

---

## Where to go next

<div class="ls-card-grid">
  <a href="getting-started/installation/" class="ls-card">
    <div class="ls-card-title">🚀 Installation</div>
    <p class="ls-card-desc">Platform-specific install commands, global vs local, auto-detection.</p>
  </a>
  <a href="getting-started/first-project/" class="ls-card">
    <div class="ls-card-title">📋 Your First Project</div>
    <p class="ls-card-desc">Walk through the full loop: new-project → discuss → plan → execute → verify → review → ship → compound.</p>
  </a>
  <a href="getting-started/five-commands/" class="ls-card">
    <div class="ls-card-title">⚡ The 5 Commands</div>
    <p class="ls-card-desc">The only commands you need to know to get through 95% of your work.</p>
  </a>
  <a href="skills/agentic-learning/" class="ls-card">
    <div class="ls-card-title">🧠 Learning Partner</div>
    <p class="ls-card-desc">All 11 @agentic-learning actions with when and why to use each.</p>
  </a>
</div>
