# Open Questions and Fixes

## Document Role

This file defines only:

* open question tracking rules;
* resolved contradiction tracking;
* accepted design decisions made while modularizing PRD v2.4;
* ownership for future ambiguity resolution;
* rules for adding new `OQ-*` items;
* rules for adding new `FIX-*` items;
* current resolved fixes that coding agents must follow;
* remaining open questions, if any;
* implementation-safe clarification log.

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
* phase transition rules;
* GameStateManager API behavior;
* implementation order;
* LLM agent rules.

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
* 20_LLM_AGENT_RULES.md

Implementation target:

* Godot 4.6.2
* GDScript
* .tres Resources
* Dictionary state snapshots
* GameStateManager.gd Autoload
* GUT tests

## 1. Purpose

This file is the project’s ambiguity control document.

It exists so future LLM agents do not invent missing gameplay logic when they find:

* unclear rules;
* contradictions between PRD modules;
* missing validation errors;
* missing schema fields;
* unclear ownership;
* implementation gaps;
* naming conflicts;
* architecture conflicts.

All unresolved gameplay-affecting questions must be tracked here before implementation.

All already-resolved PRD v2.4 contradictions must also be recorded here so coding agents know which corrected modular rule wins.

## 2. Ownership Boundaries

This file owns:

* open question IDs;
* resolved fix IDs;
* decision status tracking;
* clarification history;
* rules for documenting ambiguity;
* rules for deciding whether implementation may proceed.

This file references:

* owner modules for final rules;
* accepted decisions from modular PRD cleanup;
* implementation blockers found during coding.

This file does not own:

* final gameplay rules after they are moved into owner modules;
* direct implementation behavior;
* validation error definitions;
* state schemas;
* test requirements beyond open-question tracking.

When a question is resolved:

1. update this file;
2. update the owner PRD module;
3. update tests;
4. remove any temporary implementation workaround.

## 3. Core Terms

| Term                 | Meaning                                                                                                                 |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Open Question        | Unresolved ambiguity that may affect implementation or gameplay.                                                        |
| Fix                  | Resolved contradiction, missing rule, or architecture correction.                                                       |
| Owner Module         | PRD file that must receive the final rule after a question is resolved.                                                 |
| Gameplay Impact      | Any change to rules, balance, state mutation, scoring, validation, phase flow, random, AI choices, or winner logic.     |
| Architecture Impact  | Any change to file ownership, dependency direction, state ownership, Autoload behavior, UI boundary, or test structure. |
| Documentation Impact | Clarification that does not change gameplay behavior.                                                                   |
| Blocking             | Implementation must not proceed until resolved.                                                                         |
| Non-Blocking         | Implementation may proceed using already-defined safe behavior.                                                         |
| Accepted Decision    | A decision confirmed during modular PRD cleanup and now treated as part of the modular PRD source of truth.             |

## 4. Runtime State

This module defines no gameplay runtime state.

However, implementation may optionally maintain a documentation-only tracking file:

```text
res://docs/open_questions_status.md
```

Rules:

* optional tracking files must not be loaded by gameplay code;
* gameplay must not depend on open-question status;
* open-question status is documentation only;
* unresolved open questions must not be hidden inside code comments.

## 5. Rules

### 5.1. Open Question ID Rule

Every open question must use stable ID format:

```text
OQ-001
OQ-002
OQ-003
```

Do not reuse deleted IDs.

### 5.2. Fix ID Rule

Every resolved contradiction or correction must use stable ID format:

```text
FIX-001
FIX-002
FIX-003
```

Do not reuse deleted IDs.

### 5.3. Owner Module Rule

Every `OQ-*` and `FIX-*` must identify one owner module.

If ownership is unclear, the first task is to resolve ownership.

Example:

```text
Owner module: 10_STREET_DEALS_AND_DEBTS.md
```

### 5.4. Gameplay Impact Rule

If a decision changes gameplay, an LLM agent must not decide alone.

Gameplay-impacting examples:

* changing card prices;
* changing card effects;
* changing contract requirements;
* changing Street Deal effects;
* changing AI profile values;
* changing winner tie-break;
* changing random call order;
* changing when debt penalties apply.

These require explicit design approval before implementation.

### 5.5. Architecture Clarification Rule

If a correction only clarifies architecture and does not change gameplay, it may be recorded as a resolved fix.

Examples:

* replacing `SaveManager.gd` with `DebugSnapshotManager.gd`;
* clarifying that UI must call GameStateManager;
* clarifying that `.tres` Resources must not store runtime state;
* clarifying that `state["contacts"]` owns only pending offers.

### 5.6. No Hidden Implementation Rule

Unresolved questions must not be solved by:

* hidden fallback code;
* TODO comments without `OQ-*`;
* hardcoded assumptions;
* silent schema additions;
* test-only behavior.

### 5.7. Static Scan Rule

The project static scan must fail on ambiguity markers unless they reference an `OQ-*` ID.

Tracked markers:

* `TODO`;
* `TBD`;
* `FIXME`;
* `???`.

Allowed example:

```gdscript
# TODO OQ-004: confirm whether future campaign progression changes Turf Level.
```

Forbidden example:

```gdscript
# TODO: decide later
```

### 5.8. Resolved Fix Authority Rule

If a resolved fix in this file conflicts with original PRD v2.4 text, the modular PRD owner file wins.

This file records the reason for the correction.

Coding agents must implement the owner module, not the outdated original contradiction.

## 6. Validation Rules

### 6.1. Open Question Entry Validation

Every `OQ-*` entry must include:

| Field                 |                   Required |
| --------------------- | -------------------------: |
| ID                    |                        yes |
| Title                 |                        yes |
| Status                |                        yes |
| Owner module          |                        yes |
| Related modules       |                        yes |
| Type                  |                        yes |
| Blocking              |                        yes |
| Problem               |                        yes |
| Options               | yes, if gameplay-impacting |
| Recommended option    |              yes, if known |
| Decision              |         yes, when resolved |
| Implementation impact |                        yes |
| Test impact           |                        yes |

### 6.2. Fix Entry Validation

Every `FIX-*` entry must include:

| Field                 | Required |
| --------------------- | -------: |
| ID                    |      yes |
| Title                 |      yes |
| Status                |      yes |
| Owner module          |      yes |
| Related modules       |      yes |
| Problem               |      yes |
| Accepted correction   |      yes |
| Gameplay impact       |      yes |
| Implementation impact |      yes |
| Test impact           |      yes |

### 6.3. Valid Status Values

Allowed statuses:

| Status                  | Meaning                                                           |
| ----------------------- | ----------------------------------------------------------------- |
| `open`                  | Not resolved.                                                     |
| `needs_design_decision` | Requires user/designer decision.                                  |
| `resolved`              | Decision accepted and owner module updated.                       |
| `moved_to_owner_module` | No longer tracked here as active; owner file contains final rule. |
| `rejected`              | Proposed issue was invalid or duplicate.                          |

