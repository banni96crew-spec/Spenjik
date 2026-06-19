---
name: ccg
description: 'Cursor Agent-Codex-Gemini tri-model orchestration via /ask codex + /ask gemini, then Cursor Agent synthesizes results'
---

# CCG - Cursor Agent-Codex-Gemini Tri-Model Orchestration

## Cursor Compatibility

This skill is formatted for Cursor Agent Skills. Use Cursor's available tools for file edits, shell commands, search, web access, user questions, and any supported delegation. Treat legacy provider, agent, or workflow-tool examples as workflow guidance; if a named tool is unavailable in Cursor, perform the step with available Cursor capabilities or ask the user before substituting behavior.

CCG routes through the canonical `/ask` skill (`/ask codex` + `/ask gemini`), then Cursor Agent synthesizes both outputs into one answer.

Use this when you want parallel external perspectives without launching tmux team workers.

## When to Use

- Backend/analysis + frontend/UI work in one request
- Code review from multiple perspectives (architecture + design/UX)
- Cross-validation where Codex and Gemini may disagree
- Fast advisor-style parallel input without team runtime orchestration

## Requirements

- **Codex CLI**: `npm install -g @openai/codex` (or `@openai/codex`)
- **Gemini CLI**: `npm install -g @google/gemini-cli`
- `omc ask` command available
- If either CLI is unavailable, continue with whichever provider is available and note the limitation

## How It Works

```text
1. Cursor Agent decomposes the request into two advisor prompts:
   - Codex prompt (analysis/architecture/backend)
   - Gemini prompt (UX/design/docs/alternatives)

2. Cursor Agent runs via CLI (skill nesting not supported):
   - `omc ask codex "<codex prompt>"`
   - `omc ask gemini "<gemini prompt>"`

3. Artifacts are written under `.workflow/artifacts/ask/`

4. Cursor Agent synthesizes both outputs into one final response
```

## Execution Protocol

When invoked, Cursor Agent MUST follow this workflow:

### 1. Decompose Request
Split the user request into:

- **Codex prompt:** architecture, correctness, backend, risks, test strategy
- **Gemini prompt:** UX/content clarity, alternatives, edge-case usability, docs polish
- **Synthesis plan:** how to reconcile conflicts

### 2. Invoke advisors via CLI

> **Note:** Skill nesting (invoking a skill from within an active skill) is not supported in Cursor. Always use the direct CLI path via Bash tool.

Run both advisors:

```bash
omc ask codex "<codex prompt>"
omc ask gemini "<gemini prompt>"
```

### 3. Collect artifacts

Read latest ask artifacts from:

```text
.workflow/artifacts/ask/codex-*.md
.workflow/artifacts/ask/gemini-*.md
```

### 4. Synthesize

Return one unified answer with:

- Agreed recommendations
- Conflicting recommendations (explicitly called out)
- Chosen final direction + rationale
- Action checklist

## Fallbacks

If one provider is unavailable:

- Continue with available provider + Cursor Agent synthesis
- Clearly note missing perspective and risk

If both unavailable:

- Fall back to Cursor Agent-only answer and state CCG external advisors were unavailable

## Invocation

```bash
/ccg <task description>
```

Example:

```bash
/ccg Review this PR - architecture/security via Codex and UX/readability via Gemini
```
