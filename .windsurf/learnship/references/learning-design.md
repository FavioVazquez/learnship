# Learning × Design Integration

How to use the Learning Partner and Design System together. These two layers amplify each other when used at the right moments.

---

## The Core Idea

Building software teaches you things. Building *interfaces* teaches you even more — because design decisions are high-stakes, visible, and often irreversible once shipped. The Learning Partner captures that knowledge before it evaporates.

The pattern:
1. **Before design** — brainstorm to surface blind spots
2. **During design** — use steering commands to maintain quality
3. **After design** — reflect to consolidate what you learned

---

## Before Any Design Work

### Start with brainstorm

Before writing a line of UI code, use:
```
@agentic-learning brainstorm [interface or feature name]
```

This surfaces:
- What problem does this UI solve? For whom?
- What mental model does the user have coming in?
- What are the 2-3 approaches? What are the trade-offs?
- What's the one thing they'll remember about this interface?

The brainstorm is saved to `docs/brainstorm/` — it becomes a design brief that both the agent and you can reference.

### Use either-or to log design decisions

When you choose between two approaches (card layout vs. table, modal vs. inline edit, sidebar vs. tabs), log it:
```
@agentic-learning either-or
```

This creates a decision journal entry — paths considered, the choice, the rationale. When you revisit the design in 3 weeks and wonder "why did we do it this way?", the journal has the answer.

---

## During Design Sprints

### Use steering commands to maintain quality

While building interfaces, invoke design steering commands directly:

| Moment | Command |
|--------|---------|
| Before starting any new component | `/audit` — check what quality problems to avoid |
| After first pass of implementation | `/critique` — get honest feedback before polish |
| Typography looks off | `/typography` — systematic type review |
| Colors feel wrong | `/color` — OKLCH-based palette review |
| Layout feels cramped or cluttered | `/layout` — spatial rhythm review |
| Adding animations | `/motion` — purposeful motion, not decoration |
| Building forms | `/forms` — labels, validation, error states |
| Writing button labels or headings | `/copy` — UX writing review |
| Worried about accessibility | `/accessibility` — focus, contrast, screen readers |

### The AI Slop Test

Run `/critique` and ask: "If someone saw this and said 'AI made this' — would they be right?"

If yes, that's the signal to push harder. Use `@agentic-learning struggle` to work through it yourself first:
```
@agentic-learning struggle "make this interface feel genuinely designed, not AI-generated"
```

This forces you to try your own design thinking before getting a solution — which builds the design intuition that transfers to the next project.

---

## After Design Phases

### Reflect after execute-phase

When a UI phase finishes executing:
```
@agentic-learning reflect
```

Three questions:
1. What design decisions did you make? Which ones felt right?
2. What were you trying to achieve aesthetically and functionally?
3. What's still fuzzy — patterns you used but don't fully understand?

### Schedule design patterns for review

After a design-heavy phase:
```
@agentic-learning space
```

This schedules the design patterns you used (OKLCH color, container queries, motion easing, etc.) for spaced review — so they transfer to long-term memory instead of being forgotten between projects.

---

## Learning Design Patterns Explicitly

When you encounter a design pattern you want to understand deeply (not just copy):

```
@agentic-learning learn [pattern name]
```

Examples:
- `@agentic-learning learn OKLCH color spaces`
- `@agentic-learning learn container queries vs media queries`
- `@agentic-learning learn exponential easing curves`
- `@agentic-learning learn fluid typography with clamp()`

The `learn` action uses active retrieval — you explain what you know first, then gaps are filled. This is how design patterns become intuition, not just copy-paste.

### Quiz yourself on design principles

After reading the design skill reference files:
```
@agentic-learning quiz typography
@agentic-learning quiz color-and-contrast
@agentic-learning quiz motion-design
```

---

## The Full Design-Learning Loop

```
brainstorm → build → /critique → /polish → reflect → space
```

1. `@agentic-learning brainstorm` — clarify the problem and approach
2. Build with steering commands as checkpoints
3. `/critique` — honest quality check
4. `/polish` — elevate and refine
5. `@agentic-learning reflect` — consolidate what you learned
6. `@agentic-learning space` — schedule patterns for review

Each time through this loop, the design decisions get better — not because the AI gets better, but because *you* do.