### 6.4. Valid Types

Allowed types:

| Type            | Meaning                                                      |
| --------------- | ------------------------------------------------------------ |
| `gameplay`      | Affects rules, balance, scoring, or resolution.              |
| `architecture`  | Affects project structure, state ownership, or dependencies. |
| `api`           | Affects public methods, payloads, result shapes.             |
| `schema`        | Affects Dictionary state fields.                             |
| `test`          | Affects test coverage or static scans.                       |
| `documentation` | Clarifies docs without changing behavior.                    |

### 6.5. Blocking Rule

If an open question is marked:

```text
Blocking: yes
```

then implementation of the affected behavior must stop.

Agents may still implement unrelated safe behavior.

## 7. Resolution / Processing Flow

### 7.1. Adding a New Open Question

When an ambiguity is found:

1. Identify owner module.
2. Add new `OQ-*` entry.
3. Mark status.
4. Describe the exact contradiction or missing rule.
5. List gameplay-impacting options.
6. Recommend an option only if safe.
7. Mark whether blocking.
8. Do not implement unresolved behavior.
9. Add tests only after resolution.

### 7.2. Resolving an Open Question

When a decision is made:

1. Update `OQ-*` status to `resolved`.
2. Record accepted decision.
3. Update owner module.
4. Update schema/API/constants if needed.
5. Add or update tests.
6. Remove temporary blockers.
7. Add corresponding `FIX-*` entry if the decision corrected a contradiction.

### 7.3. Adding a Resolved Fix

When modular PRD cleanup resolves a contradiction:

1. Add `FIX-*` entry.
2. Identify original ambiguity.
3. State accepted correction.
4. Mark gameplay impact.
5. Reference owner module where final rule lives.
6. Add required tests.

### 7.4. Implementation Agent Flow

When an LLM coding agent sees an ambiguity:

1. Search this file for an existing `OQ-*`.
2. If one exists and is open, follow the blocking rule.
3. If one exists and is resolved, implement the owner module.
4. If none exists, add a new `OQ-*`.
5. Do not invent behavior.

## 8. API Expectations

This module has no runtime gameplay API.

Recommended documentation-only entry format:

```text
### OQ-000 — Title

Status:
Owner module:
Related modules:
Type:
Blocking:
Problem:
Options:
Recommended option:
Decision:
Implementation impact:
Test impact:
```

Recommended resolved fix format:

```text
### FIX-000 — Title

Status:
Owner module:
Related modules:
Problem:
Accepted correction:
Gameplay impact:
Implementation impact:
Test impact:
```

## 9. Current Open Questions

At the time this modular PRD set is generated, there are no known blocking open questions.

Coding agents must still add new `OQ-*` entries if implementation reveals missing behavior.

## 10. Resolved Fixes and Accepted Decisions

### FIX-001 — Street Deal participant ownership

Status: `resolved`

Owner module:

* 10_STREET_DEALS_AND_DEBTS.md

Related modules:

* 02_CORE_LOOP_AND_PHASES.md
* 13_AI_SYSTEM.md
* 17_UI_UX_SPEC.md

Problem:

* Original PRD text did not clearly state whether AI players choose Street Deal options.
* Some Street Deal effects target AI, which could be misread as AI participation.

Accepted correction:

* In MVP, only the human chooses Street Deal options.
* AI players do not choose Street Deals.
* AI may still receive explicit Street Deal side effects where defined.

Gameplay impact:

* Yes.
* Prevents agents from inventing AI Street Deal choice logic.

Implementation impact:

* `StreetDealLogic.select_street_deal()` must reject AI `player_id`.
* `choices_by_player` normally stores only `player_1`.

Test impact:

* Test AI Street Deal selection fails with `INVALID_TARGET`.
* Test AI side effects still resolve where explicitly defined.

### FIX-002 — Street Deal and debt state ownership

Status: `resolved`

Owner module:

* 10_STREET_DEALS_AND_DEBTS.md

Related modules:

* 04_GAME_STATE_SCHEMA.md
* 06_ECONOMY_AND_MARKET.md
* 16_GAME_STATE_MANAGER_API.md

Problem:

* Original PRD placed Street Deal state in both `state["street_deals"]` and `player["street_deals"]`.
* Original PRD also suggested global `active_debts`, but debts belong to players.

Accepted correction:

* `state["street_deals"]` owns global offer/event state:

  * current deal;
  * used deal IDs;
  * choices;
  * pending Street Deal handoffs.
* `player["debts"]` owns player debt state.
* `player["street_deals"]` must not be used as source of truth.

Gameplay impact:

* No balance change.
* Clarifies ownership and prevents duplicate state bugs.

Implementation impact:

* Add `player["debts"]`.
* Remove or ignore player-level Street Deal state as source of truth.

Test impact:

* Validator tests must confirm debts exist on players.
* DebtLogic tests must read/write `player["debts"]`.

### FIX-003 — Active debt blocks only Loan Shark

Status: `resolved`

Owner module:

* 10_STREET_DEALS_AND_DEBTS.md

Related modules:

* 06_ECONOMY_AND_MARKET.md
* 14_DETERMINISTIC_RANDOM.md

Problem:

* Original PRD said `loan_shark` requires no active debt, but did not clarify whether active debt blocks all Street Deals.

Accepted correction:

* Active debt blocks only `loan_shark`.
* Other Street Deals remain available.

Gameplay impact:

* Yes.
* Prevents active debt from unintentionally disabling all Street Deal content.

Implementation impact:

* Street Deal eligibility filters out only `loan_shark` when human has active debt.

Test impact:

* Test active debt excludes `loan_shark`.
* Test active debt does not block other eligible Street Deals.

### FIX-004 — Turf Level 8 payment definition

Status: `resolved`

Owner module:

* 12_TURF_LEVELS.md

Related modules:

* 10_STREET_DEALS_AND_DEBTS.md
* 06_ECONOMY_AND_MARKET.md

Problem:

* Original PRD said human Street Deal payments increase by +1 at Turf Level 8 but did not define “payment.”

Accepted correction:

* “Payment” means direct upfront Nal cost paid immediately by the human when selecting a Street Deal option.
* Affected:

  * `dirty_tip` Option A;
  * `black_market_cache` Option B;
  * `risky_contract` Option A.
* Not affected:

  * `loan_shark` debt amount due;
  * debt penalties;
  * future debt repayment;
  * positive Nal gains;
  * AI side effects.

Gameplay impact:

* Yes.
* Prevents Turf Level 8 from unintentionally increasing debt amounts or penalties.

Implementation impact:

* StreetDealLogic must use TurfLevelLogic payment delta only for direct upfront costs.

