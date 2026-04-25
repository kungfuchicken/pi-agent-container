---
name: gemini-code-review
description: Request a code review from Gemini as a third set of eyes. Use after writing code to get feedback on quality, bugs, and consistency before committing. Supports file paths, git diffs, or staged changes.
argument-hint: [--repo <project>] <file-path|--staged|--diff [ref]>
allowed-tools: Read, Glob, Grep, Bash, Task, mcp__gemini__chat, AskUserQuestion
---

# Gemini Code Review

Request feedback on code changes from Gemini, acting as a third set of eyes before committing.

## Invocation

`/gemini-code-review [--repo <project>] <target>`

**Repository selection**: See [repo resolution rules](../_shared/repo-resolution.md).

**Target**:
- **File path(s)**: `src/foo.rs src/bar.rs`
- **`--staged`**: Review staged changes (git diff --cached)
- **`--diff`**: Review unstaged changes (git diff)
- **`--diff <ref>`**: Review changes since ref (git diff <ref>)
- **`--pr`**: Review current PR diff

**Examples**:
```bash
/gemini-code-review --staged
/gemini-code-review --repo myapp --staged
/gemini-code-review --repo tracker src/lib.rs
```

**Arguments received**: $ARGUMENTS

---

## Architecture: Phased Execution

This skill uses a **phased approach** to manage context efficiently:

```
Phase 1: Scope (main context)     ─► Lightweight stats, user confirms
Phase 2: Review (Task agent)      ─► Full code + Gemini call (isolated)
Phase 3: Present & Act (main)     ─► Show findings, help fix issues
```

**Why phases?** The full diff/code + Gemini prompt + response consumes significant context. Running Phase 2 in a Task agent isolates that cost, keeping the main session lean for follow-up fixes.

---

## Phase 1: Scope & Confirm

**Goal**: Gather lightweight metadata, confirm scope before heavy lifting.

### 1.1 Resolve Repository

If `--repo` provided, resolve per [repo resolution rules](../_shared/repo-resolution.md).
Report resolved path to user.

### 1.2 Gather Metadata (Lightweight)

For diffs:
```bash
# Stats only, not full diff
git diff --stat [--cached]
```

For files:
```bash
# Line counts only
wc -l <files>
```

### 1.3 Present Scope Summary

```markdown
## Review Scope

**Repository**: `acme/myapp/`
**Target**: Staged changes
**Files**: 3
**Lines**: +47/-12

**Files affected**:
- src/client.rs (modified)
- src/backoff.rs (new)
- tests/client_test.rs (modified)

Proceed with Gemini review?
```

### 1.4 User Confirms

Wait for confirmation before Phase 2. This allows:
- Aborting if scope is wrong
- Adjusting target if needed
- Avoiding wasted context on incorrect reviews

---

## Phase 2: Gemini Review (Task Agent)

**Goal**: Run the review in isolated context.

Launch a Task agent with `subagent_type: general-purpose` to:

1. **Gather full context**:
   - Complete diff or file contents
   - Surrounding code for context (if reviewing diff)
   - Project CLAUDE.md (conventions)

2. **Call Gemini** with the review prompt (see Appendix A)

3. **Return structured findings** only—not the raw code or full prompt

### Task Agent Prompt Template

```
You are gathering context and requesting a Gemini code review.

**Repository**: {resolved_path}
**Target**: {staged changes / files / diff}

## Steps

1. Get the code to review:
   {git diff command or file read}

2. Read surrounding context for affected files

3. Read project CLAUDE.md for conventions

4. Call Gemini with the review prompt (Appendix A format)

5. Return ONLY Gemini's structured response. Do not include:
   - The full diff/code
   - The prompt you sent
   - Your own commentary

Format your final output as:
---BEGIN REVIEW---
{Gemini's response verbatim}
---END REVIEW---
```

---

## Phase 3: Present & Act

**Goal**: Show findings, help user address issues.

### 3.1 Present Review

Extract Gemini's response from the Task agent and display:

