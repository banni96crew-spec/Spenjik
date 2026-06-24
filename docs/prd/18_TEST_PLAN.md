# Test Plan

## Document Role

This file defines only:

* test strategy;
* GUT test structure;
* unit test ownership;
* integration test ownership;
* replay test requirements;
* static scan requirements;
* fixture requirements;
* test naming conventions;
* minimum required test files;
* validation expectations for all modules;
* mutation-safety test rules;
* deterministic-random test rules;
* architecture-boundary test rules.

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
* UI behavior;
* phase transition logic.

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
* 19_IMPLEMENTATION_ORDER.md
* 20_LLM_AGENT_RULES.md
* 21_OPEN_QUESTIONS_AND_FIXES.md

Implementation target:

* Godot 4.6.2
* GDScript
* .tres Resources
* Dictionary state snapshots
* GameStateManager.gd Autoload
* GUT tests

## 1. Purpose

The test plan defines how The Turf must be verified before implementation is considered stable.

The project is built through LLM-assisted coding, so tests must act as executable rules. Every gameplay module must have:

* unit tests for isolated rules;
* integration tests for cross-module behavior;
* mutation-safety tests;
* deterministic replay tests where random is involved;
* static scans for forbidden APIs and architecture violations.

The test plan exists to prevent coding agents from silently changing gameplay, inventing missing mechanics, or moving logic into UI.

## 2. Ownership Boundaries

This file owns:

* test file layout;
* minimum test coverage by module;
* test fixture rules;
* static scan rules;
* deterministic replay requirements;
* acceptance test categories;
* test execution expectations.

This file references:

* each module PRD for exact behavior under test;
* `14_DETERMINISTIC_RANDOM.md` for replay-safe random;
* `15_GODOT_ARCHITECTURE.md` for folder and boundary scans;
* `16_GAME_STATE_MANAGER_API.md` for facade mutation tests;
* `20_LLM_AGENT_RULES.md` for coding-agent constraints.

This file does not own:

* gameplay rules;
* expected prices;
* expected card effects;
* AI scores;
* UI layout;
* implementation order;
* production save/load behavior.

If a test exposes unclear gameplay behavior, the issue must be added to:

```text
21_OPEN_QUESTIONS_AND_FIXES.md
```

The test must not invent the missing rule.

## 3. Core Terms

| Term                 | Meaning                                                                                  |
| -------------------- | ---------------------------------------------------------------------------------------- |
| Unit Test            | Test for one logic class or small rule group.                                            |
| Integration Test     | Test across multiple modules using real state snapshots.                                 |
| Static Scan          | Test that inspects source text for forbidden APIs or architecture violations.            |
| Replay Test          | Test that reruns the same scripted game with the same seed and expects identical output. |
| Fixture              | Reusable test state, player, card, or payload builder.                                   |
| Mutation-Safety Test | Test proving failed validation does not mutate active or working state.                  |
| Selector Test        | Test proving previews/views do not mutate state or active random.                        |
| Golden Snapshot      | Stored expected Dictionary output used for deterministic comparison.                     |
| Owner Module         | Module whose rules define expected behavior.                                             |
| Smoke Test           | Fast test proving a broad flow does not crash and returns valid state.                   |

## 4. Runtime State

### 4.1. Test Runtime State Rule

Tests must use Dictionary state snapshots matching:

```text
04_GAME_STATE_SCHEMA.md
```

Tests must not use UI scene state as gameplay state.

Allowed state creation sources:

* `GameStateFactory.gd`;
* `TestGameStateFactory.gd`;
* module-specific fixture helpers.

Forbidden:

* hand-written incomplete state in every test;
* UI scene nodes as gameplay state;
* mutable `.tres` Resources as runtime state.

### 4.2. Required Test Fixture Shape

Recommended fixture helper:

