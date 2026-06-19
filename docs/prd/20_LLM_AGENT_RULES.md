# LLM Agent Rules

## Document Role

This file defines only:

* rules for LLM coding agents working on The Turf;
* non-negotiable gameplay preservation constraints;
* PRD source-of-truth rules;
* module ownership rules;
* Godot 4.6.2 implementation rules;
* GDScript coding rules;
* file length rules;
* deterministic random rules;
* mutation-safety rules;
* UI boundary rules;
* AI boundary rules;
* test requirements for LLM-generated code;
* static scan requirements;
* blocker and open-question handling;
* handoff format for future LLM agents.

This file must not redefine:

* card prices;
* card effects;
* role effects;
* contract conditions;
* contact effects;
* Street Deal effects;
* debt rules;
* Turf Level effects;
* AI profiles;
* combat rules;
* economy formulas;
* market generation rules;
* deterministic random algorithms;
* UI layout behavior;
* phase transition rules;
* GameStateManager API behavior;
* implementation order.

Source of truth dependencies:

* 00_INDEX.md
* 01_PRODUCT_OVERVIEW.md
* 02_CORE_LOOP_AND_PHASES.md
* 03_IDS_AND_CONSTANTS.md
* 04_GAME_STATE_SCHEMA.md
* 05_CARDS_DATABASE.md
* 06_ECONOMY_AND_MARKET.md
* 07_COMBAT_SYSTEM.md
* 08_ROLES.md
* 09_CONTRACTS.md
* 10_STREET_DEALS_AND_DEBTS.md
* 11_CONTACTS.md
* 12_TURF_LEVELS.md
* 13_AI_SYSTEM.md
* 14_DETERMINISTIC_RANDOM.md
* 15_GODOT_ARCHITECTURE.md
* 16_GAME_STATE_MANAGER_API.md
* 17_UI_UX_SPEC.md
* 18_TEST_PLAN.md
* 19_IMPLEMENTATION_ORDER.md
* 21_OPEN_QUESTIONS_AND_FIXES.md

Implementation target:

* Godot 4.6.2
* GDScript
* .tres Resources
* Dictionary state snapshots
* GameStateManager.gd Autoload
* GUT tests

## 1. Purpose

This file defines strict operating rules for LLM agents implementing The Turf.

The goal is to prevent common LLM implementation failures:

* silently changing game balance;
* inventing missing mechanics;
* moving gameplay logic into UI;
* bypassing validation;
* using forbidden random APIs;
* creating oversized source files;
* duplicating source-of-truth logic;
* replacing Godot architecture with web-stack patterns;
* weakening tests to make broken code pass.

LLM agents must treat the modular PRD files as executable specification boundaries. If a behavior is not defined, the agent must not guess. It must add or reference an item in `21_OPEN_QUESTIONS_AND_FIXES.md`.

## 2. Ownership Boundaries

This file owns:

* LLM agent behavior rules;
* allowed and forbidden implementation patterns;
* how agents must use source-of-truth documents;
* how agents must handle unclear rules;
* how agents must write, split, and test code;
* handoff requirements between agents.

This file references:

* all gameplay modules for exact rules;
* `15_GODOT_ARCHITECTURE.md` for architecture constraints;
* `18_TEST_PLAN.md` for test expectations;
* `19_IMPLEMENTATION_ORDER.md` for build order;
* `21_OPEN_QUESTIONS_AND_FIXES.md` for unresolved blockers.

This file does not own:

* game mechanics;
* balance values;
* module APIs beyond agent behavior;
* folder structure beyond enforcing architecture rules;
* test content beyond agent requirements.

## 3. Core Terms

