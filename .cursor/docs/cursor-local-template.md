# Cursor Local Preferences Template

Use this template for personal Cursor preferences that should not become project-wide policy.
Prefer Cursor User Rules for private preferences. If your team allows local project rules, copy the relevant sections into a gitignored local rule file under `.cursor/rules/`.

## Model And Review Preferences

- Use the strongest available model for cross-document architecture, phase gates, and high-risk design decisions.
- Use the default Cursor model for ordinary implementation, document edits, and focused review.
- Prefer short, evidence-backed answers over broad speculation.

## Workflow Preferences

- Start a new Cursor chat between unrelated tasks when the previous context is no longer useful.
- Keep durable state in project files, especially `production/session-state/active.md` for long-running workflows.
- When I say "review", run the appropriate review skill for the artifact in scope, such as `code-review`, `design-review`, or `story-readiness`.

## Local Environment

- OS: [Windows/macOS/Linux]
- Shell: [PowerShell/Bash/Zsh]
- Game engine path: [path]
- Preferred package manager: [npm/pnpm/uv/cargo/etc.]
- IDE: Cursor

## Communication Style

- [Your preferences here]

## Personal Shortcuts

- "quick status" = run the `help` or `sprint-status` skill, depending on project state.
- "next story" = find the next ready story from the current sprint.
