---
name: skillify
description: 'Turn a repeatable workflow from the current session into a reusable workflow skill draft'
metadata:
  aliases: '[learner]'
---

# Skillify

## Cursor Compatibility

This skill is formatted for Cursor Agent Skills. Use Cursor's available tools for file edits, shell commands, search, web access, user questions, and any supported delegation. Treat legacy provider, agent, or workflow-tool examples as workflow guidance; if a named tool is unavailable in Cursor, perform the step with available Cursor capabilities or ask the user before substituting behavior.

Use this skill when the current session uncovered a repeatable workflow that should become a reusable Cursor skill.

> Compatibility: `/learner` is a deprecated alias for this skill. Prefer `/skillify` in docs, prompts, and new workflows. Internal implementation modules may still use the learner name.

## Goal
Capture a successful multi-step workflow as a concrete skill draft instead of rediscovering it later.

## Quality Gate
Before extracting a skill, all three should be true:
- "Could someone Google this in 5 minutes?" → No.
- "Is this specific to this codebase, project, or workflow?" → Yes.
- "Did this take real debugging, design, or operational effort to discover?" → Yes.

Prefer skills that encode decision-making heuristics, constraints, pitfalls, and verification steps. Avoid generic snippets, boilerplate, or library usage examples that belong in normal documentation.

## workflow
1. Identify the repeatable task the session accomplished.
2. Extract:
   - inputs
   - ordered steps
   - success criteria
   - constraints / pitfalls
   - verification evidence
   - best target location for the skill
3. Decide whether the workflow belongs as:
   - a repo built-in skill
   - a user/project learned skill
   - documentation only
4. When drafting a learned skill file, output a complete skill file that starts with YAML frontmatter.
   - Never emit plain markdown-only skill files.
   - Do **not** write plain markdown without frontmatter.
   - Minimum frontmatter:
     ```yaml
     ---
     name: <skill-name>
     description: <one-line description>
     triggers:
       - <trigger-1>
       - <trigger-2>
     ---
     ```
   - Write learned/user/project skills to flat file-backed paths:
     - `${AGENT_CONFIG_DIR:-~/.agent}/skills/cursor-learned/<skill-name>.md`
     - `.workflow/skills/<skill-name>.md`
   - Remember that uncommitted skills are still worktree-local until committed or copied to a user-scope directory.
5. Draft the rest of the skill file with clear triggers, steps, success criteria, and pitfalls.
6. Point out anything still too fuzzy to encode safely.

## Rules
- Only capture workflows that are actually repeatable.
- Keep the skill practical and scoped.
- Prefer explicit success criteria over vague prose.
- If the workflow still has unresolved branching decisions, note them before drafting.
- Keep `cursor-learned` as the storage directory name for compatibility; do not present it as the public invocation name.

## Output
- Proposed skill name
- Target location
- Draft workflow structure or complete skill file
- Verification or quality-gate notes
- Open questions, if any