Test impact:

* Test affected options cost +1 at Turf Level 8+.
* Test `loan_shark` amount due is unchanged.

### FIX-005 — Dirty Tip Option B random AI target

Status: `resolved`

Owner module:

* 10_STREET_DEALS_AND_DEBTS.md

Related modules:

* 13_AI_SYSTEM.md
* 14_DETERMINISTIC_RANDOM.md

Problem:

* Original PRD says random AI receives `thug`, but random must be deterministic.

Accepted correction:

* Select AI target through `SeededPicker.gd` from `ai_1`, `ai_2`, `ai_3`.

Gameplay impact:

* No balance change.
* Clarifies deterministic implementation.

Implementation impact:

* `dirty_tip` Option B consumes deterministic random.

Test impact:

* Same seed selects same AI.
* Random step updates exactly.

### FIX-006 — Risky Contract Option B richest AI tie-break

Status: `resolved`

Owner module:

* 10_STREET_DEALS_AND_DEBTS.md

Related modules:

* 13_AI_SYSTEM.md
* 14_DETERMINISTIC_RANDOM.md

Problem:

* Original PRD says richest AI receives +1 Nal but did not define tie-break.

Accepted correction:

* Richest AI is highest Nal.
* If tied, choose stable player order:

  * `ai_1`;
  * `ai_2`;
  * `ai_3`.
* No random is used.

Gameplay impact:

* Yes, but only in tie cases.

Implementation impact:

* StreetDealLogic must not call SeededPicker for this tie-break.

Test impact:

* Test highest Nal AI receives +1.
* Test tied AI resolves by stable order.

### FIX-007 — Inside Contact Option A selection

Status: `resolved`

Owner module:

* 11_CONTACTS.md

Related modules:

* 10_STREET_DEALS_AND_DEBTS.md
* 14_DETERMINISTIC_RANDOM.md
* 17_UI_UX_SPEC.md

Problem:

* Original PRD says choose 1 contact from 2 available contacts, but did not clearly define who creates the offer.

Accepted correction:

* StreetDealLogic calls ContactLogic to generate a deterministic offer of 2 contacts.
* Human selects 1 through ContactLogic.
* StreetDealLogic does not directly unlock contacts.

Gameplay impact:

* No balance change.
* Clarifies ownership.

Implementation impact:

* `inside_contact` Option A creates pending contact offer state.

Test impact:

* Test Street Deal creates contact offer.
* Test contact unlock happens only after `select_contact`.

### FIX-008 — Contact state ownership

Status: `resolved`

Owner module:

* 11_CONTACTS.md

Related modules:

* 04_GAME_STATE_SCHEMA.md
* 10_STREET_DEALS_AND_DEBTS.md
* 16_GAME_STATE_MANAGER_API.md

Problem:

* Original PRD placed `contacts` in both GameState and PlayerState without clear ownership.

Accepted correction:

* `player["contacts"]` stores owned contacts, cooldowns, and usage.
* `state["contacts"]` stores only pending global contact offer state.

Gameplay impact:

* No balance change.
* Prevents duplicate source-of-truth bugs.

Implementation impact:

* ContactLogic must read owned contacts from player.
* UI pending offer view reads `state["contacts"]["pending_offer"]`.

Test impact:

* State ownership tests must confirm split ownership.

### FIX-009 — Maximum 1 contact means no replacement

Status: `resolved`

Owner module:

* 11_CONTACTS.md

Related modules:

* 17_UI_UX_SPEC.md

Problem:

* Original PRD says maximum 1 contact, but did not define whether replacement is possible.

Accepted correction:

* If human already owns a contact, new contact offers are unavailable.
* Existing contacts cannot be replaced in MVP.

Gameplay impact:

* Yes.
* Prevents a hidden contact replacement mechanic.

Implementation impact:

* Contact offer generation fails or no-ops when contact limit is reached.

Test impact:

* Test second contact selection fails.
* Test offer is not generated if player already owns a contact.

### FIX-010 — Strong AI victory contact unlock

Status: `resolved`

Owner module:

* 11_CONTACTS.md

Related modules:

* 07_COMBAT_SYSTEM.md
* 13_AI_SYSTEM.md

Problem:

* Original PRD says contacts unlock from victory over strong AI, but did not define what that means inside a run.

Accepted correction:

* In MVP, strong AI victory means human successfully and without block destroys any Status building owned by the strong AI:

  * `stash`;
  * `workshop`;
  * `district_control`.

Gameplay impact:

* Yes.
* Makes contact unlock possible during the current run.

Implementation impact:

* CombatEngine must emit or pass attack result to ContactLogic.
* ContactLogic checks attack result and creates contact offer.

Test impact:

* Test successful Status destruction against strong AI creates offer.
* Test blocked attack does not create offer.
* Test Engine destruction does not create offer.

### FIX-011 — Strong AI victory contact offer count

Status: `resolved`

Owner module:

* 11_CONTACTS.md

Related modules:

* 12_TURF_LEVELS.md
* 14_DETERMINISTIC_RANDOM.md

Problem:

* Original PRD said strong AI victory gives contact choice and Turf Level 7 changes offer count, but the exact default count needed clarification.

Accepted correction:

* Strong AI victory normally offers 3 contacts.
* At Turf Level 7+, strong AI victory offers 2 contacts.
* `inside_contact` always offers 2 contacts.

Gameplay impact:

* Yes.
* Preserves Turf Level 7 meaning.

Implementation impact:

* ContactLogic must ask TurfLevelLogic for strong AI victory offer count.

Test impact:

* Test count 3 below Turf Level 7.
* Test count 2 at Turf Level 7+.
* Test `inside_contact` remains 2.

### FIX-012 — Corrupt Clerk consumption timing

Status: `resolved`

Owner module:

* 11_CONTACTS.md

Related modules:

* 06_ECONOMY_AND_MARKET.md
* 12_TURF_LEVELS.md

Problem:

* Original PRD says first Status card after receiving `corrupt_clerk` is cheaper by 1 but did not define failed purchase behavior.

Accepted correction:

* The discount is consumed only after a successful Status purchase.
* Failed purchase does not consume it.

Gameplay impact:

* Yes, in failed purchase edge cases.

Implementation impact:

* PriceLogic returns modifier.
* PurchaseResolver consumes flag only after successful purchase.

Test impact:

* Failed Status purchase does not consume.
* Successful Status purchase consumes.
* Non-Status purchase does not consume.

### FIX-013 — Turf Level 10 multiple AI tie-break

Status: `resolved`

Owner module:

* 12_TURF_LEVELS.md

Related modules:

* 02_CORE_LOOP_AND_PHASES.md
* 16_GAME_STATE_MANAGER_API.md

Problem:

