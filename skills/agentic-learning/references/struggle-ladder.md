# Struggle Ladder Reference

This file defines the hint escalation system used by the `struggle` action. The goal is to keep the user in productive struggle as long as possible, revealing only what is needed to unblock them — never more.

---

## Core principle

The struggle is not a failure state. It is the mechanism of learning. Each attempt — even a wrong one — builds a stronger memory trace than passively receiving the answer. The agent's job is to stay at the edge of the user's competence: challenging enough to require effort, supportive enough to prevent abandonment.

---

## Default configuration

- **Default hints before reveal:** 3
- **User can extend:** yes — say "more hints" to get additional conceptual nudges before the reveal
- **User can skip:** yes — say "show me" or "I give up" to jump directly to the full solution
- **User can increase difficulty:** yes — say "harder" to reduce the specificity of each hint

---

## The four levels

### Level 0 — The problem statement

Before any hints, the agent restates the task in clean terms and confirms the user understands *what* they're trying to accomplish. If the user doesn't know where to start at all, Level 0 surfaces that.

**What the agent says:**
- "Let's make sure we're aligned on what we're building. In your own words, what is this function/system supposed to do?"
- If they can't answer: give a one-sentence description of the goal. Then ask: "What would you try first?"

---

### Level 1 — Conceptual direction

Point the user toward the right *area* of thinking without naming the solution or the technique.

**What the agent gives:**
- The domain or category of the solution ("this is fundamentally about ordering", "think about what data structure would let you do X in constant time")
- A question that reframes the problem ("what would need to be true for this to work?", "what happens if the input is empty?")
- A reference to something the user already knows that's related ("remember how we handled the similar case in X?")

**What the agent does NOT give:**
- The name of the algorithm or pattern
- Any code
- The structure of the solution

---

### Level 2 — Structural hint

Describe what the solution *looks like* without writing it. This is about shape and structure, not content.

**What the agent gives:**
- The overall shape: "you'll need a loop here", "this probably has two phases: first X, then Y"
- The type signature or interface: "the function takes A and returns B"
- A constraint that narrows the search space: "you don't need recursion here", "this can be done in a single pass"
- A partial pseudocode sketch in plain English (not code)

**What the agent does NOT give:**
- Actual code in any language
- The specific variable names or logic

---

### Level 3 — Partial code

Give the skeleton. Leave the meaningful parts blank for the user to fill in.

**What the agent gives:**
- The function signature
- The first line or setup code
- Loop or conditional skeleton with `# your logic here` placeholders
- The return statement pattern without the expression

**Example:**
```python
def binary_search(arr, target):
    left, right = 0, len(arr) - 1
    while left <= right:
        mid = # your logic here
        if arr[mid] == target:
            # what do you return?
        elif # condition:
            # adjust left or right?
        else:
            # adjust the other one?
    return -1
```

**What the agent does NOT give:**
- The filled-in logic
- Comments explaining what each blank should contain (unless the user asks)

---

### Reveal — Full solution

Only shown when:
- The user has worked through all 3 hints and is still stuck, AND says "show me" or "I give up"
- OR the user explicitly requests a reveal at any point

**What the agent gives:**
- The complete, working solution
- A brief explanation of each meaningful part
- The key insight that makes it work

**Mandatory follow-up after reveal:**
Always ask: "Now that you've seen it — close this and try to re-implement it from scratch, without looking. That's the part that makes it stick."

---

## Extended hints (user says "more hints")

If the user asks for more hints after Level 3 but before reveal, give up to 2 additional micro-hints:

- **Micro-hint A:** Focus on the single hardest part — give one more structural clue about just that piece
- **Micro-hint B:** Give a concrete analogy from a different domain that maps to the solution structure

After Micro-hint B, only the reveal remains.

---

## "Harder" mode

If the user says "harder" at any point:
- Level 1 becomes purely Socratic: questions only, no directional hints
- Level 2 becomes conceptual direction (what would have been Level 1)
- Level 3 becomes structural hint (what would have been Level 2)
- Reveal is the only way to see actual code

---

## Calibrating difficulty

The agent should also watch for signs of unproductive struggle — frustration without progress — and adjust:

- If the user has been stuck for a long time with no meaningful attempts, it is acceptable to offer a hint one level earlier than scheduled
- If the user is making genuine attempts (even wrong ones), stay at the current level longer
- If the user's attempt is partially correct, build on what they got right: "That's the right idea for the first part — what about the case where X?"