| Term               | Meaning                                                                                                               |
| ------------------ | --------------------------------------------------------------------------------------------------------------------- |
| LLM Agent          | Any AI coding assistant, chat agent, code-generation agent, or automated refactor agent working on the project.       |
| Source of Truth    | The single PRD module that owns a rule, state field, ID, or API behavior.                                             |
| Owner Module       | The module responsible for defining and testing a behavior.                                                           |
| Forbidden Guess    | Any invented mechanic, fallback, schema field, or rule not defined by the owner module.                               |
| Safe Stub          | Temporary implementation that returns stable shapes without pretending to implement missing gameplay.                 |
| Mutation-Safe Code | Code where failed validation does not mutate state.                                                                   |
| Static Scan        | Automated test that catches forbidden APIs, architecture violations, and file length issues.                          |
| Handoff            | Context package given to the next LLM agent before it continues implementation.                                       |
| Open Question      | Tracked unresolved issue in `21_OPEN_QUESTIONS_AND_FIXES.md`.                                                         |
| Gameplay Logic     | Any code that affects state, validation, resources, cards, Nal, VP, phases, combat, AI, random, or winner resolution. |

## 4. Runtime State

This module does not define gameplay runtime state.

LLM agents must respect runtime state ownership from:

```text
04_GAME_STATE_SCHEMA.md
```

Required state handling rules:

* active gameplay state lives in `GameStateManager.gd`;
* runtime state is stored as Dictionary snapshots;
* `.tres` Resources are static data and must not store runtime state;
* UI-local state may store temporary selections only;
* failed validation must not mutate active state;
* selectors and previews must not mutate state;
* random-consuming functions must update `state["random"]` only through deterministic helpers.

LLM agents must not introduce new runtime state fields unless:

1. the field is defined by the owner PRD module;
2. the field is added to `04_GAME_STATE_SCHEMA.md`;
3. validation rules are updated;
4. tests are added.

## 5. Rules

### 5.1. Non-Negotiable Gameplay Preservation Rules

LLM agents must not change:

| Protected Area                | Rule                                                                                   |
| ----------------------------- | -------------------------------------------------------------------------------------- |
| Game length                   | Must remain exactly 15 rounds.                                                         |
| Core loop                     | Must remain Income → Market → Action → optional Street Deal → next round or game over. |
| Card IDs                      | Must not be renamed.                                                                   |
| Card prices                   | Must not be changed.                                                                   |
| Card effects                  | Must not be changed.                                                                   |
| Role IDs                      | Must not be renamed.                                                                   |
| Role effects                  | Must not be changed.                                                                   |
| Contract IDs                  | Must not be renamed.                                                                   |
| Contract conditions           | Must not be changed.                                                                   |
| Contract rewards              | Must not be changed.                                                                   |
| Contact IDs                   | Must not be renamed.                                                                   |
| Contact effects               | Must not be changed.                                                                   |
| Street Deal IDs               | Must not be renamed.                                                                   |
| Street Deal option effects    | Must not be changed.                                                                   |
| Debt rules                    | Must not be changed.                                                                   |
| Turf Levels                   | Must not be changed.                                                                   |
| AI profile IDs                | Must not be renamed.                                                                   |
| AI profile values             | Must not be changed.                                                                   |
| Deterministic random contract | Must not be changed.                                                                   |
| File length rule              | Source files must stay under 250 lines.                                                |

If a requested implementation appears to require changing one of these protected areas, the agent must stop and ask for a design decision or add an open question.

### 5.2. Source-of-Truth Rule

Before editing or generating code, the LLM agent must identify:

* target module;
* owner PRD file;
* dependent PRD files;
* required source files;
* required tests;
* affected state fields.

The agent must not implement behavior from memory if a module owns it.

Examples:

| Task                       | Required Owner                 |
| -------------------------- | ------------------------------ |
| Buying a card              | `06_ECONOMY_AND_MARKET.md`     |
| Resolving `thug`           | `07_COMBAT_SYSTEM.md`          |
| Applying Merchant discount | `08_ROLES.md`                  |
| Claiming a contract        | `09_CONTRACTS.md`              |
| Resolving `loan_shark`     | `10_STREET_DEALS_AND_DEBTS.md` |
| Applying `street_medic`    | `11_CONTACTS.md`               |
| Applying Turf Level 8      | `12_TURF_LEVELS.md`            |
| AI choosing target         | `13_AI_SYSTEM.md`              |
| Random tie-break           | `14_DETERMINISTIC_RANDOM.md`   |
| UI buy button behavior     | `17_UI_UX_SPEC.md`             |