```gdscript
class_name TestGameStateFactory

static func base_state(seed: String = "test_seed") -> Dictionary:
	return {}

static func state_with_players(seed: String = "test_seed") -> Dictionary:
	return {}

static func market_state(seed: String = "test_seed") -> Dictionary:
	return {}

static func action_state(seed: String = "test_seed") -> Dictionary:
	return {}

static func street_deal_state(seed: String = "test_seed") -> Dictionary:
	return {}
```

### 4.3. Snapshot Comparison Rule

Snapshot comparisons must ignore only explicitly debug-only fields.

Allowed ignored fields:

* wall-clock timestamps, if any exist in debug logs;
* editor-only metadata;
* an empty random history array if the test is not checking history entries.

Gameplay fields must not be ignored:

* Nal;
* VP;
* market;
* hand;
* engine;
* defense;
* status buildings;
* contracts;
* contacts;
* debts;
* random step;
* phase;
* winner;
* combat log.

### 4.4. Test Seed Rule

Tests must use stable string seeds.

Recommended seeds:

```text
test_seed_001
test_seed_market
test_seed_income
test_seed_ai
test_seed_replay
```

Tests must not use:

* current time;
* OS random;
* generated UUIDs;
* Godot random APIs.

## 5. Rules

### 5.1. GUT Rule

The project must use GUT 9.6.0 with Godot 4.6.2.

Required folder:

```text
res://tests/
```

Canonical full-suite command from the Godot project root on Linux/macOS/CI:

```bash
godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Canonical full-suite command from PowerShell:

```powershell
& $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

`godot` and `GODOT_BIN` must resolve to Godot 4.6.2. Commands must run from the directory containing `project.godot`. GUT returns exit code `0` only when all selected tests pass and exit code `1` when any selected test fails.

### 5.1.1. M0 Bootstrap Smoke Test

M0 uses a dedicated infrastructure-only smoke test:

```text
res://tests/smoke/test_gut_bootstrap.gd
```

Canonical M0 bootstrap smoke command on Linux/macOS/CI:

```bash
godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://tests/smoke/test_gut_bootstrap.gd -gexit
```

Canonical M0 bootstrap smoke command from PowerShell:

```powershell
& $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gtest=res://tests/smoke/test_gut_bootstrap.gd -gexit
```

This test verifies only that:

1. the Godot project imports and starts headlessly;
2. GUT is installed and can discover the selected test;
3. GUT can execute a minimal deterministic assertion;
4. no gameplay logic, gameplay state, catalogs, Resources, facade methods or future-milestone assumptions are required.

The M0 bootstrap smoke is not the canonical MVP smoke and must not be expanded into a fake gameplay flow.

### 5.1.2. Canonical MVP Smoke Test

Required smoke test:

```text
res://tests/integration/test_smoke_mvp.gd
```

Canonical smoke command on Linux/macOS/CI:

```bash
godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://tests/integration/test_smoke_mvp.gd -gexit
```

The smoke test performs exactly this scenario:

1. Load the project and required catalogs/resources.
2. Call `start_new_game` with fixed seed `test_seed_smoke`, Turf Level `0`, role `merchant`, and a contract selected from the deterministic preview.
3. Assert committed state validates, contains `player_1`, `ai_1`, `ai_2`, `ai_3`, and starts in Income.
4. Call `advance_phase`.
5. Assert Income resolved once for all four players, random state remains valid, phase is Market, MarketState validates, and canonical Income/phase events exist.
6. Assert no uncaught script, Resource, schema, or validation error occurred.

This integrated smoke becomes required when its dependencies exist, no later than M15. It is not an M0 gate because M0 must not implement `GameStateManager`, gameplay state, Resources, catalogs, Income or phase logic.

CI must run:

