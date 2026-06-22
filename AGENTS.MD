# AGENTS.MD

## Cursor compatibility

Before starting work:

1. Read applicable files from `.cursor/rules/`.
2. Read relevant workflows from `.cursor/skills/`.
3. Treat `.cursor/agents/` as role definitions when delegating to subagents.
4. Report which files were loaded.
5. If a Cursor-specific directive cannot be interpreted, stop and report it.

## Project Overview

**The Turf** — локальная пошаговая карточная мини-игра о борьбе за влияние, управлении ресурсами и тактических атаках. Матч рассчитан ровно на 15 раундов и включает человека и трёх локальных AI-соперников.

M0–M15 завершены. Следующий milestone: M16 — UI/UX. Проект сейчас logic-first / test-driven / headless: Godot-проект, GUT, logic modules, Resources и tests существуют; playable UI и main scene начинаются в M16. `GameStateManager.gd` существует и зарегистрирован как Autoload. Последний full GUT suite: 347/347 pass. Canonical MVP smoke: pass.

Зафиксированный стек:

- Godot 4.6.2;
- GDScript;
- Godot `Control`, `Container` и `Theme` для UI;
- `.tres` и типизированные `Resource` для статических данных;
- `Dictionary`-снимки для runtime-состояния;
- `GameStateManager.gd` как Autoload и единственный UI-facing facade;
- GUT 9.6.0 для тестов;
- Windows и Linux как целевые платформы MVP.

Web-стек, backend и C# не входят в проект: React, TypeScript, JavaScript gameplay runtime, Zustand, Tailwind, Next.js, Docker, WebSocket backend и мобильная архитектура запрещены.

## Repository Structure

Фактически существующая структура:

- `.cursor/agents/` — определения специализированных Cursor-агентов и общие принципы их работы.
- `.cursor/rules/`, `.cursor/skills/`, `.cursor/hooks/` — проектные правила, вспомогательные workflows и локальные проверки Cursor.
- `/docs/prd/` — главный источник истины по продукту, игровым системам, архитектуре, API, тестам и правилам для LLM.
- `/docs/engine-reference/godot/` — закреплённая справка по Godot 4.6, изменениям API и актуальным практикам.
- `/docs/templates/` — шаблоны проектной, архитектурной, UX-, QA- и production-документации.
- `.cursor/docs/examples/`, `.cursor/docs/references/`, `.cursor/docs/hooks-reference.md` — примеры workflow, справочные материалы и примеры проверок.
- `ROADMAP/` — контекст и задания для milestone M0–M17; порядок реализации задаётся также `docs/prd/19_IMPLEMENTATION_ORDER.md`.
- `Godot_v4.6.2-stable_win64.exe/` — локальные исполняемые файлы Godot 4.6.2 для Windows.
- `README.md` — краткий обзор статуса, стека, источников истины и порядка разработки.
- `.git/` — локальный Git-репозиторий для сохранения контрольных точек разработки.

Godot-проект и gameplay code:

- `project.godot`, `addons/gut/`, `logic/`, `data/`, `tests/` — присутствуют;
- `autoload/` — содержит зарегистрированный `GameStateManager.gd` Autoload;
- `scenes/` — начинается в M16 (UI/playable build);
- CI-конфигурация — не обнаружена.

Предписанная будущая структура Godot-проекта определена в `docs/prd/15_GODOT_ARCHITECTURE.md`:

