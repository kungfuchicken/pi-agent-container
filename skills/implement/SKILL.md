---
name: implement
description: Begin implementation from an approved plan. Establishes the plan as the authoritative spec for the session, sets up todos, and embeds alignment-maintaining behaviors. Use when starting a fresh session to implement planned work.
argument-hint: [--base <branch>] <plan-path>
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, TodoWrite, AskUserQuestion, Skill
---

# Implementation Skill

Begin implementation work from an approved plan. This skill establishes the plan as the authoritative specification for the session and sets up the working context.

## Invocation

`/implement [--base <branch>] <plan-path>`

**Arguments**:
- `--base <branch>`: Branch to create the worktree from. Defaults to `main`. Use for integration branch workflows where implementation branches need to build on accumulated work from other phases.
- `<plan-path>`: Path to the implementation plan (relative to `~working/plans/` or absolute).

**Examples**:
```bash
# Standard: branch from main
/implement myapp-audio-effects-impl-plan.md

# Integration branch: branch from accumulated work
/implement --base feature/course-lifecycle phase-2a-impl-plan.md
```

**Arguments received**: $ARGUMENTS

---

## Purpose

This skill solves two problems:

1. **Repetitive prompting**: When starting a fresh session to implement a plan, you don't need to explain the context—just invoke the skill with the plan path.

2. **Explicit transition**: Makes the shift from "planning mode" to "implementation mode" conscious and intentional. The plan represents design investment; this skill ensures we use it.

---

## Behavior

### 1. Locate and Read the Plan

- If path is relative, look in `~working/plans/` or `~working/plans/completed/`
- If path is absolute, use directly
- Read the entire plan file before proceeding

**If plan not found**: Report error with suggestions for likely locations.

### 2. Detect Plan Type

Determine if this is a **design plan** or an **implementation plan**:

**Implementation plan indicators**:
- Filename contains `-impl-plan`
- Has `## Parent Plan` section
- Has `## Implementation Order` section with blocking annotations
- Has `## File/Module Inventory` section

**Design plan indicators**:
- Filename ends in `-plan.md` without `-impl-`
- Has high-level `## Work Items` without blocking annotations
- Has `## Open Questions` section
- Lacks detailed file inventory

### 3. Handle Design Plans

**If design plan detected**, check if an implementation plan exists:

1. Look for corresponding impl plan (e.g., `{name}-impl-plan.md` or `{name}-phase-*-impl-plan.md`)
2. **If impl plan exists**: Ask which plan to implement from
3. **If no impl plan**: Ask the user:

> "This appears to be a design plan. Two approaches:
>
> 1. **Create implementation plan first** (`/impl-planning {path}`)
>    Better for complex changes—produces detailed task breakdown with tradeoff analysis
>
> 2. **Implement interactively**
>    Better for focused changes—we work through the design plan together, and I'll ask for approval on each edit
>
> Which approach fits this work?"

**If user chooses interactive**: Proceed with implementation setup, but adopt an interactive approval style (present changes, wait for approval before writing).

### 4. Verify Plan Status

Check the lifecycle table for current stage.

**If APPROVED or COMPLETED**: Proceed with implementation setup.

**If DRAFT or READY**: Ask the user:
> "This plan is at {stage} stage, not yet APPROVED. Options:
> 1. Proceed anyway (changes may occur during implementation)
> 2. Review and approve first (`/stage set approved <path>`)
> 3. Cancel"

### 5. Verify Git State & Create Worktree

Before beginning implementation, establish a clean git context.

#### 5a. Check for Uncommitted Changes

