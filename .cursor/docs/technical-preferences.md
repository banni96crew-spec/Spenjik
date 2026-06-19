# Technical Preferences

Project-specific technical decisions for **The Turf / Передел**.

Source of truth:

- `docs/prd/00_INDEX.md`
- `docs/prd/15_GODOT_ARCHITECTURE.md`
- `docs/prd/17_UI_UX_SPEC.md`
- `docs/prd/18_TEST_PLAN.md`
- `docs/prd/20_LLM_AGENT_RULES.md`
- `docs/prd/21_OPEN_QUESTIONS_AND_FIXES.md`

If this file conflicts with an owner PRD, the owner PRD wins.

## Engine & Language

- **Engine**: Godot 4.6.2 stable.
- **Language**: GDScript.
- **Typing**: Static typing wherever practical.
- **UI**: Godot `Control` nodes, `Container` nodes, scenes and `Theme`.
- **Rendering**: Not specified by the PRD. Keep the Godot 4.6.2 project default unless an approved decision requires a change.
- **Physics**: No gameplay physics requirement is defined for the MVP. Do not make gameplay logic depend on a physics backend without an approved requirement.
- **Runtime State**: `Dictionary` snapshots.
- **Static Data**: Immutable typed `.tres` Resources accessed through catalogs.
- **Gameplay Facade**: `GameStateManager.gd` Autoload.
- **Persistence**: No gameplay persistence in the MVP; only an optional `DebugSnapshotManager.gd` may write development snapshots.

## Input & Platform

- **Target Platforms**: Windows and Linux desktop first.
- **Layout**: Landscape desktop layout.
- **Primary Input**: Mouse.
- **Core Actions**: Every core command must have a button-based flow.
- **Keyboard Support**: Not specified by the PRD beyond normal desktop UI behavior.
- **Gamepad Support**: Not specified by the PRD; do not claim full support until designed and tested.
- **Touch Support**: Not part of the MVP.
- **Mobile/Web**: Mobile-first assumptions and required web export are out of scope.
- **Minimum Window**: Recommended `1280x720`.
- **Target Layout**: Recommended `1920x1080`.
- **Text Baseline**: Readable at 1080p.
- **Interaction Constraint**: Drag-and-drop must not be the only way to perform a core action.

## Naming Conventions

- **Classes / `class_name`**: `PascalCase`.
- **Functions and Variables**: `snake_case`.
- **Private Members**: Prefix with `_`.
- **Signals / Events**: `snake_case`; signal callbacks use `_on_` prefix.
- **Dictionary Keys and String IDs**: `snake_case`.
- **Constants and Enum Values**: `UPPER_SNAKE_CASE`.
- **Production Script Files**: Use the canonical names from `15_GODOT_ARCHITECTURE.md`, such as `GameStateManager.gd`, `MarketLogic.gd`, and `CardDefinition.gd`.
- **Test Files**: `test_<module_name>.gd`.
- **Test Functions**: `test_<expected_behavior>()`.
- **Scenes**: `PascalCase.tscn`, matching the canonical architecture paths.
- **Resource Files**: Canonical lowercase ID names, such as `merchant.tres` or `district_control.tres`.

## Architecture

Allowed production dependency direction:

```text
UI -> GameStateManager -> logic modules -> catalogs/resources/constants
```

- UI renders safe views, collects input payloads and calls only the public `GameStateManager` API.
- `GameStateManager.gd` owns active state, delegates rules and commits only validated successful candidate state.
- Logic modules receive explicit inputs and working state; they do not read singleton state or depend on UI.
- Catalogs load and validate Resources but do not own runtime state.
- Resources contain static data only and are not mutated at runtime.
- AI must use the same owner validators and resolvers as the human player.
- Every `.gd` source file must remain under 250 lines.
- Split validators, resolvers, selectors, builders, catalogs and fixtures when responsibilities differ.

## Performance Budgets

- **Target Framerate**: Not specified in the PRD.
- **Frame Budget**: Not specified in the PRD.
- **Draw Call Budget**: Not specified in the PRD.
- **Memory Ceiling**: Not specified in the PRD.
- **Performance Rule**: Do not invent numeric budgets. Profile before optimizing and document any future accepted budget in the owner architecture documentation.