- `autoload/` — `GameStateManager.gd`; опционально `AudioManager.gd` и `DebugSnapshotManager.gd`.
- `logic/game_state/` — фабрика, валидатор, контроллер фаз и определение победителя.
- `logic/random/` — только `SeededRandom.gd` и `SeededPicker.gd`.
- `logic/economy/`, `logic/combat/`, `logic/roles/`, `logic/contracts/`, `logic/street_deals/`, `logic/contacts/`, `logic/turf_levels/`, `logic/ai/` — модули игровых правил.
- `logic/catalog/` — доступ и валидация статических Resource-каталогов.
- `data/ids/` — стабильные ID, фазы, режимы атак и коды ошибок.
- `data/resources/` — схемы и `.tres`-экземпляры статических данных.
- `scenes/main/`, `scenes/game/`, `scenes/ui/screens/`, `scenes/ui/panels/`, `scenes/ui/widgets/` — сцены и тонкие UI-скрипты.
- `tests/unit/`, `tests/integration/`, `tests/replay/`, `tests/static/`, `tests/fixtures/` — GUT-тесты и fixtures.

## Development Rules

### Источники истины

- Перед изменением системы определить её owner-документ в `docs/prd/`.
- Минимальный контекст задачи: `20_LLM_AGENT_RULES.md`, `03_IDS_AND_CONSTANTS.md`, owner PRD системы, прямые зависимости и релевантный раздел `18_TEST_PLAN.md`.
- Не загружать без необходимости весь PRD. Если задаче требуется более 5–7 PRD-файлов одновременно, разбить задачу.
- При конфликте правил проверить `21_OPEN_QUESTIONS_AND_FIXES.md`. Не разрешать противоречия догадками.
- Не менять баланс, цены, эффекты карт, ID, роли, контракты, контакты, Street Deals, Turf Levels, AI-профили и core loop без отдельного утверждённого изменения PRD.
- Не создавать новые игровые правила, сущности, фазы, ошибки или скрытые состояния.

### Архитектура и состояние

Допустимое направление зависимостей:

```text
UI → GameStateManager → logic modules → catalogs/resources/constants
```

- `GameStateManager.gd` хранит единственный активный runtime-снимок и остаётся тонким facade.
- Logic-модули работают с явно переданным рабочим состоянием и не обращаются обратно к `GameStateManager`.
- UI только отображает состояние, собирает payload, вызывает facade, показывает preview, ошибки и причины недоступности.
- UI не рассчитывает цены, не валидирует покупки, не разрешает бой и не изменяет Nal, VP, карты, контракты, контакты, долги или фазы.
- AI использует те же `MarketLogic`, `CombatEngine` и валидаторы, что и человек; прямые изменения состояния запрещены.
- Статические данные хранятся в неизменяемых `.tres` Resources и доступны через каталоги.
- Runtime-состояние хранится в `Dictionary`; не использовать Nodes, UI state или изменяемые Resources как gameplay state.
- Стабильные ID и ошибки брать из `data/ids/`; ad-hoc строки ошибок запрещены.
- Public mutator сначала валидирует копию состояния, затем коммитит её только при `ok == true`.
- Ошибка валидации не должна менять активное или входное состояние.
- Selectors и previews не изменяют состояние, random step, логи, флаги или фазу.

Базовая форма результата mutator:

```gdscript
{
    "ok": true,
    "error": ValidationErrors.OK,
    "state": {},
    "log_entries": []
}
```

### Детерминированность

- Весь gameplay random проходит только через `logic/random/SeededRandom.gd` и `SeededPicker.gd`.
- Запрещены `randf()`, `randi()`, `randomize()` и `RandomNumberGenerator` в gameplay-коде.
- Все потребители используют общий `state["random"]`; не создавать локальные или основанные на системном времени потоки.
- Preview и selector не потребляют random.
- Рефакторинг не должен менять порядок random-вызовов и число шагов без прямого требования owner PRD и replay-тестов.
- `WinnerResolver` не использует random.

### Стиль GDScript и нейминг

