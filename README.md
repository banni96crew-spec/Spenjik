# The Turf / Передел

**The Turf** — локальная пошаговая карточная мини-игра о борьбе за влияние, ресурсах и тактических атаках. Матч длится ровно 15 раундов: человек играет против трёх локальных AI-соперников.

## Статус

**Current status:** M0–M13 completed. **Next milestone:** M14 — GameStateManager API.

Проект сейчас **logic-first / test-driven / headless**: gameplay rules и GUT-тесты работают, playable UI через Godot Run пока нет.

**Последняя проверка:** full GUT suite 307/307 tests, 4750 assertions, exit code 0 (Godot 4.6.2, GUT 9.6.0).

**Ожидаемо отсутствует до своих milestone:**

- main scene и playable build — до M16 (UI/UX);
- `GameStateManager.gd` — до M14;
- `test_smoke_mvp.gd` как обязательный gate — не позднее M15.

Source of truth: [`docs/prd/`](docs/prd/) и фактический код/tests. README — статусный обзор, не PRD.

## Технологический стек

- Godot 4.6.2 stable;
- GDScript со статической типизацией;
- Godot `Control`, `Container` и `Theme` для UI (M16+);
- `.tres` Resources для статических данных;
- `Dictionary` snapshots для runtime-состояния;
- `GameStateManager.gd` как UI-facing facade (M14+);
- GUT 9.6.0;
- Windows и Linux как первые целевые платформы.

Web/backend-стек, C#, multiplayer и gameplay persistence не входят в MVP.

## Источники истины

- [`docs/prd/00_INDEX.md`](docs/prd/00_INDEX.md) — индекс owner PRD;
- [`docs/prd/15_GODOT_ARCHITECTURE.md`](docs/prd/15_GODOT_ARCHITECTURE.md) — архитектура;
- [`docs/prd/18_TEST_PLAN.md`](docs/prd/18_TEST_PLAN.md) — тесты;
- [`docs/prd/19_IMPLEMENTATION_ORDER.md`](docs/prd/19_IMPLEMENTATION_ORDER.md) — порядок M0–M17;
- [`docs/prd/20_LLM_AGENT_RULES.md`](docs/prd/20_LLM_AGENT_RULES.md) — правила coding-agent;
- [`AGENTS.MD`](AGENTS.MD) — практическое руководство для Cursor/Codex.

## Структура репозитория

```text
project.godot                  Godot 4.6.2 project (GUT enabled)
addons/gut/                    GUT 9.6.0
logic/                         gameplay owner modules (M0–M13)
data/ids/                      stable IDs and validation errors
data/resources/                .tres Resources and schemas
tests/                         unit, integration, replay, static, smoke
autoload/                      placeholder until M14 GameStateManager
docs/prd/                      modular product specification
ROADMAP/                       milestone context
.cursor/                       agents, rules, skills
AGENTS.MD                      agent instructions
```

Полная каноническая структура: `docs/prd/15_GODOT_ARCHITECTURE.md`.

## Архитектурная граница

```text
UI -> GameStateManager -> logic modules -> catalogs/resources/constants
```

Ключевые ограничения:

- UI не содержит gameplay logic;
- failed validation не мутирует состояние;
- selectors и previews read-only;
- gameplay random только через `SeededRandom.gd` и `SeededPicker.gd`;
- каждый `.gd` source file короче 250 строк.

## Тестовые контракты

Команды выполняются из корня репозитория (каталог с `project.godot`):

```powershell
# bootstrap smoke
& $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gtest=res://tests/smoke/test_gut_bootstrap.gd -gexit

# full suite
& $env:GODOT_BIN --headless -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

- `tests/smoke/test_gut_bootstrap.gd` — import, GUT и минимальная core-state проверка;
- `tests/integration/test_smoke_mvp.gd` — обязателен не позднее M15;
- подробности: [`docs/prd/18_TEST_PLAN.md`](docs/prd/18_TEST_PLAN.md).

## Порядок разработки

```text
M0–M13 (done) -> M14 GameStateManager -> M15 integration/replay
-> M16 UI -> M17 polish
```

Не переходить к следующему milestone, если обязательный gate предыдущего не пройден.
