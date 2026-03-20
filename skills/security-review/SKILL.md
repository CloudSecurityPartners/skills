---
name: security-review
description: Use when conducting a security review of a codebase using an agent team with deterministic tools and expert analysis. Triggers on requests to review, audit, or assess security posture of a repository.
allowed-tools:
  - Agent
  - Bash
  - Read
  - Grep
  - Glob
  - Task
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

## Output Directory

All artifacts are written to `security-review/` in the project root:

```
security-review/
├── raw/                              # Phase 1
│   ├── project-overview.md           # Architecture briefing
│   ├── semgrep-results.json          # Raw semgrep output
│   ├── trufflehog-results.json       # Raw trufflehog output
│   └── trivy-results.json            # Raw trivy output
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

```
Phase 1a:  [Project Analyst]
                |
Phase 1b:  [Tool Runner]
                |
           ┌────┼────────────┬──────────────┐
Phase 2:   [SAST   ] [Dep     ] [Targeted ] [Broad    ]
           [Triage ] [Triage  ] [Expert   ] [Expert   ]
           └────┬────────────┴──────────────┘
                |
Phase 3:   [Report Writer]
                |
Phase 4:   [Round Table Moderator]
           ┌────┼────────────┬──────────────┐
           [SAST   ] [Dep     ] [Targeted ] [Broad    ]
           [Triage ] [Triage  ] [Expert   ] [Expert   ]
           └────┬────────────┴──────────────┘
                |
           [Moderator finalizes report]
```

**Key:** Phase 2 agents are persistent team members. They do their triage work, go idle, then participate in the round table when the moderator creates feedback tasks.

## Orchestration Steps

You are the **team lead**. You create the team, spawn members, create tasks with dependencies, and monitor progress.

### Step 1: Setup

```bash
mkdir -p security-review/raw security-review/triage security-review/roundtable
```

Then create the team:
```
TeamCreate: team_name="security-review", description="Security review of [project name]"
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

1. **Moderator writes discussion prompt** → `security-review/roundtable/discussion-prompt.md`
2. **Moderator creates feedback tasks** for each Phase 2 agent:
   - "Review draft report and write feedback" (assigned to sast-triage, dep-triage, targeted-expert, broad-expert)
   - These tasks are blocked by T8
3. **Phase 2 agents wake up**, read the discussion prompt, write feedback to their file in `security-review/roundtable/`
4. **Moderator reads feedback**, identifies conflicts
5. If conflicts exist, moderator creates rebuttal tasks for the conflicting agents
6. Repeat until consensus or documented dissent
7. Moderator writes `security-review/report-final.md`

### Step 5: Cleanup

After `report-final.md` is written:
1. Send shutdown messages to all team members
2. Call TeamDelete to clean up team resources
3. Notify user that the report is ready at `security-review/report-final.md`

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

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Spawning new agents for round table | Phase 2 agents are persistent — assign them feedback tasks |
| Creating all tasks including round table upfront | Moderator creates feedback tasks dynamically after writing discussion prompt |
| Running Phase 2 before tool output exists | Task dependencies (blockedBy) handle gating automatically |
| Letting agents explore the codebase themselves | All agents read `project-overview.md` first |
| Skipping round table for small finding count | Always run round table — even 2 findings benefit from cross-review |
| Forgetting to shut down team members | Send shutdown messages and call TeamDelete when done |
