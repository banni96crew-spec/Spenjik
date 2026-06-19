# Path-Specific Rules

Cursor Project Rules live in `.cursor/rules/`. Use them for durable guidance that should be applied when editing specific parts of the project.

Recommended rule set:

| Rule | Applies To | Key Constraints |
|------|------------|-----------------|
| `gameplay-code.mdc` | `src/gameplay/**` | Data-driven values, delta time, no UI ownership |
| `engine-code.mdc` | `src/core/**` | Zero allocations in hot paths, thread safety, stable APIs |
| `ai-code.mdc` | `src/ai/**` | Performance budgets, debuggability, data-driven params |
| `network-code.mdc` | `src/networking/**` | Server-authoritative, versioned messages, security |
| `ui-code.mdc` | `src/ui/**` | No game state ownership, localization-ready, accessibility |
| `design-docs.mdc` | `design/gdd/**` | Required GDD sections, formula format, edge cases |
| `narrative.mdc` | `design/narrative/**` | Lore consistency, character voice, canon levels |
| `data-files.mdc` | `assets/data/**` | JSON validity, naming conventions, schema rules |
| `shader-code.mdc` | `assets/shaders/**` | Naming conventions, performance targets, cross-platform rules |

For broad behavior that is not path-specific, prefer Cursor User Rules or a high-level project rule with a concise description.
