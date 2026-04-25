---
name: worktree-merge
description: Merge work from a git worktree back to main (or a specified target branch). Handles squashing checkpoints, merge/PR options, and worktree cleanup. Use after completing implementation work in a worktree.
argument-hint: [--repo <project>] [--target <branch>] [<worktree-or-branch>]
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
---

# Worktree Merge

Complete and merge work from a git worktree. Handles the full workflow: squash checkpoint commits, merge or create PR, clean up worktree.

## Invocation

`/worktree-merge [--repo <project>] [--target <branch>] [<worktree-or-branch>]`

**Arguments**:
- `--repo <project>`: Target repository. See [repo resolution rules](../_shared/repo-resolution.md).
- `--target <branch>`: Branch to merge into. Defaults to `main`. Use for integration branch workflows where multiple features merge to a shared branch before final integration to main.
- `<worktree-or-branch>`: Worktree directory name or branch name. Optional if already in a worktree.

**Examples**:
```bash
# From within a worktree, merge to main (default)
/worktree-merge

# Specify worktree by directory name
/worktree-merge impl-audio-effects

# Specify by branch name
/worktree-merge impl/audio-effects

# Full specification
/worktree-merge --repo myapp impl-audio-effects

# Merge to integration branch instead of main
/worktree-merge --target feature/big-refactor

# Full specification with integration branch
/worktree-merge --repo mostidy --target feature/course-lifecycle phase-2a
```

**Arguments received**: $ARGUMENTS

---

## Purpose

Worktrees enable isolated implementation work. This skill provides a consistent workflow for completing that work:

1. **Squash messy checkpoints** into clean, logical commits
2. **Choose integration path**: merge directly or create PR
3. **Clean up** worktree and optionally branch
4. **Report final state** for verification

Separating this from `/implement` allows:
- Manual worktree workflows (not plan-driven)
- Resuming incomplete `/implement` sessions
- Consistent merge hygiene across workflows

### Integration Branch Pattern

The `--target` option enables multi-phase workflows where several features merge to a shared integration branch before the final merge to `main`:

```
main
  └─► feature/big-refactor (integration branch)
        ├─► phase-1 ─► /worktree-merge --target feature/big-refactor
        ├─► phase-2 ─► /worktree-merge --target feature/big-refactor
        └─► phase-3 ─► /worktree-merge --target feature/big-refactor
                              │
                              └─► Final PR: integration → main
```

This keeps `main` stable while parallel work progresses on the integration branch.

---

## Behavior

### 1. Resolve Repository and Worktree

**If `--repo` provided**: Resolve project name/path per standard rules.

**Locate worktree**:

| Input | Resolution |
|-------|------------|
| (none, in worktree) | Use current directory |
| (none, not in worktree) | List worktrees in `.worktrees/`, ask user to select |
| `impl-foo` | Look in `.worktrees/impl-foo/` |
| `impl/foo` | Find worktree for branch `impl/foo` |
| `.worktrees/impl-foo` | Use directly |

**Verify worktree**:
```bash
git -C <repo> worktree list
```

Extract: worktree path, branch name, commit count ahead of main.

### 2. Analyze Work State

**Resolve target branch**: Use `--target` value if provided, otherwise default to `main`. Throughout this skill, `<target>` refers to this resolved branch name.

Gather information about the work to be merged:

```bash
# Commits ahead of target
git -C <worktree> log <target>..HEAD --oneline

# Any uncommitted changes?
git -C <worktree> status --porcelain

# Checkpoint commits (for squash planning)
git -C <worktree> log <target>..HEAD --oneline | grep -c '^\[checkpoint\]' || echo 0

# Check if target has diverged from the branch point
git -C <worktree> merge-base HEAD <target>
git -C <worktree> rev-parse <target>
# If these differ, target has advanced since the worktree was created
```

**Detect diverged base**: Compare `merge-base HEAD <target>` with `rev-parse <target>`. If they differ, the target branch has advanced since the worktree branch was created. This is critical for Step 3 — the branch must be rebased onto current target before squashing, otherwise `git reset --soft <target>` will stage unrelated changes from commits added to target after the branch point.

**Present summary**:
```markdown
## Worktree: `.worktrees/impl-audio-effects/`
**Branch**: `impl/audio-effects`
**Target**: `feature/big-refactor` (or `main` if default)
**Commits**: 8 (5 checkpoints, 3 regular)
**Uncommitted changes**: none
**Base diverged**: yes — target has 2 new commits since branch point

Ready to proceed with merge workflow?
```

