---
name: external-context
description: 'Invoke parallel document-specialist agents for external web searches and documentation lookup'
metadata:
  argument-hint: '<search query or topic>'
---

# External Context Skill

## Cursor Compatibility

This skill is formatted for Cursor Agent Skills. Use Cursor's available tools for file edits, shell commands, search, web access, user questions, and any supported delegation. Treat legacy provider, agent, or workflow-tool examples as workflow guidance; if a named tool is unavailable in Cursor, perform the step with available Cursor capabilities or ask the user before substituting behavior.

Fetch external documentation, references, and context for a query. Decomposes into 2-5 facets and spawns parallel document-specialist Cursor Agent agents.

## Usage

```
/external-context <topic or question>
```

### Examples

```
/external-context What are the best practices for JWT token rotation in Node.js?
/external-context Compare Prisma vs Drizzle ORM for PostgreSQL
/external-context Latest React Server Components patterns and conventions
```

## Protocol

### Step 1: Facet Decomposition

Given a query, decompose into 2-5 independent search facets:

```markdown
## Search Decomposition

**Query:** <original query>

### Facet 1: <facet-name>
- **Search focus:** What to search for
- **Sources:** Official docs, GitHub, blogs, etc.

### Facet 2: <facet-name>
...
```

### Step 2: Parallel Agent Invocation

Fire independent facets in parallel via Task tool:

```
Delegate(role="document-specialist", tier="sonnet", prompt="Search for: <facet 1 description>. Use WebSearch and WebFetch to find official documentation and examples. Cite all sources with URLs.")

Delegate(role="document-specialist", tier="sonnet", prompt="Search for: <facet 2 description>. Use WebSearch and WebFetch to find official documentation and examples. Cite all sources with URLs.")
```

Maximum 5 parallel document-specialist agents.

### Step 3: Synthesis Output Format

Present synthesized results in this format:

```markdown
## External Context: <query>

### Key Findings
1. **<finding>** - Source: [title](url)
2. **<finding>** - Source: [title](url)

### Detailed Results

#### Facet 1: <name>
<aggregated findings with citations>

#### Facet 2: <name>
<aggregated findings with citations>

### Sources
- [Source 1](url)
- [Source 2](url)
```

## Configuration

- Maximum 5 parallel document-specialist agents
- No magic keyword trigger - explicit invocation only
