---
name: debug
description: 'Diagnose the current workflow session or repo state using logs, traces, state, and focused reproduction'
---

# Debug

## Cursor Compatibility

This skill is formatted for Cursor Agent Skills. Use Cursor's available tools for file edits, shell commands, search, web access, user questions, and any supported delegation. Treat legacy provider, agent, or workflow-tool examples as workflow guidance; if a named tool is unavailable in Cursor, perform the step with available Cursor capabilities or ask the user before substituting behavior.

Use this skill when the user wants help diagnosing a current workflow/host-agent session problem, workflow breakage, or confusing runtime behavior.

## Goal
Find the real failure signal quickly and explain the next corrective step.

## workflow
1. Read the user’s issue description carefully.
2. Inspect the most relevant local evidence first:
   - trace tools
   - state tools
   - notepad / project memory when relevant
   - failing tests or commands
3. Reproduce the issue narrowly if possible.
4. Distinguish symptoms from root cause.
5. Recommend the smallest next fix or verification step.

## Rules
- Prefer real evidence over guesses.
- Use the trace/state surfaces when the issue involves orchestration, hooks, or agent flow.
- If the issue is actually a product/runtime bug rather than app code, say so plainly.
- Do not prescribe broad rewrites before isolating the failure.

## Output
- Observed failure
- Root-cause hypothesis
- Evidence for that hypothesis
- Smallest next action

