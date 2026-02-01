---
name: subagent-creator
description: Create specialized Claude Code sub-agents with custom system prompts and tool configurations. Use when users ask to create a new sub-agent, custom agent, specialized assistant, or want to configure task-specific AI workflows for Claude Code.
---

# Sub-agent Creator

Create specialized AI sub-agents for Claude Code that handle specific tasks with customized prompts and tool access.

## Sub-agent File Format

Sub-agents are Markdown files with YAML frontmatter stored in:
- **Project**: `.claude/agents/` (higher priority)
- **User**: `~/.claude/agents/` (lower priority)

### Structure

```markdown
---
name: subagent-name
description: When to use this subagent (include "use proactively" for auto-delegation)
tools: Tool1, Tool2, Tool3  # Optional - inherits all if omitted
model: sonnet               # Optional - sonnet/opus/haiku/inherit
permissionMode: default     # Optional - default/acceptEdits/bypassPermissions/plan
skills: skill1, skill2      # Optional - auto-load skills
hooks:                      # Optional - lifecycle hooks (PreToolUse, PostToolUse, Stop only)
  PreToolUse:
    - matcher: "Edit"
      hooks:
        - type: command
          command: "jq -r '.tool_input' | ./scripts/validate.sh"
---

System prompt goes here. Define role, responsibilities, and behavior.
```

### Configuration Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Lowercase with hyphens |
| `description` | Yes | Purpose and when to use (key for auto-delegation) |
| `tools` | No | Comma-separated tool list (omit to inherit all) |
| `model` | No | `sonnet`, `opus`, `haiku`, or `inherit` |
| `permissionMode` | No | `default`, `acceptEdits`, `bypassPermissions`, `plan` |
| `skills` | No | Skills to auto-load |
| `hooks` | No | Lifecycle hooks (PreToolUse, PostToolUse, Stop) |

## Creation Workflow

1. **Gather requirements**: Ask about the sub-agent's purpose, when to use it, and required capabilities
2. **Choose scope**: Project (`.claude/agents/`) or user (`~/.claude/agents/`)
3. **Define configuration**: Name, description, tools, model
4. **Write system prompt**: Clear role, responsibilities, and output format
5. **Create file**: Write the `.md` file to the appropriate location

## Writing Effective Sub-agents

### Description Best Practices

The `description` field is critical for automatic delegation:

```yaml
# Good - specific triggers
description: Expert code reviewer. Use PROACTIVELY after writing or modifying code.

# Good - clear use cases
description: Debugging specialist for errors, test failures, and unexpected behavior.

# Bad - too vague
description: Helps with code
```

### System Prompt Guidelines

1. **Define role clearly**: "You are a [specific expert role]"
2. **List actions on invocation**: What to do first
3. **Specify responsibilities**: What the sub-agent handles
4. **Include guidelines**: Constraints and best practices
5. **Define output format**: How to structure responses

### Tool Selection

- **Read-only tasks**: `Read, Grep, Glob, Bash`
- **Code modification**: `Read, Write, Edit, Grep, Glob, Bash`
- **Full access**: Omit `tools` field

See [references/available-tools.md](references/available-tools.md) for complete tool list.

## Example Sub-agents

See [references/examples.md](references/examples.md) for complete examples:
- Code Reviewer
- Debugger
- Data Scientist
- Test Runner
- Documentation Writer
- Security Auditor

## Agent Hooks

Sub-agents can include lifecycle hooks that execute automatically during agent execution. These hooks are scoped to the agent's lifecycle and are automatically cleaned up when the agent finishes.

### When to Use Agent Hooks

1. **Validation**: Verify inputs before tools execute (e.g., lint code before Edit)
2. **Quality control**: Auto-format files after editing
3. **Logging**: Track agent's tool usage for debugging
4. **Security**: Block dangerous operations for this specific agent
5. **Post-processing**: Generate reports or cleanup after agent completes

### Hook Configuration

Add hooks to the agent's frontmatter:

```yaml
---
name: code-reviewer
description: Reviews code for quality and security. Use proactively after code changes.
tools: Read, Grep, Glob, Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "jq -r '.tool_input' | ./scripts/check-safe-command.sh"
  PostToolUse:
    - matcher: "Read"
      hooks:
        - type: command
          command: "jq -r '.tool_output' | ./scripts/log-reviewed-file.sh"
  Stop:
    - matcher: "*"
      hooks:
        - type: command
          command: "./scripts/generate-review-report.sh"
---
```

### Supported Hook Events

- **PreToolUse**: Runs before tool calls (can block with exit code 2)
- **PostToolUse**: Runs after tool calls complete
- **Stop**: Runs when agent finishes responding

### Key Characteristics

- Hooks are **scoped to agent lifecycle** - only active when this agent is executing
- Hooks are **automatically cleaned up** when agent finishes
- Scripts use **relative paths from agent `.md` file location** (e.g., `./scripts/validate.sh` relative to `.claude/agents/my-agent.md`)
- JSON input is **piped to stdin** - use `jq` to parse (e.g., `jq -r '.tool_input.file_path'`)
- **`once: true` is NOT supported** for Agent hooks (only for Skills and Slash commands)
- Exit code 2 in PreToolUse blocks the tool

### Example: Auto-formatting Agent

```yaml
---
name: code-formatter
description: Format code files automatically
tools: Read, Edit, Bash
hooks:
  PostToolUse:
    - matcher: "Edit"
      hooks:
        - type: command
          command: "jq -r '.tool_input.file_path' | xargs npx prettier --write"
---

You are a code formatting specialist.

When invoked:
1. Read the target files
2. Apply formatting rules
3. Edit files with proper formatting

The PostToolUse hook will automatically run prettier after each edit. The hook receives JSON via stdin and uses `jq` to extract the file path.
```

## Template

Copy from [assets/subagent-template.md](assets/subagent-template.md) to start a new sub-agent.

## Quick Start Example

Create a code reviewer sub-agent:

```bash
mkdir -p .claude/agents
```

### Basic Version (without hooks)

Write to `.claude/agents/code-reviewer.md`:

```markdown
---
name: code-reviewer
description: Reviews code for quality and security. Use proactively after code changes.
tools: Read, Grep, Glob, Bash
model: inherit
---

You are a senior code reviewer.

When invoked:
1. Run git diff to see changes
2. Review modified files
3. Report issues by priority

Focus on:
- Code readability
- Security vulnerabilities
- Error handling
- Best practices
```

### Advanced Version (with hooks)

For automatic validation and reporting, add hooks:

```markdown
---
name: code-reviewer
description: Reviews code for quality and security. Use proactively after code changes.
tools: Read, Grep, Glob, Bash
model: inherit
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "jq -r '.tool_input.command' | grep -q 'rm -rf' && exit 2 || exit 0"
  Stop:
    - matcher: "*"
      hooks:
        - type: command
          command: "echo 'Code review completed' >> ~/.claude/review-log.txt"
---

You are a senior code reviewer.

When invoked:
1. Run git diff to see changes
2. Review modified files
3. Report issues by priority

Focus on:
- Code readability
- Security vulnerabilities
- Error handling
- Best practices

The PreToolUse hook blocks dangerous bash commands, and the Stop hook logs completion.
```
