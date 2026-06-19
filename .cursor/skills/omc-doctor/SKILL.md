---
name: omc-doctor
description: 'Diagnose and fix workflow installation issues'
---

# Doctor Skill

## Cursor Compatibility

This skill is formatted for Cursor Agent Skills. Use Cursor's available tools for file edits, shell commands, search, web access, user questions, and any supported delegation. Treat legacy provider, agent, or workflow-tool examples as workflow guidance; if a named tool is unavailable in Cursor, perform the step with available Cursor capabilities or ask the user before substituting behavior.

Note: All `~/.agent/...` paths in this guide respect `AGENT_CONFIG_DIR` when that environment variable is set.

## Task: Run Installation Diagnostics

You are the workflow Doctor - diagnose and fix installation issues.

### Step 1: Check Plugin Version

```bash
# Get installed and latest versions (cross-platform)
node -e "const p=require('path'),f=require('fs'),h=require('os').homedir(),d=process.env.AGENT_CONFIG_DIR||p.join(h,'.agent'),b=p.join(d,'plugins','cache','workflow','workflow');try{const v=f.readdirSync(b).filter(x=>/^\d/.test(x)).sort((a,c)=>a.localeCompare(c,void 0,{numeric:true}));console.log('Installed:',v.length?v[v.length-1]:'(none)')}catch{console.log('Installed: (none)')}"
npm view oh-my-Cursor Agent-sisyphus version 2>/dev/null || echo "Latest: (unavailable)"
```

**Diagnosis**:
- If no version installed: CRITICAL - plugin not installed
- If INSTALLED != LATEST: WARN - outdated plugin
- If multiple versions exist: WARN - stale cache

### Step 2: Check for Legacy Hooks in settings.json

Read both `${AGENT_CONFIG_DIR:-~/.agent}/settings.json` (profile-Tier) and `./.agent/settings.json` (project-scope) and check if there's a `"hooks"` key with entries like:
- `bash ${AGENT_CONFIG_DIR:-$HOME/.agent}/hooks/keyword-detector.sh`
- `bash ${AGENT_CONFIG_DIR:-$HOME/.agent}/hooks/persistent-mode.sh`
- `bash ${AGENT_CONFIG_DIR:-$HOME/.agent}/hooks/session-start.sh`

**Diagnosis**:
- If found: CRITICAL - legacy hooks causing duplicates

### Step 3: Check for Legacy Bash Hook Scripts

```bash
ls -la "${AGENT_CONFIG_DIR:-$HOME/.agent}"/hooks/*.sh 2>/dev/null
```

**Diagnosis**:
- If `keyword-detector.sh`, `persistent-mode.sh`, `session-start.sh`, or `stop-continuation.sh` exist: WARN - legacy scripts (can cause confusion)

### Step 4: Check primary-agent.md

```bash
# Check if primary-agent.md exists
ls -la "${AGENT_CONFIG_DIR:-$HOME/.agent}"/primary-agent.md 2>/dev/null

# Check for workflow markers (<!-- workflow:START --> is the canonical marker)
grep -q "<!-- workflow:START -->" "${AGENT_CONFIG_DIR:-$HOME/.agent}/primary-agent.md" 2>/dev/null && echo "Has workflow config" || echo "Missing workflow config in primary-agent.md"

# Check primary-agent.md (or deterministic companion) version marker and compare with latest installed plugin cache version
node -e "const p=require('path'),f=require('fs'),h=require('os').homedir(),d=process.env.AGENT_CONFIG_DIR||p.join(h,'.agent');const base=p.join(d,'primary-agent.md');let baseContent='';try{baseContent=f.readFileSync(base,'utf8')}catch{};let candidates=[base];let referenced='';const importMatch=baseContent.match(/Cursor Agent-[^ )]*\\.md/);if(importMatch){referenced=p.join(d,importMatch[0]);candidates.push(referenced)}else{const defaultCompanion=p.join(d,'agent-workflow.md');if(f.existsSync(defaultCompanion))candidates.push(defaultCompanion);try{const others=f.readdirSync(d).filter(n=>/^Cursor Agent-.*\\.md$/i.test(n)).sort().map(n=>p.join(d,n));for(const o of others){if(candidates.includes(o)===false)candidates.push(o)}}catch{}};let agentV='(missing)';let agentSource='(none)';for(const file of candidates){try{const c=f.readFileSync(file,'utf8');const m=c.match(/<!--\\s*workflow:VERSION:([^\\s]+)\\s*-->/i);if(m){agentV=m[1];agentSource=file;break}}catch{}};if(agentV==='(missing)'&&candidates.length>0){agentV='(missing marker)';agentSource='scanned deterministic primary agent sources';};let pluginV='(none)';try{const b=p.join(d,'plugins','cache','workflow','workflow');const v=f.readdirSync(b).filter(x=>/^\\d/.test(x)).sort((a,c)=>a.localeCompare(c,void 0,{numeric:true}));pluginV=v.length?v[v.length-1]:'(none)';}catch{};console.log('primary-agent.md workflow version:',agentV);console.log('workflow version source:',agentSource);console.log('Latest cached plugin version:',pluginV);if(agentV==='(missing)'||agentV==='(missing marker)'||pluginV==='(none)'){console.log('VERSION CHECK SKIPPED: missing Cursor Agent marker or plugin cache')}else if(agentV===pluginV){console.log('VERSION MATCH: Cursor Agent and plugin cache are aligned')}else{console.log('VERSION DRIFT: primary-agent.md and plugin versions differ')}"

# Check companion files for file-split pattern (e.g. agent-workflow.md)
find "${AGENT_CONFIG_DIR:-$HOME/.agent}" -maxdepth 1 -type f -name 'Cursor Agent-*.md' -print 2>/dev/null
while IFS= read -r f; do
  grep -q "<!-- workflow:START -->" "$f" 2>/dev/null && echo "Has workflow config in companion: $f"
done < <(find "${AGENT_CONFIG_DIR:-$HOME/.agent}" -maxdepth 1 -type f -name 'Cursor Agent-*.md' -print 2>/dev/null)

# Check if primary-agent.md references a companion file
grep -o "Cursor Agent-[^ )]*\.md" "${AGENT_CONFIG_DIR:-$HOME/.agent}/primary-agent.md" 2>/dev/null
```

