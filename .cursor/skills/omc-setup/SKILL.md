---
name: omc-setup
description: 'Install or refresh workflow for plugin, npm, and local-dev setups from the canonical setup flow'
---

# workflow Setup

## Cursor Compatibility

This skill is formatted for Cursor Agent Skills. Use Cursor's available tools for file edits, shell commands, search, web access, user questions, and any supported delegation. Treat legacy provider, agent, or workflow-tool examples as workflow guidance; if a named tool is unavailable in Cursor, perform the step with available Cursor capabilities or ask the user before substituting behavior.

This is the **only command you need to learn**. After running this, everything else is automatic.

**When this skill is invoked, immediately execute the workflow below. Do not only restate or summarize these instructions back to the user.**

Note: All `~/.agent/...` paths in this guide respect `AGENT_CONFIG_DIR` when that environment variable is set.

## Best-Fit Use

Choose this setup flow when the user wants to **install, refresh, or repair workflow itself**.

- Marketplace/plugin install users should land here after `/plugin install workflow`
- npm users should land here after `npm i -g oh-my-Cursor Agent-sisyphus@latest`
- local-dev and worktree users should land here after updating the checked-out repo and rerunning setup

## Flag Parsing

Check for flags in the user's invocation:
- `--help` → Show Help Text (below) and stop
- `--local` → Phase 1 only (target=local), then stop
- `--global` → Phase 1 only (target=global), then stop
- `--force` → Skip Pre-Setup Check, run full setup (Phase 1 → 2 → 3 → 4)
- No flags → Run Pre-Setup Check, then full setup if needed

## Help Text

When user runs with `--help`, display this and stop:

```
workflow Setup - Configure workflow

USAGE:
  /omc-setup           Run initial setup wizard (or update if already configured)
  /omc-setup --local   Configure local project (.agent/primary-agent.md)
  /omc-setup --global  Configure global settings (~/.agent/primary-agent.md)
  /omc-setup --force   Force full setup wizard even if already configured
  /omc-setup --help    Show this help

MODES:
  Initial Setup (no flags)
    - Interactive wizard for first-time setup
    - Configures primary-agent.md (local or global)
    - Sets up HUD statusline
    - Checks for updates
    - Offers MCP server configuration
    - Configures team mode defaults (agent count, type, model)
    - If already configured, offers quick update option

  Local Configuration (--local)
    - Downloads fresh primary-agent.md to ./.agent/
    - Backs up existing primary-agent.md to .agent/primary-agent.md.backup.YYYY-MM-DD
    - Project-specific settings
    - Use this to update project config after workflow upgrades

  Global Configuration (--global)
    - Downloads fresh primary-agent.md to ~/.agent/
    - Backs up existing primary-agent.md to ~/.agent/primary-agent.md.backup.YYYY-MM-DD
    - Default: explicitly overwrites ~/.agent/primary-agent.md so plain `Cursor Agent` also uses workflow
    - Optional preserve mode keeps the user's base `primary-agent.md` and installs workflow into `agent-workflow.md` for `workflow` launches
    - Applies to all Cursor sessions
    - Cleans up legacy hooks
    - Use this to update global config after workflow upgrades

  Force Full Setup (--force)
    - Bypasses the "already configured" check
    - Runs the complete setup wizard from scratch
    - Use when you want to reconfigure preferences

EXAMPLES:
  /omc-setup           # First time setup (or update primary-agent.md if configured)
  /omc-setup --local   # Update this project
  /omc-setup --global  # Update all projects
  /omc-setup --force   # Re-run full setup wizard

For more info: https://github.com/Yeachan-Heo/workflow
```


## Active Plugin Root Resolution

Before running setup shell commands or reading phase files, resolve the current workflow plugin root. This prevents an already-running Cursor session from continuing to use a stale `AGENT_PLUGIN_ROOT` after `/plugin marketplace update workflow` installs a newer cache version.

```bash
WORKFLOW_SETUP_PLUGIN_ROOT=$(node -e "const f=require('fs'),p=require('path'),h=require('os').homedir(),d=(process.env.AGENT_CONFIG_DIR||p.join(h,'.agent')).replace(/[\\/]+$/,''),b=p.join(d,'plugins','cache','workflow','workflow'),valid=r=>f.existsSync(p.join(r,'skills','workflow-setup','SKILL.md'))||f.existsSync(p.join(r,'hooks','hooks.json'))||f.existsSync(p.join(r,'docs','primary-agent.md'));try{const vs=f.readdirSync(b,{withFileTypes:true}).filter(e=>(e.isDirectory()||e.isSymbolicLink())&&/^\d+\.\d+\.\d+/.test(e.name)).map(e=>e.name).sort((a,c)=>c.localeCompare(a,void 0,{numeric:true}));const hit=vs.map(v=>p.join(b,v)).find(valid);if(hit)console.log(hit);else if(process.env.agent_PLUGIN_ROOT)console.log(process.env.agent_PLUGIN_ROOT)}catch{if(process.env.agent_PLUGIN_ROOT)console.log(process.env.agent_PLUGIN_ROOT)}")
export WORKFLOW_SETUP_PLUGIN_ROOT
```

Use `${WORKFLOW_SETUP_PLUGIN_ROOT:-${AGENT_PLUGIN_ROOT}}` for all setup script and phase paths, then immediately repair stale cache references before any prompts or phase work:

```bash
node "${WORKFLOW_SETUP_PLUGIN_ROOT:-${AGENT_PLUGIN_ROOT}}/scripts/repair-plugin-cache.mjs"
```