* Original PRD says AI wins equal VP ties if AI is among leaders but did not define which AI wins when multiple AI are tied.

Accepted correction:

* At Turf Level 10+, if one or more AI are tied for highest VP, AI wins.
* If multiple AI are tied, choose:

  1. highest Nal;
  2. stable AI order `ai_1`, then `ai_2`, then `ai_3`.

Gameplay impact:

* Yes, but only in tied endgame cases.

Implementation impact:

* WinnerResolver must call TurfLevelLogic tie-break helper.
* WinnerResolver must not use random.

Test impact:

* Test multiple AI tied choose highest Nal.
* Test equal Nal uses stable order.

### FIX-014 — Strong AI selection

Status: `resolved`

Owner module:

* 13_AI_SYSTEM.md

Related modules:

* 14_DETERMINISTIC_RANDOM.md
* 12_TURF_LEVELS.md

Problem:

* Original PRD required strong AI but did not fully define selection behavior.

Accepted correction:

* Select exactly one strong AI from `ai_1`, `ai_2`, `ai_3`.
* Use deterministic `SeededPicker.gd`.

Gameplay impact:

* Yes.
* Defines run setup variability.

Implementation impact:

* AIBotController setup consumes random for strong AI selection.

Test impact:

* Same seed selects same strong AI.
* Exactly one strong AI exists.

### FIX-015 — AI profile assignment

Status: `resolved`

Owner module:

* 13_AI_SYSTEM.md

Related modules:

* 14_DETERMINISTIC_RANDOM.md

Problem:

* Original PRD listed 6 AI profiles but did not fully define assignment behavior.

Accepted correction:

* Deterministically select 3 unique profiles from 6 through `SeededPicker.gd`.
* Assign selected profiles in stable order:

  * first to `ai_1`;
  * second to `ai_2`;
  * third to `ai_3`.

Gameplay impact:

* Yes.
* Defines AI variety per run.

Implementation impact:

* AIBotController setup consumes random for profile selection.

Test impact:

* Test unique profiles.
* Test deterministic assignment.

### FIX-016 — AI Market purchase count

Status: `resolved`

Owner module:

* 13_AI_SYSTEM.md

Related modules:

* 06_ECONOMY_AND_MARKET.md

Problem:

* Original PRD did not specify whether AI buys one card or multiple cards during Market.

Accepted correction:

* AI may buy multiple cards while valid candidates exist and reserve is respected.
* One-copy-per-card-ID-per-round still applies.

Gameplay impact:

* Yes.
* Makes AI economy behavior stronger and consistent with Market rules.

Implementation impact:

* AIPurchaseLogic loops after each successful purchase.

Test impact:

* Test AI can buy multiple cards.
* Test loop stops when no candidate remains.
* Test reserve still applies.

### FIX-017 — AI purchase score tie-break

Status: `resolved`

Owner module:

* 13_AI_SYSTEM.md

Related modules:

* 14_DETERMINISTIC_RANDOM.md

Problem:

* Original PRD references deterministic tie-break but did not fully define how to choose equal purchase scores.

Accepted correction:

* Equal best purchase score uses `SeededPicker.gd`.

Gameplay impact:

* Yes, in tie cases.

Implementation impact:

* AIPurchaseLogic consumes random only when a real tie exists.

Test impact:

* Test tied score uses deterministic picker.
* Test single best score consumes no tie-break random.

### FIX-018 — AI attack probability timing

Status: `resolved`

Owner module:

* 13_AI_SYSTEM.md

Related modules:

* 07_COMBAT_SYSTEM.md
* 14_DETERMINISTIC_RANDOM.md

Problem:

* Original PRD listed attack probability but did not define when it is rolled.

Accepted correction:

* AI rolls attack probability once at the start of its Action turn.
* If roll passes, AI may attempt attacks.
* If roll fails, AI ends Action.
* Fallback must not override a failed probability roll.

Gameplay impact:

* Yes.

Implementation impact:

* AIActionLogic consumes one random step per AI Action turn when AI has War cards.

Test impact:

* Test one roll per Action turn.
* Test failed roll ends Action.
* Test fallback does not force attack after failed roll.

### FIX-019 — AI War card count per Action

Status: `resolved`

Owner module:

* 13_AI_SYSTEM.md

Related modules:

* 02_CORE_LOOP_AND_PHASES.md
* 07_COMBAT_SYSTEM.md

Problem:

* Original PRD says players may play any number of War cards, but AI behavior needed clarification.

Accepted correction:

* If AI decides to attack, it may play multiple valid War cards until no valid attacks remain.
* Loop limit is based on War cards in hand at Action start.

Gameplay impact:

* Yes.

Implementation impact:

* AIActionLogic must re-evaluate after each attack.

Test impact:

* Test AI can play multiple War cards.
* Test unused War cards remain in hand.

### FIX-020 — AI target score tie-break

Status: `resolved`

Owner module:

* 13_AI_SYSTEM.md

Related modules:

* 14_DETERMINISTIC_RANDOM.md

Problem:

* Original PRD references deterministic target tie-break but did not define exact behavior.

Accepted correction:

* Equal target scores use `SeededPicker.gd`.

Gameplay impact:

* Yes, in tie cases.

Implementation impact:

* AITargetLogic consumes random only on real tie.

Test impact:

* Test deterministic target tie-break.
* Test no random consumed when one best target exists.

### FIX-021 — Unified deterministic random state

Status: `resolved`

Owner module:

* 14_DETERMINISTIC_RANDOM.md

Related modules:

* 06_ECONOMY_AND_MARKET.md
* 09_CONTRACTS.md
* 10_STREET_DEALS_AND_DEBTS.md
* 11_CONTACTS.md
* 13_AI_SYSTEM.md

Problem:

* Original PRD included examples deriving market random from `game_seed + round`, conflicting with unified `state["random"]`.

Accepted correction:

* All gameplay random consumes unified `state["random"]`.
* Tags are labels only.
* Market generation must not use `game_seed + round` as a standalone random stream.

Gameplay impact:

* Yes.
* Changes random step ownership and replay behavior.

Implementation impact:

* All random consumers must pass and return `state["random"]`.

Test impact:

* Replay tests must compare final random step.
* Consumer tests must assert exact step usage.

### FIX-022 — `roll_d6_pair` gameplay API shape

Status: `resolved`

Owner module:

* 14_DETERMINISTIC_RANDOM.md

Related modules:

* 06_ECONOMY_AND_MARKET.md

Problem:

* Original PRD showed `roll_d6_pair(seed, step)`, which does not update unified random state.

Accepted correction:

* Gameplay API must be `roll_d6_pair(random_state, tag)`.
* It consumes exactly 2 steps and returns updated random state.

Gameplay impact:

* Yes.
* Ensures Income dice participate in shared replay sequence.

Implementation impact:

* IncomeLogic must store returned random state.

