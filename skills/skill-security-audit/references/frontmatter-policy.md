# Frontmatter Policy — `allowed-tools` Risk Matrix

Risk classification for `allowed-tools` declarations in SKILL.md frontmatter. Used during Phase 1 (Permissions Analysis) to assess whether a skill requests appropriate permissions.

---

## Tool Risk Classifications

### Individual Tools

| Tool | Risk Level | Rationale |
|------|-----------|-----------|
| `Read` | LOW | Read-only file access |
| `Grep` | LOW | Content search, read-only |
| `Glob` | LOW | File pattern matching, read-only |
| `WebSearch` | LOW | Web search, read-only |
| `Edit` | MEDIUM | Can modify existing files |
| `Write` | MEDIUM | Can create/overwrite files |
| `NotebookEdit` | MEDIUM | Can modify Jupyter notebooks |
| `WebFetch` | MEDIUM | Can access external URLs, potential for data exfiltration |
| `Bash` | HIGH | Arbitrary command execution |
| `Task` | MEDIUM | Can spawn sub-agents (inherits parent permissions) |
| `mcp__*` | VARIES | MCP tools — risk depends on specific server capabilities |

### Dangerous Combinations

| Combination | Risk | Attack Chain |
|-------------|------|-------------|
| `Bash` + `WebFetch` | CRITICAL | Execute arbitrary commands + exfiltrate data to external server |
| `Bash` + `Write` | CRITICAL | Execute arbitrary commands + persist changes (backdoor installation) |
| `Bash` + `Write` + `WebFetch` | CRITICAL | Full attack chain: download, execute, persist, exfiltrate |
| `Write` + `WebFetch` | HIGH | Download malicious content + write to disk |
| `Bash` + `Read` | HIGH | Execute commands + read sensitive files for exfiltration |
| `Edit` + `Bash` | HIGH | Modify files + execute (e.g., modify then run a script) |
| `Write` + `Glob` | MEDIUM | Discover files + overwrite them |

---

## Expected Tools by Skill Purpose

Reference for what tools a skill *should* need based on its stated purpose.

| Skill Type | Expected Tools | Suspicious If Also Requests |
|------------|----------------|---------------------------|
| **Code review / linting** | `Read`, `Grep`, `Glob` | `Bash`, `Write`, `WebFetch` |
| **Documentation generator** | `Read`, `Grep`, `Glob`, `Write` | `Bash`, `WebFetch` |
| **Text editor / formatter** | `Read`, `Write`, `Edit` | `Bash`, `WebFetch` |
| **Static analysis** | `Read`, `Grep`, `Glob`, `Bash` | `WebFetch`, `Write` (unless writing reports) |
| **Build / CI tool** | `Read`, `Bash`, `Glob` | `WebFetch` (unless downloading dependencies) |
| **Testing framework** | `Read`, `Bash`, `Glob`, `Grep` | `WebFetch`, `Write` (unless writing test files) |
| **Security scanner** | `Read`, `Grep`, `Glob`, `Bash`, `Task` | `Write` (unless writing reports), `WebFetch` |
| **Deployment tool** | `Read`, `Bash`, `Glob` | — (broad access may be expected) |
| **Research / exploration** | `Read`, `Grep`, `Glob`, `WebSearch`, `WebFetch` | `Bash`, `Write` |
| **Refactoring tool** | `Read`, `Write`, `Edit`, `Grep`, `Glob` | `Bash`, `WebFetch` |
| **Brainstorming / planning** | `Read`, `Grep`, `Glob` (or none) | `Bash`, `Write`, `WebFetch` |

---

## Assessment Procedure

### Step 1: List all `allowed-tools`

Extract the `allowed-tools` array from each SKILL.md's YAML frontmatter.

### Step 2: Classify individual tool risk

Rate each tool per the Individual Tools table above.

### Step 3: Check for dangerous combinations

Cross-reference against the Dangerous Combinations table.

### Step 4: Compare against expected tools

Based on the skill's stated `description` and `name`, identify the expected skill type and compare actual vs. expected tools.

### Step 5: Flag discrepancies

- **Expected tool missing:** Note as INFO (skill may be intentionally limited)
- **Unexpected low-risk tool:** Note as INFO
- **Unexpected medium-risk tool:** Note as MEDIUM finding
- **Unexpected high-risk tool:** Note as HIGH finding
- **Dangerous combination present:** Note as HIGH or CRITICAL finding depending on combination

### Step 6: Check for undeclared tool usage

Scan the skill's content for instructions that imply tools not listed in `allowed-tools`:
- References to running shell commands without `Bash` in allowed-tools
- References to writing files without `Write`/`Edit` in allowed-tools
- References to fetching URLs without `WebFetch` in allowed-tools

Undeclared tool usage indicates either:
- The skill relies on the user approving tool calls at runtime (MEDIUM risk — circumvents the permission model's intent)
- The skill expects to inherit permissions from a parent context (review the parent)

---

## Special Cases

### No `allowed-tools` declared

If a SKILL.md has no `allowed-tools` in its frontmatter, the skill relies entirely on Claude's default permissions or the user's permission settings. This is:
- **LOW risk** if the skill is purely instructional (no tool usage implied)
- **MEDIUM risk** if the skill references tool usage without declaring them
- **INFO** — note that the skill has no explicit permission boundary

### MCP Tools (`mcp__*`)

MCP tools connect to external servers and have capabilities that vary by implementation. Any MCP tool should be:
- Flagged as **MEDIUM** minimum risk
- Investigated for what the specific MCP server does
- Flagged as **HIGH** if the MCP server has write/execute/network capabilities

### `Task` Tool

The `Task` tool spawns sub-agents. Risk depends on:
- Whether the sub-agent inherits the skill's allowed-tools
- Whether the skill specifies what the sub-agent should do
- Flag as **MEDIUM** — sub-agents can perform actions the skill itself could
