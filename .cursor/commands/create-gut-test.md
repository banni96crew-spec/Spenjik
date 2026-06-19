### 4. `create-gut-test` — шаблон GUT‑теста для модуля

**Цель:**  Создать заготовку теста в GUT со структурой «happy path» и «failed validation», чтобы обеспечить покрытие требований из тестового плана:contentReference[oaicite:15]{index=15} и правил мутации состояния:contentReference[oaicite:16]{index=16}.

**Когда использовать:**  При добавлении нового логического модуля или функции; сразу после написания кода.

**Команда / промт:**
```text
# Новый GUT‑тест для модуля

Попроси пользователя указать:
- Имя тестируемого модуля (например, IncomeLogic);
- Тип теста: unit, integration, replay или static.

## Действия
1. Определи путь теста:
   - Для unit‑теста: `res://tests/unit/test_<module>.gd`;
   - Для интеграционного: `res://tests/integration/test_<module>_<scenario>.gd`.
2. Создай файл и добавь заголовок `extends "res://addons/gut/test.gd"`.
3. Импортируй модуль, который тестируется (например, `const IncomeLogic = preload("res://logic/economy/IncomeLogic.gd")`).
4. Создай функцию `func before_all():` для подготовки состояния и фикстур.
5. Добавь минимум два теста:
   - `func test_happy_path() -> void:` — вызывает модуль с корректным `state`/`payload` и проверяет, что `ok == true` и возвращаемое состояние валидно.
   - `func test_failed_validation_no_mutation() -> void:` — вызывает модуль с некорректным `payload`, проверяет, что `ok == false` и исходное состояние не изменилось.
6. Если модуль содержит функции‑предпросмотры, добавь отдельный тест для проверки отсутствия мутации и изменения random‑step.
7. Используй `assert_eq`, `assert_false`, `assert_true` из GUT.