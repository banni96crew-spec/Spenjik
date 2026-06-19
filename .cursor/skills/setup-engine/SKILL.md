---
name: setup-engine
description: >-
  Validate, pin, refresh, or upgrade the project's Godot 4.6.2 desktop
  environment and local engine reference. This project does not perform engine
  selection.
---

# Setup Engine

## Inputs

- Treat arguments as: `[validate | refresh | upgrade <old-version> <new-version>]`.
- No argument defaults to `validate`.

## Fixed project constraints

- Engine: Godot 4.6.2 stable.
- Language: GDScript.
- Test framework: GUT 9.6.0.
- Platforms: Windows and Linux desktop.
- UI: Godot `Control`, `Container`, scenes, and `Theme`.
- Do not introduce another engine, C#, or an unapproved platform target.
- Owner PRDs and `.cursor/docs/technical-preferences.md` are authoritative.

## Validate mode

1. Read `AGENTS.MD` and `.cursor/docs/technical-preferences.md`.
2. If present, read `docs/engine-reference/godot/VERSION.md`.
3. Locate the configured Godot binary:
   - PowerShell: `$env:GODOT_BIN`, then `Get-Command godot`.
   - Linux shell: `$GODOT_BIN`, then `command -v godot`.
4. Run the binary with `--version` when available.
5. Verify that the reported version is exactly Godot 4.6.2 stable.
6. Verify that the preferences specify GDScript, Windows/Linux desktop, and
   GUT 9.6.0.
7. Report mismatches. Do not silently rewrite owner PRDs or change the engine.

If no executable is available, report `NOT RUN`; do not claim validation
passed.

## Refresh mode

Refresh only the Godot reference already used by this project:

1. Confirm the pinned version from the owner documentation.
2. Use official Godot documentation and release material for that exact
   version.
3. Update only existing files under `docs/engine-reference/godot/`.
4. Preserve project-specific notes and explicitly record source URLs, retrieval
   date, and applicable version.
5. Do not change the pinned version during refresh.

If the reference directory is absent, report the gap and ask before creating a
new documentation set.

## Upgrade mode

An upgrade changes project scope and requires explicit user approval.

1. Confirm old and new exact versions.
2. Gather official migration notes for that version range.
3. Produce an impact report covering:
   - changed or removed APIs;
   - project settings and renderer changes;
   - GDScript compatibility;
   - GUT compatibility;
   - scene, resource, import, and export risks;
   - required validation.
4. Do not change PRDs, engine binaries, project files, or the pinned version
   until the user approves the upgrade plan.

## Agent routing

- General Godot architecture: `godot-specialist`.
- GDScript: `godot-gdscript-specialist`.
- Rendering and shaders: `godot-shader-specialist`.
- UI: `ui-programmer` and `ux-designer`.
- Tests: `test-engineer` or `qa-lead`.

## Output

Report:

- mode;
- expected and detected Godot versions;
- checked files and commands;
- PASS, FAIL, or NOT RUN;
- exact mismatches;
- files changed;
- remaining decisions requiring approval.