### 5.3. No Invention Rule

LLM agents must not invent:

* new cards;
* new roles;
* new contracts;
* new contacts;
* new Street Deals;
* new debts;
* new Turf Levels;
* new AI profiles;
* new phases;
* new random systems;
* new validation meanings;
* hidden campaign progression;
* hidden save/load behavior;
* replacement contact rules;
* AI Street Deal choice rules.

If behavior is unclear:

1. do not implement it;
2. add or reference an `OQ-*` item in `21_OPEN_QUESTIONS_AND_FIXES.md`;
3. implement only the defined safe subset.

### 5.4. Godot-Only Rule

Implementation must target:

```text
Godot 4.6.2
GDScript
Godot Control UI
.tres Resources
GUT
```

Forbidden implementation targets:

* React;
* TypeScript;
* JavaScript gameplay runtime;
* Zustand;
* Tailwind;
* Docker;
* WebSocket backend;
* Node backend;
* browser-first architecture;
* C# version;
* mobile-first architecture.

The project is a local Godot desktop game.

### 5.5. Architecture Boundary Rule

Allowed dependency direction:

```text
UI → GameStateManager → logic modules → catalogs/resources/constants
```

Forbidden:

* UI mutating gameplay state directly;
* UI calling low-level mutators directly;
* logic importing UI scenes;
* Resources mutating runtime state;
* AI bypassing MarketLogic or CombatEngine;
* WinnerResolver using random;
* GameStateManager becoming a gameplay mega-file.

### 5.6. File Length Rule

Every `.gd` source file must stay under:

```text
250 lines
```

This applies to:

* logic files;
* Autoload files;
* UI scripts;
* Resource schema scripts;
* constants files;
* tests where practical.

If a file approaches the limit, split it into:

* validator;
* resolver;
* log builder;
* selector;
* catalog;
* helper;
* test fixture.

Do not create god-objects.

### 5.7. Deterministic Random Rule

Gameplay random must go only through:

```text
res://logic/random/SeededRandom.gd
res://logic/random/SeededPicker.gd
```

Forbidden in gameplay logic:

```text
randf(
randi(
randomize(
RandomNumberGenerator
```

LLM agents must not:

* create local random streams;
* use `game_seed + round` as standalone random;
* use system time;
* use OS random;
* use Godot RandomNumberGenerator;
* consume random in preview functions;
* use random in WinnerResolver.

### 5.8. Mutation Safety Rule

Failed validation must not mutate state.

Required mutator pattern:

1. validate first;
2. mutate only a working copy;
3. return structured result;
4. commit only if `ok == true`;
5. leave active state unchanged on failure.

Selectors and previews must not:

* mutate state;
* consume random;
* write logs;
* consume flags;
* consume temporary modifiers;
* advance phases.

### 5.9. UI Rule

UI may:

* display state;
* collect user input;
* build payloads;
* call GameStateManager;
* show disabled reasons;
* request previews;
* refresh views.

UI must not:

* calculate final price;
* validate affordability;
* apply card effects;
* resolve combat;
* mutate Nal or VP;
* unlock contacts;
* claim rewards directly;
* apply Street Deal effects;
* process debts;
* run AI logic;
* call random for gameplay.

### 5.10. AI Rule

AI may choose actions, but it must use the same validated systems as the human.

AI must not:

* buy cards by directly changing Nal or owned cards;
* attack by directly changing target state;
* bypass reserve rules;
* bypass CombatEngine;
* bypass MarketLogic;
* receive human roles in MVP;
* receive contracts in MVP;
* choose Street Deals in MVP;
* override module validation.

### 5.11. Test Rule

Every implementation task must include or update tests.

Minimum requirements:

* happy-path test;
* failed-validation mutation test;
* edge-case test;
* selector no-mutation test if selectors are involved;
* deterministic random step test if random is involved;
* static scan update if architecture risk is involved.

LLM agents must not weaken tests to make broken implementation pass.

### 5.12. Open Question Rule