Test impact:

* Test dice step advances by 2.
* Test same seed and starting step returns same dice.

### FIX-023 — SaveManager replaced by DebugSnapshotManager

Status: `resolved`

Owner module:

* 15_GODOT_ARCHITECTURE.md

Related modules:

* 01_PRODUCT_OVERVIEW.md
* 18_TEST_PLAN.md

Problem:

* Original project structure listed `SaveManager.gd`, while MVP says no persistence.

Accepted correction:

* Do not implement gameplay persistence in MVP.
* Replace `SaveManager.gd` with optional `DebugSnapshotManager.gd`.
* Debug snapshot may write JSON to `user://` only for development/tests.

Gameplay impact:

* No.

Implementation impact:

* No save/load gameplay loop.
* Debug snapshot must not be required for normal gameplay.

Test impact:

* Static architecture scan should not require SaveManager.
* Debug snapshot tests are optional.

### FIX-024 — GameStateManager API naming correction

Status: `resolved`

Owner module:

* 16_GAME_STATE_MANAGER_API.md

Related modules:

* 02_CORE_LOOP_AND_PHASES.md
* 17_UI_UX_SPEC.md

Problem:

* Original PRD mixed `next_phase()` and phase-specific public API names.

Accepted correction:

* Use `advance_phase()` for explicit phase advancement.
* Use phase-safe methods:

  * `end_market_for_player`;
  * `end_action_for_player`;
  * `skip_action_for_player`.

Gameplay impact:

* No gameplay rule change.
* Clarifies facade API.

Implementation impact:

* UI must not set phase fields directly.
* GameStateManager delegates to GamePhaseController.

Test impact:

* API tests must cover phase-safe methods.
* Static scan must reject UI direct phase mutation.

### FIX-025 — Rebuild District Control API

Status: `resolved`

Owner module:

* 16_GAME_STATE_MANAGER_API.md

Related modules:

* 06_ECONOMY_AND_MARKET.md
* 07_COMBAT_SYSTEM.md

Problem:

* Original PRD allowed rebuild after Federal Raid but did not clearly define public API ownership.

Accepted correction:

* Use dedicated API:

```gdscript
func rebuild_district_control(player_id: String) -> Dictionary:
	return {}
```

* Do not implement rebuild as fake card ID.

Gameplay impact:

* No balance change.
* Clarifies API.

Implementation impact:

* Market UI calls dedicated GameStateManager method.

Test impact:

* Test valid rebuild succeeds.
* Test invalid rebuild fails with no mutation.

### FIX-026 — UI gameplay boundary

Status: `resolved`

Owner module:

* 17_UI_UX_SPEC.md

Related modules:

* 15_GODOT_ARCHITECTURE.md
* 16_GAME_STATE_MANAGER_API.md
* 18_TEST_PLAN.md

Problem:

* Original PRD said UI must not own gameplay logic, but exact forbidden patterns needed formalization.

Accepted correction:

* UI may only render, collect input, build payloads, call GameStateManager, show previews, and show errors.
* UI must not calculate prices, resolve combat, mutate state, unlock contacts, or apply rewards.

Gameplay impact:

* No.

Implementation impact:

* UI scripts remain thin.
* All gameplay actions go through GameStateManager.

Test impact:

* UI static boundary scan required.

### FIX-027 — Implementation order correction

Status: `resolved`

Owner module:

* 19_IMPLEMENTATION_ORDER.md

Related modules:

* 18_TEST_PLAN.md
* 15_GODOT_ARCHITECTURE.md

Problem:

* Original PRD implementation order placed GameStateManager before many owner modules, risking a mega-file facade.

Accepted correction:

* Implement foundations first.
* Implement logic modules before final GameStateManager facade.
* Implement UI last.

Gameplay impact:

* No.

Implementation impact:

* GameStateManager stays thin.
* Owner modules get tested first.

Test impact:

* Readiness tests and architecture scans enforce ordering.

### FIX-028 — LLM agent no-invention rule

Status: `resolved`

Owner module:

* 20_LLM_AGENT_RULES.md

Related modules:

* All modules

Problem:

* LLM agents may fill unclear gaps with invented behavior.

Accepted correction:

* Agents must not invent hidden gameplay rules.
* Ambiguities must be tracked here as `OQ-*`.

Gameplay impact:

* No direct gameplay change.
* Prevents accidental future gameplay drift.

Implementation impact:

* Agents must stop and ask or add open question for unclear behavior.

Test impact:

* Static scan must reject untracked `TODO`, `TBD`, `FIXME`, `???`.

### FIX-029 — Source file length enforcement

Status: `resolved`

Owner module:

* 15_GODOT_ARCHITECTURE.md

Related modules:

* 18_TEST_PLAN.md
* 20_LLM_AGENT_RULES.md

Problem:

* Original PRD states source files must stay under 250 lines, but enforcement needed to be repeated across modules.

Accepted correction:

* Every `.gd` source file must stay under 250 lines.
* Split validators, resolvers, selectors, log builders, and helpers early.

Gameplay impact:

* No.

Implementation impact:

* Static file length scan required.

Test impact:

* `test_file_length_scan.gd` required.

### FIX-030 — `contacts` and `street_deals` duplicate source-of-truth prevention

Status: `resolved`

Owner module:

* 04_GAME_STATE_SCHEMA.md

Related modules:

* 10_STREET_DEALS_AND_DEBTS.md
* 11_CONTACTS.md
* 15_GODOT_ARCHITECTURE.md

Problem:

* Original schema examples could lead agents to keep duplicated ownership fields in both global and player state.

Accepted correction:

* Contacts:

  * owned state in `player["contacts"]`;
  * pending offers in `state["contacts"]`.
* Street Deals:

  * global offer/event state in `state["street_deals"]`;
  * debts in `player["debts"]`.

Gameplay impact:

* No balance change.

Implementation impact:

* GameStateValidator must enforce ownership expectations.

Test impact:

* Schema tests must confirm no duplicated source of truth is used.

### FIX-031 — Canonical GameState keys, IDs, errors, and events

Status: `resolved`

Owner modules:

* 03_IDS_AND_CONSTANTS.md
* 04_GAME_STATE_SCHEMA.md

Related modules:

* 09_CONTRACTS.md
* 10_STREET_DEALS_AND_DEBTS.md
* 11_CONTACTS.md
* 13_AI_SYSTEM.md
* 16_GAME_STATE_MANAGER_API.md

Accepted correction:

