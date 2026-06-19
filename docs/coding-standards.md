# Coding Standards

These standards apply to **The Turf / Передел**. Owner PRDs in `docs/prd/` take priority if a conflict is found.

## Source of Truth

- Identify the owner PRD before implementing a system.
- Use `docs/prd/03_IDS_AND_CONSTANTS.md` for stable IDs, errors and event types.
- Use `docs/prd/04_GAME_STATE_SCHEMA.md` for runtime state shapes and ownership.
- Use `docs/prd/15_GODOT_ARCHITECTURE.md` for module boundaries and dependency direction.
- Use `docs/prd/18_TEST_PLAN.md` for test structure and commands.
- Use `docs/prd/19_IMPLEMENTATION_ORDER.md` for milestone prerequisites and gates.
- Use `docs/prd/21_OPEN_QUESTIONS_AND_FIXES.md` instead of inventing missing behavior.

## GDScript

- Target Godot 4.6.2 stable and GDScript only.
- Use static typing wherever practical for variables, parameters, return values, arrays and signals.
- Keep every `.gd` source file under 250 lines.
- Give each file, class and function one focused responsibility.
- Use `PascalCase` for classes, `snake_case` for functions and variables, and `UPPER_SNAKE_CASE` for constants.
- Use canonical production filenames from `15_GODOT_ARCHITECTURE.md`.
- Document public APIs and explain non-obvious invariants or trade-offs.
- Do not hardcode stable gameplay IDs, error strings or event types.
- Keep gameplay values data-driven through explicit Resource fields.
- Do not parse descriptions or display text to recover gameplay rules.

## Architecture and State

Allowed dependency direction:

```text
UI -> GameStateManager -> logic modules -> catalogs/resources/constants
```

- UI must not own gameplay logic or mutate gameplay state directly.
- Logic modules must not import UI, depend on the scene tree or read singleton active state.
- `GameStateManager.gd` remains a thin facade and the only UI-facing mutation boundary.
- Static `.tres` Resources are immutable at runtime.
- Runtime state uses validated `Dictionary` snapshots.
- Validate before mutation, mutate a deep working copy, and commit only when `ok == true`.
- Failed validation must not change state, random step, logs or phase.
- Selectors and previews are read-only and must not consume active gameplay random.
- AI uses the same validated systems as the human player.

## Deterministic Random

- Gameplay random is allowed only through `SeededRandom.gd` and `SeededPicker.gd`.
- Do not use `randf()`, `randi()`, `randomize()`, `RandomNumberGenerator`, system time or OS random for gameplay.
- Preserve exact random-step consumption during bug fixes and refactors.
- Run replay tests when random call order or replay-sensitive flow can change.

## Testing Standards

- Test framework: GUT 9.6.0 with Godot 4.6.2.
- Test files: `test_<module_name>.gd`.
- Test functions: `test_<expected_behavior>()`.
- Use fixed seeds, complete fixtures and isolated test state.
- Required behavior coverage includes happy paths, failed-validation/no-mutation cases, edge cases and adjacent-module integration.
- Selectors and previews require no-mutation and no-random-step tests.
- Random consumers require deterministic-result and exact-step tests.
- Do not weaken, skip or delete valid tests to make a change pass.
- Do not claim a test passed unless its command was executed successfully.

### M0 Bootstrap Smoke

The M0-only bootstrap smoke verifies that the Godot project loads and GUT can discover and execute a minimal test. It contains no gameplay assumptions.

Path:

```text
res://tests/smoke/test_gut_bootstrap.gd
```

PowerShell command:

```powershell
& $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gtest=res://tests/smoke/test_gut_bootstrap.gd -gexit
```

### Canonical MVP Smoke

The canonical integrated smoke is required once its gameplay dependencies exist, no later than M15.

Path:

```text
res://tests/integration/test_smoke_mvp.gd
```

PowerShell command:

```powershell
& $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gtest=res://tests/integration/test_smoke_mvp.gd -gexit
```

### Full GUT Suite

```powershell
& $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

All commands run from the directory containing `project.godot`. These commands become executable after M0 installs GUT; this document does not indicate that M0 has been completed.

## Documentation Standards

- Use Markdown for project documentation.
- Update only the owner document for a rule and link to it from dependent documents.
- Do not duplicate gameplay tables or create competing sources of truth.
- Record unresolved gameplay/API/state questions as `OQ-*`.
- `TODO`, `TBD`, `FIXME` and `???` are forbidden unless linked to a tracked `OQ-*`.
- Keep implementation handoffs explicit: changed files, tests added, commands run, results and remaining limitations.

## Git Standards

- Use Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`.
- Keep one logical change per commit.
- Reference the relevant milestone, task or owner PRD in the commit body when useful.
- Do not commit secrets, machine-specific paths, generated Godot cache or local editor state.
- Do not create commits or push without an explicit user request.

## Completion Checklist

- The change matches its owner PRD and current milestone.
- No unrelated cleanup or future-milestone behavior was introduced.
- Existing user work was preserved.
- Public APIs, result shapes, IDs and error codes remain compatible.
- Relevant GUT tests and static/replay checks were added or updated.
- Executed checks are reported as pass/fail; unexecuted checks are reported as not run.