**If uncommitted changes**: Offer to commit them first.

### 3. Rebase and Squash Checkpoint Commits

This step has two phases: (a) rebase onto current target if needed, then (b) squash checkpoints.

#### 3a. Rebase onto current target

**CRITICAL**: If Step 2 detected that target has diverged (merge-base differs from target HEAD), the branch MUST be rebased before squashing. Without this, `git reset --soft <target>` will stage the diff between the old branch point and the new target HEAD — including unrelated changes from commits added to target after the branch was created.

```bash
# Only if target has diverged from branch point:
git -C <worktree> rebase <target>
```

**If rebase conflicts**: Offer to resolve, abort, or skip squash and merge as-is.

**After rebase**: Verify `merge-base HEAD <target>` now equals `rev-parse <target>` (branch is rooted on current target).

#### 3b. Squash checkpoints

If checkpoint commits exist, squash them into logical units.

**Identify squash targets**:
```bash
git -C <worktree> log <target>..HEAD --oneline
```

Look for `[checkpoint]` prefixed commits to squash.

**Squash strategy**:
- Group checkpoints between regular commits
- Each final commit should be coherent and self-contained
- Preserve regular (non-checkpoint) commits as boundaries

**Determine squash approach**:

| Commit Pattern | Approach |
|----------------|----------|
| All checkpoints | Squash all into single commit |
| Checkpoints + regular commits | Preserve regular commits, squash checkpoints into them |
| No checkpoints | Skip squash, commits are already clean |

**Execute squash** (non-interactive):

**IMPORTANT**: Do NOT use bare `git rebase -i` as it opens an interactive editor and fails in automated execution. Either use `git reset --soft` (preferred) or set `GIT_SEQUENCE_EDITOR` to automate the rebase todo list.

*Case 1: All checkpoints (most common)*
```bash
# Reset to target, keeping all changes staged
git -C <worktree> reset --soft <target>

# VERIFY: Only expected files are staged
git -C <worktree> diff --cached --stat
# If unexpected files appear, STOP — the rebase in 3a was likely skipped or failed.
# Abort with: git -C <worktree> reset --hard HEAD@{1}

# Create a single clean commit
git -C <worktree> commit -m "$(cat <<'EOF'
<Summary of implementation>

<Bullet points of key changes>

Co-Authored-By: Claude <model> <noreply@anthropic.com>
EOF
)"
```

*Case 2: Mixed checkpoints and regular commits*
```bash
# Use GIT_SEQUENCE_EDITOR to automate the rebase non-interactively
# This marks [checkpoint] commits as 'fixup' while preserving regular commits
GIT_SEQUENCE_EDITOR="sed -i.bak '/\[checkpoint\]/s/^pick/fixup/'" \
  git -C <worktree> rebase -i <target>
```

The `GIT_SEQUENCE_EDITOR` environment variable replaces the interactive editor with a sed command that automatically marks checkpoint commits for fixup.

If automated rebase fails (conflicts), fall back to simpler approach:
1. Ask user: squash everything into one commit, or keep as-is?
2. If squash all: use Case 1 approach (`reset --soft`)
3. If keep as-is: proceed to merge with messy history

**Final commit format**:
```
<Summary of changes>

<Details if needed>

Co-Authored-By: Claude <model> <noreply@anthropic.com>
```

**If no checkpoints**: Skip squash, commits are already clean.

**If squash fails**: Report the error, offer to keep commits as-is and proceed with merge.

### 4. Choose Integration Path

Ask user (note: option text adapts to target branch name):
```
How would you like to integrate this work?

1. **Merge to <target>** - Direct merge, keeps branch history
2. **Create PR** - Push branch, open pull request targeting <target>
3. **Keep branch** - No merge, just clean up checkpoints
```

#### Option 1: Merge to target

```bash
# Switch to target in the main repo (not worktree)
cd <repo-root>
git checkout <target>
git pull --ff-only origin <target>  # Ensure up to date

# Merge the implementation branch
git merge impl/<name> --no-ff -m "Merge impl/<name>: <summary>"
```

**If merge conflicts**: Offer to resolve or abort.

#### Option 2: Create PR

```bash
# Push branch
git -C <worktree> push -u origin impl/<name>

# Create PR targeting the target branch
gh pr create --base <target> --title "<summary>" --body "$(cat <<'EOF'
## Summary
<goals from commits or plan>

## Changes
<list of logical commits>

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**Note**: The `--base <target>` flag ensures the PR targets the correct branch. When using an integration branch pattern, this creates a PR against the integration branch, not `main`.

Report PR URL.

#### Option 3: Keep branch

No merge action. Checkpoints are squashed, branch is ready for manual handling.

### 5. Clean Up Worktree

**After merge to target**:
```bash
# Remove worktree
git -C <repo> worktree remove .worktrees/impl-<name>

