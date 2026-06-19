# The Turf / Передел

**The Turf** — локальная пошаговая карточная мини-игра о борьбе за влияние, ресурсах и тактических атаках. Матч длится ровно 15 раундов: человек играет против трёх локальных AI-соперников.

## Статус

Проект находится на стадии подготовки к реализации.

Готовы:

- модульный PRD;
- архитектура Godot-проекта;
- схема состояния и публичный API;
- тестовая стратегия;
- roadmap M0–M17;
- правила для Cursor/Codex.

Ещё не выполнены:

- M0 Project Bootstrap;
- `project.godot`;
- подключение GUT;
- исходный GDScript-код;
- сцены, Resources и тесты.

Наличие команд и ожидаемой структуры в документации не означает, что Godot-проект уже создан или проверки уже запускались.

## Технологический стек

- Godot 4.6.2 stable;
- GDScript со статической типизацией;
- Godot `Control`, `Container` и `Theme` для UI;
- `.tres` Resources для статических данных;
- `Dictionary` snapshots для runtime-состояния;
- `GameStateManager.gd` как единственный UI-facing gameplay facade;
- GUT 9.6.0;
- Windows и Linux как первые целевые платформы.

Web/backend-стек, C#, multiplayer и gameplay persistence не входят в MVP.

## Источники истины

Начальная точка документации:

- [`docs/prd/00_INDEX.md`](docs/prd/00_INDEX.md)

Основные документы:

- [`docs/prd/01_PRODUCT_OVERVIEW.md`](docs/prd/01_PRODUCT_OVERVIEW.md) — продукт и scope;
- [`docs/prd/15_GODOT_ARCHITECTURE.md`](docs/prd/15_GODOT_ARCHITECTURE.md) — архитектура и структура проекта;
- [`docs/prd/18_TEST_PLAN.md`](docs/prd/18_TEST_PLAN.md) — GUT, smoke, replay и static tests;
- [`docs/prd/19_IMPLEMENTATION_ORDER.md`](docs/prd/19_IMPLEMENTATION_ORDER.md) — порядок M0–M17;
- [`docs/prd/20_LLM_AGENT_RULES.md`](docs/prd/20_LLM_AGENT_RULES.md) — правила coding-agent;
- [`docs/prd/21_OPEN_QUESTIONS_AND_FIXES.md`](docs/prd/21_OPEN_QUESTIONS_AND_FIXES.md) — принятые исправления и открытые вопросы;
- [`AGENTS.MD`](AGENTS.MD) — практическое руководство для Cursor/Codex.

При конфликте owner PRD имеет приоритет над roadmap, общими шаблонами и старыми материалами.

## Структура репозитория

```text
.cursor/                         Cursor agents, rules, skills and hooks
docs/
  prd/                           Modular product and engineering specification
  engine-reference/godot/        Pinned Godot 4.6 reference
  templates/                     Documentation templates
ROADMAP/                         Milestone context and implementation tasks
AGENTS.MD                        Repository instructions for AI agents
README.md                        Repository overview
```

Будущая структура Godot-проекта описана в `docs/prd/15_GODOT_ARCHITECTURE.md`. Не следует создавать gameplay-файлы будущих milestone как пустые заглушки.

## Архитектурная граница

```text
UI -> GameStateManager -> logic modules -> catalogs/resources/constants
```

Ключевые ограничения:

- UI не содержит gameplay logic;
- AI использует те же валидаторы и resolver-модули, что и человек;
- failed validation не мутирует состояние;
- selectors и previews read-only;
- gameplay random проходит только через `SeededRandom.gd` и `SeededPicker.gd`;
- каждый `.gd` source file короче 250 строк.

## Тестовые контракты

После выполнения M0:

- `tests/smoke/test_gut_bootstrap.gd` проверяет только импорт проекта и работоспособность GUT;
- `tests/integration/test_smoke_mvp.gd` проверяет интегрированный MVP flow и становится обязательным не позднее M15;
- полный suite запускается из каталога с `project.godot`.

Команды задокументированы в:

- [`docs/coding-standards.md`](docs/coding-standards.md);
- [`docs/prd/18_TEST_PLAN.md`](docs/prd/18_TEST_PLAN.md).

До выполнения M0 эти команды неприменимы.

## Порядок разработки

```text
M0 bootstrap
-> constants and IDs
-> Resources and catalogs
-> deterministic random
-> state factory and validator
-> gameplay owner modules
-> GameStateManager facade
-> integration and replay
-> UI/UX
-> polish and hardening
```

Не переходить к следующему milestone, если обязательный gate предыдущего не пройден.

## Правила участия

- Перед изменением определить owner PRD и текущий milestone.
- Не менять баланс, ID, игровые правила и API без обновления owner PRD.
- Не выдумывать отсутствующее поведение; использовать процесс `OQ-*`.
- Добавлять тесты вместе с изменением поведения.
- Не утверждать, что непроведённая проверка прошла.
- Использовать Conventional Commits.

Подробные правила: [`docs/coding-standards.md`](docs/coding-standards.md) и [`AGENTS.MD`](AGENTS.MD).
