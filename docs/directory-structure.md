# Directory Structure

```text
/
├── .cursor/
│   ├── skills/                  # Cursor Skills, one folder per reusable workflow
│   ├── rules/                   # Cursor Project Rules for path- or workflow-specific guidance
│   └── docs/                    # Workflow documentation, templates, references, and catalogs
├── src/                         # Game source code (core, gameplay, ai, networking, ui, tools)
├── assets/                      # Game assets (art, audio, vfx, shaders, data)
├── design/                      # Game design documents (gdd, narrative, levels, balance)
├── docs/                        # Technical documentation (architecture, api, postmortems)
│   └── engine-reference/        # Curated engine API snapshots (version-pinned)
├── tests/                       # Test suites (unit, integration, performance, playtest)
├── tools/                       # Build and pipeline tools (ci, build, asset-pipeline)
├── prototypes/                  # Throwaway prototypes (isolated from src/)
└── production/                  # Production management (sprints, milestones, releases)
    ├── session-state/           # Ephemeral session state (active.md — gitignored)
    └── session-logs/            # Session audit trail (gitignored)
```

Keep Cursor-specific reusable behavior under `.cursor/`. Keep product, design, production, and implementation artifacts in their domain folders so skills can find them predictably.