# Delete branch (merged, safe)
git -C <repo> branch -d impl/<name>
```

**After PR created**:
```bash
# Remove worktree (frees disk space)
git -C <repo> worktree remove .worktrees/impl-<name>

# Keep branch (needed for PR)
```

**After "keep branch"**:
```bash
# Keep both worktree and branch
# User handles manually
```

Ask before cleanup:
> "Remove worktree `.worktrees/impl-<name>/`? (Branch will be kept for PR)"

### 6. Report Final State

Always conclude with a clear summary:

```markdown
## Merge Complete

**Branch**: `impl/audio-effects`
**Target**: `feature/big-refactor` (or `main`)
**Integration**: Merged to <target> (or PR #42 created, or kept for manual handling)

**Commits merged**:
- `abc1234` Implement AudioEffect trait and module structure
- `def5678` Add GainEffect and FilterEffect
- `ghi9012` Integration tests for effect chain

**Cleanup**:
- Worktree `.worktrees/impl-audio-effects/` removed
- Branch `impl/audio-effects` deleted (merged)

**To verify**: `git log <target> --oneline -5`
```

For PR:
```markdown
## PR Created

**Branch**: `impl/audio-effects`
**Target**: `feature/big-refactor`
**PR**: https://github.com/org/repo/pull/42

**Cleanup**:
- Worktree removed
- Branch preserved for PR

**Next steps**: Review and merge PR when ready
```

---

## Notes for Claude

When executing this skill:

1. **Resolve context first**: Determine repo, worktree, and **target branch** before any operations. Target defaults to `main` if `--target` not provided.
2. **Verify worktree state**: Check for uncommitted changes, count commits
3. **Always check for diverged target**: Compare `merge-base HEAD <target>` with `rev-parse <target>`. If they differ, rebase onto target BEFORE any squash operation. Skipping this causes `reset --soft <target>` to stage unrelated changes from commits added to target after the branch point — this is the single most common failure mode of this skill.
4. **Verify staged files after soft reset**: After `git reset --soft <target>`, always run `git diff --cached --stat` and confirm only expected files are staged. If unexpected files appear, abort with `git reset --hard HEAD@{1}` and investigate.
5. **Be careful with rebase**: Interactive rebase can be destructive—confirm before proceeding
6. **Preserve non-checkpoint commits**: Only squash `[checkpoint]` commits
7. **Report resolved paths**: Always show the user exactly which worktree/branch/target is being processed
8. **Final state is mandatory**: Always output the summary showing what was done and how to verify
9. **Don't force cleanup**: Ask before removing worktrees
10. **Handle conflicts gracefully**: If merge or rebase conflicts, explain and offer options
11. **Display target in prompts**: When target is not `main`, make it clear in prompts and summaries (e.g., "Merge to `feature/integration`" not just "Merge")

---

## Edge Cases

- **Target diverged since branch point**: Target branch has new commits not in the branch. MUST rebase before squashing — otherwise `reset --soft <target>` stages the full diff between old base and new target, pulling in unrelated changes. Detect via `merge-base HEAD <target>` != `rev-parse <target>`.
- **Not in a worktree, none specified**: List available worktrees, ask user to select
- **Worktree has no commits ahead of target**: Nothing to merge—report and exit
- **Branch already merged**: Detect and offer cleanup only
- **Remote branch exists but diverged**: Warn about force push implications
- **Rebase conflicts**: Offer to resolve, skip problematic commits, or abort
- **Merge conflicts**: Offer to resolve or keep branch for manual handling
- **Worktree for different repo**: Error clearly—worktrees are repo-specific
- **Branch pushed but no PR**: Offer to create PR or merge locally
- **Target branch doesn't exist locally**: Fetch from origin first, or error if it doesn't exist remotely either
- **Target is an integration branch**: When `--target` specifies a non-main branch, PRs should use `--base <target>` to target that branch instead of main

---

## Relationship to /implement

The `/implement` skill uses this workflow internally for Session Completion. This skill extracts that logic for:

- Standalone use (manual worktree workflows)
- Resuming incomplete `/implement` sessions
- Consistent merge hygiene

When `/implement` reaches completion, it can delegate to this skill's logic rather than duplicating it.
