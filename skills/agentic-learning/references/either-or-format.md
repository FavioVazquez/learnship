# Either/Or — Decision Journal Format

This file defines the format and philosophy for the `either-or` action. It is a reference for the agent when guiding the user through a decision journaling session.

---

## The idea

Kierkegaard's *Either/Or* (1843) argues that the most important human acts are not forced on us — they are chosen. The act of choosing consciously, with awareness of what you are giving up, is what defines character and direction.

Applied to building software with AI agents: every significant decision made during development — architectural choices, technology tradeoffs, scope decisions, process choices — shapes what you build and what you learn. Most of these decisions are made implicitly, in seconds, and forgotten.

The `either-or` action makes them explicit. Not to second-guess every choice, but to:

1. **Learn from the act of choosing** — articulating alternatives forces clearer thinking
2. **Build a project memory** — decisions and their rationale become documentation
3. **Track consequences over time** — filling in the "Outcome" field later closes the feedback loop between intention and reality
4. **Develop judgment** — reviewing past decisions reveals patterns in how you think and what you value

---

## When to use it

- When you are about to make a technology choice
- When you realize you just made a significant architectural decision
- When there is genuine tension between two valid approaches
- When the agent proposes something and you want to record why you accepted or rejected it
- When you want to revisit a past decision and update its outcome

Good candidates:
- "Use X vs Y" (technology, library, pattern)
- "Build vs buy"
- "Ship now vs refactor first"
- "Implement feature A vs feature B next"
- "Use an agent for this vs write it manually"
- "Accept the agent's suggestion vs override it"

Not every micro-decision needs to be journaled. Reserve it for choices with meaningful consequences that are worth revisiting.

---

## The dialogue flow

The agent should gather the required fields through a brief conversational exchange, asking one question at a time:

1. If no decision is stated: "What decision did you just make — or are you about to make?"
2. "What were the real alternatives you considered?" (push for at least 2 genuine options; resist straw men)
3. "What did you choose?"
4. "Why? What values, constraints, or evidence drove that choice?"
5. "What do you expect to happen as a result?"

Then write the entry without asking further questions.

---

## Entry format

Entries are appended to `docs/decisions/YYYY-MM-DD-decisions.md`. Multiple decisions in one day go in the same file, separated by `---`.

```markdown
## [HH:MM] <decision title>

**Context:** <what were you building, what was the moment of decision — 1-3 sentences>

**Paths considered:**
- **A — <short name>:** <description of this path and its trade-offs>
- **B — <short name>:** <description of this path and its trade-offs>
- **C — <short name> (optional):** <if there was a third real option>

**Chosen:** <A / B / C>

**Rationale:** <why this path — values, constraints, evidence, intuition — be honest>

**Expected consequences:** <what do you expect to happen as a result of this choice — be specific>

**Outcome (to fill later):** _pending_

---
```

---

## Example entries

### Example 1 — Technology choice

```markdown
## [10:34] Auth: JWT vs session-based auth

**Context:** Building a multi-tenant SaaS API. Need to decide the authentication strategy before implementing the user service.

**Paths considered:**
- **A — JWT (stateless):** Tokens carry all claims; no server-side session store needed. Scales horizontally without sticky sessions. Hard to revoke before expiry.
- **B — Session-based (stateful):** Sessions stored in Redis; easy to revoke instantly. Requires session store infrastructure; adds a network hop on every request.

**Chosen:** A — JWT

**Rationale:** We don't have a Redis cluster yet and don't want to add infrastructure complexity in the early stages. Token expiry of 15 minutes + refresh tokens gives acceptable revocation latency for our threat model.

**Expected consequences:** We'll need to implement refresh token rotation carefully. If we need instant revocation later, we'll have to add a token denylist — that's acceptable technical debt for now.

**Outcome (to fill later):** _pending_

---
```

### Example 2 — Process choice

```markdown
## [14:22] Ship v0.1 vs refactor the data pipeline first

**Context:** The data pipeline works but is messy — hardcoded paths, no error handling. v0.1 release is blocked on it working, not on it being clean.

**Paths considered:**
- **A — Ship as-is:** Get feedback sooner. Risk: if we need to change the pipeline, the mess will slow us down.
- **B — Refactor first:** Clean foundation. Risk: we're refactoring before we know what the actual requirements are from real users.

**Chosen:** A — Ship as-is

**Rationale:** We don't know what feedback will demand. Refactoring before validating the product is a classic trap. We'll add a TODO and revisit after first user interviews.

**Expected consequences:** Technical debt in the pipeline. If the product direction is validated, we'll spend ~2 days cleaning it up with better specs. If it pivots, we saved that time.

**Outcome (to fill later):** _pending_

---
```

### Example 3 — Agent override

```markdown
## [16:05] Accept agent's suggested schema vs override with custom design

**Context:** Agent proposed a normalized schema with 4 tables for the content model. I was leaning toward a simpler 2-table design with JSON columns for flexibility.

**Paths considered:**
- **A — Agent's 4-table normalized schema:** Proper relational structure; better for complex queries; more migration overhead.
- **B — My 2-table + JSON design:** Simpler; flexible; potential query performance issues at scale; harder to index.

**Chosen:** A — Agent's normalized schema

**Rationale:** The agent's reasoning about query patterns was correct. My preference for JSON was driven by laziness about migrations, not by a genuine architectural argument. Normalized is the right call here.

**Expected consequences:** More migration files upfront. Better query performance and data integrity long-term.

**Outcome (to fill later):** _pending_

---
```

---

## Filling in outcomes

When a decision's consequences have played out, the user (or agent, if asked) can return to fill in the outcome:

```markdown
**Outcome (filled YYYY-MM-DD):** The JWT approach worked well for 3 months. When we needed instant revocation for a security incident, we added a Redis-backed denylist in ~4 hours. The technical debt was manageable as predicted.
```

Reviewing outcomes is a high-value learning activity. The `reflect` action can incorporate past `either-or` entries as material for reflection.