* Contract offers use only `state["contract_offer_ids"]`.
* Runtime contracts use only `player["contracts"]`.
* Owned contacts use `player["contacts"]`; pending contact offer uses `state["contacts"]["pending_offer"]`.
* Debts use only `player["debts"]`.
* Temporary modifiers use only `player["temporary_modifiers"]`.
* AI player IDs are exactly `ai_1`, `ai_2`, `ai_3`.
* Turf Level is an integer member of `TurfLevelIds.ALL`; string territory IDs are forbidden.
* Street Deal option IDs are exactly `option_a` and `option_b`.
* Validation uses the complete canonical `ValidationErrors` list without fallback strings.
* Gameplay logging uses only `LogEventTypes.ALL` and exact event payload contracts.
* Contract failure reasons are exactly `war_played` and `deadline_exceeded`; every first failure appends `CONTRACT_FAILED`.
* Combat, discard, skip, contact, and Street Deal events contain only their documented typed payload fields; free-form nested result dictionaries are forbidden.

Implementation impact:

* `04_GAME_STATE_SCHEMA.md` is the final runtime-state authority.
* GameStateValidator rejects aliases, extra keys, wrong types, invalid IDs, and invalid event payloads.

Test impact:

* Schema, constants, ID, error, and event payload tests are required.

### FIX-032 — Atomic advance_phase and facade direction

Status: `resolved`

Owner modules:

* 02_CORE_LOOP_AND_PHASES.md
* 16_GAME_STATE_MANAGER_API.md

Related modules:

* 04_GAME_STATE_SCHEMA.md
* 13_AI_SYSTEM.md
* 15_GODOT_ARCHITECTURE.md

Accepted correction:

* `advance_phase` performs exactly one legal phase transition through GamePhaseController.
* Income -> Market resolves all four players and Market entry in one atomic candidate-state transaction.
* Incomplete Market, Action, or Street Deal returns `PHASE_NOT_READY`.
* Any delegated or final validation error discards the complete candidate and appends no active-state event.
* Dependency direction is facade -> logic; logic modules never call GameStateManager.

Implementation impact:

* GameStateManager copies, delegates, validates, commits, emits signals, and adapts results.
* Logic owns gameplay calculations, validation, random consumption, and candidate-state transitions.

Test impact:

* Phase rollback, event order, error propagation, and logic/facade boundary tests are required.

### FIX-033 — Canonical Income and two-stage contract setup

Status: `resolved`

Owner modules:

* 06_ECONOMY_AND_MARKET.md
* 09_CONTRACTS.md

Related modules:

* 03_IDS_AND_CONSTANTS.md
* 04_GAME_STATE_SCHEMA.md
* 16_GAME_STATE_MANAGER_API.md
* 17_UI_UX_SPEC.md

Accepted correction:

* Income is `dice_sum + laundries * 2 + informers + brothel_bonus_if_doubles`.
* `black_cash` replaces Brothel `+5` with `+6`; no rounding or Income clamp exists.
* Income is added to `player["nal"]`, returned in the operation result, and logged; no duplicate Income state key exists.
* Contract Stage 1 previews exactly three deterministic IDs without active-state mutation.
* Contract Stage 2 regenerates the same IDs, validates membership, creates one human runtime contract, and commits all contract fields atomically.

Test impact:

* Income component/order tests and contract preview/commit determinism tests are required.

### FIX-034 — Executable GUT and CI smoke contract

Status: `resolved`

Owner module:

* 18_TEST_PLAN.md

Related modules:

* 15_GODOT_ARCHITECTURE.md
* 16_GAME_STATE_MANAGER_API.md

Accepted correction:

* Use GUT 9.6.0 with Godot 4.6.2.
* The PRD defines exact headless full-suite and single smoke-test commands.
* CI runs import, smoke, then full GUT suite.
* Any non-zero exit, import/parse/schema failure, failed assertion, or timeout fails CI.

Test impact:

* `res://tests/integration/test_smoke_mvp.gd` is required.

### FIX-035 — Complete M1 constants-file scope

Status: `resolved`

Owner module:

* 19_IMPLEMENTATION_ORDER.md

Related modules:

* 03_IDS_AND_CONSTANTS.md
* 15_GODOT_ARCHITECTURE.md
* 18_TEST_PLAN.md

Problem:

* The M1 milestone listed only 11 constants files while `03_IDS_AND_CONSTANTS.md` required 20 files.
* This made the M1 completion gate inconsistent with the canonical constants owner.

Accepted correction:

* `03_IDS_AND_CONSTANTS.md` owns the complete M1 constants-file list.
* M1 requires all 20 files listed in that document.
* `19_IMPLEMENTATION_ORDER.md` must list the same complete set.

Gameplay impact:

* No.

Implementation impact:

* M1 creates all 20 constants files before Resource, state, or gameplay milestones begin.

Test impact:

* M1 tests verify that all 20 files exist and that their required constants are complete and unique.

## 11. Accepted Design Decisions Summary

| Area                      | Accepted Decision                                                          |
| ------------------------- | -------------------------------------------------------------------------- |
| Street Deal participation | Human chooses; AI only receives explicit side effects.                     |
| Debt ownership            | Debts are stored in `player["debts"]`.                                     |
| Active debt blocking      | Blocks only `loan_shark`.                                                  |
| Turf Level 8              | Increases only direct upfront human Street Deal payments by +1.            |
| Contact ownership         | Owned contacts on player; pending offers globally.                         |
| Contact limit             | Max 1 contact, no replacement in MVP.                                      |
| Strong AI victory         | Human destroys strong AI Status building successfully and unblocked.       |
| Strong AI contact offer   | 3 options normally, 2 at Turf Level 7+.                                    |
| `inside_contact` offer    | Always 2 contact options.                                                  |
| `corrupt_clerk`           | Consumed only after successful Status purchase.                            |
| Turf Level 10 AI tie      | AI winner by highest Nal, then stable AI order.                            |
| Strong AI selection       | Deterministic `SeededPicker`.                                              |
| AI profiles               | 3 unique profiles selected deterministically and assigned to `ai_1..ai_3`. |
| AI Market                 | AI may buy multiple valid cards while respecting reserve.                  |
| AI attack roll            | One deterministic roll per AI Action turn.                                 |
| AI War cards              | AI may play multiple valid War cards after passing attack roll.            |
| Random state              | All gameplay random consumes shared `state["random"]`.                     |
| Save policy               | No persistence in MVP; debug snapshot only.                                |
| UI boundary               | UI never owns gameplay logic.                                              |
| Implementation order      | Foundations → logic → facade → integration → UI.                           |
| GameState authority       | `04_GAME_STATE_SCHEMA.md`; aliases and extra runtime keys are forbidden.    |
| AI/Turf IDs               | `ai_1..ai_3`; Turf Level integer `0..10`.                                   |
| Street Deal option IDs    | `option_a` and `option_b`.                                                  |
| Phase transaction         | `advance_phase` is atomic; Income -> Market resolves all players once.      |
| Dependency direction      | Facade -> logic; logic never calls GameStateManager.                        |
| Income formula            | 2d6 + Laundry + Informant + conditional Brothel bonus.                      |
| Contract setup            | Pure three-offer preview, then validated atomic commit.                     |
| Test command              | Godot 4.6.2 + GUT 9.6.0; import -> smoke -> full suite.                     |

