---
name: omc-reference
description: 'workflow agent catalog, available tools, team pipeline routing, commit protocol, and skills registry. Auto-loads when delegating to agents, using workflow tools, orchestrating teams, making commits, or invoking skills.'
disable-model-invocation: true
metadata:
  user-invocable: 'false'
---

# workflow Reference

## Cursor Compatibility

This skill is formatted for Cursor Agent Skills. Use Cursor's available tools for file edits, shell commands, search, web access, user questions, and any supported delegation. Treat legacy provider, agent, or workflow-tool examples as workflow guidance; if a named tool is unavailable in Cursor, perform the step with available Cursor capabilities or ask the user before substituting behavior.

Use this built-in reference when you need detailed workflow catalog information that does not need to live in every `primary-agent.md` session.

## Agent Catalog

Prefix: ``. See `agents/*.md` for full prompts.

- `explore` (haiku) — fast codebase search and mapping
- `analyst` (opus) — requirements clarity and hidden constraints
- `planner` (opus) — sequencing and execution plans
- `architect` (opus) — system design, boundaries, and long-horizon tradeoffs
- `debugger` (sonnet) — root-cause analysis and failure diagnosis
- `executor` (sonnet) — implementation and refactoring
- `verifier` (sonnet) — completion evidence and validation
- `tracer` (sonnet) — trace gathering and evidence capture
- `security-reviewer` (sonnet) — trust boundaries and vulnerabilities
- `code-reviewer` (opus) — comprehensive code review
- `test-engineer` (sonnet) — testing strategy and regression coverage
- `designer` (sonnet) — UX and interaction design
- `writer` (haiku) — documentation and concise content work
- `qa-tester` (sonnet) — runtime/manual validation
- `scientist` (sonnet) — data analysis and statistical reasoning
- `document-specialist` (sonnet) — SDK/API/framework documentation lookup
- `git-master` (sonnet) — commit strategy and history hygiene
- `code-simplifier` (opus) — behavior-preserving simplification
- `critic` (opus) — plan/design challenge and review

## Model Routing

- `haiku` — quick lookups, lightweight inspection, narrow docs work
- `sonnet` — standard implementation, debugging, and review
- `opus` — architecture, deep analysis, consensus planning, and high-risk review

## Tools Reference

### External AI / orchestration
- `/team N:executor "task"`
- `omc team N:codex|gemini "..."`
- `omc ask <Cursor Agent|codex|gemini>`
- `/ccg`

### workflow state
- `state_read`, `state_write`, `state_clear`, `state_list_active`, `state_get_status`

### Team runtime
- `TeamCreate`, `TeamDelete`, `SendMessage`, `TaskCreate`, `TaskList`, `TaskGet`, `TaskUpdate`

### Notepad
- `notepad_read`, `notepad_write_priority`, `notepad_write_working`, `notepad_write_manual`

### Project memory
- `project_memory_read`, `project_memory_write`, `project_memory_add_note`, `project_memory_add_directive`

### Code intelligence
- LSP: `lsp_hover`, `lsp_goto_definition`, `lsp_find_references`, `lsp_diagnostics`, and related helpers
- AST: `ast_grep_search`, `ast_grep_replace`
- Utility: `python_repl`

## Skills Registry

Invoke built-in workflows via `/<name>`.

### Cursor skills
- `autopilot` — full autonomous execution from idea to working code
- `Ralph` — persistence loop until completion with verification
- `ultrawork` — high-throughput parallel execution
- `visual-verdict` — structured visual QA verdicts
- `team` — coordinated team orchestration
- `ccg` — Codex + Gemini + Cursor Agent synthesis lane
- `ultraqa` — QA cycle: test, verify, fix, repeat
- `workflow-plan` — planning workflow and `/plan`-safe alias
- `ralplan` — consensus planning workflow
- `science-workflow` — science/research workflow
- `external-context` — external docs/research workflow
- `deepinit` — hierarchical AGENTS.md generation
- `deep-interview` — Socratic ambiguity-gated requirements workflow
- `ai-slop-cleaner` — regression-safe cleanup workflow

### Utility skills
- `ask`, `cancel`, `note`, `skillify`, `learner` (deprecated alias), `workflow-setup`, `mcp-setup`, `hud`, `workflow-doctor`, `trace`, `release`, `project-session-manager`, `skill`, `writer-memory`, `configure-notifications`

### Keyword triggers kept compact in primary-agent.md
- `"autopilot"→autopilot`
- `"Ralph"→Ralph`
- `"ulw"→ultrawork`
- `"ccg"→ccg`
- `"ralplan"→ralplan`
- `"deep interview"→deep-interview`
- `"deslop" / "anti-slop"→ai-slop-cleaner`
- `"deep-analyze"→analysis mode`
- `"tdd"→TDD mode`
- `"deepsearch"→codebase search`
- `"ultrathink"→deep reasoning`
- `"cancel-workflow"→cancel`
- Team orchestration is explicit via `/team`.

## Team Pipeline

Stages: `team-plan` → `team-prd` → `team-exec` → `team-verify` → `team-fix` (loop).

- Use `team-fix` for bounded remediation loops.
- `team Ralph` links the team pipeline with Ralph-style sequential verification.
- Prefer team mode when independent parallel lanes justify the coordination overhead.

## Commit Protocol

Use git trailers to preserve decision context in every commit message.

### Format
- Intent line first: why the change was made
- Optional body with context and rationale
- Structured trailers when applicable

### Common trailers
- `Constraint:` active constraint shaping the decision
- `Rejected:` alternative considered | reason for rejection
- `Directive:` forward-looking warning or instruction
- `Confidence:` `high` | `medium` | `low`
- `Scope-risk:` `narrow` | `moderate` | `broad`
- `Not-tested:` known verification gap

### Example
```text
feat(docs): reduce always-loaded workflow instruction footprint

Move reference-only orchestration content into a native Cursor Agent skill so
session-start guidance stays small while detailed workflow reference remains available.

Constraint: Preserve primary-agent.md marker-based installation flow
Rejected: Sync all built-in skills in legacy install | broader behavior change than issue requires
Confidence: high
Scope-risk: narrow
Not-tested: End-to-end plugin marketplace install in a fresh Cursor Agent profile
```