```bash
godot --headless --editor --path "$PWD" --quit
godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://tests/integration/test_smoke_mvp.gd -gexit
godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Success means all three commands exit `0`, the smoke test has zero failed assertions, and the full GUT suite has zero failed tests. Any non-zero exit code, parse/import error, missing Resource, schema failure, failed assertion, or test-process timeout is a CI failure.

### 5.2. Test File Length Rule

Test files should stay under:

```text
250 lines
```

If a test file grows too large:

* split by module;
* split by behavior group;
* move fixture helpers into `tests/fixtures/`;
* do not remove coverage.

### 5.3. Test Naming Rule

Test files must use:

```text
test_<module_name>.gd
```

Test functions should use:

```gdscript
func test_<expected_behavior>() -> void:
	pass
```

Good examples:

```gdscript
func test_failed_purchase_does_not_mutate_state() -> void:
	pass

func test_thug_with_insider_ignores_cops() -> void:
	pass

func test_contract_claim_twice_fails() -> void:
	pass
```

### 5.4. Mutation-Safety Rule

Every public mutator must have at least one failed-validation test proving state remains unchanged.

Required pattern:

```gdscript
var before := state.duplicate(true)
var result := SomeLogic.resolve(state, invalid_payload)

assert_false(result["ok"])
assert_eq(state, before)
```

For `GameStateManager.gd`, test active state:

```gdscript
var before := GameStateManager.get_state_snapshot()
var result := GameStateManager.buy_card("bad_player", "stash")
var after := GameStateManager.get_state_snapshot()

assert_false(result["ok"])
assert_eq(after, before)
```

### 5.5. Selector Rule

Every selector or preview must be tested to prove:

* no state mutation;
* no random step mutation;
* stable result shape.

Selectors include:

* price preview;
* market view;
* combat preview;
* valid targets;
* valid engine targets;
* disabled reason methods;
* contract state view;
* contact offer view;
* Street Deal view;
* debt status view.

### 5.6. Deterministic Random Rule

Every gameplay random consumer must have tests proving:

* same seed and same state produce same result;
* random step advances exactly as specified;
* forbidden random APIs are absent.

Random consumers:

* Income dice;
* market generation;
* contract offers;
* Street Deal generation;
* `dirty_tip` random AI target;
* contact offers;
* strong AI selection;
* AI profile assignment;
* AI purchase tie-break;
* AI target tie-break;
* AI attack probability.

### 5.7. Static Scan Rule

Static scans must run as tests.

Static scans must fail on:

* forbidden random APIs in gameplay code;
* UI direct gameplay mutation;
* logic importing UI scenes;
* source files over 250 lines;
* banned non-Godot stack artifacts;
* duplicated source-of-truth files;
* untracked `TODO`, `TBD`, or `FIXME` without `OQ-*`.

### 5.8. Resource Validation Rule

Every `.tres` Resource category must have catalog tests:

* all required Resources exist;
* IDs are valid;
* no duplicates;
* required fields are present;
* display summaries are not parsed as logic.

### 5.9. Gameplay Coverage Rule

Each module must test:

* happy path;
* failed validation;
* edge cases;
* state mutation;
* interaction with adjacent modules;
* static architecture constraints if relevant.

### 5.10. No Test-Only Gameplay Rule

Tests may create helpers and fixtures, but must not create hidden gameplay behavior that production code lacks.

Forbidden:

* test-only card effects;
* test-only validation bypasses;
* test-only random systems;
* test-only phase rules.

Allowed:

* fixture builders;
* state setup shortcuts;
* mock-like lightweight wrappers for log inspection;
* deterministic test seeds.

## 6. Validation Rules

### 6.1. Test Suite Validation

The full test suite is valid only if:

| Condition                                  | Required |
| ------------------------------------------ | -------: |
| All required test files exist              |      yes |
| All module unit tests pass                 |      yes |
| All integration tests pass                 |      yes |
| All static scans pass                      |      yes |
| Replay tests pass                          |      yes |
| No source file exceeds 250 lines           |      yes |
| No forbidden random APIs in gameplay logic |      yes |
| No UI-owned gameplay logic                 |      yes |

### 6.2. Test Failure Handling

When a test fails:

1. Do not change gameplay rules to satisfy the test unless the PRD owner module confirms the behavior.
2. Check the owner module.
3. If the owner module is unclear, add an open question.
4. If the test is wrong, update the test.
5. If implementation is wrong, fix implementation.
6. Add regression coverage if the bug was non-trivial.

### 6.3. Open Question Validation

Static scan should flag untracked ambiguity markers:

```text
TODO
TBD
FIXME
???
```

Allowed only if the same line or nearby comment references an `OQ-*` ID from:

```text
21_OPEN_QUESTIONS_AND_FIXES.md
```

### 6.4. Failed Validation Mutation Rule

All tests for failed validation must assert no mutation unless the owner module explicitly says otherwise.

Default rule:

```text
failed validation = no state mutation
```

## 7. Resolution / Processing Flow

### 7.1. Test Implementation Flow

For each module:

1. Read owner module PRD.
2. Create or update fixtures.
3. Write unit tests for constants and validation.
4. Write happy-path tests.
5. Write failed-validation mutation tests.
6. Write edge-case tests.
7. Write integration tests with adjacent modules.
8. Add static scans if module has architecture risks.
9. Run module tests.
10. Run full test suite.

### 7.2. Bug Fix Flow

When a bug is found:

1. Reproduce with a failing test.
2. Confirm expected behavior from owner module.
3. Fix implementation.
4. Re-run affected tests.
5. Re-run static scans.
6. Re-run replay tests if random or phase flow changed.

### 7.3. Replay Test Flow

Replay test must:

1. Start game with fixed seed.
2. Use deterministic setup choices.
3. Execute scripted human choices.
4. Let AI run through deterministic logic.
5. Complete 15 rounds or a defined shorter replay scenario.
6. Save final snapshot.
7. Repeat from the same seed and script.
8. Compare final snapshots exactly.
9. Assert same random step.

### 7.4. Static Scan Flow

Static scan tests must:

1. Walk relevant source directories.
2. Read `.gd` files as text.
3. Apply forbidden pattern checks.
4. Apply file length checks.
5. Apply UI boundary checks.
6. Apply logic boundary checks.
7. Fail with clear file path and pattern.

## 8. API Expectations

### 8.1. Test Fixture API

Required fixture files:

```text
res://tests/fixtures/TestGameStateFactory.gd
res://tests/fixtures/TestPlayers.gd
res://tests/fixtures/TestCards.gd
res://tests/fixtures/TestStates.gd
```

Recommended API:

```gdscript
class_name TestStates

