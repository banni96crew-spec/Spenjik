---
name: test-setup
description: >-
  Scaffold the project's Godot 4.6.2 testing infrastructure with GUT 9.6.0,
  the approved test directories, a bootstrap smoke test, and optional CI.
---

# Test Setup

## Inputs

- Treat arguments as: `[audit | scaffold | ci | force]`.
- No argument defaults to `audit`.

## Fixed test stack

- Godot 4.6.2 stable.
- GDScript.
- GUT 9.6.0.
- Windows and Linux desktop.
- Canonical roots:
  - `tests/smoke/`
  - `tests/unit/`
  - `tests/integration/`
  - `tests/replay/`
  - `tests/static/`
  - `tests/fixtures/`
- Bootstrap smoke: `tests/smoke/test_gut_bootstrap.gd`.
- Canonical MVP smoke: `tests/integration/test_smoke_mvp.gd`.

Do not substitute another test framework.

## Audit mode

1. Read `AGENTS.MD` and `.cursor/docs/technical-preferences.md`.
2. Check for `project.godot`.
3. Check for `addons/gut/` and determine its installed version from available
   addon metadata.
4. Check every canonical test directory.
5. Check the bootstrap and MVP smoke paths.
6. Check `.github/workflows/tests.yml`.
7. Report each item as PRESENT, MISSING, VERSION MISMATCH, or NOT APPLICABLE.

The MVP smoke may be absent before integrated gameplay exists. It becomes
mandatory no later than the milestone defined by the owner PRD.

## Scaffold mode

Create only missing paths and files. Never overwrite an existing test or addon.

Minimum bootstrap test:

```gdscript
extends GutTest

func test_gut_bootstrap() -> void:
	assert_true(true)
```

Do not download or install GUT without explicit approval. If `addons/gut/` is
missing, report:

- required version: 9.6.0;
- source and checksum are not yet approved unless documented locally;
- installation is blocked until source, license, checksum, and compatibility
  procedure are recorded.

## Commands

PowerShell bootstrap smoke:

```powershell
& $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gtest=res://tests/smoke/test_gut_bootstrap.gd -gexit
```

PowerShell full suite:

```powershell
& $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

PowerShell canonical MVP smoke:

```powershell
& $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gtest=res://tests/integration/test_smoke_mvp.gd -gexit
```

Equivalent CI sequence:

```bash
godot --headless --editor --path "$PWD" --quit
godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://tests/integration/test_smoke_mvp.gd -gexit
godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

## CI mode

Create `.github/workflows/tests.yml` only when the user requested CI setup and
the repository has:

- `project.godot`;
- GUT 9.6.0 installed;
- an approved Godot 4.6.2 acquisition strategy;
- runnable bootstrap coverage.

The workflow must:

1. run on pushes and pull requests;
2. obtain exactly Godot 4.6.2 from a documented source;
3. verify the downloaded artifact checksum;
4. import the project headlessly;
5. run the applicable smoke test;
6. run the complete GUT suite;
7. fail on non-zero exit codes.

Do not invent download URLs or checksums.

## Verification

After changes:

1. list created and pre-existing files;
2. run the narrow bootstrap check when possible;
3. run the full suite only when a valid Godot project exists;
4. run `git diff --check`;
5. report commands as PASS, FAIL, or NOT RUN.
