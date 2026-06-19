---
name: test-helpers
description: >-
  Create small, project-specific GUT 9.6.0 helpers for Godot 4.6.2 tests after
  repeated test boilerplate has been demonstrated.
---

# Test Helpers

## Inputs

- Treat arguments as: `[system-name | audit | scaffold]`.
- Default: `audit`.

## Rules

- Framework: GUT 9.6.0 only.
- Language: statically typed GDScript where supported.
- Helpers belong under `tests/fixtures/` or a narrowly named helper directory
  already established by the test plan.
- Prefer plain fixture builders, snapshot comparators, and assertion helpers.
- Do not hide the behavior under test behind a large abstraction.
- Do not introduce mutable shared global fixtures.
- Use fixed seeds and explicit random-step expectations.
- Failed-validation helpers must verify no mutation of both active and input
  state.
- Selector and preview helpers must verify that state, logs, phase, flags, and
  random step remain unchanged.

## Audit mode

1. Read the relevant owner PRD and test-plan section.
2. Inspect at least three related GUT tests, when available.
3. Identify repeated setup or assertions.
4. Recommend a helper only when repetition is real and the helper has one
   narrow responsibility.

## Scaffold mode

Create helpers only after their API is justified by existing tests. Useful
categories include:

- canonical state fixture builders;
- deep-copy and no-mutation assertions;
- deterministic random-state fixtures;
- catalog/resource fixtures;
- log-entry assertions;
- scene lifecycle helpers for integration tests.

Example no-mutation helper:

```gdscript
class_name StateAssertions
extends RefCounted

static func assert_unchanged(
	owner: GutTest,
	before: Dictionary,
	after: Dictionary,
	context: String = "state"
) -> void:
	owner.assert_eq(after, before, "%s must not mutate" % context)
```

Example deterministic fixture:

```gdscript
class_name RandomFixtures
extends RefCounted

static func make_random_state(seed: int, step: int = 0) -> Dictionary:
	return {
		"seed": seed,
		"step": step,
	}
```

Adapt names and shapes to the owner PRD. Do not invent gameplay fields.

## Verification

1. Run the smallest GUT tests that use the helper.
2. Run the adjacent unit/integration group.
3. Confirm the helper does not create production dependencies.
4. Report exact commands and PASS, FAIL, or NOT RUN.