```markdown
## Gemini Code Review

**Target**: Staged changes (3 files, +47/-12 lines)

{Gemini's structured response}

---
*Review by Gemini. You are the decision-maker.*
```

### 3.2 Facilitate Fixes

After presenting the review:
- Ask if any issues need clarification
- Offer to help fix specific issues
- Don't auto-fix—wait for direction

### 3.3 Track Attribution

When fixing issues from the review, remind about attribution per [attribution guidelines](../_shared/attribution.md).

---

## Notes for Claude

### Phase 1 (Main Context)
1. **Keep it light**: Only gather stats, not full diffs/files
2. **Resolve --repo first**: Report the resolved path
3. **Confirm before Phase 2**: User must agree to proceed

### Phase 2 (Task Agent)
4. **Use Task tool**: Launch with `subagent_type: general-purpose`
5. **Structured return**: Agent returns only Gemini's response
6. **Include context**: Agent should read surrounding code for diffs

### Phase 3 (Main Context)
7. **Present faithfully**: Don't filter Gemini's response
8. **Don't auto-fix**: Present review, wait for direction
9. **Attribution on fixes**: See [attribution guidelines](../_shared/attribution.md)

---

## Appendix A: Gemini Review Prompt

The Task agent sends this to Gemini:

```
You are reviewing code as an experienced developer. Identify issues and suggest improvements. You do NOT rewrite code—you provide observations.

## Code Under Review

{code content or diff}

## File Context

{surrounding code if reviewing a diff}

## Project Conventions

{CLAUDE.md excerpts}

## Review Criteria

Evaluate for substantive issues (not style nitpicks):

1. **Correctness**: Logic errors, edge cases, error handling, race conditions
2. **Clarity**: Self-documenting, descriptive names, explained complexity
3. **Consistency**: Follows project conventions, matches surrounding code
4. **Completeness**: Test coverage, documentation updates
5. **Performance**: Only if actually problematic
6. **Security**: Input validation, injection risks, secrets handling

## Response Format

**Summary**: One sentence on what this code does and overall quality.

**Issues** (if any):
For each: Severity (Critical/Important/Minor), Location, Issue, Suggestion

**Questions** (if any): Clarifying questions about intent.

**Observations** (if any): Worth noting but not wrong.

**Positive Notes**: 1-2 things done well.
```

---

## Example Session

```
User: /gemini-code-review --repo myapp --staged

Claude: I'll set up a code review for your staged changes.

Resolving repository... found: `acme/myapp/`

## Review Scope

**Repository**: `acme/myapp/`
**Target**: Staged changes
**Files**: 3
**Lines**: +47/-12

**Files affected**:
- src/client.rs (modified)
- src/backoff.rs (new)
- tests/client_test.rs (modified)

Proceed with Gemini review?

User: yes

Claude: Launching review agent...

[Task agent runs Phase 2 in isolated context]

## Gemini Code Review

**Target**: Staged changes (3 files, +47/-12 lines)

**Summary**
Adds rate limiting to the API client with exponential backoff. Solid implementation with one important overflow issue.

**Issues**

1. **Severity**: Important
   **Location**: `src/client.rs:142`
   **Issue**: Exponential backoff can overflow for retry counts > 6
   **Suggestion**: Cap at maximum delay (e.g., 30 seconds)

2. **Severity**: Minor
   **Location**: `src/client.rs:156`
   **Issue**: Error message doesn't include wait duration
   **Suggestion**: Include calculated delay for debugging

**Questions**
- Is `max_retries = 10` intentional? That's potentially a very long wait.

**Positive Notes**
- Good use of existing `Backoff` trait
- Solid test coverage for happy path

---
*Review by Gemini. You are the decision-maker.*

The overflow issue is worth fixing before committing. Want me to help?

User: Yes, cap it at 30 seconds.

Claude: I'll add the cap.

[Makes the fix]

Done. When committing, include attribution since this addresses Gemini's feedback:

git commit -m "Add rate limiting to API client

Implements exponential backoff with jitter. Caps maximum
backoff at 30 seconds to prevent overflow.

Co-Authored-By: Gemini <noreply@google.com>"
```