Unclear behavior must be tracked in:

```text
21_OPEN_QUESTIONS_AND_FIXES.md
```

Allowed ambiguity markers in code or docs only if linked to an open question:

* `TODO`;
* `TBD`;
* `FIXME`;
* `???`.

Untracked ambiguity markers must fail static scan.

## 6. Validation Rules

### 6.1. Agent Pre-Implementation Checklist

Before writing code, the LLM agent must verify:

| Check                                |           Required |
| ------------------------------------ | -----------------: |
| Target module is identified          |                yes |
| Owner PRD file is known              |                yes |
| Dependency PRD files are known       |                yes |
| Required source files are known      |                yes |
| Required tests are known             |                yes |
| Relevant state fields are known      |                yes |
| Relevant validation errors are known |                yes |
| Random usage is known                | yes, if applicable |
| Open questions are checked           |                yes |
| File split plan exists               |                yes |

### 6.2. Agent Output Validation

Every code output must satisfy:

| Condition                       | Required |
| ------------------------------- | -------: |
| Godot 4.6.2 compatible GDScript |      yes |
| Static typing where practical   |      yes |
| Stable result shapes            |      yes |
| No forbidden random APIs        |      yes |
| No UI-owned gameplay logic      |      yes |
| No Resource runtime mutation    |      yes |
| No source file over 250 lines   |      yes |
| Tests added or updated          |      yes |
| Failed validation safe          |      yes |

### 6.3. Validation Error Rule

LLM agents must use stable error constants from:

```text
res://data/ids/ValidationErrors.gd
```

Agents must not return ad-hoc error strings.

If a needed error code is missing:

1. stop implementation of the affected path;
2. add or resolve an `OQ-*` entry in `21_OPEN_QUESTIONS_AND_FIXES.md`;
3. update the owner PRD and `03_IDS_AND_CONSTANTS.md` before adding the constant;
4. update tests.

Fallback and ad-hoc error codes are forbidden.

### 6.4. Resource Validation Rule

When creating `.tres` Resources:

* IDs must match constants;
* no duplicate IDs;
* required fields must be filled;
* descriptions are display text only;
* effect summaries must not be parsed by logic;
* Resources must not contain runtime state.

### 6.5. Failed Implementation Rule

If tests fail:

* do not continue to later modules;
* do not remove tests;
* do not loosen assertions without checking owner PRD;
* fix the implementation or escalate to open question.

## 7. Resolution / Processing Flow

### 7.1. Standard LLM Implementation Flow

For every coding task, the LLM agent must follow this order:

1. Read the target module PRD.
2. Read direct dependency PRDs.
3. Identify owner module boundaries.
4. Check `21_OPEN_QUESTIONS_AND_FIXES.md`.
5. Identify required source files and tests.
6. Create or update tests.
7. Implement the smallest valid code slice.
8. Run relevant tests.
9. Run static scans.
10. Split files if near 250 lines.
11. Return a concise implementation summary with changed files and test status.

### 7.2. Bug Fix Flow

When fixing a bug:

1. Reproduce with a failing test.
2. Confirm expected behavior from owner PRD.
3. Fix implementation.
4. Add regression test if missing.
5. Run affected tests.
6. Run static scans if touched architecture/random/UI.
7. Do not change balance unless owner PRD explicitly changes.

### 7.3. Refactor Flow

When refactoring:

1. Do not change behavior.
2. Keep public APIs stable.
3. Preserve result shapes.
4. Preserve deterministic random step counts.
5. Preserve error codes.
6. Run all affected tests.
7. Run replay tests if random, AI, phase, market, or combat order changed.

### 7.4. Open Question Flow

If behavior is unclear:

1. Stop implementing that behavior.
2. Add an `OQ-*` item to `21_OPEN_QUESTIONS_AND_FIXES.md`.
3. Include:

   * module;
   * unclear rule;
   * options;
   * recommended option;
   * gameplay impact.
4. Implement only unrelated safe parts.
5. Add tests only for defined behavior.

### 7.5. Handoff Flow