## 12. Deferred Non-MVP Questions

These are not blockers for MVP because the modular PRD intentionally excludes them.

### OQ-001 — Campaign persistence after MVP

Status: `open`

Owner module:

* Future persistence module

Related modules:

* 01_PRODUCT_OVERVIEW.md
* 15_GODOT_ARCHITECTURE.md

Type:

* architecture

Blocking:

* no

Problem:

* MVP has no campaign persistence.
* Future versions may need save/load or campaign progression.

Options:

* Add a real `SaveManager.gd`.
* Keep only debug snapshots.
* Add campaign progression module.

Recommended option:

* Defer until after MVP.

Decision:

* Not part of MVP.

Implementation impact:

* Do not implement gameplay save/load in MVP.

Test impact:

* None for MVP beyond ensuring debug snapshot is optional.

### OQ-002 — Automatic Turf Level progression after MVP

Status: `open`

Owner module:

* Future progression module

Related modules:

* 12_TURF_LEVELS.md
* 01_PRODUCT_OVERVIEW.md

Type:

* gameplay

Blocking:

* no

Problem:

* MVP selects Turf Level manually before the run.
* Automatic progression between runs is out of scope.

Options:

* Increase Turf Level after wins.
* Increase Turf Level after specific achievements.
* Keep manual selection only.

Recommended option:

* Defer until campaign/progression design exists.

Decision:

* Not part of MVP.

Implementation impact:

* Do not implement automatic Turf Level changes.

Test impact:

* MVP tests must ensure Turf Level cannot change during a run.

### OQ-003 — Web export and platform-specific UX after MVP

Status: `open`

Owner module:

* Future platform module

Related modules:

* 01_PRODUCT_OVERVIEW.md
* 15_GODOT_ARCHITECTURE.md
* 17_UI_UX_SPEC.md

Type:

* architecture

Blocking:

* no

Problem:

* MVP targets Windows and Linux desktop.
* Web export is optional later.

Options:

* Add Web export support later.
* Keep desktop only.
* Add separate web UX rules.

Recommended option:

* Defer.

Decision:

* Not part of MVP.

Implementation impact:

* Do not add web-stack code.

Test impact:

* Static scan must continue banning React/TypeScript/Zustand/Tailwind/Docker implementation artifacts.

### OQ-004 — Canonical Street Deal Resource effect payloads and display text

Status: `resolved`

Owner module:

* 10_STREET_DEALS_AND_DEBTS.md

Related modules:

* 03_IDS_AND_CONSTANTS.md
* 11_CONTACTS.md
* 12_TURF_LEVELS.md
* 18_TEST_PLAN.md
* 19_IMPLEMENTATION_ORDER.md

Type:

* data schema

Blocking:

* yes

Problem:

* `StreetDealDefinition` requires `title`, `description`, option labels, option descriptions, and `option_a_effects` / `option_b_effects`.
* `10_STREET_DEALS_AND_DEBTS.md` defines the gameplay meaning of each option but does not define the exact Dictionary payload shape for `.tres` Resource data.
* M2 cannot create strict Street Deal `.tres` Resources without inventing undocumented fields or effect payloads.

Options:

* Option A: keep Street Deal effect payloads as free-form dictionaries.
* Option B: store only display text in Resources and let future StreetDealLogic hardcode all behavior.
* Option C: define canonical data-only effect payload dictionaries using `EffectTypes`, with stable keys and no gameplay resolution logic.

Decision:

* Use Option C.

Accepted correction:

Street Deal Resource effect payloads are data-only dictionaries. They describe static effect data but do not resolve gameplay.

Every effect dictionary must use:

