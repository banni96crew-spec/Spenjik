# Context Management

Cursor agent context is a shared working resource. Keep the durable state of long workflows in project files so a new chat can resume without relying on hidden conversation history.

## File-Backed State

Maintain `production/session-state/active.md` for long-running workflows. Update it after major steps, before pausing, and before switching topics.

The state file should contain:

```markdown
# Active Session

Task: Implement hitbox detection
Skill: dev-story
Current step: Writing tests
Artifact: production/epics/combat/story-001.md
Next action: Run code-review after tests pass
Open questions:
- [question]
```

For production-stage work, skills may also use a compact status block:

```markdown
<!-- STATUS
Stage: Production
Epic: combat
Feature: hitbox-detection
Task: story-001
Next: code-review
-->
```

## Starting Or Resuming Work

At the beginning of a resumed workflow:

1. Read `production/session-state/active.md` if it exists.
2. Read the primary artifact named in the state file.
3. Reconstruct only the context needed for the next step.
4. Continue from the next incomplete step rather than restarting the workflow.

## When To Start A New Cursor Chat

Start a new chat when:

- The active task changes to an unrelated feature or domain.
- The conversation has accumulated failed attempts or stale assumptions.
- You need an independent review of a document authored in the current chat.
- The active skill explicitly asks for independent review.

Before starting a new chat, write a short state update to `production/session-state/active.md`.

## Context Budgets By Task Type

| Task type | Startup context target |
|-----------|------------------------|
| Light read/review | Current file + relevant rule only |
| Story implementation | Story, linked GDD, linked ADRs, control manifest, touched code |
| Architecture review | GDD summaries, ADR summaries, traceability artifacts |
| Phase gate | Current phase artifacts, prior verdicts, risks, blockers |

## Specialist Review Passes

Use specialist review passes for independent domain critique. Provide full artifact paths and the exact review question. Do not rely on unstated chat history.

A specialist pass should return:

- Verdict: PASS / CONCERNS / BLOCKED / FAIL
- Findings with file references where applicable
- Required changes
- Optional suggestions

## Compaction And Recovery

If context becomes too large, summarize the current state into `production/session-state/active.md`, then continue in a fresh Cursor chat. The next chat should read the state file and the named artifacts first.