## Testing

- **Framework**: GUT 9.6.0 with Godot 4.6.2.
- **Coverage Threshold**: No percentage threshold is defined. Behavioral coverage and required test categories are mandatory.
- **Test Roots**: `tests/unit/`, `tests/integration/`, `tests/replay/`, `tests/static/`, `tests/fixtures/`.
- **M0 Bootstrap Smoke**: `tests/smoke/test_gut_bootstrap.gd`; verifies only that Godot and GUT can load and execute a minimal test.
- **Canonical MVP Smoke**: `tests/integration/test_smoke_mvp.gd`; required when the integrated gameplay flow exists, no later than M15.
- **Required Behavior Coverage**:
  - happy path;
  - failed validation with no state mutation;
  - edge cases;
  - adjacent-module integration;
  - selector/preview no-mutation checks;
  - exact deterministic random-step checks where random is consumed;
  - replay checks for replay-sensitive changes;
  - static architecture scans.
- **Determinism**: Use fixed seeds and isolated fixtures. Never depend on current time, OS random or test order.

## Forbidden Patterns

- Gameplay random through `randf()`, `randi()`, `randomize()` or `RandomNumberGenerator`.
- Local random streams, system time or OS random for gameplay.
- UI-owned gameplay calculations or direct state mutation.
- Logic importing UI scenes or reading `GameStateManager` singleton state.
- AI bypassing owner validators, `MarketLogic`, `CombatEngine` or phase flow.
- Runtime mutation of `.tres` Resources.
- Ad-hoc gameplay IDs, event types or validation error strings.
- Parsing descriptions or display text as gameplay data.
- Source files of 250 lines or more.
- Untracked `TODO`, `TBD`, `FIXME` or `???` without an `OQ-*` reference.
- React, TypeScript, JavaScript gameplay runtime, Zustand, Tailwind, Next.js, Docker, backend services, WebSockets and C# implementation.
- Gameplay save/load, accounts, multiplayer, telemetry, analytics, cloud sync or remote configuration in the MVP.

## Allowed Libraries / Addons

- **GUT 9.6.0** — approved test framework.
- No other third-party addon is approved by the PRD.
- Any new addon requires explicit approval, an exact version or commit, source/license review and a Godot 4.6.2 compatibility test.
- Do not modify `addons/gut/` internals unless the task explicitly concerns installing or updating GUT.

## Architecture Decisions

- The modular owner PRDs are the accepted architecture and gameplay authority.
- No separate ADR set is currently required or present.
- Create an ADR only for a new architectural decision not already owned by the PRD; do not duplicate PRD rules into ADRs.
- Unresolved gameplay, API, state or validation decisions belong in `docs/prd/21_OPEN_QUESTIONS_AND_FIXES.md`.

## Engine Specialists

- **Primary**: `godot-specialist`.
- **Language / Code Specialist**: `godot-gdscript-specialist`.
- **Shader Specialist**: `godot-shader-specialist`.
- **UI Specialist**: `ui-programmer`, with `ux-designer` for UX requirements.
- **Testing Specialist**: `test-engineer` or `qa-lead`, using GUT conventions from the PRD.
- **Architecture Review**: `technical-director` or `lead-programmer`.
- **Routing Rule**: Check the pinned Godot reference in `docs/engine-reference/godot/` before using version-sensitive APIs.

### File Extension Routing

| File Extension / Type | Specialist |
|---|---|
| `.gd` gameplay and state code | `godot-gdscript-specialist` |
| `.gdshader`, materials and rendering | `godot-shader-specialist` |
| UI `.gd` and `.tscn` | `ui-programmer` |
| General `.tscn` scene architecture | `godot-specialist` |
| `.tres` schemas and catalogs | `godot-gdscript-specialist` |
| GUT tests under `tests/` | `test-engineer` |
| GDExtension/native code | Out of scope unless separately approved |
| General architecture review | `technical-director` / `lead-programmer` |
