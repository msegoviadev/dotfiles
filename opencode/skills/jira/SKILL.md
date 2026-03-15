---
name: jira
description: Interact with Jira using the jira CLI. View, create, transition, assign, and comment on issues. Use when the user mentions Jira, issue keys, sprints, or ticket work.
metadata:
  tags: jira, issues, tickets, cli, project-management, sprint
---

## When to Use

Use this skill when:
- User mentions Jira, tickets, or issue keys (pattern `[A-Z]+-[0-9]+`)
- User wants to view, create, update, or transition an issue
- User wants to manage sprints, assignments, or comments
- User wants to query issues with JQL

## Prerequisites

- `jira` CLI installed: `brew install ankitpokhrel/jira-cli/jira`
- Authenticated: `jira init` (runs setup wizard)

If `jira` is not available, guide the user to install and run `jira init` before proceeding.

## Core Safety Principles

- **Fetch before modifying.** Always `jira issue view ISSUE-KEY` first. Never assume the current status, assignee, or field values.
- **Show before editing.** Display the original description before proposing changes. Jira has no undo.
- **Verify transitions.** Transition names are project-specific. Run `jira issue move ISSUE-KEY --help` or check available states before transitioning.
- **Get approval before bulk changes.** Bulk operations trigger notifications — always confirm with the user before executing.

## Workflow

### Step 1: Confirm CLI is available

```bash
which jira || echo "not found"
```

If missing, stop and guide the user through installation and `jira init`.

### Step 2: Fetch current state

Always view the issue before making any changes:

```bash
jira issue view ISSUE-KEY
```

### Step 3: Draft the action

Prepare the command, show it to the user, and get explicit approval before running any write operation (create, move, assign, comment).

### Step 4: Execute

Run the approved command. For complex operations (multi-line descriptions, bulk changes), consult `references/commands.md`.

## When to Load Full References

**Simple operations** (view a single issue, list my open tickets) — no reference needed.

**Load `references/commands.md` for:**
- Multi-line issue descriptions or comments
- Advanced JQL queries
- Sprint management
- Issue linking
- Transition troubleshooting
- Any flags you are not certain about
