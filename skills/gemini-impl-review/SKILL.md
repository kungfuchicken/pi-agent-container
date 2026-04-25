---
name: gemini-impl-review
description: Request an implementation plan review from Gemini as a third set of eyes. Use after drafting an impl-plan to get feedback on technical decisions, task ordering, and feasibility before advancing to READY.
argument-hint: <impl-plan-path>
allowed-tools: Read, Glob, mcp__gemini__chat
disable-model-invocation: true
---

# Gemini Implementation Plan Review

Request feedback on an implementation plan from Gemini, acting as a third set of eyes. Gemini provides critique and suggestions but does NOT make changes directly.

## Invocation

`/gemini-impl-review <impl-plan-path>`

**Arguments received**: $ARGUMENTS

---

## Purpose

Implementation plans translate design intent into concrete technical specifications. This review surfaces:

- Flawed technical decisions or unconsidered alternatives
- Missing dependencies in task ordering
- Gaps in test coverage specifications
- Questionable tradeoff resolutions
- File/module organization issues
- Acceptance criteria that aren't verifiable

**Gemini's role**: Technical reviewer and devil's advocate. It questions decisions and probes for weaknesses—it does NOT rewrite or implement.

---

## Behavior

### 1. Locate and Read the Implementation Plan

- Resolve the path (relative to `~working/plans/` or absolute)
- If no argument provided, list available impl-plans and ask which to review
- Read the entire plan content

### 2. Gather Context

Read supporting materials that inform the review:
- The parent design plan (from the `Parent Plan` field)
- Referenced architecture docs
- Existing code mentioned in the File/Module Inventory
- Project CLAUDE.md for coding conventions

### 3. Prepare Review Prompt for Gemini

Send the implementation plan to Gemini with this structured review request:

```
You are reviewing an implementation plan as a technical reviewer. Your role is to probe for weaknesses, question decisions, and identify gaps. You do NOT rewrite the plan—you provide observations and questions that improve it.

## Implementation Plan Content

{full impl-plan content}

## Parent Design Plan Summary

{key context from parent design plan if available}

## Project Conventions

{relevant excerpts from CLAUDE.md if available}

## Review Criteria

Evaluate the plan against these criteria and provide specific, actionable feedback:

### 1. Technical Decisions
- Are decisions well-justified with clear rationale?
- Are there obvious alternatives not considered?
- Do the chosen approaches align with project conventions?
- Are there decisions that seem premature or could be deferred?

### 2. Tradeoff Analysis
- Are tradeoffs explicitly stated (what's being traded)?
- Is the resolution justified given project priorities?
- Are there hidden tradeoffs not acknowledged?

### 3. Implementation Order
- Do blocking annotations reflect real dependencies?
- Are there parallelization opportunities missed?
- Is the order logical for incremental verification?
- Are there tasks that should be split or merged?

### 4. File/Module Inventory
- Does the organization follow project conventions?
- Are dependencies between modules clear?
- Are there missing files (tests, configs, docs)?
- Is the scope appropriate (not over-engineered)?

### 5. Code Patterns
- Do the example patterns look idiomatic?
- Are there potential issues with the proposed interfaces?
- Do type signatures make sense?

### 6. Test Specifications
- Is coverage appropriate for the complexity?
- Are edge cases considered?
- Are integration tests scoped correctly?
- Can the tests actually verify the stated behavior?

### 7. Acceptance Criteria
- Are all criteria boolean (clearly true/false)?
- Are they verifiable without subjective judgment?
- Do they cover the goals from the design plan?
- Are there missing criteria?

### 8. Error Handling
- Is the error handling approach consistent with project conventions?
- Are failure modes considered?
- Is the recovery strategy appropriate?

## Response Format

Provide your review in this structure:

**Technical Strengths** (2-4 points)
What's well-designed in this plan.

**Decision Challenges** (2-5 points)
Technical decisions that deserve scrutiny. For each:
- What the decision is
- Why it might be problematic
- What alternative or additional consideration is warranted

**Task Ordering Issues** (if any)
Specific problems with the implementation order.

**Coverage Gaps** (if any)
Missing tests, error handling, or acceptance criteria.

**Questions** (3-6 points)
Specific technical questions that, if answered, would strengthen the plan.

**Suggestions** (2-5 points)
Concrete improvements. Cite sections by name.

**Overall Assessment**
One paragraph: Is this plan ready for implementation, or does it need more work? Be specific about what's blocking readiness.
```

### 4. Present Gemini's Review

Display the review to the user with clear attribution:

```markdown
## Gemini Implementation Review: {plan title}

{Gemini's structured response}

---

*This review was generated by Gemini as a third-party technical perspective. Consider the feedback, but you are the decision-maker.*
```

### 5. Invite Discussion

After presenting the review:
- Ask if any points need clarification
- Offer to discuss specific technical concerns
- Remind about `/stage set ready <path>` when revisions are complete

### 6. Track Adopted Contributions

When the user decides to incorporate Gemini's feedback:

1. **Note which suggestions are being adopted** as you help revise the plan
2. **Update or add a Contributors section** to the plan:

```markdown
## Contributors

| Contributor | Contribution |
|-------------|--------------|
| {Author} | Initial draft |
| Gemini | Technical review: {brief description of adopted feedback} |
| Claude | {if applicable} |
```

