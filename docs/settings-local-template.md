# Cursor Local Settings Template

Cursor does not use Cursor's `Cursor User Rules or local preferences` permission and hook model. Use this document as a checklist for local Cursor configuration and private preferences.

## Where To Put Local Preferences

- Cursor User Rules: private instructions that apply across projects.
- Cursor Project Rules: shared project instructions in `.cursor/rules/` when they should be committed.
- Gitignored local project rules: optional team convention for private project-specific preferences.

## Recommended Local Settings

- Keep project-wide workflow instructions in committed docs and rules, not private settings.
- Keep personal tone, shell, editor, and model preferences in User Rules.
- Do not store secrets in Cursor rules, docs, skills, or chat history.

## Local Automation

Cursor hook events such as `PreToolUse`, `PostToolUse`, `SessionStart`, and `PostCompact` are not assumed to exist in Cursor. For equivalent safety checks, prefer:

- Git hooks for commit/push validation.
- CI workflows for build, test, and asset validation.
- Cursor Rules for path-specific guidance.
- Cursor Skills for explicit project workflows.

## Suggested User Rule Snippet

```markdown
When working in this project, read `.cursor/docs/quick-start.md` and `.cursor/docs/workflow-catalog.yaml` when you need workflow context. Use Cursor Skills from `.cursor/skills/` when a specialist review pass matches their descriptions. Ask before editing production planning artifacts unless the user explicitly requested the edit.
```
