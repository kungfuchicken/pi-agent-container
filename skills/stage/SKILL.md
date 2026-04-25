---
name: stage
description: List and advance plans through lifecycle stages (DRAFT → READY → APPROVED → COMPLETED). Use for checking plan status or advancing plans to the next stage.
argument-hint: list [filter] | set <stage> <path>
allowed-tools: Read, Edit, Write, Bash, Glob
disable-model-invocation: true
---

# Plan Stage Management Skill

List and manage the lifecycle stage of plans in `~working/plans/`.

Plans progress through four stages:
- **DRAFT**: Being actively developed, may have gaps
- **READY**: Complete and coherent, awaiting approval decision
- **APPROVED**: Committed to implementation, resources allocated
- **COMPLETED**: All work done, archived in `completed/`

## Invocation

`/stage <command> [args]`

**Arguments received**: $ARGUMENTS

---

## Commands

### `list [filter]`

List plans with their current lifecycle stages.

**Usage**:
- `/stage list` — All plans
- `/stage list draft` — Only DRAFT plans
- `/stage list ready` — Only READY plans
- `/stage list approved` — Only APPROVED plans
- `/stage list completed` — Only COMPLETED plans

**Steps**:
1. Find the workspace's `~working/plans/` directory
2. Glob for `*.md` files in `plans/` and `plans/completed/`
3. For each plan, read the lifecycle table and extract current stage
4. Display as a table, filtered if a stage was specified

**Output format**:
```
| Plan | Stage | Location |
|------|-------|----------|
| safisto-phase1a-foundation-plan.md | COMPLETED | completed/ |
| draft-safisto-phase1b-mvp-completion-plan.md | READY | plans/ |
```

**Determining current stage**: Read the lifecycle table. The current stage is the last one with a date (not "—").

---

### `set <stage> <path>`

Advance a plan to the specified stage.

**Usage**:
- `/stage set ready <path>` — Advance DRAFT → READY
- `/stage set approved <path>` — Advance READY → APPROVED
- `/stage set completed <path>` — Advance APPROVED → COMPLETED

**Valid stage values**: `ready`, `approved`, `completed`

---

#### `set ready <path>`

Advance a plan from DRAFT to READY.

**Prerequisites**: Plan must currently be at DRAFT stage.

**Steps**:
1. Read the plan file
2. Verify current stage is DRAFT (READY date should be "—")
3. Update the lifecycle table: set READY date to today (YYYY-MM-DD)
4. Optionally update Status header
5. Confirm the update

**Example transformation**:
```markdown
| READY | — | |
```
becomes:
```markdown
| READY | 2025-01-22 | Plan reviewed, pending approval |
```

---

#### `set approved <path>`

Advance a plan from READY to APPROVED.

**Prerequisites**: Plan must currently be at READY stage.

**Steps**:
1. Read the plan file
2. Verify current stage is READY (APPROVED date should be "—")
3. Update the lifecycle table: set APPROVED date to today
4. Update the Status header (remove "READY", set to stage name or "IN PROGRESS")
5. Rename file: remove `draft-` prefix
6. Report the new filename

**Example file rename**:
```
draft-safisto-phase1b-mvp-completion-plan.md
→ safisto-phase1b-mvp-completion-plan.md
```

---

#### `set completed <path>`

Advance a plan from APPROVED to COMPLETED.

**Prerequisites**: Plan must currently be at APPROVED stage (no `draft-` prefix).

**Steps**:
1. Read the plan file
2. Verify current stage is APPROVED (COMPLETED date should be "—")
3. Update the lifecycle table: set COMPLETED date to today
4. Update the Status header to "COMPLETED"
5. Create `completed/` subdirectory if it doesn't exist
6. Move file to `completed/` subdirectory
7. Check for parent plan references and update them
8. Report the new file location

**Parent plan update**:
If the plan has a `**Parent plan**:` header, read that parent plan and update any Phase Plans table to reflect the new path in `completed/`.

---

## Locating Plan Files

Plans live in `~working/plans/` relative to the workspace root.

**To find the workspace**:
1. Check if current directory contains `~working/plans/`
2. Walk up parent directories looking for `~working/plans/`
3. Use the provided path directly if it's absolute

**Path argument handling**:
- If just a filename: look in `~working/plans/`
- If starts with `completed/`: look in `~working/plans/completed/`
- If absolute path: use directly

---

## Lifecycle Table Format

Plans must contain a lifecycle table in this format:

```markdown
## Lifecycle

| Stage | Date | Notes |
|-------|------|-------|
| DRAFT | YYYY-MM-DD | Initial plan created |
| READY | — | |
| APPROVED | — | |
| COMPLETED | — | |
```

The skill updates dates and may add brief notes. Use "—" for stages not yet reached.

---

## Edge Cases

- **Missing lifecycle table**: Report error, suggest adding the table with template
- **Wrong current stage**: If plan isn't at the expected stage, report current stage and what's needed
- **File not found**: Report error with helpful message about expected locations
- **Parent plan not found**: Warn but continue with completion
- **Already at target stage**: Report that no change is needed

---

## Example Session

```
User: /stage list
→ Shows all plans with stages

User: /stage list ready
→ Shows only READY plans

User: /stage set ready draft-safisto-phase1c-plan.md
→ Updates READY date in lifecycle table

User: /stage set approved draft-safisto-phase1c-plan.md
→ Updates APPROVED date, renames to safisto-phase1c-plan.md

User: /stage set completed safisto-phase1c-plan.md
→ Updates COMPLETED date, moves to completed/, updates parent plan
```

---

## Notes for Claude

When executing this skill:

1. **Be explicit** about what you're changing before making edits
2. **Confirm success** with the new file state after each operation
3. **For set approved/completed**: Show the git-style file rename/move in output
4. **Date format**: Always use YYYY-MM-DD (ISO 8601)
5. **Preserve content**: Only modify the lifecycle table and status header; leave all other content unchanged
6. **Stage detection**: Current stage = last row in lifecycle table with a real date (not "—")
