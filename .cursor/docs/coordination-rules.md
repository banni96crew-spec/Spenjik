# Agent Coordination Rules

These rules describe how Cursor should coordinate specialist roles during complex game-development workflows. They are process guidance, not a separate Cursor agent runtime.

## Delegation Model

1. **Vertical delegation**: Directors set direction, department leads own domain decisions, and specialists execute scoped work.
2. **Horizontal consultation**: Roles at the same level may compare findings, but they do not make binding decisions outside their domain.
3. **Conflict resolution**: Escalate design conflicts to `creative-director`, technical conflicts to `technical-director`, and scope/timeline conflicts to `producer`.
4. **Change propagation**: When a design change affects multiple domains, `producer` coordinates the impact scan and follow-up work.
5. **No unilateral cross-domain edits**: A role must not edit files outside its domain unless the active skill explicitly delegates that work.

## Review Depth

Use `production/review-mode.txt` when present:

| Mode | Meaning | Use when |
|------|---------|----------|
| `solo` | Skip specialist review passes unless the user asks for them | Fast prototypes, jams, personal work |
| `lean` | Run only phase-gate or high-risk reviews | Default for solo developers and small teams |
| `full` | Run all relevant specialist review passes | High-risk milestones, team workflows, production gates |

If no review mode is configured, default to `lean`.

## Specialist Review Passes

A specialist review pass is an independent analysis step performed from a specific role perspective. It can happen in the same Cursor conversation, a separate Cursor chat, or a Cursor subagent when separate context or parallel execution is useful.

Use specialist review passes when:

- Two or more domains must validate the same artifact.
- A decision is high-risk or cross-system.
- The active skill explicitly requires domain review before writing or approving an artifact.

Do not use specialist review passes when:

- The specialist review pass is a simple single-file edit.
- The answer is already determined by an accepted ADR, GDD, or rule.
- The user asked for a fast solo-mode pass.

## Parallel Review Protocol

When reviews are independent:

1. Start all independent review passes before waiting for results.
2. Give each pass the same artifact paths, constraints, and specific review question.
3. Collect all results before making dependent decisions.
4. If any pass is BLOCKED, surface it immediately and continue only with an explicit fallback.
5. Produce a partial report if some passes complete and others block.

## Skill Metadata

Cursor Skills are selected automatically from the `name` and `description` in each `SKILL.md`. Keep selection cues in those fields instead of carrying over legacy tool-routing metadata.
