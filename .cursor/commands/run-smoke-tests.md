# Запуск smoke‑тестов

1. Открой встроенный терминал в Cursor.
2. Убедись, что текущий каталог содержит `project.godot`.
3. В зависимости от среды выполни одну из команд:
   - **Linux/macOS/CI:**
     ```bash
     godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://tests/smoke/test_gut_bootstrap.gd -gexit
     ```
   - **Windows/PowerShell:**
     ```powershell
     & $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gtest=res://tests/smoke/test_gut_bootstrap.gd -gexit
     ```
4. Проверь код возврата: `0` означает успешный smoke, `1` — ошибка. При ошибке проанализируй сообщение и исправь конфигурацию.
5. Не расширяй smoke‑тесты — они проверяют только импорт проекта и наличие GUT.