```gdscript
{
	"type": "",
	"target": "",
	"amount": 0,
	"card_id": "",
	"card_type": "",
	"modifier_type": "",
	"delta": 0,
	"minimum": 0,
	"debt_amount_due": 0,
	"deadline_round_delta": 0,
	"penalty": {},
	"contact_offer_count": 0
}

Allowed target values:

human
random_ai
richest_ai

Allowed effect type values are from EffectTypes.gd.

Unused fields must keep neutral values:

String: ""
int: 0
Dictionary: {}

Canonical Street Deal Resource display data and effects:

loan_shark
title: Loan Shark
description: Borrow Nal now and accept a delayed debt risk.
option_a_label: Big loan
option_a_description: Gain 10 Nal. Create a debt for 12 Nal due in 2 rounds. If unpaid, lose all Nal and 1 VP.
option_a_effects:
- type: add_nal
  target: human
  amount: 10
- type: create_debt
  target: human
  debt_amount_due: 12
  deadline_round_delta: 2
  penalty:
    lose_all_nal: true
    vp_delta: -1

option_b_label: Small loan
option_b_description: Gain 5 Nal. Create a debt for 6 Nal due in 2 rounds. If unpaid, lose 1 VP.
option_b_effects:
- type: add_nal
  target: human
  amount: 5
- type: create_debt
  target: human
  debt_amount_due: 6
  deadline_round_delta: 2
  penalty:
    lose_all_nal: false
    vp_delta: -1
dirty_tip
title: Dirty Tip
description: Buy useful information or let the streets heat up.
option_a_label: Buy the tip
option_a_description: Pay 3 Nal and receive Bruiser in hand.
option_a_effects:
- type: lose_nal
  target: human
  amount: 3
- type: add_card_to_hand
  target: human
  card_id: bruiser

option_b_label: Sell the tip
option_b_description: Gain 3 Nal. A deterministic random AI receives Thug.
option_b_effects:
- type: add_nal
  target: human
  amount: 3
- type: add_card_to_hand
  target: random_ai
  card_id: thug
cheap_protection
title: Cheap Protection
description: Secure a cheaper defense or take quick cash with future risk.
option_a_label: Arrange protection
option_a_description: The next Defense card costs 2 less, minimum 1.
option_a_effects:
- type: add_temporary_modifier
  target: human
  modifier_type: next_defense_card_price_delta
  card_type: defense
  delta: -2
  minimum: 1

option_b_label: Take the cash
option_b_description: Gain 2 Nal. The next War card costs 1 more.
option_b_effects:
- type: add_nal
  target: human
  amount: 2
- type: add_temporary_modifier
  target: human
  modifier_type: next_war_card_price_delta
  card_type: war
  delta: 1
black_market_cache
title: Black Market Cache
description: Choose between cash now or a costly victory point.
option_a_label: Take the cash
option_a_description: Gain 6 Nal.
option_a_effects:
- type: add_nal
  target: human
  amount: 6

option_b_label: Secure influence
option_b_description: Pay 6 Nal and gain 1 VP.
option_b_effects:
- type: lose_nal
  target: human
  amount: 6
- type: add_vp
  target: human
  amount: 1
inside_contact
title: Inside Contact
description: Find a useful contact or take immediate cash.
option_a_label: Meet the contact
option_a_description: Choose 1 contact from 2 deterministic contact offers.
option_a_effects:
- type: unlock_contact
  target: human
  contact_offer_count: 2

option_b_label: Take the envelope
option_b_description: Gain 4 Nal.
option_b_effects:
- type: add_nal
  target: human
  amount: 4
risky_contract
title: Risky Contract
description: Chase influence at a cost or take cash while helping the richest AI.
option_a_label: Push the deal
option_a_description: Pay 3 Nal and gain 1 VP.
option_a_effects:
- type: lose_nal
  target: human
  amount: 3
- type: add_vp
  target: human
  amount: 1

option_b_label: Back off
option_b_description: Gain 5 Nal. The richest AI gains 1 Nal.
option_b_effects:
- type: add_nal
  target: human
  amount: 5
- type: add_nal
  target: richest_ai
  amount: 1

Implementation impact:

StreetDealDefinition.gd may store option_a_effects and option_b_effects as Array[Dictionary].
M2 may create all six Street Deal .tres files using this payload contract.
Future StreetDealLogic must validate and resolve these payloads explicitly.
Display text must never be parsed as gameplay behavior.

Test impact:

M2 Resource integrity tests must verify:
all six Street Deal Resources exist;
every Street Deal ID matches StreetDealIds.ALL;
every option has label, description, and effect payloads;
every effect uses the canonical keys;
every effect type exists in EffectTypes.ALL;
every target is one of human, random_ai, richest_ai;
no undocumented effect keys exist.

### OQ-005 — Canonical Contact Resource effect types and display text

Status: `resolved`

Owner module:

* 11_CONTACTS.md

Related modules:

* 03_IDS_AND_CONSTANTS.md
* 06_ECONOMY_AND_MARKET.md
* 10_STREET_DEALS_AND_DEBTS.md
* 18_TEST_PLAN.md
* 19_IMPLEMENTATION_ORDER.md

Type:

* data schema

Blocking:

* yes

Problem:

* `ContactDefinition` requires `title`, `description`, `effect_kind`, `cooldown_rounds`, and `effect_type`.
* `11_CONTACTS.md` defines each contact effect in prose but does not define exact stable `effect_type` values or canonical display text.
* M2 cannot create strict Contact `.tres` Resources without inventing Resource values.

Options:

* Option A: use contact IDs as `effect_type`.
* Option B: use generic `passive` / `active` as `effect_type`.
* Option C: define stable contact-specific `effect_type` strings that describe the effect hook.

Decision:

* Use Option C.

Accepted correction:

Contact Resource effect types are stable strings. They identify the contact hook/effect family but do not resolve gameplay.

Allowed `effect_type` values:

```text
brothel_double_bonus_plus_one
first_status_card_discount
prevent_debt_vp_loss_once

Canonical Contact Resource data:

black_cash
id: black_cash
title: Black Cash
description: Brothel double bonus gives +6 Nal instead of +5.
effect_kind: passive
cooldown_rounds: 0
effect_type: brothel_double_bonus_plus_one
corrupt_clerk
id: corrupt_clerk
title: Corrupt Clerk
description: First Status card after receiving this contact is cheaper by 1.
effect_kind: passive
cooldown_rounds: 0
effect_type: first_status_card_discount
street_medic
id: street_medic
title: Street Medic
description: Once per game prevents loss of 1 VP from a debt penalty.
effect_kind: active
cooldown_rounds: 0
effect_type: prevent_debt_vp_loss_once

Implementation impact:

ContactDefinition.gd may store effect_type as String.
M2 may create all three Contact .tres files using these exact values.
Future ContactLogic must resolve behavior explicitly by contact ID and/or effect_type.
Display text must never be parsed as gameplay behavior.

Test impact:

M2 Resource integrity tests must verify:
all three Contact Resources exist;
every Contact ID matches ContactIds.ALL;
effect_kind is exactly passive or active;
black_cash and corrupt_clerk are passive;
street_medic is active;
cooldown_rounds == 0 for all MVP contacts;
effect_type is one of the three accepted values;
display text is populated but not used as gameplay data.

## 13. Required Source Files

This module requires no gameplay source file.

Recommended documentation file:

```text
res://docs/open_questions_and_fixes.md
```

Optional. Must not be used by gameplay code.

Related static test file:

```text
res://tests/static/test_open_questions_docs.gd
```

## 14. Required GUT Tests

Recommended static test:

```text
res://tests/static/test_open_questions_docs.gd
```

Minimum checks:

* every `OQ-*` entry has required fields;
* every `FIX-*` entry has required fields;
* no duplicate `OQ-*` IDs;
* no duplicate `FIX-*` IDs;
* no untracked `TODO`, `TBD`, `FIXME`, or `???`;
* open blocking questions are reported clearly;
* resolved fixes reference owner modules;
* Markdown files do not create duplicate source-of-truth rules.

## 15. Static Scan Requirements

Static scan must fail if code or docs contain ambiguity markers without `OQ-*` reference:

```text
TODO
TBD
FIXME
???
```

Static scan must fail if:

* duplicate `OQ-*` IDs exist;
* duplicate `FIX-*` IDs exist;
* a blocking open question is ignored by implementation notes;
* an implementation adds behavior for an open blocking question;
* docs create two conflicting source-of-truth modules for one behavior.

Markdown may mention `TODO`, `TBD`, `FIXME`, or `???` only in this file or static scan rules as forbidden marker examples.

## 16. Implementation Notes For LLM Agents

When implementing:

* Check this file before inventing any missing behavior.
* If a rule appears contradictory, look for a `FIX-*` entry.
* If a question is open and blocking, do not implement that behavior.
* If a question is open and non-blocking, implement only the defined MVP subset.
* If no question exists, add one instead of guessing.
* After a decision is made, update the owner module and tests.
* Do not leave ambiguity in code comments without an `OQ-*` ID.
* Do not treat deferred non-MVP questions as MVP work.

## 17. Acceptance Criteria

This module is complete when:

* all known PRD v2.4 contradictions are tracked as resolved fixes;
* all accepted design decisions from modular cleanup are recorded;
* no known blocking MVP open questions remain;
* deferred non-MVP questions are clearly marked non-blocking;
* future LLM agents have a clear process for ambiguity handling;
* static scan rules for ambiguity markers are defined;
* owner module update rules are defined;
* implementation cannot proceed through hidden assumptions.

## 18. Final Rule

If a rule is unclear, track it here before code turns uncertainty into gameplay.
