# Запуск полного набора тестов

1. Открой терминал в каталоге с `project.godot`.
2. Запусти полный набор тестов:
   - **Linux/macOS/CI:**
     ```bash
     godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
     ```
   - **Windows/PowerShell:**
     ```powershell
     & $env:GODOT_BIN --headless -d -s --path (Get-Location).Path addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
     ```
3. Дождись завершения тестов и зафиксируй результат. Код возврата `0` означает, что все тесты прошли, `1` — существуют ошибки.
4. Не запускай полный набор тестов, пока не прошёл smoke‑тест и канонический MVP smoke (после M15).