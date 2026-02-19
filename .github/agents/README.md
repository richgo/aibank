# OpenSpec — GitHub Copilot Custom Agents

A set of GitHub Copilot custom agents implementing the [OpenSpec](https://github.com/Fission-AI/OpenSpec) spec-driven development workflow. No MCP servers, no external dependencies — just `.md` files in `.github/agents/` with handoffs wiring each step to the next.

## Agents

| Agent | Purpose | Tools | Hands Off To |
|-------|---------|-------|-------------|
| **explore** | Investigate codebase, think through ideas | read, search | → new, ff |
| **new** | Scaffold a change directory | read, edit, search | → proposal, ff |
| **proposal** | Write the WHY — intent, scope, approach | read, edit, search | → specs |
| **specs** | Write the WHAT — requirements & scenarios | read, edit, search | → design |
| **design** | Write the HOW — technical decisions | read, edit, search | → tasks |
| **tasks** | Write the DO — implementation checklist | read, edit, search | → apply |
| **apply** | Execute — write code per task list | read, edit, search, execute | → verify, archive |
| **verify** | Check — spec compliance review | read, search | → apply, archive |
| **archive** | Close — merge specs, archive change | read, edit, search | → new, explore |
| **ff** | Fast-forward — all planning in one pass | read, edit, search | → apply, verify |

## Workflow

```
                           explore (optional)
                                │
                                ▼
                              new
                                │
             ┌──────────────────┴──────────────────┐
             │                                     │
            ff                                proposal
      (all at once)                            │
             │                               specs
             │                                 │
             │                              design
             │                                 │
             │                              tasks
             └──────────────────┬──────────────────┘
                                │
                             apply
                                │
                             verify
                                │
                            archive ──→ (loop back to new)
```

**Two paths:**
- **Fast path:** `new` → `ff` → `apply` → `archive`
- **Incremental path:** `new` → `proposal` → `specs` → `design` → `tasks` → `apply` → `archive`

Each agent presents **handoff buttons** at the end of its work, so you click through the workflow without remembering command names.

## Installation

Copy the `.github/agents/` directory into your repository:

```bash
cp -r .github/agents/ <your-repo>/.github/agents/
```

Commit and push to your default branch.

## Usage

### VS Code / JetBrains

Select an agent from the Copilot Chat dropdown. Handoff buttons appear inline to move to the next step.

### github.com (Coding Agent)

Assign an agent to an issue:
> @ff Add dark mode toggle with system preference detection

### CLI

```bash
gh copilot --agent ff "Add dark mode toggle"
```

## Handoff Chain

Handoffs use `send: false` so the developer always reviews the pre-filled prompt before continuing.

```
explore ───[Scaffold Change]──────→ new
explore ───[Fast-Forward]─────────→ ff

new ───────[Write Proposal]───────→ proposal
new ───────[Fast-Forward]─────────→ ff

proposal ──[Write Specs]──────────→ specs
specs ─────[Write Design]────────→ design
design ────[Break Into Tasks]────→ tasks
tasks ─────[Start Implementation]→ apply

apply ─────[Verify Against Specs]→ verify
apply ─────[Archive Change]──────→ archive

verify ────[Fix Issues]──────────→ apply
verify ────[Archive Change]──────→ archive

archive ───[Start New Change]────→ new
archive ───[Explore Next Idea]───→ explore
```

## Directory Structure

After a full workflow cycle:

```
openspec/
├── config.yaml              # Optional project config
├── specs/                   # Living spec library (canonical truth)
│   ├── auth-session/
│   │   └── spec.md
│   └── ui-theme/
│       └── spec.md
└── changes/
    ├── add-dark-mode/       # Active change
    │   ├── .openspec.yaml
    │   ├── proposal.md
    │   ├── specs/
    │   │   └── ui-theme/
    │   │       └── spec.md
    │   ├── design.md
    │   └── tasks.md
    └── archive/             # Completed changes
        └── 2026-02-18-fix-login/
```

## Customization

Each agent is a self-contained Markdown file. Edit freely to change templates, add project rules, or adjust tool permissions. Agents respect `openspec/config.yaml` for project-level context when it exists.

## Compatibility

- GitHub Copilot Coding Agent (github.com) — `handoffs` ignored, agents still work
- VS Code Copilot Chat — full handoff button support
- JetBrains Copilot Chat — full handoff button support
- Eclipse, Xcode — preview support

Based on [OpenSpec v1.1.x](https://github.com/Fission-AI/OpenSpec) OPSX workflow.