static func clone_state(state: Dictionary) -> Dictionary:
	return state.duplicate(true)

static func assert_no_mutation(test_ref: GutTest, before: Dictionary, after: Dictionary) -> void:
	test_ref.assert_eq(after, before)
```

### 8.2. Static Scan Helper API

Recommended file:

```text
res://tests/fixtures/StaticScanHelper.gd
```

Recommended API:

```gdscript
class_name StaticScanHelper

static func get_gd_files_under(path: String) -> Array[String]:
	return []

static func file_contains(path: String, pattern: String) -> bool:
	return false

static func count_lines(path: String) -> int:
	return 0

static func assert_no_patterns(test_ref: GutTest, paths: Array[String], patterns: Array[String]) -> void:
	pass
```

### 8.3. Replay Helper API

Recommended file:

```text
res://tests/fixtures/ReplayScriptRunner.gd
```

Recommended API:

```gdscript
class_name ReplayScriptRunner

static func run_scripted_game(seed: String, script: Array[Dictionary]) -> Dictionary:
	return {}

static func normalize_snapshot(snapshot: Dictionary) -> Dictionary:
	return snapshot
```

### 8.4. Required Result Assertions

Tests should assert:

* `result["ok"]`;
* `result["error"]`;
* expected state changes;
* no unexpected state changes;
* log entries where relevant;
* random step changes where relevant.

## 9. Edge Cases

| Edge Case                        | Condition                                       | Expected Behavior         | Error Code            | Mutation Rule                                   |
| -------------------------------- | ----------------------------------------------- | ------------------------- | --------------------- | ----------------------------------------------- |
| Test uses incomplete fixture     | Required schema field missing.                  | Fixture validation fails. | `REQUIREMENT_NOT_MET` | Do not use fixture.                             |
| Failed mutator changes state     | State differs after failed result.              | Test fails.               | N/A                   | Fix implementation.                             |
| Selector changes random step     | Random step changes after preview.              | Test fails.               | N/A                   | Fix selector.                                   |
| Replay mismatch                  | Same seed/script produces different result.     | Test fails.               | N/A                   | Fix random call order or hidden nondeterminism. |
| Static scan finds `randf()`      | Gameplay code contains forbidden API.           | Test fails.               | N/A                   | Replace with deterministic random.              |
| Static scan finds UI mutation    | UI mutates gameplay state.                      | Test fails.               | N/A                   | Route through GameStateManager.                 |
| Source file over 250 lines       | Any `.gd` file exceeds limit.                   | Test fails.               | N/A                   | Split file.                                     |
| Resource ID duplicate            | Two Resources share ID.                         | Catalog test fails.       | `REQUIREMENT_NOT_MET` | Fix data.                                       |
| Missing Resource                 | Required `.tres` missing.                       | Catalog test fails.       | `REQUIREMENT_NOT_MET` | Add Resource.                                   |
| Open TODO without OQ             | `TODO` has no issue ID.                         | Static scan fails.        | N/A                   | Add `OQ-*` or resolve.                          |
| UI test requires gameplay result | UI test tries to assert internal logic formula. | Test is invalid.          | N/A                   | Move assertion to logic test.                   |

## 10. Required Source Files

### 10.1. Required Test Directories

```text
res://tests/
res://tests/smoke/
res://tests/unit/
res://tests/integration/
res://tests/replay/
res://tests/static/
res://tests/fixtures/
```

`res://tests/smoke/` contains only the M0 infrastructure bootstrap smoke. Integrated gameplay smoke tests belong in `res://tests/integration/`.