At handoff, the LLM agent must provide:

* completed files;
* changed files;
* tests added;
* tests passing;
* tests failing;
* open questions created or referenced;
* known limitations;
* next recommended milestone.

The next agent must not assume hidden context.

## 8. API Expectations

This module has no runtime gameplay API.

It defines the required format for LLM task prompts and handoffs.

### 8.1. Required LLM Task Prompt Shape

Every implementation task given to an LLM agent should include:

```text
Target module:
Target source files:
Owner PRD:
Dependency PRDs:
Required tests:
Allowed changes:
Forbidden changes:
Open questions to respect:
Acceptance criteria:
```

### 8.2. Recommended Agent Work Summary Shape

At the end of an implementation task, the agent should report:

```text
Implemented:
- ...

Changed files:
- ...

Tests added/updated:
- ...

Tests run:
- ...

Result:
- pass/fail/not run

Open questions:
- none / OQ-...

Notes:
- ...
```

### 8.3. Required Code Result Shape Convention

Mutator result:

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"state": {},
	"log_entries": []
}
```

Failed result:

```gdscript
{
	"ok": false,
	"error": ValidationErrors.REQUIREMENT_NOT_MET,
	"state": {}
}
```

Selectors:

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"view": {}
}
```

## 9. Edge Cases

| Edge Case                             | Condition                                          | Expected Behavior                                                                       | Error Code | Mutation Rule                          |
| ------------------------------------- | -------------------------------------------------- | --------------------------------------------------------------------------------------- | ---------- | -------------------------------------- |
| Agent finds conflicting PRD rules     | Two files disagree.                                | Follow lower-numbered owner only if ownership is clear; otherwise create open question. | N/A        | Do not implement conflicting behavior. |
| Agent needs missing state field       | Field not in schema.                               | Update owner schema PRD or open question first.                                         | N/A        | Do not add hidden field.               |
| Agent needs missing error code        | Error not in constants.                            | Stop the affected path; resolve an `OQ-*`, then update the owner PRD and constants.      | N/A        | No gameplay mutation.                  |
| Agent file exceeds 250 lines          | Source file too long.                              | Split immediately.                                                                      | N/A        | No behavior change.                    |
| Agent wants helper class              | Helper reduces file length or clarity.             | Allowed if architecture direction remains valid.                                        | N/A        | Helper must not own unrelated rules.   |
| Agent wants to parse description text | Resource has readable summary.                     | Forbidden. Use explicit IDs and fields.                                                 | N/A        | No mutation.                           |
| Agent cannot run tests                | Tooling unavailable.                               | Say tests were not run; do not claim they passed.                                       | N/A        | No false status.                       |
| Agent sees failing test               | Test fails after change.                           | Fix or report failure.                                                                  | N/A        | Do not hide.                           |
| Agent modifies random call order      | Random step changes.                               | Must update only if owner module requires; run replay tests.                            | N/A        | Preserve replay determinism.           |
| Agent adds UI behavior needing logic  | UI needs new selector.                             | Add selector to `16_GAME_STATE_MANAGER_API.md` first.                                   | N/A        | UI must not read internals.            |
| Agent sees missing gameplay rule      | Rule absent from owner module.                     | Add open question.                                                                      | N/A        | Do not invent.                         |
| Agent creates temporary stub          | Stub allowed only by `19_IMPLEMENTATION_ORDER.md`. | Must be marked incomplete.                                                              | N/A        | Stub must not fake gameplay.           |
| Agent uses web stack                  | Creates React/TS/Zustand/Tailwind/Docker file.     | Forbidden. Static scan fails.                                                           | N/A        | Remove file.                           |
| Agent uses forbidden random           | Gameplay code includes Godot RNG.                  | Forbidden. Static scan fails.                                                           | N/A        | Replace with deterministic random.     |

## 10. Required Source Files

This module requires no gameplay source file.

LLM agents must respect required source files listed in:

* `15_GODOT_ARCHITECTURE.md`;
* module-specific PRD files;
* `18_TEST_PLAN.md`;
* `19_IMPLEMENTATION_ORDER.md`.