## Pre-Setup Check: Already Configured?

**CRITICAL**: Before doing anything else, check if setup has already been completed. This prevents users from having to re-run the full setup wizard after every update.

```bash
# Check if setup was already completed
CONFIG_FILE="${AGENT_CONFIG_DIR:-$HOME/.agent}/.workflow-config.json"

if [ -f "$CONFIG_FILE" ]; then
  SETUP_COMPLETED=$(jq -r '.setupCompleted // empty' "$CONFIG_FILE" 2>/dev/null)
  SETUP_VERSION=$(jq -r '.setupVersion // empty' "$CONFIG_FILE" 2>/dev/null)

  if [ -n "$SETUP_COMPLETED" ] && [ "$SETUP_COMPLETED" != "null" ]; then
    echo "omc setup was already completed on: $SETUP_COMPLETED"
    [ -n "$SETUP_VERSION" ] && echo "Setup version: $SETUP_VERSION"
    ALREADY_CONFIGURED="true"
  fi
fi
```

### If Already Configured (and no --force flag)

If `ALREADY_CONFIGURED` is true AND the user did NOT pass `--force`, `--local`, or `--global` flags:

Use a concise user question to prompt:

**Question:** "workflow is already configured. What would you like to do?"

**Options:**
1. **Update primary-agent.md only** - Download latest primary-agent.md without re-running full setup
2. **Run full setup again** - Go through the complete setup wizard
3. **Cancel** - Exit without changes

**If user chooses "Update primary-agent.md only":**
- Detect if local (.agent/primary-agent.md) or global (~/.agent/primary-agent.md) config exists
- If local exists, run: `bash "${WORKFLOW_SETUP_PLUGIN_ROOT:-${AGENT_PLUGIN_ROOT}}/scripts/setup-Cursor Agent-md.sh" local`
- If only global exists, run: `bash "${WORKFLOW_SETUP_PLUGIN_ROOT:-${AGENT_PLUGIN_ROOT}}/scripts/setup-Cursor Agent-md.sh" global`
- Skip all other steps
- Report success and exit

**If user chooses "Run full setup again":**
- Continue with Resume Detection below

**If user chooses "Cancel":**
- Exit without any changes

### Force Flag Override

If user passes `--force` flag, skip this check and proceed directly to setup.

## Resume Detection

Before starting any phase, check for existing state:

```bash
bash "${WORKFLOW_SETUP_PLUGIN_ROOT:-${AGENT_PLUGIN_ROOT}}/scripts/setup-progress.sh" resume
```

If state exists (output is not "fresh"), use a concise user question to prompt:

**Question:** "Found a previous setup session. Would you like to resume or start fresh?"

**Options:**
1. **Resume from step $LAST_STEP** - Continue where you left off
2. **Start fresh** - Begin from the beginning (clears saved state)

If user chooses "Start fresh":
```bash
bash "${WORKFLOW_SETUP_PLUGIN_ROOT:-${AGENT_PLUGIN_ROOT}}/scripts/setup-progress.sh" clear
```

## Phase Execution

### For `--local` or `--global` flags:
Read the file at `${WORKFLOW_SETUP_PLUGIN_ROOT:-${AGENT_PLUGIN_ROOT}}/skills/omc-setup/phases/01-install-Cursor Agent-md.md` and follow its instructions.
(The phase file handles early exit for flag mode.)

### For full setup (default or --force):
Execute phases sequentially. For each phase, read the corresponding file and follow its instructions:

1. **Phase 1 - Install primary-agent.md**: Read `${WORKFLOW_SETUP_PLUGIN_ROOT:-${AGENT_PLUGIN_ROOT}}/skills/omc-setup/phases/01-install-Cursor Agent-md.md` and follow its instructions.

2. **Phase 2 - Environment Configuration**: Read `${WORKFLOW_SETUP_PLUGIN_ROOT:-${AGENT_PLUGIN_ROOT}}/skills/omc-setup/phases/02-configure.md` and follow its instructions. Phase 2 must delegate HUD/statusLine setup to the `hud` skill; do not generate or patch `statusLine` paths inline here.

3. **Phase 3 - Integration Setup**: Read `${WORKFLOW_SETUP_PLUGIN_ROOT:-${AGENT_PLUGIN_ROOT}}/skills/omc-setup/phases/03-integrations.md` and follow its instructions.

4. **Phase 4 - Completion**: Read `${WORKFLOW_SETUP_PLUGIN_ROOT:-${AGENT_PLUGIN_ROOT}}/skills/omc-setup/phases/04-welcome.md` and follow its instructions.

## Graceful Interrupt Handling

**IMPORTANT**: This setup process saves progress after each phase via `${WORKFLOW_SETUP_PLUGIN_ROOT:-${AGENT_PLUGIN_ROOT}}/scripts/setup-progress.sh`. If interrupted (Ctrl+C or connection loss), the setup can resume from where it left off.

## Keeping Up to Date

After installing workflow updates (via npm or plugin update):

**Automatic**: Just run `/omc-setup` - it will detect you've already configured and offer a quick "Update primary-agent.md only" option that skips the full wizard.

**Manual options**:
- `/omc-setup --local` to update project config only
- `/omc-setup --global` to update global config only
- `/omc-setup --force` to re-run the full wizard (reconfigure preferences)

This ensures you have the newest features and agent configurations without the token cost of repeating the full setup.
