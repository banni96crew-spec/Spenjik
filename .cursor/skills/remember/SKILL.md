---
name: remember
description: 'Review reusable project knowledge and decide what belongs in project memory, notepad, or durable docs'
---

# Remember

## Cursor Compatibility

This skill is formatted for Cursor Agent Skills. Use Cursor's available tools for file edits, shell commands, search, web access, user questions, and any supported delegation. Treat legacy provider, agent, or workflow-tool examples as workflow guidance; if a named tool is unavailable in Cursor, perform the step with available Cursor capabilities or ask the user before substituting behavior.

Use this skill when the user wants to preserve or organize useful knowledge discovered during a session.

## Goal
Promote durable, reusable knowledge into the right memory surface instead of leaving it buried in chat history.

## Memory surfaces
- **Project memory** — durable team/project knowledge
- **Notepad priority** — short high-signal context for the next turns
- **Notepad working** — temporary active-session notes
- **Docs / AGENTS / Cursor Agent files** — durable instructions and conventions when they truly belong there

## workflow
1. Gather the relevant session findings.
2. Classify each item:
   - durable project fact
   - temporary working note
   - operator preference or instruction
   - duplicate / stale / conflicting information
3. Propose the best destination for each item.
4. Write or update only the appropriate memory surface.
5. Call out duplicates or conflicts that should be cleaned up.

## Rules
- Do not dump everything into one store.
- Prefer project memory for durable team knowledge.
- Prefer notepad for short-lived working context.
- Keep entries concise and actionable.
- If something is uncertain, mark it as uncertain rather than storing it as fact.

## Output
- What was stored
- Where it was stored
- Any duplicates/conflicts found