### 10.2. Required Fixture Files

```text
res://tests/fixtures/TestGameStateFactory.gd
res://tests/fixtures/TestPlayers.gd
res://tests/fixtures/TestCards.gd
res://tests/fixtures/TestStates.gd
res://tests/fixtures/StaticScanHelper.gd
res://tests/fixtures/ReplayScriptRunner.gd
```

### 10.3. Required Unit Test Files

```text
res://tests/unit/test_seeded_random.gd
res://tests/unit/test_seeded_picker.gd
res://tests/unit/test_game_state_factory.gd
res://tests/unit/test_game_state_validator.gd
res://tests/unit/test_phase_controller.gd
res://tests/unit/test_winner_resolver.gd
res://tests/unit/test_card_catalog.gd
res://tests/unit/test_price_logic.gd
res://tests/unit/test_market_logic.gd
res://tests/unit/test_income_logic.gd
res://tests/unit/test_combat_engine.gd
res://tests/unit/test_role_logic.gd
res://tests/unit/test_contract_logic.gd
res://tests/unit/test_street_deal_logic.gd
res://tests/unit/test_debt_logic.gd
res://tests/unit/test_contact_logic.gd
res://tests/unit/test_turf_level_logic.gd
res://tests/unit/test_ai_bot_controller.gd
res://tests/unit/test_ai_purchase_logic.gd
res://tests/unit/test_ai_target_logic.gd
res://tests/unit/test_game_state_manager_api.gd
```

### 10.4. Required Integration Test Files

```text
res://tests/integration/test_setup_flow.gd
res://tests/integration/test_smoke_mvp.gd
res://tests/integration/test_market_to_action_flow.gd
res://tests/integration/test_income_flow.gd
res://tests/integration/test_combat_hooks.gd
res://tests/integration/test_contract_hooks.gd
res://tests/integration/test_street_deal_contact_flow.gd
res://tests/integration/test_ai_turn_flow.gd
res://tests/integration/test_full_round_flow.gd
res://tests/integration/test_game_over_flow.gd
```

