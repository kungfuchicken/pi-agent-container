---
name: gemini-merge-review
description: Request a pre-merge review from Gemini on a branch, commit range, or PR. Use after implementation to get feedback before merging. Focuses on holistic assessment of the change set.
argument-hint: [--repo <path>] [--branch [name]|--commits <range>|--pr [number]]
allowed-tools: Read, Glob, Grep, Bash, Task, mcp__gemini__chat, AskUserQuestion
---

# Gemini Merge Review (Pre-Merge)

Request feedback on completed work from Gemini, acting as a third set of eyes before merge.

## Invocation

`/gemini-merge-review [--repo <project>] <target>`

**Repository selection**: See [repo resolution rules](../_shared/repo-resolution.md).

**Target**:
- `--branch`: Current branch vs main
- `--branch <name>`: Specified branch vs main
- `--commits <range>`: Commit range (e.g., `HEAD~5..HEAD`)
- `--pr`: Current PR
- `--pr <number>`: Specified PR

**Examples**:
```bash
/gemini-merge-review --repo myapp --branch impl/audio-effects
/gemini-merge-review --branch
/gemini-merge-review --pr 42
```

**Arguments received**: $ARGUMENTS

---

## Architecture: Phased Execution

This skill uses a **phased approach** to manage context efficiently:

```
Phase 1: Scope (main context)          ─► Lightweight metadata, user confirms
Phase 2: Review (Task agent)           ─► Full diff + Gemini call (isolated)
Phase 3: Present & Triage (main)       ─► Show findings, help address
```

**Why phases?** The full diff + Gemini prompt + response consumes significant context. Running Phase 2 in a Task agent isolates that cost, keeping the main session lean for follow-up work.

---

## Phase 1: Scope & Confirm

**Goal**: Gather lightweight metadata, confirm scope before heavy lifting.

### 1.1 Resolve Repository

If `--repo` provided, resolve per [repo resolution rules](../_shared/repo-resolution.md).
Report resolved path to user.

### 1.2 Gather Metadata (Lightweight)

```bash
# Commit count and summary
git log main..HEAD --oneline

# Diff stats only (not full diff)
git diff main...HEAD --stat

# Check for related plan
ls ~working/plans/*{branch-name}* 2>/dev/null
```

### 1.3 Present Scope Summary

```markdown
## Review Scope

**Repository**: `acme/myapp/`
**Target**: `impl/audio-effects` vs `main`
**Commits**: 8
**Files changed**: 12
**Lines**: +847/-23

**Modules affected**:
- `src/audio/effects/` (new)
- `src/audio/node.rs` (modified)
- `tests/audio/` (new tests)

**Related plan**: `~working/plans/myapp-audio-effects-impl-plan.md`

Proceed with Gemini review?
```

### 1.4 User Confirms

Wait for confirmation before Phase 2. This allows:
- Aborting if scope is wrong
- Adjusting target if needed
- Avoiding wasted context on incorrect reviews

---

## Phase 2: Gemini Review (Task Agent)

**Goal**: Run the expensive review in isolated context.

Launch a Task agent with `subagent_type: general-purpose` to:

1. **Gather full context**:
   - Complete diff (`git diff main...HEAD`)
   - Commit messages (`git log main..HEAD`)
   - Project CLAUDE.md (conventions)
   - Related plan summary (if found)

2. **Call Gemini** with the review prompt (see Appendix A)

3. **Return structured findings** only—not the raw diff or full prompt

### Task Agent Prompt Template

```
You are gathering context and requesting a Gemini merge review.

**Repository**: {resolved_path}
**Branch**: {branch_name}
**Base**: main

## Steps

1. Get the full diff:
   git -C {repo} diff main...{branch}

2. Get commit history:
   git -C {repo} log main..{branch} --format="%h %s"

3. Read project CLAUDE.md for conventions

4. If plan exists at {plan_path}, read the Goals and Acceptance Criteria sections

5. Call Gemini with the review prompt (Appendix A format)

6. Return ONLY Gemini's structured response. Do not include:
   - The full diff
   - The prompt you sent
   - Your own commentary

Format your final output as:
---BEGIN REVIEW---
{Gemini's response verbatim}
---END REVIEW---
```

---

## Phase 3: Present & Triage

**Goal**: Show findings, help user address issues.

### 3.1 Present Review

Extract Gemini's response from the Task agent and display:

```markdown
## Gemini Merge Review

**Target**: `impl/audio-effects` vs `main`
**Commits**: 8 | **Files**: 12 | **Lines**: +847/-23

{Gemini's structured response}

---
*Review by Gemini. You are the decision-maker.*
```

### 3.2 Triage by Readiness

**If "Ready"**:
- Confirm merge path (`/worktree-merge` or manual)
- Note any follow-up work suggested

**If "Needs Work"**:
- List blocking issues
- Offer to help address each
- Track fixes for attribution

