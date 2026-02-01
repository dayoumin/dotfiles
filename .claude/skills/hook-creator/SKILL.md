---
name: hook-creator
description: Create and configure Claude Code hooks for customizing agent behavior. Use when the user wants to (1) create a new hook, (2) configure automatic formatting, logging, or notifications, (3) add file protection or custom permissions, (4) set up pre/post tool execution actions, or (5) asks about hook events like PreToolUse, PostToolUse, Notification, etc.
version: 1.0.0
claude_code_version: 2.1.27
last_updated: 2025-02-01
---

# Hook Creator

Create Claude Code hooks that execute shell commands at specific lifecycle events.

## Hook Creation Workflow

1. **Identify the use case** - Determine what the hook should accomplish
2. **Select the appropriate event** - Choose from available hook events (see references/hook-events.md)
3. **Design the hook command** - Write shell command that processes JSON input from stdin
4. **Configure the matcher** - Set tool/event filter (use `*` for all, or specific tool names like `Bash`, `Edit|Write`)
5. **Choose storage location** - User settings (`~/.claude/settings.json`) or project (`.claude/settings.json`)
6. **Test the hook** - Verify behavior with a simple test case

## Hook Configuration Structure

```json
{
  "hooks": {
    "<EventName>": [
      {
        "matcher": "<ToolPattern>",
        "hooks": [
          {
            "type": "command",
            "command": "<shell-command>"
          }
        ]
      }
    ]
  }
}
```

## Common Patterns

### Reading Input Data

Hooks receive JSON via stdin (NOT as placeholder variables). Use `jq` to extract fields:

```bash
# Extract tool input field
jq -r '.tool_input.file_path'

# Extract with fallback
jq -r '.tool_input.description // "No description"'

# Conditional processing
jq -r 'if .tool_input.file_path then .tool_input.file_path else empty end'
```

**IMPORTANT**: Do NOT use `$TOOL_INPUT` or `$TOOL_OUTPUT` as shell variables. The entire JSON is piped to stdin. Use pipes:

```bash
# ✅ Correct
command: "jq -r '.tool_input' | ./scripts/process.sh"

# ❌ Incorrect (legacy/deprecated)
command: "./scripts/process.sh $TOOL_INPUT"
```

### Exit Codes for PreToolUse

- `0` - Allow the tool to proceed
- `2` - Block the tool and provide feedback to Claude

### Matcher Patterns

- `*` - Match all tools
- `Bash` - Match only Bash tool
- `Edit|Write` - Match Edit or Write tools
- `Read` - Match Read tool

## Quick Examples

**Log all bash commands:**
```bash
jq -r '"\(.tool_input.command)"' >> ~/.claude/bash-log.txt
```

**Auto-format TypeScript after edit:**
```bash
jq -r '.tool_input.file_path' | { read f; [[ "$f" == *.ts ]] && npx prettier --write "$f"; }
```

**Block edits to .env files:**
```bash
python3 -c "import json,sys; p=json.load(sys.stdin).get('tool_input',{}).get('file_path',''); sys.exit(2 if '.env' in p else 0)"
```

## Skill Hooks vs Global Hooks

Hooks can be configured in two scopes:

### Global Hooks (settings.json)

Configured in `~/.claude/settings.json` or `.claude/settings.json`:

- **Scope**: Active for all Claude Code sessions
- **Lifecycle**: Persistent until manually removed
- **Use cases**: User-wide preferences, project-wide enforcement

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "echo 'Global hook'"}]
      }
    ]
  }
}
```

### Skill Hooks (SKILL.md frontmatter)

Configured in SKILL.md YAML frontmatter:

- **Scope**: Active only when Skill is executing
- **Lifecycle**: Automatically cleaned up when Skill finishes
- **Use cases**: Skill-specific validation, quality control, agent orchestration

```yaml
---
name: my-skill
description: Example skill with hooks
hooks:
  PreToolUse:
    - matcher: "Edit"
      hooks:
        - type: command
          command: "./scripts/validate.sh"  # Simple script (no JSON processing)
---
```

### Subagent Hooks (.claude/agents/)

Configured in subagent `.md` files:

- **Scope**: Active only when that specific subagent is executing
- **Lifecycle**: Automatically cleaned up when subagent finishes
- **Use cases**: Agent-specific validation, logging, quality control

```yaml
---
name: code-reviewer
description: Reviews code quality
hooks:
  PostToolUse:
    - matcher: "Read"
      hooks:
        - type: command
          command: "./scripts/track-files.sh"  # Simple logging script
---
```

## Using Hooks in Skills

To add hooks to a Skill, include them in the YAML frontmatter:

```yaml
---
name: quiz-workflow
description: Create Korean learning quizzes with 3-agent validation
hooks:
  PreToolUse:
    - matcher: "Task"
      hooks:
        - type: command
          command: "jq -r '.tool_input' | ./scripts/check-agent-order.sh"
          once: true
  PostToolUse:
    - matcher: "mcp__supabase-mcp__execute_sql"
      hooks:
        - type: command
          command: "jq -r '.tool_output' | ./scripts/validate-db-insert.sh"
  Stop:
    - matcher: "*"
      hooks:
        - type: command
          command: "./scripts/generate-quality-report.sh"
---
```

**Note**: The `once: true` field is supported for Skills and Slash commands, but NOT for Agents.

### Sequential Agent Execution Example

When running multiple agents in sequence (e.g., creator → validator → reviewer), use hooks to enforce order:

**Skill structure:**
```
quiz-workflow/
├── SKILL.md (with hooks configuration)
└── scripts/
    ├── check-agent-order.sh
    └── mark-checkpoint.sh
```

**Hook configuration in SKILL.md:**
```yaml
hooks:
  PreToolUse:
    - matcher: "Task"
      hooks:
        - type: command
          command: "jq -r '.tool_input' | ./scripts/check-agent-order.sh"
  PostToolUse:
    - matcher: "Task"
      hooks:
        - type: command
          command: "jq -r '.tool_output' | ./scripts/mark-checkpoint.sh"
```

**scripts/check-agent-order.sh:**
```bash
#!/bin/bash
# Parse JSON directly from stdin (already filtered by jq in hook command)
agent=$(jq -r '.subagent_type // empty')

# Check prerequisites
case "$agent" in
  "quiz-validator")
    [[ -f /tmp/quiz-creator.done ]] || exit 2  # Block if creator not done
    ;;
  "quiz-reviewer")
    [[ -f /tmp/quiz-validator.done ]] || exit 2  # Block if validator not done
    ;;
esac
exit 0
```

**scripts/mark-checkpoint.sh:**
```bash
#!/bin/bash
# Parse JSON directly from stdin (already filtered by jq in hook command)
agent=$(jq -r '.subagent_type // empty')
touch "/tmp/${agent}.done"
```

This pattern ensures Agent 2 cannot start before Agent 1 completes.

## Resources

- **Hook Events Reference**: See `references/hook-events.md` for detailed event documentation with input/output schemas
- **Example Configurations**: See `references/examples.md` for complete, tested hook configurations
