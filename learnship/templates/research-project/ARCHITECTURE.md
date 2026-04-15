# Architecture Research Template

Template for `.planning/research/ARCHITECTURE.md` — system structure patterns for the project domain.

<template>

```markdown
# Architecture Research

**Domain:** [domain type]
**Researched:** [date]
**Confidence:** [HIGH/MEDIUM/LOW]

## Component Boundaries

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        [Layer Name]                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │ [Comp]  │  │ [Comp]  │  │ [Comp]  │  │ [Comp]  │        │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘        │
│       │            │            │            │              │
├───────┴────────────┴────────────┴────────────┴──────────────┤
│                        [Layer Name]                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │                    [Component]                       │    │
│  └─────────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                        [Layer Name]                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                   │
│  │ [Store]  │  │ [Store]  │  │ [Store]  │                   │
│  └──────────┘  └──────────┘  └──────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| [name] | [what it owns] | [how it's usually built] |
| [name] | [what it owns] | [how it's usually built] |
| [name] | [what it owns] | [how it's usually built] |

## Data Flow

### Primary Data Flow

```
[Source] → [Transform/Process] → [Destination]
   ↓
[Side Effect / Event]
   ↓
[Consumer]
```

### Data Flow Description

| Flow | Source | Destination | Format | Notes |
|------|--------|-------------|--------|-------|
| [name] | [where data originates] | [where it goes] | [JSON/binary/stream] | [important details] |
| [name] | [where data originates] | [where it goes] | [JSON/binary/stream] | [important details] |

## Build Order

Suggested implementation sequence based on dependencies:

| Order | Component | Dependencies | Rationale |
|-------|-----------|--------------|-----------|
| 1 | [component] | None | [why first — usually data layer or core abstractions] |
| 2 | [component] | [depends on #1] | [why this order] |
| 3 | [component] | [depends on #1, #2] | [why this order] |
| 4 | [component] | [depends on #2, #3] | [why this order] |

## Integration Points

### External Integrations

| Integration | Type | Protocol | Auth | Notes |
|------------|------|----------|------|-------|
| [service] | [API/SDK/webhook] | [REST/gRPC/WS] | [key/OAuth/none] | [rate limits, gotchas] |

### Internal Boundaries

| Boundary | Left Side | Right Side | Contract |
|----------|-----------|------------|----------|
| [name] | [module A] | [module B] | [interface/API shape] |

## Recommended Project Structure

```
src/
├── [folder]/           # [purpose]
│   ├── [subfolder]/    # [purpose]
│   └── [file].ts       # [purpose]
├── [folder]/           # [purpose]
│   ├── [subfolder]/    # [purpose]
│   └── [file].ts       # [purpose]
├── [folder]/           # [purpose]
└── [folder]/           # [purpose]
```

---
*Architecture research for: [domain]*
*Researched: [date]*
```

</template>

<guidelines>

**Component Boundaries:**
- Use ASCII diagrams for system overview — they render in any terminal or editor
- Each component should have a single clear responsibility
- If a component does two things, it should probably be two components

**Data Flow:**
- Show the primary happy path first, then edge cases
- Note data format at each boundary (JSON, binary, stream)
- Identify where data transforms happen — these are common bug sources

**Build Order:**
- This directly feeds into roadmap phase ordering
- Always start with the data layer or core abstractions
- UI comes last (it depends on everything below it)

**Integration Points:**
- Note rate limits, auth requirements, and known gotchas
- External integrations are the most common source of runtime failures
- Define internal boundaries as interfaces/contracts — this enables parallel work

**Project Structure:**
- Follow domain conventions (e.g., Next.js app/ router, Django apps/)
- Group by feature, not by type, for most projects
- Keep the structure flat enough to navigate but deep enough to organize

</guidelines>
