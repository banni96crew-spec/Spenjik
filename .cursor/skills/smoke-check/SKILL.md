---
name: smoke-check
description: >-
  Run the approved Godot 4.6.2 and GUT 9.6.0 smoke gate before QA hand-off.
  Produces an evidence-based PASS, FAIL, or NOT RUN report.
---

# Smoke Check

## Inputs

- Treat arguments as: `[bootstrap | mvp | full | quick]`.
- Default: `full`.

## Preconditions

1. Read `AGENTS.MD` and `.cursor/docs/technical-preferences.md`.
2. Verify that `project.godot`, `addons/gut/gut_cmdln.gd`, and `tests/` exist.
3. Resolve Godot from `$env:GODOT_BIN` on PowerShell or `godot` on PATH.
4. Verify the executable reports Godot 4.6.2 stable.
5. Record whether `.github/workflows/tests.yml` exists.

If a required artifact is absent, stop the affected check and report its exact
status. Do not substitute another framework or runner.

## Test modes

### Bootstrap

Use while the repository only needs to prove that Godot imports and GUT runs:

```powershell
& $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gtest=res://tests/smoke/test_gut_bootstrap.gd -gexit
```

### MVP

Use after the integrated gameplay path exists:

```powershell
& $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gtest=res://tests/integration/test_smoke_mvp.gd -gexit
```

### Full

Run project import, the applicable smoke test, then the complete suite:

```powershell
& $env:GODOT_BIN --headless --editor --path (Get-Location).Path --quit
& $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Run the MVP smoke before the full suite when
`tests/integration/test_smoke_mvp.gd` exists; otherwise run the bootstrap smoke.

### Quick

Run only the applicable smoke test. Quick mode does not replace the full suite
for a release or milestone gate.

## Manual desktop checks

When a runnable build exists, verify only approved desktop scope:

- launches on the available target OS;
- minimum supported window remains usable;
- primary mouse flow works;
- keyboard behavior works where specified;
- gamepad behavior is checked only if it has been designed and claimed;
- no clipping at approved desktop resolutions;
- the mini-game enters and exits through the approved parent-scene boundary;
- no error spam appears in Godot output.

Do not add requirements for unsupported platforms.

## Verdict rules

- `FAIL`: any executed import, smoke, or full-suite command exits non-zero.
- `PASS`: every required command ran and passed.
- `PASS WITH WARNINGS`: required automated checks passed but optional manual
  desktop checks or CI evidence are incomplete.
- `NOT RUN`: the engine, project, addon, or required test is unavailable.

Never convert `NOT RUN` into `PASS`.

## Report

Write `production/qa/smoke-[date].md` only when that output is requested and
the parent directory is in scope. Include:

- Godot version;
- GUT version/evidence;
- mode;
- exact commands;
- exit codes and pass/fail counts;
- manual desktop checks;
- CI presence;
- verdict;
- blockers and missing evidence.
