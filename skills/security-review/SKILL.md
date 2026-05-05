---
name: security-review
description: Use when reviewing, auditing, or assessing the security posture of a codebase or repository — vulnerability scanning, SAST triage, dependency CVE review, secrets detection.
allowed-tools:
  - Agent
  - Bash
  - Read
  - Grep
  - Glob
  - TeamCreate
  - TeamDelete
  - SendMessage
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
---

# Security Review Agent Team

## Overview

Create an agent team to conduct a phased security review: project analysis, deterministic tool scanning, parallel expert triage, report writing, and consensus-driven round table. Produces a markdown report with confirmed findings, severity ratings, and an appendix of uncertain items.

## When to Use

- User asks to conduct a security review, security audit, or security assessment of a codebase
- User wants to run security tools and have results triaged by experts
- User wants a structured security report with findings

## When NOT to Use

- One-off tool runs without triage ("just run semgrep")
- Reviewing a single file or PR for security issues
- Compliance audits requiring specific frameworks (SOC2, PCI-DSS)

## Prerequisites

The following tools must be installed on the host machine:
- **semgrep** — static analysis
- **trufflehog** — secrets detection
- **trivy** — dependency vulnerability scanning

## Configuration Options

The team lead can enable optional analysis modes when the user requests them:

- **Semgrep Pro engine** (`SEMGREP_PRO`, default `false`) — when the user requests it (e.g., "use semgrep pro", "enable pro engine"), pass `SEMGREP_PRO=true` to the tool-runner. Adds `--pro` to the semgrep invocation, enabling interfile/interprocedural taint analysis and Pro languages (Apex, C#, Elixir). Requires the host to have run `semgrep login` and `semgrep install-semgrep-pro` previously; if missing, semgrep will fail with a clear error and the tool-runner will surface it via `tool-runner-errors.md` rather than silently falling back.

## Output Directory

All artifacts are written to `security-review/` in the project root:

```
security-review/
├── raw/                              # Phase 1
│   ├── project-overview.md           # Architecture briefing
│   ├── semgrep-results.json          # Raw semgrep output (JSON)
│   ├── trufflehog-fs.jsonl           # Raw trufflehog filesystem scan (JSON Lines)
│   ├── trufflehog-git.jsonl          # Raw trufflehog git history scan (JSON Lines)
│   ├── trivy-results.json            # Raw trivy output (JSON)
│   └── tool-runner-errors.md         # (optional) tool failures, if any
├── triage/                           # Phase 2
│   ├── sast-triage.md                # SAST true/false positive analysis
│   ├── dependency-triage.md          # Exploitable dependency analysis
│   ├── targeted-expert.md            # High-risk area findings
│   └── broad-expert.md              # General security findings
├── roundtable/                       # Phase 4
│   ├── discussion-prompt.md
│   ├── *-feedback.md                 # Per-agent feedback
│   └── round-N-prompt.md            # Subsequent debate prompts
├── report-draft.md                   # Phase 3
└── report-final.md                   # Phase 4 final output
```

## Execution Flow

1. **Phase 1a** — `project-analyst` writes briefing
2. **Phase 1b** — `tool-runner` runs scanners (depends on 1a)
3. **Phase 2 (parallel, depend on 1b):**
   - `sast-triage`
   - `dep-triage`
   - `targeted-expert`
   - `broad-expert`
4. **Phase 3** — `report-writer` compiles draft (depends on all of Phase 2)
5. **Phase 4** — `roundtable-moderator` (depends on Phase 3) re-engages the four Phase 2 agents for consensus debate, then writes the final report

**Key:** Phase 2 agents are persistent team members. They do their triage work, go idle, then pick up round-table feedback tasks the moderator creates — same agents, full triage context preserved.

## Orchestration Steps

You are the **team lead**. You create the team, spawn members, create tasks with dependencies, and monitor progress.

### Step 1: Setup

First, verify required tools are installed. If any are missing, stop and ask the user to install them before proceeding:

```bash
for tool in semgrep trufflehog trivy; do
  command -v "$tool" >/dev/null || { echo "missing: $tool"; missing=1; }
done
[ -z "$missing" ] || exit 1
mkdir -p {PROJECT_ROOT}/security-review/raw {PROJECT_ROOT}/security-review/triage {PROJECT_ROOT}/security-review/roundtable
```

Determine `{PROJECT_NAME}` (the display name used in the team description and report title) — usually the repo directory name unless the user specifies otherwise.

Then create the team:
```
TeamCreate: team_name="security-review", description="Repo security review of {PROJECT_NAME}"
```

### Step 2: Create All Tasks Upfront

Create tasks with dependency chains so agents can self-coordinate. Use `agent-prompts.md` for the detailed prompt content — pass the relevant section as the agent's initial prompt when spawning.

| Task | Subject | blockedBy |
|------|---------|-----------|
| T1 | Phase 1a: Analyze project and write overview | — |
| T2 | Phase 1b: Run security tools and save output | T1 |
| T3 | Phase 2: Triage SAST findings | T2 |
| T4 | Phase 2: Triage dependency findings | T2 |
| T5 | Phase 2: Targeted security expert review | T2 |
| T6 | Phase 2: Broad security expert review | T2 |
| T7 | Phase 3: Write draft report | T3, T4, T5, T6 |
| T8 | Phase 4: Moderate round table | T7 |

**Do not create round table feedback tasks yet.** The moderator will create those in Phase 4 after writing the discussion prompt.

### Step 3: Spawn Team Members and Assign Phase 1

Spawn agents using the Agent tool with `team_name="security-review"`. Use prompts from `agent-prompts.md`.

**Phase 1 (sequential):**
1. Spawn `project-analyst` — assign T1
2. When T1 completes, spawn `tool-runner` — assign T2

**Phase 2 (parallel — spawn all four after T2 completes):**
3. Spawn `sast-triage` — assign T3
4. Spawn `dep-triage` — assign T4
5. Spawn `targeted-expert` — assign T5
6. Spawn `broad-expert` — assign T6

**Phase 3 (after all Phase 2 tasks complete):**
7. Spawn `report-writer` — assign T7

**Phase 4:**
8. Spawn `roundtable-moderator` — assign T8

### Step 4: Phase 4 — Round Table Coordination

The round table uses the team's task system for multi-agent debate:

1. **Moderator decides whether a round table is needed** — if the draft has no severity disagreements, no uncertain findings, and every confirmed finding has ≥2 analyst sources, the round table is skipped. Moderator writes `roundtable/skipped.md`, copies the draft to `report-final.md` with a brief note, and the phase ends.
2. **Otherwise, moderator writes discussion prompt** → `security-review/roundtable/discussion-prompt.md` containing only questions and file pointers — does NOT embed the draft (each agent reads the canonical draft directly to avoid 4× duplication).
3. **Moderator creates feedback tasks** for each Phase 2 agent (sast-triage, dep-triage, targeted-expert, broad-expert), blocked by T8.
4. **Phase 2 agents wake up**, read the discussion prompt + draft, write feedback to their file in `security-review/roundtable/`
5. **Moderator reads feedback**, identifies conflicts
6. If conflicts exist, moderator creates rebuttal tasks for the conflicting agents
7. Repeat until consensus or documented dissent — capped at 3 rounds total to prevent infinite loops
8. Moderator writes `security-review/report-final.md`

### Step 5: Cleanup

After `report-final.md` is written:
1. Send shutdown messages to all team members
2. Call TeamDelete to clean up team resources
3. Notify user that the report is ready at `{PROJECT_ROOT}/security-review/report-final.md`

## Key Principles

### Persistent Team Members Over Subagents

Phase 2 agents stay alive as idle team members after their triage work. When the moderator creates round table feedback tasks, the same agents pick them up with their full analysis context intact.

### Context Window Pressure (Fallback)

If a Phase 2 agent's context is too full to take on round table feedback:
1. Spawn a replacement agent with the same name
2. Have it read its predecessor's triage output file plus the discussion prompt
3. This preserves key findings without the full exploration transcript
4. This is a fallback, not the default — persistent agents with full context are preferred

### Consensus-Driven Round Table

- Agents challenge each other's findings, debate severity ratings
- Must reach agreement before the report is finalized
- For items that cannot reach consensus, dissent is documented in the finding
- The moderator drives resolution, does not override agents

### Finding Deduplication

- Multiple instances of the same vulnerability class are one finding with all locations listed
- If two agents independently found the same issue, merge into one finding
- Confirmed findings get full write-ups with suggested remediation
- Uncertain findings go to "Needs Further Investigation" appendix

## Scope Customization

Default behavior is full-repository review. When the user limits scope (e.g., "only the API layer", "skip vendored code"):

1. Add the scope directive to the `project-analyst` prompt as an additional context line — it will be reflected in `project-overview.md` and inherited by all downstream agents.
2. Pass scope-narrowing flags to `tool-runner`:
   - **semgrep:** scan specific subpaths instead of `{PROJECT_ROOT}`, or use `--exclude` for vendored directories
   - **trivy:** use `--skip-dirs` for irrelevant paths
   - **trufflehog:** point `filesystem` at specific subpaths
3. Phase 2 agents pick up the scope automatically by reading `project-overview.md`.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Spawning new agents for round table | Phase 2 agents are persistent — assign them feedback tasks |
| Creating all tasks including round table upfront | Moderator creates feedback tasks dynamically after writing discussion prompt |
| Running Phase 2 before tool output exists | Task dependencies (blockedBy) handle gating automatically |
| Letting agents explore the codebase themselves | All agents read `project-overview.md` first |
| Skipping round table for small finding count | Always run round table — even 2 findings benefit from cross-review |
| Forgetting to shut down team members | Send shutdown messages and call TeamDelete when done |