- Использовать статическую типизацию переменных, параметров, возвращаемых значений, массивов и сигналов везде, где это поддерживается.
- Классы и `class_name`: `PascalCase`.
- Функции, переменные, сигналы и Dictionary-ключи: `snake_case`.
- Константы и значения enum: `SCREAMING_SNAKE_CASE`.
- Приватные поля и методы начинать с `_`; callbacks сигналов — с `_on_`.
- Имена проектных файлов следуют утверждённой архитектуре, например `GameStateManager.gd`, `MarketLogic.gd`, `CardDefinition.gd`.
- Один `class_name` на файл; ответственность файла должна быть узкой.
- Публичные классы и методы документировать.
- Каждый `.gd`-файл должен быть короче 250 строк. Заранее разделять validator, resolver, selector, log builder, catalog и helper.
- Предпочитать композицию глубокому наследованию и событийное взаимодействие постоянному polling.
- Не добавлять прямые зависимости gameplay logic от UI-узлов или сцен.
- Не использовать текстовые описания Resource как входные данные логики: правила задаются явными полями и ID.
- Gameplay-значения должны быть data-driven, а не разбросаны по скриптам.
- Не добавлять абстракции «на будущее», несвязанный рефакторинг или cleanup вне задачи.

### Импорты и Godot API

- Перед использованием Godot API проверить `docs/engine-reference/godot/VERSION.md`, `deprecated-apis.md`, `breaking-changes.md`, `current-best-practices.md` и релевантный файл из `modules/`.
- При расхождении памяти модели и локальной engine reference приоритет имеет локальная справка для Godot 4.6.
- Для поиска GDScript использовать `rg --glob "*.gd"`; типа ripgrep `gdscript` не существует.
- Logic не импортирует `res://scenes/ui/`, UI не импортирует низкоуровневую логику для мутаций, Resources не импортируют runtime logic.

### Ошибки, неопределённости и тесты

- Не скрывать ошибки и не заменять точные `ValidationErrors` общими строками.
- Если необходимого правила, поля или error code нет, остановить затронутую ветку и оформить либо сослаться на `OQ-*` в `21_OPEN_QUESTIONS_AND_FIXES.md`.
- `TODO`, `TBD`, `FIXME` и `???` допустимы только рядом со ссылкой на зарегистрированный `OQ-*`.
- Для gameplay-изменений добавлять или обновлять GUT-тесты: happy path, failed-validation/no-mutation, edge case и интеграцию с соседними модулями.
- Для selectors проверять отсутствие мутации; для random — одинаковый результат при одинаковом seed и точное изменение step.
- Не удалять, не ослаблять и не пропускать тесты ради зелёного результата.
- Если проверку нельзя запустить, явно указать `не запускалась`; не утверждать, что она прошла.

## Cursor / Codex Agent Instructions

1. Сначала изучить фактические файлы, связанные вызовы, тесты, конфиги и owner PRD; не судить код, который не был прочитан.
2. Проверить `21_OPEN_QUESTIONS_AND_FIXES.md` и relevant engine reference до реализации.
3. Сформулировать границы задачи, затрагиваемые state fields, API, тесты и допустимые файлы.
4. Не менять архитектуру, public API, баланс или gameplay-правила без явной необходимости и утверждённого источника истины.
5. Делать минимальный полный набор изменений; не трогать несвязанные файлы и не перезаписывать пользовательскую работу.
6. Не удалять существующую функциональность и не выполнять разрушительные Git/filesystem-операции без явного разрешения.
7. При неоднозначности не угадывать: назвать точный пробел и его влияние; для gameplay-неопределённости использовать процесс `OQ-*`.
8. Перед изменением файла проверить его callers, зависимости и соседние тесты.
9. Сохранять текущий стиль и структуру. Новые паттерны вводить только при доказанной необходимости.
10. Нетривиальные решения объяснять через причину, компромисс и влияние на совместимость или детерминизм.
11. После изменения выполнить сначала узкие, затем пропорциональные риску общие проверки.
12. Проверить итоговый diff на scope creep, временный debug-код, секреты, неиспользуемые импорты и случайные изменения.
13. В отчёте перечислить изменённые файлы, выполненные проверки, результаты, ограничения и открытые вопросы.
14. Явное поручение пользователя создать или изменить файл считается разрешением на соответствующую запись. Для новых творческих, стратегических или высокорисковых решений сначала представить варианты и получить решение пользователя.