Recommended documentation file:

```text
res://docs/agent_handoff_template.md
```

Optional. Must not be used by gameplay code.

## 11. Required GUT Tests

This module does not require a dedicated gameplay test file.

Its rules must be enforced through static and architecture tests.

Recommended static tests:

* `res://tests/static/test_file_length_scan.gd`;
* `res://tests/static/test_static_random_scan.gd`;
* `res://tests/static/test_architecture_static_scan.gd`;
* `res://tests/static/test_ui_static_boundaries.gd`;
* `res://tests/static/test_open_questions_docs.gd`;
* `res://tests/static/test_banned_stack_scan.gd`.

Minimum checks:

* no forbidden random APIs in gameplay code;
* no UI direct gameplay mutation;
* no logic-to-UI dependencies;
* no source file over 250 lines;
* no banned web-stack files;
* no untracked `TODO`, `TBD`, `FIXME`, or `???`;
* no duplicate source-of-truth docs for one module.

## 12. Static Scan Requirements

Static scan must fail if gameplay `.gd` files contain:

```text
randf(
randi(
randomize(
RandomNumberGenerator
```

Static scan must fail if UI scripts contain direct gameplay mutation patterns:

```text
GameStateManager.state[
["nal"] +=
["nal"] -=
["vp"] +=
["vp"] -=
["hand"].append
["hand"].erase
["purchased_this_round"].append
["combat_log"].append
```

Static scan must fail if logic files reference UI implementation:

```text
res://scenes/ui/
Control
Button
Label
TextureRect
Panel
get_node(
$"
```

Static scan must fail if source files exceed:

```text
250 lines
```

Static scan must fail if project contains banned implementation stack artifacts:

* `.tsx`;
* `.jsx`;
* `.ts` gameplay files;
* `package.json`;
* `tailwind.config`;
* `vite.config`;
* `next.config`;
* `docker-compose.yml`;
* `Dockerfile`;
* `zustand`;
* `React`;
* `WebSocket` backend.

Exception:

* Markdown may mention banned stack terms only as forbidden/out-of-scope references.
* Tests may mention banned patterns only to scan for them.

Static scan must fail if docs or code contain ambiguity markers without an `OQ-*` reference:

* `TODO`;
* `TBD`;
* `FIXME`;
* `???`.

## 13. Implementation Notes For LLM Agents

When coding:

* Use Godot 4.6.2 GDScript.
* Use static typing wherever practical.
* Use `class_name` for reusable classes.
* Use `snake_case` Dictionary keys.
* Use constants for stable IDs.
* Use `.tres` Resources for static data.
* Use Dictionaries for runtime state.
* Use GameStateManager as the UI-facing facade.
* Use owner modules for gameplay rules.
* Use stable result shapes.
* Validate before mutating.
* Duplicate state for public mutators.
* Commit only on success.
* Keep previews read-only.
* Keep selectors read-only.
* Keep Resources immutable.
* Keep files under 250 lines.
* Split early.
* Add tests with code.
* Run static scans.
* Be honest about tests not run.

When not coding:

* Do not promise future background work.
* Do not claim implementation is complete without tests.
* Do not hide uncertainty.
* Do not invent missing logic.
* Do not produce mixed-language docs unless explicitly requested.
* Do not rewrite protected gameplay rules.

## 14. Acceptance Criteria

This module is complete when:

* LLM agents have clear non-negotiable constraints;
* protected gameplay areas are listed;
* source-of-truth behavior is defined;
* no-invention rule is explicit;
* Godot-only implementation rule is explicit;
* deterministic random restrictions are explicit;
* UI boundary rules are explicit;
* AI boundary rules are explicit;
* file length rule is explicit;
* mutation-safety requirements are explicit;
* open-question handling is explicit;
* handoff format is defined;
* static scan requirements are defined;
* banned stack artifacts are defined;
* test expectations are defined;
* future coding agents can implement modules without guessing architectural behavior.

## 15. Final Rule

An LLM agent may generate code, tests, and docs, but it must never become the designer of hidden gameplay rules.
