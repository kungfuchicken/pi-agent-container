---
name: github-issue
description: Generate a properly formatted GitHub Issue following OSS program standards. Auto-suggests labels, extracts acceptance criteria, and optionally creates the issue via GitHub API.
argument-hint: <description of work needed> [--repo <project>]
allowed-tools: AskUserQuestion, Bash, Read, Glob, Grep
---

# GitHub Issue Generator

Generate properly formatted GitHub Issues following your organization standards.

## Invocation

`/github-issue <natural language description> [--repo <project>]`

**Description**: Describe what needs to be done in natural language. The skill will extract:
- Appropriate label category
- Clear, concise title
- Outcome-focused description
- Acceptance criteria

**Repository**: Optional. If provided, the issue can be created directly via `gh` CLI.

**Examples**:
```bash
/github-issue Add a logout button to the user profile page so users can sign out
/github-issue --repo webapp Fix the bug where API returns 500 when username is empty
/github-issue The system shall validate email addresses before saving to database
```

**Arguments received**: $ARGUMENTS

---

## Execution Steps

### Step 1: Parse Input

Extract key information from the natural language description:
1. **Identify the type of work**: Feature, Bug, Improvement, Documentation, etc.
2. **Determine appropriate label**: `[FEATURE]`, `[BUG]`, `[API]`, `[UI]`, `[DOCS]`, `[INFRA]`, `[TEST]`, `[REFACTOR]`
3. **Extract the core action/outcome**

### Step 2: Generate Issue Structure

Create the formatted issue following this template:

```markdown
# [LABEL] Clear Title

## Description
[Single sentence in one of these formats:]
- User story: "As a [role], I need [capability] so that [benefit]"
- Behavioral: "Given [context], when [action], then [outcome]"
- System story: "The system shall [behavior]"

## Acceptance Criteria
- [ ] [Outcome statement - describes end state, TRUE/FALSE evaluable]
- [ ] [Another outcome statement]
  - [ ] [Sub-criterion if hierarchical grouping needed]

## Notes
[Optional: Additional context, links to docs/examples, implementation suggestions]

## Testing Notes
[Optional: Suggestions for automated testing approaches]
```

**Guidelines for generation**:
- **Title**: Short (under 70 chars), action-oriented
- **Label**: Choose based on primary work type
- **Description**:
  - Use "As a..." for user-facing features (roles: user, admin, developer)
  - Use "Given/when/then" for behavioral specifications
  - Use "The system shall..." for backend processes/components
  - Avoid conjunctions ("and", "then") that suggest multiple issues
- **Acceptance Criteria**:
  - Use GitHub-flavored Markdown checkboxes: `- [ ]` (dash, space, bracket, space, bracket)
  - Outcome-focused, NOT task lists
  - Should describe WHAT to achieve, not HOW
  - TRUE/FALSE evaluable statements
  - Group related criteria hierarchically with indentation
  - Include negative criteria if relevant ("should NOT...")
  - Omit criteria that apply to all work (those go in repo docs)
- **Notes**: Only include if there's genuinely useful context
- **Testing Notes**: Only include if you can suggest specific testing approaches

### Step 3: Present for Review

Display the generated issue and ask:
```markdown
## Generated GitHub Issue

[full formatted issue text]

---

**Review the issue above.** Would you like to:
1. Create it now
2. Copy to clipboard for manual creation
3. Revise the issue
```

### Step 4: Resolve Repository

Determine the target repository using this precedence:

1. **`--repo` flag**: If explicitly provided
2. **Current directory**: Check if current directory is a git repo:
   ```bash
   git remote get-url origin
   ```
   Extract org/repo from the URL
3. **Plan context**: If working from a plan file, check for repo references in:
   - Plan frontmatter (repository field, GitHub URLs)
   - Project structure references
   - File paths mentioned in the plan
   - **Note**: Extract repo info from plan, but never reference the plan file in the issue itself
4. **Ask user**: If unable to resolve, ask which repository

### Step 5: Check for Duplicates

Before creating, search for potential duplicate issues:

1. **Extract search terms** from the title (remove label, get key nouns/verbs)

2. **Search open issues**:
   ```bash
   gh issue list --repo <org/repo> \
     --search "is:issue is:open <search-terms>" \
     --limit 10 \
     --json number,title,url,state
   ```

3. **Analyze results**:
   - Compare titles for similarity (semantic matching, not just exact)
   - Look for keyword overlap in search terms
   - Identify potential duplicates

4. **If potential duplicates found**, present them:
   ```markdown
   ⚠️  **Potential duplicate issues found:**

   1. #42: Add logout functionality to profile page
      https://github.com/example-org/webapp/issues/42
      Status: Open

   2. #38: User logout feature
      https://github.com/example-org/webapp/issues/38
      Status: Open

   **Options:**
   1. Create anyway (this is unique work)
   2. Update existing issue #42 (add details/refinements)
   3. Cancel (issue already exists)
   ```

5. **If user chooses to update**:

   a. **Analyze the existing issue** (fetch it to see current content):
      ```bash
      gh issue view <number> --repo <org/repo> --json title,body
      ```

   b. **Recommend an approach** based on the relationship between old and new:
      - **Comment** (recommended when): New info supplements/extends the existing issue (additional AC, testing notes, implementation ideas, related use cases)
      - **Edit** (recommended when): New info corrects/replaces the existing description or AC, or the existing issue is incomplete/unclear

   c. **Present recommendation**:
      ```markdown
      **Suggested approach: Add comment (Recommended)**

      Rationale: Your new acceptance criteria extend the existing issue without contradicting it. A comment preserves the discussion history and notifies watchers.

      **Options:**
      1. Add comment with new details (Recommended)
      2. Edit the issue description to incorporate new details
      3. Cancel
      ```

   d. **Execute the chosen approach**:
      - **Comment**: `gh issue comment <number> --body "..."`
      - **Edit**: `gh issue edit <number> --body "..."` (append or replace based on context)

   e. **Report outcome** with issue URL

6. **If no duplicates or user confirms creation**, proceed to Step 6

### Step 6: Create the Issue

1. **Verify `gh` CLI is available** (assume installed per user note)

2. **Create the issue**:
   ```bash
   gh issue create --repo <org/repo> \
     --title "[LABEL] Title" \
     --body "$(cat <<'EOF'
   ## Description
   ...
   EOF
   )"
   ```

3. **Report the issue URL** returned by `gh`

4. **If working from a plan file**, offer to update the plan:
   ```markdown
   ✓ Issue created: https://github.com/example-org/webapp/issues/42

   Would you like me to add this issue URL to the plan file for tracking?
   ```

   If user agrees, add a reference in the plan (typically in a "Related Issues" section or inline where relevant)

---

## Label Selection Guide

Auto-suggest labels based on these patterns:

| Pattern in Description | Suggested Label | Example |
|------------------------|-----------------|---------|
| "fix bug", "error", "crash", "broken" | `[BUG]` | Fix crash when submitting empty form |
| "add feature", "new capability", "implement" | `[FEATURE]` | Add export to CSV functionality |
| "API", "endpoint", "REST", "GraphQL" | `[API]` | Create endpoint for user preferences |
| "UI", "button", "page", "interface", "display" | `[UI]` | Add logout button to profile page |
| "documentation", "docs", "README", "guide" | `[DOCS]` | Document authentication flow |
| "improve", "optimize", "enhance", "refactor" | `[REFACTOR]` | Optimize database query performance |
| "test", "testing", "coverage" | `[TEST]` | Add integration tests for auth flow |
| "infrastructure", "CI/CD", "deploy", "build" | `[INFRA]` | Set up automated deployment pipeline |
| "security", "vulnerability", "auth" | `[SECURITY]` | Fix SQL injection in search endpoint |
| "performance", "slow", "latency" | `[PERF]` | Reduce page load time |

**Multiple labels**: If work clearly spans categories, suggest both (e.g., `[API][SECURITY]`)

---

## Acceptance Criteria Extraction

