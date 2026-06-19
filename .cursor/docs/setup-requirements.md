# Setup Requirements

These requirements support the Cursor-based game-development workflow. Optional tools should fail gracefully: missing tools reduce automation coverage but should not block ordinary editing.

## Required

| Tool | Purpose | Install |
|------|---------|---------|
| Cursor | AI agent IDE and Cursor Skills runtime | [cursor.com](https://cursor.com) |
| Git | Version control, branch management, history-based reports | [git-scm.com](https://git-scm.com/) |
| Project game engine | Build and test execution | Godot / Unity / Unreal as chosen |

## Recommended

| Tool | Used for | Install |
|------|----------|---------|
| Bash or Git Bash | Cross-platform repository scripts | Included with Git for Windows |
| Python 3 | JSON/data validation and utility scripts | [python.org](https://www.python.org/) |
| jq | JSON parsing in optional repository scripts | See below |

### Installing jq

Windows:

```powershell
winget install jqlang.jq
```

macOS:

```bash
brew install jq
```

Linux:

```bash
sudo apt install jq     # Debian/Ubuntu
sudo dnf install jq     # Fedora
```

## Platform Notes

### Windows

- Install Git for Windows with Git Bash.
- Use PowerShell for ordinary Cursor terminal work unless a script explicitly requires Bash.
- If repository scripts call `bash tools/...`, verify `bash.exe` is on PATH.

### macOS / Linux

- Bash, Python, and Git are usually preinstalled or available through the system package manager.
- Install engine-specific CLI tooling if CI or smoke checks need headless builds.

## Verifying Your Setup

```bash
git --version
python --version
jq --version
```

Also verify the chosen engine can run from the command line.

## What Happens Without Optional Tools

| Missing | Impact |
|---------|--------|
| jq | JSON validation scripts may skip structured checks |
| Python 3 | Data validation and report-generation helpers may be unavailable |
| Bash | Shell scripts written for Bash need PowerShell equivalents or Git Bash |

## Recommended IDE

Use Cursor as the primary IDE for this workflow. Keep project rules in `.cursor/rules/`, reusable workflows in `.cursor/skills/`, and workflow documentation in `.cursor/docs/`.