Run `git status` in the target repository (identified from plan's file inventory).

**If uncommitted changes exist**, ask the user:
> "This repository has uncommitted changes. How should we proceed?
> 1. Commit now (I'll help with a commit message)
> 2. Continue anyway (parallel work or intentional WIP)
> 3. Inspect changes first"

**If clean**: Proceed to worktree creation.

#### 5b. Resolve Base Branch

**Resolve base branch**: Use `--base` value if provided, otherwise default to `main`. Throughout this section, `<base>` refers to this resolved branch name.

Verify the base branch exists and is up to date:

```bash
# Fetch latest from origin
git fetch origin <base>

# Check if base branch exists locally
git rev-parse --verify <base>
```

**If base branch doesn't exist locally**: Create it tracking the remote:
```bash
git checkout -b <base> origin/<base>
git checkout -  # Return to previous branch
```

#### 5c. Create Worktree

Create an isolated worktree for this implementation session, branching from the resolved base:

```bash
# Create worktrees directory and worktree with implementation branch
mkdir -p .worktrees
git worktree add .worktrees/impl-{plan-name} -b impl/{plan-name} <base>
```

**Prerequisite**: The repository's `.gitignore` must include `.worktrees/`. This is a one-time setup per repo, not handled by this skill.

**Worktree location**: `.worktrees/impl-{plan-name}/` inside the target repository.
**Branch name**: `impl/{plan-name}` (e.g., `impl/myapp-audio-effects`).
**Base branch**: `<base>` (e.g., `main` or `feature/course-lifecycle-rearchitecture`).

Change working context to the worktree for all subsequent operations.

**If worktree already exists** (from incomplete previous session):
> "Found existing worktree for this plan at `.worktrees/impl-{plan-name}/`.
> This suggests a previous session didn't complete. Options:
> 1. Resume in existing worktree (check for WIP commits)
> 2. Remove and start fresh
> 3. Inspect first"

**If base is an integration branch**: Report clearly:
> "Creating worktree from integration branch `<base>` (not `main`).
> This worktree will have access to work merged to the integration branch."

### 6. Display Plan Summary

Present a brief summary:
- **Title** and **Status**
- **Goals** section (or first few lines)
- **Work Items** or **Implementation Order** count
- Any **Open Questions** that remain (design plans) or **Tradeoff Analysis** highlights (impl plans)

### 7. Set Up Todos

Extract work items from the plan and create todos using TodoWrite:
- **Implementation plans**: Parse `## Implementation Order` section, preserve blocking annotations in todo notes
- **Design plans (interactive)**: Parse `## Work Items` section
- Convert each item to a todo
- Mark all as `pending` initially

### 8. Establish Session Context

Confirm to the user:
> "Implementation session established. The plan at `{path}` is the authoritative spec.
>
> **Working agreements for this session:**
> - I'll anchor implementation decisions to the plan
> - If I diverge from the plan, I'll note it explicitly
> - If the plan proves wrong or incomplete, I'll update it
> - Changes are welcome—alignment matters more than the document
>
> Ready to begin with the first work item?"

---

## Implementation Principles

These behaviors are embedded for the duration of the implementation session:

### Anchor to the Plan

The plan is the starting point for all implementation decisions. Before writing code:
- Reference the plan's structure, paths, and design decisions
- Don't rely solely on reading source files—check what the plan specifies
- Use the plan's vocabulary consistently

### Note Divergences Explicitly

Improvements discovered during implementation are welcome. When diverging from the plan:
- Call it out: "The plan says X; I'm doing Y because..."
- Don't silently deviate
- Document the rationale

### Update the Plan

If implementation reveals the plan was wrong or incomplete:
- Update the plan to reflect reality
- Keep the plan as living documentation, not a historical artifact
- This maintains alignment for future sessions or collaborators

### Maintain Communication

The plan is less important than the act of planning. What matters is:
- Shared understanding of intent
- Continuous alignment as details emerge
- The plan as a communication tool, not a contract

### Attribution Tracking

Implementation work builds on contributions from multiple sources. See [attribution guidelines](../_shared/attribution.md) for full details.

**Key points for implementation**:
- Checkpoint commits don't need attribution (they get squashed)
- Final commits include `Co-Authored-By` trailers for all substantive contributors
- Track when implementing suggestions from Gemini reviews
- Check the plan's Contributors section for prior contributions
- Attribution flows from plan → implementation

### Checkpoint Commits

Make frequent checkpoint commits during implementation to enable rollback, exploration, and interruption resilience.

**When to checkpoint:**
- After completing each todo item (especially if tests pass)
- Before attempting a risky or uncertain change
- After fixing a bug or resolving an issue
- When switching focus between files or concerns

**Checkpoint commit format** (strict—enables auto-approval):
```bash
# Step 1: stage files (separate Bash call)
git add <changed-files>

# Step 2: commit (separate Bash call)
git commit -m "[checkpoint] {brief description of what was just completed}"
```

**Important**:
- Always use `-m` flag with the `[checkpoint]` prefix exactly as shown. This format is pre-approved in permissions.
- Do not use heredocs or multi-line commit messages for checkpoints.
- **Never chain `git add` and `git commit` with `&&`**. Run them as separate Bash tool calls (sequentially). Chained commands are evaluated as a single unit and may not match pre-approved permissions.
- **`git init` is not a checkpoint commit**. Repository initialization is a separate action—run it as its own Bash call, not chained with add/commit.

**Examples:**
```
[checkpoint] effects module structure created
[checkpoint] AudioEffect trait compiles
[checkpoint] GainEffect passing tests
[checkpoint] fixed trait bounds on EffectChain
```

**Benefits for agent work:**
- **Rollback granularity**: Revert to last working state without manual reconstruction
- **Exploration branches**: Commit, try approach A, reset if it fails, try approach B
- **Interruption resilience**: Less work lost if session ends unexpectedly
- **Debugging via bisect**: Identify which change caused a failure
- **Transparency**: User can watch progress via `git log`

Checkpoint commits are squashed into clean history at session end (see Session Completion).

---

## Session Completion

When all work items are complete (or the user ends the session), delegate to `/worktree-merge`.

### Complete Session

When all todos are done, offer to proceed with merge workflow:

```
Claude: All work items complete!

## Implementation Summary

**Plan**: `~working/plans/myapp-audio-effects-impl-plan.md`
**Branch**: `impl/myapp-audio-effects`
**Worktree**: `.worktrees/impl-myapp-audio-effects/`
**Checkpoint commits**: 6

Ready to squash and merge. Options:

1. **Run `/worktree-merge`** - Squash checkpoints, choose merge/PR, clean up
2. **Review first** - Inspect commits with `git log main..HEAD` before merging
3. **Keep as-is** - Leave worktree and checkpoints for manual handling
```

The `/worktree-merge` skill handles:
1. Committing any uncommitted changes
2. Squashing checkpoint commits into logical units
3. Offering merge/PR options
4. Cleaning up the worktree
5. Reporting final state

After `/worktree-merge` completes, advance the plan:
- If merged: Advance plan to COMPLETED stage (`/stage set completed {path}`)
- If PR created: Plan stays at APPROVED until PR merges

### Incomplete Session

**If session ends incomplete** (user stops, context limit, interrupted):

1. Commit any uncommitted work as a checkpoint:
```bash
git add <changed-files>
git commit -m "[checkpoint] WIP - session ending incomplete"
```

2. Do NOT squash—keep checkpoints for next session

3. Report incomplete state:
```markdown
## Session Summary (Incomplete)

**Plan**: {plan-path}
**Branch**: `impl/{plan-name}`
**Worktree**: `.worktrees/impl-{plan-name}/`

**Status**: Work in progress

**Completed**: {list of done todos}
**Remaining**: {list of pending todos}

**To resume**: Start a new session and run `/implement {plan-path}`
The existing worktree will be detected and you'll be offered the option to resume.

**To review current state**:
- `cd .worktrees/impl-{plan-name}/`
- `git log main..HEAD` (see commits)
- `git diff main...HEAD` (see full diff)
```

---

## Path Resolution

**To find the workspace `~working/plans/`**:
1. Check if current directory contains `~working/plans/`
2. Walk up parent directories looking for `~working/plans/`
3. If path is absolute, use directly

**Path argument handling**:
- Filename only: look in `~working/plans/`
- `completed/filename`: look in `~working/plans/completed/`
- Absolute path: use directly
- Glob patterns allowed: `*phase1*` to match partial names

---

## Notes for Claude

When executing this skill:

### Setup (Steps 1-8)
1. **Read the full plan** before any other action—this is the authoritative spec
2. **Detect plan type early**: Check for `-impl-plan` in filename, `## Implementation Order`, `## Parent Plan`
3. **Offer choice for design plans**: Don't assume interactive mode—let user decide
4. **Don't skip verification**: Even if the user seems eager, check the stage
5. **Keep the plan path visible**: Reference it throughout the session
6. **Todos are derived from plan**: Don't invent work items not in the plan
7. **Always use worktrees**: Create a worktree at session start, no exceptions
8. **Resolve base branch early**: Parse `--base` argument; default to `main` if not provided. The base branch determines what code the implementation builds upon.

### During Implementation
8. **Divergence is OK**: The goal is alignment, not rigid adherence
9. **Interactive mode = more checkpoints**: When implementing from design plan interactively, present changes before writing
10. **Checkpoint frequently**: Commit after each todo item completes (especially after tests pass), before risky changes, and after fixing issues. Use `[checkpoint]` prefix.
11. **Checkpoint commit format is strict**: Always use `git commit -m "[checkpoint] ..."` with the `-m` flag. This format is pre-approved. **Never chain git add and git commit with `&&`**—run them as separate sequential Bash calls. Chained commands don't match pre-approved permissions.
12. **Checkpoints enable exploration**: If unsure about an approach, checkpoint first, then try it. If it fails, `git reset --hard HEAD~1` returns to safety.
13. **Track attribution sources**: Note when implementing suggestions from Gemini reviews or other external sources. Check the plan's Contributors section.

### Session Completion
14. **Recommend /worktree-merge, don't auto-invoke**: When all work items complete, present a summary and offer options including `/worktree-merge`. Give the user a chance to review before merging.
15. **Incomplete sessions**: If ending early, commit WIP checkpoint, report state with worktree location, keep worktree for resume
16. **Advance plan after merge**: After successful merge (via `/worktree-merge` or manual), advance plan to COMPLETED

---

## Example Sessions

### Example 1: Implementation Plan (Full Session with Git)

```
User: /implement myapp-audio-effects-impl-plan.md

Claude: I'll set up implementation from this plan.

[Reads the plan file]

**Plan**: Myapp Audio Effects - Implementation Plan
**Type**: Implementation plan (has Implementation Order, File Inventory)
**Status**: APPROVED (2025-01-20)
**Parent**: myapp-audio-effects-plan.md

Checking git state in the target repository...

[Runs git status]

Repository has uncommitted changes:
  modified: src/audio/node.rs
  new file: src/audio/mixer.rs

How should we proceed?
1. Commit now (I'll help with a commit message)
2. Continue anyway (parallel work or intentional WIP)
3. Inspect changes first

User: 2 - that's parallel work on the mixer feature

Claude: Understood, continuing with parallel work noted.

Currently on branch `main`. Creating worktree for this implementation...

[Creates .worktrees/impl-myapp-audio-effects with branch impl/myapp-audio-effects]

Worktree created at `.worktrees/impl-myapp-audio-effects/`.

**Implementation Order** (6 items):
1. Create audio/effects/mod.rs module structure
2. Define AudioEffect trait and EffectChain (blocked by: 1)
3. Implement GainEffect (blocked by: 2)
4. Implement FilterEffect (blocked by: 2)
5. Add effect chain to AudioNode (blocked by: 3, 4)
6. Write integration tests (blocked by: 5)

**Key Decisions**: 3 documented (parameter storage, chain ordering, bypass behavior)

Setting up todos with blocking annotations...

Implementation session established. The plan at
`~working/plans/myapp-audio-effects-impl-plan.md` is the authoritative spec.

**Working agreements for this session:**
- I'll anchor implementation decisions to the plan
- If I diverge from the plan, I'll note it explicitly
- If the plan proves wrong or incomplete, I'll update it
- Changes are welcome—alignment matters more than the document

Ready to begin with item 1: "Create audio/effects/mod.rs module structure"?

User: yes

[... implements module structure ...]

Claude: Module structure created. Tests pass.

[Checkpoint commit: "[checkpoint] effects module structure created"]

Moving to item 2: "Define AudioEffect trait and EffectChain"...

[... implements trait ...]

Claude: Trait compiles, basic tests pass.

[Checkpoint commit: "[checkpoint] AudioEffect trait compiles"]

[... implements GainEffect ...]

[Checkpoint commit: "[checkpoint] GainEffect passing tests"]

[... implements FilterEffect, hits a snag with trait bounds ...]

Claude: Running into trait bound issues. Let me checkpoint before trying a fix.

[Checkpoint commit: "[checkpoint] FilterEffect WIP - trait bounds issue"]

[... fixes the issue ...]

[Checkpoint commit: "[checkpoint] fixed trait bounds on EffectChain"]

[... completes remaining items ...]

[Checkpoint commit: "[checkpoint] integration tests passing"]

Claude: All work items complete!

## Implementation Summary

**Plan**: `~working/plans/myapp-audio-effects-impl-plan.md`
**Branch**: `impl/myapp-audio-effects`
**Worktree**: `.worktrees/impl-myapp-audio-effects/`
**Checkpoint commits**: 6

Ready to squash and merge. Options:

1. **Run `/worktree-merge`** - Squash checkpoints, choose merge/PR, clean up
2. **Review first** - Inspect commits with `git log main..HEAD`
3. **Keep as-is** - Leave worktree for manual handling

User: 1

Claude: [Invokes /worktree-merge]

[/worktree-merge handles squash, user chooses PR, creates PR, cleans up worktree]

## Merge Complete

**Branch**: `impl/myapp-audio-effects`
**PR**: https://github.com/org/myapp/pull/42
**Worktree**: removed

Advancing plan to COMPLETED.

[Runs /stage set completed myapp-audio-effects-impl-plan.md]

Done! Plan archived to `~working/plans/completed/`.
```

### Example 2: Design Plan (Offers Choice)

```
User: /implement myapp-audio-effects-plan.md

Claude: I'll examine this plan.

[Reads the plan file]

This appears to be a **design plan** (has Work Items and Open Questions, no
Implementation Order or File Inventory).

I don't see a corresponding implementation plan (`myapp-audio-effects-impl-plan.md`).

Two approaches:

1. **Create implementation plan first** (`/impl-planning myapp-audio-effects-plan.md`)
   Better for complex changes—produces detailed task breakdown with tradeoff analysis

2. **Implement interactively**
   Better for focused changes—we work through the design plan together, and
   I'll ask for approval on each edit

Which approach fits this work?

User: let's do interactive

Claude: Got it. I'll set up for interactive implementation.

**Plan**: Myapp Audio Effects
**Status**: APPROVED (2025-01-20)
**Goals**: Enable real-time audio effects processing

**Work Items** (5 high-level items):
1. Define AudioEffect trait and core types
2. Implement gain and filter effects
3. Add effect chain to audio nodes
4. Create effect parameter UI bindings
5. Write integration tests

**Interactive mode**: I'll present proposed changes and wait for your approval
before writing code.

Ready to discuss the first work item: "Define AudioEffect trait and core types"?
```

---

## Edge Cases

- **Plan has no Work Items section**: Ask user how to proceed—perhaps extract from Design section, or work through Goals
- **Multiple matching plans**: List matches, ask user to specify
- **Plan references other plans** (phased): Note the parent/child relationship, focus on the specified plan
- **Design plan has existing impl plan**: List the impl plan(s), ask which to use
- **Impl plan references outdated design plan**: Warn that parent plan may have changed, ask if tradeoffs need re-evaluation
- **Session continues past plan scope**: If all work items complete, check if plan should move to COMPLETED stage
- **Interactive mode divergence**: When implementing interactively from a design plan, if significant complexity emerges, suggest pausing to create an impl plan
- **Existing worktree found**: A previous session didn't complete—offer to resume, start fresh, or inspect
- **Worktree creation fails**: Branch already exists remotely, or git state is corrupted—diagnose and offer options
- **Merge conflicts at session end**: If merge to main has conflicts, offer to resolve or keep branch for manual handling
- **Session interrupted mid-work**: Commit WIP with clear prefix, keep worktree, note incomplete todos in commit message. Don't squash—keep checkpoints for next session. Always output the Session Summary (Incomplete) with worktree location and remaining todos.
- **`.worktrees/` not gitignored**: Warn user and ask them to add it to `.gitignore` before proceeding
- **Rebase conflicts during squash**: If conflicts arise during interactive rebase, resolve them or offer to keep commits unsquashed
- **Resuming session with existing checkpoints**: When resuming a worktree from a previous session, continue from existing checkpoints—don't start over
- **Exploration branch needed**: If trying multiple approaches, create a temporary branch from the last checkpoint rather than resetting
- **Integration branch doesn't exist**: If `--base` specifies a branch that doesn't exist locally or remotely, error with clear message
- **Integration branch out of date**: If base branch has new commits since last fetch, warn and offer to update before creating worktree
- **Multiple phases using same integration branch**: Each phase creates its own worktree from the integration branch. After one phase merges, other in-flight worktrees should rebase onto the updated integration branch before merging.