## Commands

Команды выполняются из корня репозитория (каталог с `project.godot`). `GODOT_BIN` должен указывать на Godot 4.6.2.

M0 bootstrap smoke в PowerShell:

```powershell
& $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gtest=res://tests/smoke/test_gut_bootstrap.gd -gexit
```

Этот тест проверяет только импорт проекта и работоспособность GUT. Канонический MVP smoke ниже становится обязательным после появления интегрированных gameplay-зависимостей, не позднее M15.

Полный GUT suite в PowerShell:

```powershell
& $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Канонический MVP smoke test в PowerShell:

```powershell
& $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gtest=res://tests/integration/test_smoke_mvp.gd -gexit
```

CI-последовательность, определённая в PRD:

```bash
godot --headless --editor --path "$PWD" --quit
godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://tests/integration/test_smoke_mvp.gd -gexit
godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Требования:

- `godot` или `$env:GODOT_BIN` должен указывать на Godot 4.6.2.
- GUT должен быть версии 9.6.0.
- Canonical smoke test: `res://tests/integration/test_smoke_mvp.gd`.

Отдельные подтверждённые команды запуска игры, сборки/export, линтинга и форматирования: **Не обнаружено в проекте**.

## Code Quality Checklist

- [ ] Прочитаны owner PRD, прямые зависимости и релевантные тесты.
- [ ] Изменения соответствуют Godot 4.6.2 и текущей архитектуре.
- [ ] Нет несогласованных изменений gameplay-правил, баланса, ID или public API.
- [ ] Изменён только необходимый scope; пользовательские и несвязанные файлы сохранены.
- [ ] Нет дублирования источников истины, скрытого состояния и ad-hoc error strings.
- [ ] UI не содержит gameplay logic; logic не зависит от UI; AI не обходит валидаторы.
- [ ] Gameplay random использует только `SeededRandom`/`SeededPicker`.
- [ ] Failed validation не мутирует состояние; selectors/previews остаются read-only.
- [ ] `.gd`-файлы короче 250 строк, код типизирован и читаем.
- [ ] Нет неиспользуемых импортов, временных логов, секретов и непомеченных `TODO`/`FIXME`.
- [ ] Сохранены API, result shapes, error codes и deterministic random step count.
- [ ] Добавлены или обновлены необходимые unit/integration/replay/static тесты.
- [ ] Доступные проверки запущены; фактический результат указан без предположений.

## Important Notes

- Главный риск проекта — расхождение реализации с owner PRD. Не переносить правила из памяти, старого монолитного PRD или общих agent-шаблонов, если модульный PRD задаёт более конкретное правило.
- `.cursor/docs/technical-preferences.md` заполнен из модульного PRD. Поля, для которых PRD не задаёт численных или engine-level решений, явно отмечены как неопределённые и не должны заполняться догадками.
- `.cursor/docs/coding-standards.md` синхронизирован с Godot 4.6.2, GDScript и GUT 9.6.0. Универсальные Unity/Unreal и GdUnit4-команды к проекту не применяются.
- MVP не включает multiplayer, backend, аккаунты, campaign persistence, обязательный web export, мобильную адаптацию, C#-версию и card editor.
- `SaveManager.gd` не нужен. Допустим только необязательный `DebugSnapshotManager.gd`, который не участвует в gameplay loop.
- Реализация идёт в порядке milestone из `docs/prd/19_IMPLEMENTATION_ORDER.md`: constants → Resources/catalogs → deterministic random → state factory/validator → owner logic + tests → facade → integration/replay → UI.
- UI до зелёных logic-тестов допускается только как placeholder без gameplay-правил.
- Пользователь принимает творческие и стратегические решения. Агент должен показывать варианты и компромиссы, когда требования действительно не определены, но не запрашивать повторное разрешение на уже явно поручённое изменение.
