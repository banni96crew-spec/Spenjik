---
name: hud
description: 'Configure HUD display options (layout, presets, display elements)'
metadata:
  argument-hint: '[setup|minimal|focused|full|status]'
  role: 'config-writer  # DOCUMENTATION ONLY - This skill writes to ~/.agent/ paths'
  scope: '~/.agent/**  # DOCUMENTATION ONLY - Allowed write scope'
---

# HUD Skill

## Cursor Compatibility

This skill is formatted for Cursor Agent Skills. Use Cursor's available tools for file edits, shell commands, search, web access, user questions, and any supported delegation. Treat legacy provider, agent, or workflow-tool examples as workflow guidance; if a named tool is unavailable in Cursor, perform the step with available Cursor capabilities or ask the user before substituting behavior.

Configure the workflow HUD (Heads-Up Display) for the statusline.

Note: All `~/.agent/...` paths in this guide respect `AGENT_CONFIG_DIR` when that environment variable is set.

## Quick Commands

| Command | Description |
|---------|-------------|
| `/hud` | Show current HUD status (auto-setup if needed) |
| `/hud setup` | Install/repair HUD statusline |
| `/hud minimal` | Switch to minimal display |
| `/hud focused` | Switch to focused display (default) |
| `/hud full` | Switch to full display |
| `/hud status` | Show detailed HUD status |

## Auto-Setup

When you run `/hud` or `/hud setup`, the system will automatically:
1. Check if `~/.agent/hud/workflow-hud.mjs` exists
2. Check if `statusLine` is configured in `~/.agent/settings.json`
3. If missing, create the HUD wrapper script and configure settings
4. Report status and prompt to restart Cursor if changes were made

**IMPORTANT**: If the argument is `setup` OR if the HUD script doesn't exist at `~/.agent/hud/workflow-hud.mjs`, you MUST create the HUD files directly using the instructions below.

### Setup Instructions (Run These Commands)

**Step 1:** Check if setup is needed:
```bash
node -e "const p=require('path'),f=require('fs'),d=process.env.AGENT_CONFIG_DIR||p.join(require('os').homedir(),'.agent');console.log(f.existsSync(p.join(d,'hud','workflow-hud.mjs'))?'EXISTS':'MISSING')"
```

**Step 2:** Verify the plugin is installed:
```bash
node -e "const p=require('path'),f=require('fs'),d=process.env.AGENT_CONFIG_DIR||p.join(require('os').homedir(),'.agent'),b=p.join(d,'plugins','cache','workflow','workflow');try{const v=f.readdirSync(b).filter(x=>/^\d/.test(x)).sort((a,c)=>a.localeCompare(c,void 0,{numeric:true}));if(v.length===0){console.log('Plugin not installed - run: /plugin install workflow');process.exit()}const l=v[v.length-1],h=p.join(b,l,'dist','hud','index.js');console.log('Version:',l);console.log(f.existsSync(h)?'READY':'NOT_FOUND - try reinstalling: /plugin install workflow')}catch{console.log('Plugin not installed - run: /plugin install workflow')}"
```

**Step 3:** If workflow-hud.mjs is MISSING or argument is `setup`, install the HUD wrapper and its dependency from the canonical template:

```bash
HUD_DIR="${AGENT_CONFIG_DIR:-$HOME/.agent}/hud"
mkdir -p "$HUD_DIR/lib"
cp "${AGENT_PLUGIN_ROOT}/scripts/lib/hud-wrapper-template.txt" "$HUD_DIR/workflow-hud.mjs"
cp "${AGENT_PLUGIN_ROOT}/scripts/lib/config-dir.mjs" "$HUD_DIR/lib/config-dir.mjs"
```

**IMPORTANT:** Always copy from the canonical template at `scripts/lib/hud-wrapper-template.txt`. Do NOT write the wrapper content inline — the template is the single source of truth and is guarded by drift tests (`src/__tests__/hud-wrapper-template-sync.test.ts`, `src/__tests__/paths-consistency.test.ts`).

**Step 4:** Make it executable (Unix only, skip on Windows):
```bash
node -e "if(process.platform==='win32'){console.log('Skipped (Windows)')}else{require('fs').chmodSync(require('path').join(process.env.AGENT_CONFIG_DIR||require('path').join(require('os').homedir(),'.agent'),'hud','workflow-hud.mjs'),0o755);console.log('Done')}"
```

**Step 5:** Update settings.json to use the HUD:

Read `${AGENT_CONFIG_DIR:-~/.agent}/settings.json`, then update/add the `statusLine` field.

**IMPORTANT:** Do not use `~` in the command. On Unix, use `$HOME` to keep the path portable across machines. On Windows, use an absolute path because Windows does not expand `~` in shell commands.

If you are on Windows, first determine the correct path:
```bash
node -e "const p=require('path').join(require('os').homedir(),'.agent','hud','workflow-hud.mjs').split(require('path').sep).join('/');console.log(JSON.stringify(p))"
```

**IMPORTANT:** The command path MUST use forward slashes on all platforms. Cursor executes statusLine commands via bash, which interprets backslashes as escape characters and breaks the path.

Then set the `statusLine` field. On Unix it should stay portable and look like:
```json
{
  "statusLine": {
    "type": "command",
    "command": "node ${AGENT_CONFIG_DIR:-$HOME/.agent}/hud/workflow-hud.mjs"
  }
}
```

On Windows the path uses forward slashes (not backslashes):
```json
{
  "statusLine": {
    "type": "command",
    "command": "node C:/Users/username/.agent/hud/workflow-hud.mjs"
  }
}
```

Use the Edit tool to add/update this field while preserving other settings.