### 10.5. Required Replay Test Files

```text
res://tests/replay/test_replay_determinism.gd
res://tests/replay/test_replay_random_step_consistency.gd
```

### 10.6. Required Static Test Files

```text
res://tests/static/test_static_random_scan.gd
res://tests/static/test_architecture_static_scan.gd
res://tests/static/test_ui_static_boundaries.gd
res://tests/static/test_file_length_scan.gd
res://tests/static/test_resource_integrity_scan.gd
res://tests/static/test_open_questions_docs.gd
```

Each source file must stay under:

```text
250 lines
```

Split large tests by behavior group.

## 11. Required GUT Tests

The canonical MVP smoke test must pass independently through the command in Section 5.1.2 before the full suite runs once the integrated smoke becomes applicable.

### 11.1. Constants and IDs

Minimum tests:

* all card IDs are unique;
* all role IDs are unique;
* all contract IDs are unique;
* all contact IDs are unique;
* all Street Deal IDs are unique;
* all AI profile IDs are unique;
* all Turf Levels 0-10 exist;
* all validation error codes referenced by modules exist.

### 11.2. Resource and Catalog Tests

Minimum tests:

* every required `.tres` exists;
* every Resource ID matches expected constants;
* no duplicate Resource IDs;
* every Resource required field is set;
* catalogs can return definitions by ID;
* catalogs return safe failure for invalid IDs;
* Resources are not mutated during gameplay tests.

### 11.3. Game State Tests

Minimum tests:

* factory creates valid base state;
* player count is 4;
* exactly one human player exists;
* exactly three AI players exist;
* random state exists;
* market state exists;
* contract state exists;
* contact state exists;
* Street Deal state exists;
* player debts field exists;
* role flags exist;
* turf flags exist;
* validator rejects missing required fields.

### 11.4. Phase Tests

Minimum tests:

* game starts in correct initial phase;
* Market readiness works;
* Action order works;
* skipped action works;
* Street Deal phases occur after rounds 4, 8, and 12;
* game ends after round 15;
* phase transitions do not bypass validation.

### 11.5. Deterministic Random Tests

Minimum tests:

* same seed and step gives same value;
* random step increments correctly;
* dice consume 2 steps;
* pickers consume expected steps;
* previews do not consume active random; contract preview uses only temporary setup random;
* all random consumers use shared `state["random"]`;
* forbidden random APIs are absent.

### 11.6. Economy and Market Tests

Minimum tests:

* starting resources match role and Turf Level rules;
* market generation is deterministic;
* rotating market slot count respects Turf Level 4;
* purchases validate Nal;
* purchases validate market availability;
* purchases validate one-copy-per-round;
* price modifiers apply in expected order;
* failed purchases do not mutate state;
* Income rolls deterministic dice;
* Accountant protected Nal works;
* Cops upkeep works;
* District Control rebuild works.

### 11.7. Combat Tests

Minimum tests:

* every War card validates correctly;
* every War card resolves correctly;
* blocked attacks consume cards;
* failed attacks do not consume cards;
* `insider` works only with `thug`;
* `saboteur` requires attacker-selected engine target;
* Cops, Cartel, and Judge defense rules work;
* combat hooks update contracts and contacts correctly;
* combat preview does not mutate state.

### 11.8. Role Tests

Minimum tests:

* all role setup effects work;
* all role price modifiers work;
* Accountant `vp >= 1` requirement works;
* Gray Cardinal bypass works;
* first-effect flags consume only on successful purchase;
* per-round role flags reset correctly;
* failed purchases do not consume role flags.

### 11.9. Contract Tests

Minimum tests:

* deterministic 3 contract offers;
* human selects exactly 1 contract;
* AI does not receive contracts;
* every contract condition works;
* deadlines fail only when `round > deadline`;
* completed contracts can be claimed after deadline;
* claim applies reward once;
* claim twice fails;
* failed claim does not mutate state.