**Diagnosis**:
- If primary-agent.md missing: CRITICAL - primary-agent.md not configured
- If `<!-- workflow:START -->` found in primary-agent.md: OK
- If `<!-- workflow:START -->` found in a companion file (e.g. `agent-workflow.md`): OK - file-split pattern detected
- If no workflow markers in primary-agent.md or any companion file: WARN - outdated primary-agent.md
- If `workflow:VERSION` marker is missing from deterministic Cursor Agent source scan (base + referenced companion): WARN - cannot verify primary-agent.md freshness
- If `primary-agent.md workflow version` != `Latest cached plugin version`: WARN - version drift detected (run `workflow update` or `omc setup`)

### Step 5: Check Ralph Ruby Dependency

Ralph workflows require Ruby. Check for Ruby explicitly so fresh installations get actionable guidance instead of a later opaque Ralph failure.

```bash
if command -v ruby >/dev/null 2>&1; then
  echo "Ruby for Ralph: $(ruby --version 2>/dev/null | head -1)"
else
  echo "Ruby for Ralph: MISSING"
  echo "Install Ruby before using Ralph. Ubuntu/Debian: sudo apt update && sudo apt install ruby-full"
  echo "macOS: brew install ruby"
fi
```

**Diagnosis**:
- If Ruby is found: OK - Ralph dependency present
- If Ruby is missing: WARN - Ralph workflows may fail until Ruby is installed

### Step 6: Check for Stale Plugin Cache

```bash
# Count versions in cache (cross-platform)
node -e "const p=require('path'),f=require('fs'),h=require('os').homedir(),d=process.env.AGENT_CONFIG_DIR||p.join(h,'.agent'),b=p.join(d,'plugins','cache','workflow','workflow');try{const v=f.readdirSync(b).filter(x=>/^\d/.test(x));console.log(v.length+' version(s):',v.join(', '))}catch{console.log('0 versions')}"
```

**Diagnosis**:
- If > 1 version: WARN - multiple cached versions (cleanup recommended)

### Step 7: Check for Legacy Curl-Installed Content

Check for legacy agents, commands, and skills installed via curl (before plugin system).
**Important**: Only flag files whose names match actual plugin-provided names. Do NOT flag user's custom agents/commands/skills that are unrelated to workflow.

```bash
# Check for legacy agents directory
ls -la "${AGENT_CONFIG_DIR:-$HOME/.agent}"/agents/ 2>/dev/null

# Check for legacy commands directory
ls -la "${AGENT_CONFIG_DIR:-$HOME/.agent}"/commands/ 2>/dev/null

# Check for legacy skills directory
ls -la "${AGENT_CONFIG_DIR:-$HOME/.agent}"/skills/ 2>/dev/null
```

**Diagnosis**:
- If `~/.agent/agents/` exists with files matching plugin agent names: WARN - legacy agents (now provided by plugin)
- If `~/.agent/commands/` exists with files matching plugin command names: WARN - legacy commands (now provided by plugin)
- If `~/.agent/skills/` exists with files matching plugin skill names: WARN - legacy skills (now provided by plugin)
- If custom files exist that do NOT match plugin names: OK - these are user custom content, do not flag them

**Known plugin agent names** (check agents/ for these):
`architect.md`, `document-specialist.md`, `explore.md`, `executor.md`, `debugger.md`, `planner.md`, `analyst.md`, `critic.md`, `verifier.md`, `test-engineer.md`, `designer.md`, `writer.md`, `qa-tester.md`, `scientist.md`, `security-reviewer.md`, `code-reviewer.md`, `git-master.md`, `code-simplifier.md`