**Step 6:** Clean up old HUD scripts (if any):
```bash
node -e "const p=require('path'),f=require('fs'),d=process.env.AGENT_CONFIG_DIR||p.join(require('os').homedir(),'.agent'),t=p.join(d,'hud','workflow-hud.js');try{if(f.existsSync(t)){f.unlinkSync(t);console.log('Removed legacy workflow-hud.js')}else{console.log('No legacy script found')}}catch{}"
```

**Step 7:** Tell the user to restart Cursor for changes to take effect.

## Display Presets

### Minimal
Shows only the essentials:
```
[workflow] Ralph | ultrawork | todos:2/5
```

### Focused (Default)
Shows all relevant elements:
```
[workflow] branch:main | Ralph:3/10 | US-002 | ultrawork skill:planner | ctx:67% | agents:2 | bg:3/5 | todos:2/5
```

### Full
Shows everything including multi-line agent details:
```
[workflow] repo:workflow branch:main | Ralph:3/10 | US-002 (2/5) | ultrawork | ctx:[████░░]67% | agents:3 | bg:3/5 | todos:2/5
├─ O architect    2m   analyzing architecture patterns...
├─ e explore     45s   searching for test files
└─ s executor     1m   implementing validation logic
```

## Multi-Line Agent Display

When agents are running, the HUD shows detailed information on separate lines:
- **Tree characters** (`├─`, `└─`) show visual hierarchy
- **Agent code** (O, e, s) indicates agent type with model tier color
- **Duration** shows how long each agent has been running
- **Description** shows what each agent is doing (up to 45 chars)

## Display Elements

| Element | Description |
|---------|-------------|
| `[workflow]` | Mode identifier |
| `repo:name` | Git repository name (cyan) |
| `branch:name` | Git branch name (cyan) |
| `Ralph:3/10` | Ralph loop iteration/max |
| `US-002` | Current PRD story ID |
| `ultrawork` | Active mode badge |
| `skill:name` | Last activated skill (cyan) |
| `ctx:67%` | Context window usage |
| `agents:2` | Running subagent count |
| `bg:3/5` | Background task slots |
| `todos:2/5` | Todo completion |

## Color Coding

- **Green**: Normal/healthy
- **Yellow**: Warning (context >70%, Ralph >7)
- **Red**: Critical (context >85%, Ralph at max)

## Configuration Location

HUD config is stored in `~/.agent/settings.json` under the `workflowHud` key (or your custom config directory if `AGENT_CONFIG_DIR` is set).

Legacy config location (deprecated): `~/.agent/.workflow/hud-config.json`

## Manual Configuration

You can manually edit the config file. Each option can be set individually - any unset values will use defaults.

```json
{
  "preset": "focused",
  "elements": {
    "workflowLabel": true,
    "updateNotification": true,
    "Ralph": true,
    "autopilot": true,
    "prdStory": true,
    "activeSkills": true,
    "lastSkill": true,
    "contextBar": true,
    "agents": true,
    "agentsFormat": "multiline",
    "backgroundTasks": true,
    "todos": true,
    "thinking": true,
    "thinkingFormat": "text",
    "permissionStatus": false,
    "apiKeySource": false,
    "profile": true,
    "promptTime": true,
    "sessionHealth": true,
    "useBars": true,
    "showCallCounts": true,
    "callCountsFormat": "auto",
    "safeMode": true,
    "maxOutputLines": 4
  },
  "thresholds": {
    "contextWarning": 70,
    "contextCompactSuggestion": 80,
    "contextCritical": 85,
    "persistenceLoopWarning": 7
  },
  "staleTaskThresholdMinutes": 30,
  "contextLimitWarning": {
    "threshold": 80,
    "autoCompact": false
  }
}
```

### callCountsFormat

Controls the call-count badge icon style:
- `"auto"` (default): emoji on macOS/Linux, ASCII on Windows/WSL
- `"emoji"`: force `🔧 🤖 ⚡`
- `"ascii"`: force `T: A: S:`

### safeMode

When `safeMode` is `true` (default), the HUD strips ANSI codes and uses ASCII-only output to prevent terminal rendering corruption during concurrent updates. This is especially important on Windows and when using terminal multiplexers.

### agentsFormat Options

- `count`: agents:2
- `codes`: agents:Oes (type-coded with model tier casing)
- `codes-duration`: agents:O(2m)es (codes with duration)
- `detailed`: agents:[architect(2m),explore,exec]
- `descriptions`: O:analyzing code | e:searching (codes + what they're doing)
- `tasks`: [analyzing code, searching...] (just descriptions)
- `multiline`: Multi-line display with full agent details on separate lines

## Troubleshooting

If the HUD is not showing:
1. Run `/hud setup` to auto-install and configure
2. Restart Cursor after setup completes
3. If still not working, run `/omc-doctor` for full diagnostics

**Legacy string format migration:** Older workflow versions wrote `statusLine` as a plain string (e.g., `"~/.agent/hud/workflow-hud.mjs"`). Modern Cursor (v2.1+) requires an object format. Running the installer or `/hud setup` will auto-migrate legacy strings to the correct object format:
```json
{
  "statusLine": {
    "type": "command",
    "command": "node ${AGENT_CONFIG_DIR:-$HOME/.agent}/hud/workflow-hud.mjs"
  }
}
```

**Node 24+ compatibility:** The HUD wrapper script imports `homedir` from `node:os` (not `node:path`). If you encounter `SyntaxError: The requested module 'path' does not provide an export named 'homedir'`, re-run the installer to regenerate `workflow-hud.mjs`.

Manual verification:
- HUD script: `~/.agent/hud/workflow-hud.mjs`
- Settings: `~/.agent/settings.json` should have `statusLine` configured as an object with `type` and `command` fields

---

*The HUD updates automatically every ~300ms during active sessions.*