### 11.10. Street Deal and Debt Tests

Minimum tests:

* Street Deals generate in rounds 4, 8, 12;
* used deals do not repeat;
* only human chooses options;
* all Street Deal option effects work;
* Turf Level 8 increases only direct upfront payments;
* debts are stored on player;
* active debt blocks only `loan_shark`;
* debt auto-repay works;
* overdue penalties work;
* Street Medic hook works.

### 11.11. Contact Tests

Minimum tests:

* contact offers are deterministic;
* max 1 contact rule works;
* `inside_contact` offers 2 contacts;
* strong AI victory offers 3 or 2 based on Turf Level 7;
* `black_cash` works;
* `corrupt_clerk` works;
* `street_medic` works;
* failed contact selection does not mutate state.

### 11.12. Turf Level Tests

Minimum tests:

* Turf Levels validate 0-10;
* levels are cumulative;
* Level 1 AI Nal bonus works;
* Level 2 strong AI VP bonus works;
* Level 3 human Nal penalty works;
* Level 4 market size works;
* Level 5 Cops upkeep interval works;
* Level 6 AI War discount works;
* Level 7 contact offer reduction works;
* Level 8 Street Deal payment increase works;
* Level 9 AI War weight multiplier works;
* Level 10 AI-favored VP tie-break works.

### 11.13. AI Tests

Minimum tests:

* strong AI selection deterministic;
* profile assignment deterministic and unique;
* AI purchase scoring works;
* AI reserve works;
* AI can buy multiple cards;
* AI purchase tie-break uses SeededPicker;
* AI attack probability rolls once;
* AI can play multiple War cards after attack roll succeeds;
* AI target scoring works;
* AI target tie-break uses SeededPicker;
* AI uses CombatEngine;
* AI does not receive roles, contracts, or Street Deal choices.

### 11.14. GameStateManager Tests

Minimum tests:

* mutators commit only on success;
* failed mutators leave active state unchanged;
* selectors return deep copies or safe views;
* selectors do not consume active random; contract preview uses only temporary setup random;
* required API methods exist;
* signals emit correctly;
* `GameStateManager.gd` stays under 250 lines.

### 11.15. UI Static Tests

Minimum tests:

* UI scripts call GameStateManager for gameplay;
* UI scripts do not mutate gameplay state;
* UI scripts do not contain gameplay random;
* UI scripts do not contain price or combat logic;
* UI scripts stay under 250 lines.

### 11.16. M16.1-M16.6 UI Polish Tests

These tests verify the UI polish PRDs without redefining their behavior. See the
owner M16.x PRD for executable requirements.

M16.1:

* `tests/unit/test_ui_layout.gd`;
* `tests/unit/test_ui_screens.gd`;
* `tests/static/test_ui_static_boundaries.gd`.

M16.2:

* `tests/unit/test_card_view_visual_system.gd`;
* CardView is type-driven;
* no hardcoded specific card IDs in CardView;
* no full-card PNG-only renderer;
* no runtime use of `CARD_STYLE_REFERENCE`.

M16.3:

* `tests/unit/test_tabletop_atmosphere.gd`;
* theme/background loads;
* atmosphere remains UI/theme-only;
* no copyrighted Inscryption asset/text/layout dependency;
* no gameplay mutation.

M16.4:

* `tests/unit/test_ui_feedback.gd`;
* feedback/animation is UI-only;
* feedback does not mutate state;
* feedback does not consume gameplay random;
* presentation lock cannot block gameplay/replay.

M16.5:

* `tests/unit/test_ui_audio.gd`;
* audio/tactility is UI-only;
* no persistence/save-load/user profile;
* no gameplay random;
* missing optional audio assets do not crash if audio is optional;
* audio does not affect replay snapshot/random step.

M16.6:

* `tests/unit/test_ux_clarity.gd`;
* phase hints exist;
* known error codes map to readable text;
* unknown error fallback exists;
* hints do not invent gameplay availability;
* log formatting does not mutate dictionaries.