**IMPORTANT**: Always use GitHub-flavored Markdown checkbox syntax: `- [ ]` (not `* [ ]` or `- []`)

When generating AC from natural language, look for:

**Explicit outcomes** in the description:
- "users can..." → `[ ] Users can [action]`
- "should display..." → `[ ] System displays [thing] when [condition]`
- "must validate..." → `[ ] System validates [input] before [action]`

**Implied outcomes** based on work type:
- Bug fixes: `[ ] Bug no longer occurs when [original trigger]`
- New features: `[ ] Users can [core capability]`, `[ ] Feature is accessible via [entry point]`
- API work: `[ ] Endpoint returns [expected response] for [input]`, `[ ] API validates [input constraints]`

**Quality criteria** (adapt to context):
- `[ ] Changes include unit tests with >80% coverage`
- `[ ] Documentation is updated to reflect changes`
- `[ ] No new linter warnings introduced`

**Negative criteria** (what to avoid):
- `[ ] Existing functionality is not broken`
- `[ ] Performance does not degrade for [scenario]`

---

## Notes for Claude

1. **Be concise**: Avoid verbose issue descriptions. One sentence is the goal.

2. **Avoid over-specifying**: Let developers choose the implementation approach unless constraints are critical.

3. **Extract, don't invent**: Base the issue on what the user described. If critical information is missing, ask rather than assuming.

4. **Plan files are local, issues are public**: When generating issues from plan context:
   - **Extract and replicate** content from the plan into the issue
   - **Never reference** the plan file directly (e.g., "See design-plan.md")
   - Plans can link to issues (one-way: plan → issue URL)
   - Issues must be self-contained for team visibility
   - After creating an issue, offer to add the issue URL to the plan file

4. **Hierarchical AC**: Group related criteria under parent items:
   ```markdown
   - [ ] Authentication system works correctly
     - [ ] Users can log in with valid credentials
     - [ ] Users cannot log in with invalid credentials
     - [ ] Session expires after 24 hours
   ```

5. **TRUE/FALSE test**: Every AC should be evaluable as true or false. Avoid vague statements like "improve performance" (how much?). Use "Page loads in under 2 seconds" instead.

6. **Repo resolution**: Auto-detect repository from:
   - `--repo` flag if provided
   - Current directory if it's a git repo (`git remote get-url origin`)
   - Plan context if working from a plan file (check frontmatter, file paths, project references)
   - Workspace-level CLAUDE.md context for project location patterns
   - Ask user only if unable to resolve

7. **Duplicate detection**: Always search for potential duplicates before creating. Use semantic matching on titles, not just exact string comparison.

8. **Update vs Create**: If duplicates found, offer to update existing issue with additional details instead of creating a new one.

9. **Don't create automatically**: Always show the issue first for review, check for duplicates, and confirm before creating via `gh`.

10. **Handle `gh` failures gracefully**: If auth fails or other errors occur, provide the formatted text for manual creation.

---

## Example Session

```
User: /github-issue Add a logout button to the user profile page

Claude: I'll generate a GitHub Issue for that work.

## Generated GitHub Issue

# [UI] Add logout button to user profile

## Description
As a user, I need a logout button on my profile page so that I can securely end my session.

## Acceptance Criteria
- [ ] Logout button is visible on the user profile page
- [ ] Clicking the logout button ends the user session
- [ ] User is redirected to the home page after logout
- [ ] Session cookies are cleared on logout

---

**Review the issue above.** Would you like to:
1. Create it now (requires `gh` CLI and --repo)
2. Copy to clipboard for manual creation
3. Revise the issue

User: Create it

Claude: I'll create the issue in the webapp repository.

Resolving repository from current directory... found: `example-org/webapp`

Checking for duplicate issues...

⚠️  **Potential duplicate found:**

#38: Add user logout feature
https://github.com/example-org/webapp/issues/38
Status: Open

This appears to be similar work. Would you like to:
1. Create anyway (different scope/approach)
2. Update issue #38 with additional details
3. Cancel

User: Create anyway, #38 is about the header logout, this is for the profile page

Claude: Got it, creating new issue...

✓ Issue created: https://github.com/example-org/webapp/issues/42

Done! Issue #42 is ready for your team.
```