**If "Needs Discussion"**:
- Summarize key questions
- Don't proceed without direction

### 3.3 Handle Follow-Up Fixes

When addressing issues from the review, follow [attribution guidelines](../_shared/attribution.md).

---

## Notes for Claude

### Phase 1 (Main Context)
1. **Keep it light**: Only gather stats, not full diffs
2. **Resolve --repo first**: Report the resolved path
3. **Confirm before Phase 2**: User must agree to proceed

### Phase 2 (Task Agent)
4. **Use Task tool**: Launch with `subagent_type: general-purpose`
5. **Structured return**: Agent returns only Gemini's response
6. **Don't duplicate context**: Agent gathers its own; main session doesn't need it

### Phase 3 (Main Context)
7. **Present faithfully**: Don't filter Gemini's response
8. **Triage by readiness**: Different paths for Ready/Needs Work/Needs Discussion
9. **Attribution on fixes**: Substantive fixes get `Co-Authored-By: Gemini`

### General
10. **Don't auto-fix**: Present review, wait for direction
11. **Follow-up commits**: On shared branches, create new commits (don't amend)

---

## Appendix A: Gemini Review Prompt

The Task agent sends this to Gemini:

```
You are reviewing a completed branch/PR as an integration reviewer. Evaluate whether this change set is ready to merge. You do NOT make fixes—you provide observations.

## Change Context
**Target**: {branch/PR}
**Commits**: {count}

## Commit History
{git log output}

## Full Diff
{complete diff}

## Project Conventions
{CLAUDE.md excerpts}

## Related Plan
{plan summary or "None"}

## Review Criteria

Evaluate holistically for integration readiness:

1. **Architectural Coherence**: Fits existing architecture? New patterns justified?
2. **Completeness**: All pieces present (impl, tests, docs)?
3. **Consistency**: Naming, patterns, conventions followed?
4. **Integration Risk**: What could break? Conflicts? Performance? Security?
5. **Test Coverage**: Adequate? Edge cases covered?
6. **Documentation**: Self-documenting? Non-obvious decisions explained?

## Response Format

**Summary**: 2-3 sentences on what this accomplishes and overall assessment.

**Merge Readiness**: Ready / Needs Work / Needs Discussion

**Blocking Issues** (if any): What's wrong, why it matters, how to address.

**Non-Blocking Suggestions** (if any): Improvements for now or follow-up.

**Test Assessment**: Coverage adequate? What's missing?

**Follow-Up Work** (if any): Tech debt or enhancements revealed.

**Positive Notes**: What's done well.
```

---

## Example Session

```
User: /gemini-merge-review --repo myapp --branch impl/audio-effects

Claude: I'll set up a merge review for this branch.

Resolving repository... found: `acme/myapp/`

## Review Scope

**Repository**: `acme/myapp/`
**Target**: `impl/audio-effects` vs `main`
**Commits**: 8
**Files changed**: 12
**Lines**: +847/-23

**Modules affected**:
- src/audio/effects/ (new)
- src/audio/node.rs (modified)

**Related plan**: `~working/plans/myapp-audio-effects-impl-plan.md`

Proceed with Gemini review?

User: yes

Claude: Launching review agent...

[Task agent runs Phase 2 in isolated context]

## Gemini Merge Review

**Target**: `impl/audio-effects` vs `main`
**Commits**: 8 | **Files**: 12 | **Lines**: +847/-23

**Summary**
Implements audio effects system with AudioEffect trait, GainEffect, FilterEffect, and EffectChain. Solid implementation following the plan, good test coverage.

**Merge Readiness**: Needs Work

**Blocking Issues**

1. **Missing persistence integration test**
   - Plan specifies "Effect chain state persists across restart" but no test verifies this
   - Add serialization/deserialization test for EffectChain

2. **Silent error handling in EffectChain::process()**
   - `let _ = effect.process(&mut buffer);` ignores errors
   - Propagate or log errors for debuggability

**Non-Blocking Suggestions**
- Add `#[must_use]` to `EffectChain::new()`
- Document effect parameter ranges in type definitions

**Test Assessment**
Good unit coverage. Missing integration test noted above.

**Positive Notes**
- Clean trait/impl separation
- Excellent doc comments
- Edge cases tested (zero gain, passthrough)

---
*Review by Gemini. You are the decision-maker.*

Two blocking issues. Want me to help address them?

User: Yes, fix both.

Claude: I'll address each issue.

[Adds persistence test]
[Fixes error handling]

Committing with attribution:

git commit -m "Add effect chain persistence integration test

Review feedback from: Gemini

Co-Authored-By: Gemini <noreply@google.com>"

git commit -m "Propagate errors from EffectChain::process()

Review feedback from: Gemini

Co-Authored-By: Gemini <noreply@google.com>"

Both issues addressed. Ready to merge with `/worktree-merge`?
```