Do not create brittle beauty tests that compare exact pixels or colors unless a
stable theme assertion already exists. Prefer structural/static tests.

### 11.17. Replay Tests

Minimum tests:

* same seed and scripted inputs produce identical final snapshot;
* same seed produces same market history;
* same seed produces same AI profile assignment;
* same seed produces same strong AI;
* same seed produces same Street Deals;
* same seed produces same contact offers;
* final random step is identical.

## 12. Static Scan Requirements

Static scan must fail if gameplay logic contains:

```text
randf(
randi(
randomize(
RandomNumberGenerator
```

Static scan must fail if UI scripts contain:

```text
GameStateManager.state[
["nal"] +=
["nal"] -=
["vp"] +=
["vp"] -=
["hand"].append
["hand"].erase
["combat_log"].append
```

Static scan must fail if logic files reference UI scene paths:

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

Static scan must fail if `.gd` file line count exceeds:

```text
250
```

Static scan must fail if banned non-Godot implementation stack files or terms appear as implementation targets:

* React;
* TypeScript;
* Zustand;
* Tailwind;
* Docker;
* WebSocket backend.

M16.1-M16.6 UI polish static scans must also cover:

```text
CARD_STYLE_REFERENCE
C:\Users\
http://
https://
FileAccess
user://
SaveManager
SaveLoad
RandomNumberGenerator
randf(
randi(
randomize(
```

`CARD_STYLE_REFERENCE`, `C:\Users\`, `http://`, and `https://` must not appear
in runtime `.gd`, `.tscn`, or `.tres` paths. `FileAccess` and `user://` are
forbidden in UI polish files except approved debug-only scope. Audio APIs
(`AudioStreamPlayer`, `AudioStreamPlayer2D`, `AudioStreamPlayer3D`,
`AudioServer`) are allowed only in approved audio UI scope, not gameplay logic.

`CardView.gd` must not hardcode specific card IDs and must not depend on
full-card PNG-only rendering. All `.gd` files remain under 250 lines.

Static scan must fail if PRD/generated Markdown contains untracked:

```text
TODO
TBD
FIXME
???
```

unless tied to an `OQ-*` ID.

## 13. Implementation Notes For LLM Agents

When writing or updating tests:

* Write tests before or alongside implementation.
* Do not weaken tests to hide bugs.
* Do not change gameplay rules inside tests.
* Use owner modules as expected behavior.
* Use deterministic seeds.
* Use fixtures instead of copy-pasted partial states.
* Test failed validation mutation safety.
* Test previews for no mutation.
* Test random step changes exactly.
* Test static architecture boundaries.
* Keep test files under 250 lines.
* Split large test files.
* Add regression tests for every fixed bug.
* If behavior is unclear, add an open question instead of guessing.

When implementing production code:

* run the related unit test first;
* run the related integration test second;
* run static scans;
* run replay tests if random, phase, AI, market, or setup changed.

## 14. Acceptance Criteria

This module is complete when:

* GUT is installed and usable;
* required test directories exist;
* required fixture files exist;
* required unit test files exist;
* required integration test files exist;
* the canonical smoke command passes in headless mode;
* CI import, smoke, and full-suite commands return exit code 0;
* required replay test files exist;
* required static test files exist;
* all constants and Resource integrity tests pass;
* all state factory and validator tests pass;
* all deterministic random tests pass;
* all economy, combat, role, contract, Street Deal, debt, contact, Turf Level, and AI tests pass;
* all GameStateManager API tests pass;
* all UI boundary tests pass;
* all static scans pass;
* replay tests produce identical final snapshots for same seed and script;
* failed validation mutation safety is covered across public mutators;
* selector no-mutation behavior is covered;
* no source file exceeds 250 lines;
* no forbidden random APIs exist in gameplay code;
* UI does not own gameplay logic.

## 15. Final Rule

Tests are executable PRD rules; if behavior is not tested, an LLM agent must not assume it is safe.
