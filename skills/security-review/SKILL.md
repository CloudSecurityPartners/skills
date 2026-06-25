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

Create an agent team to conduct a phased security review: project analysis, deterministic tool scanning, parallel expert triage, dynamic validation against a running instance, report writing, and consensus-driven round table. Produces a markdown report with confirmed findings, severity ratings, a **validation status** for every finding (dynamically validated vs. code-only), and an appendix of uncertain items.

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
- **curl** — exercising the running application during dynamic validation

For the dynamic validation phase, the host should also be able to boot the application (e.g., **docker** / **docker compose**, or the project's native runtime — Ruby, Node, Python, etc.). Dynamic validation is best-effort: if the app cannot be booted, the review still completes and all findings are reported as **Code-Only**.

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
├── validation/                       # Phase 2.5
│   ├── app-setup.md                  # How the app was booted (or why it couldn't be)
│   ├── dynamic-validation.md         # Per-finding validation status + evidence
│   └── evidence/                     # Saved requests/responses, repro scripts, logs
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
Phase 2.5: [Dynamic Validator]   (boots app, reproduces findings)
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
mkdir -p security-review/raw security-review/triage security-review/validation/evidence security-review/roundtable
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
| T7 | Phase 2.5: Set up app locally and dynamically validate findings | T3, T4, T5, T6 |
| T8 | Phase 3: Write draft report | T7 |
| T9 | Phase 4: Moderate round table | T8 |

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

**Phase 2.5 (after all Phase 2 tasks complete):**
7. Spawn `dynamic-validator` — assign T7

**Phase 3 (after T7 completes):**
8. Spawn `report-writer` — assign T8

**Phase 4:**
9. Spawn `roundtable-moderator` — assign T9

### Step 4: Phase 4 — Round Table Coordination

The round table uses the team's task system for multi-agent debate:

1. **Moderator writes discussion prompt** → `security-review/roundtable/discussion-prompt.md`
2. **Moderator creates feedback tasks** for each Phase 2 agent:
   - "Review draft report and write feedback" (assigned to sast-triage, dep-triage, targeted-expert, broad-expert)
   - These tasks are blocked by T9
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

### Dynamic Validation Status

Every finding in the final report carries a **Validation Status** so readers know how strong the evidence is:

- **Dynamically Validated** — reproduced against a running instance of the app. Evidence (request/response, repro script, or log excerpt) is saved under `security-review/validation/evidence/` and referenced in the finding.
- **Code-Only** — confirmed by source-code analysis but not exercised against a running app (either the app couldn't be booted, the path wasn't reachable in the test environment, or dynamic testing was out of scope for that finding).
- **Validation Inconclusive** — a dynamic test was attempted but neither confirmed nor refuted the finding (e.g., the endpoint required state the validator couldn't reach). Stays a finding, flagged for the round table.
- **Refuted by Validation** — the dynamic test showed the issue is NOT exploitable as described. The validator documents this; the round table decides whether to downgrade, reclassify as a false positive, or keep with caveats.

Dynamic validation never *creates* findings on its own and never silently drops a code-confirmed finding — it only annotates and provides evidence. A static-only finding is still a real finding.

### Best-Effort App Setup

The validator auto-detects how to run the app (docker-compose, Dockerfile, README, Makefile, language-native commands), proposes a command, and confirms with the user before booting. If the app cannot be booted, the phase does NOT fail — it records why in `validation/app-setup.md` and marks all findings **Code-Only**.

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
| Failing the review when the app won't boot | App setup is best-effort — record why and mark findings Code-Only, then continue |
| Booting the app without user confirmation | Validator proposes the run command and confirms before executing it |
| Running destructive exploit payloads against the app | Validate with minimal, non-destructive proofs; never run payloads that delete/corrupt data |
| Dropping a code-confirmed finding because it wasn't reproducible | Static-only findings stay — mark Code-Only or Validation Inconclusive, never silently remove |
| Forgetting to shut down team members | Send shutdown messages and call TeamDelete when done |