---

## Example Session 2: Bug Fix

```
User: /github-issue --repo simulator Fix the crash when username field is submitted empty

Claude: I'll generate a GitHub Issue for that bug fix.

## Generated GitHub Issue

# [BUG] Fix crash on empty username submission

## Description
Given a user submits the login form with an empty username field, when the form is processed, then the application should validate the input gracefully instead of crashing.

## Acceptance Criteria
- [ ] Application does not crash when username field is empty
- [ ] User receives a clear error message indicating username is required
- [ ] Form submission is prevented until username is provided
- [ ] No stack trace is exposed to the user

## Notes
Current behavior: Application throws NullPointerException when username is null/empty. Expected behavior: Input validation catches empty username before processing.

## Testing Notes
- Add unit test for empty string username
- Add unit test for null username
- Add integration test for form submission with missing required fields

---

**Review the issue above.** Would you like to:
1. Create it now
2. Copy to clipboard for manual creation
3. Revise the issue

User: Looks good, create it

Claude: Resolving repository from current directory... found: `example-org/simulator`

Checking for duplicate issues... no duplicates found.

Creating issue...

✓ Issue created: https://github.com/example-org/simulator/issues/73

Done! Issue #73 is ready for your team.
```

---

## Example Session 3: Duplicate Handling with Update

```
User: /github-issue The API should validate email format before saving user profiles

Claude: I'll generate a GitHub Issue for that work.

## Generated GitHub Issue

# [API] Validate email format before saving profiles

## Description
The system shall validate email address format before saving user profile data to prevent invalid entries in the database.

## Acceptance Criteria
- [ ] Email addresses are validated against RFC 5322 format
- [ ] Invalid email addresses are rejected with clear error message
- [ ] Validation occurs before database write operation
- [ ] Existing profiles with invalid emails are not affected

## Testing Notes
- Test valid email formats: user@example.com, user+tag@domain.co.uk
- Test invalid formats: missing @, multiple @, invalid characters
- Test edge cases: very long emails, international characters

---

**Review the issue above.** Would you like to:
1. Create it now
2. Copy to clipboard for manual creation
3. Revise the issue

User: Create it

Claude: Resolving repository from current directory... found: `example-org/webapp`

Checking for duplicate issues...

⚠️  **Potential duplicate found:**

#67: Add email validation to user registration
https://github.com/example-org/webapp/issues/67
Status: Open

This appears to be related work. Would you like to:
1. Create anyway (different scope/approach)
2. Update issue #67 with additional details
3. Cancel

User: Update it

Claude: Fetching existing issue #67...

Existing issue covers email validation in the registration flow. Your new details extend this to profile updates, which is related but distinct scope.

**Suggested approach: Add comment (Recommended)**

Rationale: Your acceptance criteria and testing notes are complementary to the existing issue. A comment preserves the original context while expanding the scope to include profile updates, and notifies anyone watching the issue.

**Options:**
1. Add comment with new details (Recommended)
2. Edit the issue description to incorporate new details
3. Cancel

User: Add comment

Claude: Adding comment to issue #67...

✓ Comment added: https://github.com/example-org/webapp/issues/67#issuecomment-xxxxx

Comment content:
---
## Additional Scope: Profile Updates

Email validation should also apply when users update their profiles, not just during registration.

### Additional Acceptance Criteria
- [ ] Email addresses are validated against RFC 5322 format in profile updates
- [ ] Invalid email addresses are rejected with clear error message
- [ ] Validation occurs before database write operation
- [ ] Existing profiles with invalid emails are not affected

### Testing Notes
- Test valid email formats: user@example.com, user+tag@domain.co.uk
- Test invalid formats: missing @, multiple @, invalid characters
- Test edge cases: very long emails, international characters
---

Done! Issue #67 has been updated with the additional scope.
```
```