3. **For commit messages**, remind the user that adopted contributions warrant attribution:
   - Minor feedback (clarifications, small fixes): No special attribution needed
   - Substantive contributions (new decisions, restructured tasks, identified technical gaps): Include `Co-Authored-By: Gemini <noreply@google.com>`

---

## Notes for Claude

When executing this skill:

1. **Read both plans**: The impl-plan AND the parent design plan for full context
2. **Include project conventions**: Gemini should know about coding standards from CLAUDE.md
3. **Read referenced code**: If the plan mentions existing files, read them for context
4. **Don't filter Gemini's response**: Present it faithfully, even if you disagree
5. **Attribution matters**: Proper attribution flows through the entire workflow:
   - Always make clear this feedback is from Gemini in the review presentation
   - When the user incorporates Gemini's suggestions, note those contributions
   - Track which specific suggestions were adopted so commit messages can include appropriate attribution (e.g., `Co-Authored-By: Gemini <noreply@google.com>`)
   - If Gemini's feedback leads to significant changes (revised decisions, reordered tasks, new test specifications), that contribution deserves explicit acknowledgment
   - Attribution is not just courtesy—it's intellectual honesty about the collaborative nature of the work
6. **Don't auto-implement suggestions**: Your role is to facilitate the review, not act on it
7. **Be available for follow-up**: Technical discussions may require iteration
8. **Suggest attribution when appropriate**: If the user adopts significant feedback from Gemini, remind them to note this for commit attribution

---

## Example Session

```
User: /gemini-impl-review draft-myapp-audio-effects-impl-plan.md

Claude: I'll request a technical review from Gemini on the Audio Effects implementation plan.

[Reads the impl-plan]
[Reads the parent design plan]
[Reads relevant sections of CLAUDE.md]
[Sends to Gemini with structured review prompt]

## Gemini Implementation Review: Audio Effects - Implementation Plan

**Technical Strengths**
- Clear dependency ordering between tasks—the blocking annotations make sense
- Good use of newtype wrappers for EffectId and ChainId, consistent with project conventions
- Test specifications cover both unit and integration scenarios appropriately

**Decision Challenges**

1. **Effect parameter storage as struct fields**
   - Decision: Parameters as typed struct fields rather than HashMap
   - Concern: The plan mentions "effects will evolve"—adding parameters requires struct changes and potentially breaking serialization
   - Consider: A hybrid approach where core parameters are struct fields but optional/experimental parameters use a typed extension map

2. **Single-threaded effect processing**
   - Decision: Process effects sequentially on audio thread
   - Concern: For complex chains, this may exceed the latency budget mentioned in the design plan
   - Consider: At minimum, document the expected chain length limit, or consider a work-stealing approach for expensive effects

**Task Ordering Issues**
- Task 4 (integration tests) depends on Task 3, but Task 3 is very broad ("Implement all effects"). Consider splitting Task 3 by effect category so integration tests can begin earlier.

**Coverage Gaps**
- No test specified for effect chain serialization/deserialization
- Missing acceptance criterion for "effect chain survives app restart"

**Questions**
- What's the maximum expected chain length? This affects whether single-threaded processing is viable.
- How are effect parameters validated? The code patterns show setters but no validation.
- Should preset loading be atomic (all-or-nothing) or partial (load what's valid)?

**Suggestions**
- Add a "Constraints" section documenting performance boundaries (max chain length, latency budget)
- Split Task 3 into 3a (time-based effects), 3b (frequency effects), 3c (dynamics effects)
- Add serialization round-trip test to Test Specifications

**Overall Assessment**
This plan is close to ready but has two blocking issues: (1) the broad Task 3 should be split for incremental verification, and (2) the serialization gap needs a test specification. The parameter storage decision is worth revisiting but isn't blocking. Address the task split and add the serialization test, then this is ready for APPROVED.

---

*This review was generated by Gemini as a third-party technical perspective. Consider the feedback, but you are the decision-maker.*

Would you like to discuss any of these points? The task splitting and serialization gap seem like quick fixes.

User: Good points. Let's split Task 3 and add the serialization test.

Claude: I'll help you make those changes. Since we're incorporating Gemini's feedback
about task ordering (from Task Ordering Issues) and the serialization test gap
(from Coverage Gaps), I'll note these as contributions.

[Makes the edits to the plan]

I've updated the plan:
- Split Task 3 into 3a, 3b, 3c with appropriate blocking annotations
- Added `test_effect_chain_serialization_roundtrip` to Test Specifications
- Added acceptance criterion: "Effect chain state persists across app restart"
- Updated the Contributors section:

| Contributor | Contribution |
|-------------|--------------|
| You | Initial draft |
| Gemini | Technical review: task ordering improvement, serialization test gap |

When you commit these changes:

    git commit -m "Refine audio effects impl-plan per technical review

    Split broad implementation task for incremental verification.
    Add serialization round-trip test specification.

    Co-Authored-By: Gemini <noreply@google.com>"

The parameter storage decision challenge is noted but not blocking—you can revisit
it during implementation if the "effects will evolve" concern materializes.

Ready for `/stage set ready`?
```