**Known plugin skill names** (check skills/ for these):
`ai-slop-cleaner`, `ask`, `autopilot`, `cancel`, `ccg`, `configure-notifications`, `deep-interview`, `deepinit`, `external-context`, `hud`, `skillify`, `learner`, `mcp-setup`, `workflow-doctor`, `workflow-setup`, `omc-teams`, `plan`, `project-session-manager`, `Ralph`, `ralplan`, `release`, `science-workflow`, `setup`, `skill`, `team`, `ultraqa`, `ultrawork`, `visual-verdict`, `writer-memory`

**Known plugin command names** (check commands/ for these):
`ultrawork.md`, `deepsearch.md`

---

## Report Format

After running all checks, output a report:

```
## workflow Doctor Report

### Summary
[HEALTHY / ISSUES FOUND]

### Checks

| Check | Status | Details |
|-------|--------|---------|
| Plugin Version | OK/WARN/CRITICAL | ... |
| Legacy Hooks (settings.json) | OK/CRITICAL | ... |
| Legacy Scripts (~/.agent/hooks/) | OK/WARN | ... |
| primary-agent.md | OK/WARN/CRITICAL | ... |
| Ralph Ruby Dependency | OK/WARN | ... |
| Plugin Cache | OK/WARN | ... |
| Legacy Agents (~/.agent/agents/) | OK/WARN | ... |
| Legacy Commands (~/.agent/commands/) | OK/WARN | ... |
| Legacy Skills (~/.agent/skills/) | OK/WARN | ... |

### Issues Found
1. [Issue description]
2. [Issue description]

### Recommended Fixes
[List fixes based on issues]
```

---

## Auto-Fix (if user confirms)

If issues found, ask user: "Would you like me to fix these issues automatically?"

If yes, apply fixes:

### Fix: Legacy Hooks in settings.json
Remove the `"hooks"` section from `${AGENT_CONFIG_DIR:-~/.agent}/settings.json` (keep other settings intact)

### Fix: Legacy Bash Scripts
```bash
rm -f "${AGENT_CONFIG_DIR:-$HOME/.agent}"/hooks/keyword-detector.sh
rm -f "${AGENT_CONFIG_DIR:-$HOME/.agent}"/hooks/persistent-mode.sh
rm -f "${AGENT_CONFIG_DIR:-$HOME/.agent}"/hooks/session-start.sh
rm -f "${AGENT_CONFIG_DIR:-$HOME/.agent}"/hooks/stop-continuation.sh
```

### Fix: Outdated Plugin
```bash
# Clear plugin cache (cross-platform)
node -e "const p=require('path'),f=require('fs'),d=process.env.AGENT_CONFIG_DIR||p.join(require('os').homedir(),'.agent'),b=p.join(d,'plugins','cache','workflow','workflow');try{f.rmSync(b,{recursive:true,force:true});console.log('Plugin cache cleared. Restart Cursor to fetch latest version.')}catch{console.log('No plugin cache found')}"
```

### Fix: Stale Cache (multiple versions)
```bash
# Keep only latest version (cross-platform)
node -e "const p=require('path'),f=require('fs'),h=require('os').homedir(),d=process.env.AGENT_CONFIG_DIR||p.join(h,'.agent'),b=p.join(d,'plugins','cache','workflow','workflow');try{const v=f.readdirSync(b).filter(x=>/^\d/.test(x)).sort((a,c)=>a.localeCompare(c,void 0,{numeric:true}));v.slice(0,-1).forEach(x=>f.rmSync(p.join(b,x),{recursive:true,force:true}));console.log('Removed',v.length-1,'old version(s)')}catch(e){console.log('No cache to clean')}"
```

### Fix: Missing/Outdated primary-agent.md
Fetch latest from GitHub and write to `${AGENT_CONFIG_DIR:-~/.agent}/primary-agent.md`:
```
WebFetch(url: "https://raw.githubusercontent.com/Yeachan-Heo/workflow/main/docs/primary-agent.md", prompt: "Return the complete raw markdown content exactly as-is")
```

### Fix: Legacy Curl-Installed Content

Remove legacy agents, commands, and skills directories (now provided by plugin):

```bash
# Backup first (optional - ask user)
# mv "${AGENT_CONFIG_DIR:-$HOME/.agent}"/agents "${AGENT_CONFIG_DIR:-$HOME/.agent}"/agents.bak
# mv "${AGENT_CONFIG_DIR:-$HOME/.agent}"/commands "${AGENT_CONFIG_DIR:-$HOME/.agent}"/commands.bak
# mv "${AGENT_CONFIG_DIR:-$HOME/.agent}"/skills "${AGENT_CONFIG_DIR:-$HOME/.agent}"/skills.bak

# Or remove directly
rm -rf "${AGENT_CONFIG_DIR:-$HOME/.agent}"/agents
rm -rf "${AGENT_CONFIG_DIR:-$HOME/.agent}"/commands
rm -rf "${AGENT_CONFIG_DIR:-$HOME/.agent}"/skills
```

**Note**: Only remove if these contain workflow-related files. If user has custom agents/commands/skills, warn them and ask before removing.

---

## Post-Fix

After applying fixes, inform user:
> Fixes applied. **Restart Cursor** for changes to take effect.
