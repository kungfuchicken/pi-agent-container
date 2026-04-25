---
name: impl-planning
description: Create an implementation plan from an approved design plan. Extracts glossary/decisions, analyzes tradeoffs, and produces a concrete implementation specification. Use when a design plan needs detailed technical breakdown before implementation.
argument-hint: <design-plan-path> [--phase <phase-name>]
allowed-tools: Read, Write, Glob, AskUserQuestion
---

# Implementation Planning Skill

Create a detailed implementation plan from an approved design plan. Implementation plans translate "what and why" into "how exactly"—specific files, code patterns, task ordering, and verification steps.

## Invocation

`/impl-planning <design-plan-path> [--phase <phase-name>]`

**Arguments received**: $ARGUMENTS

---

## Purpose

Design plans establish intent and high-level approach. Implementation plans provide:

- Concrete file/module inventory
- Sequenced work items with dependencies
- Technical decisions with tradeoff analysis
- Test specifications and acceptance criteria
- Verification steps

This separation allows design plans to remain stable while implementation details evolve.

---

## Behavior

### 1. Locate and Read the Design Plan

- Resolve the path (relative to `~working/plans/` or absolute)
- Read the entire design plan
- Verify it's at least READY (warn if still DRAFT)

**Extract from design plan**:
- Title and context
- Goals and non-goals
- Glossary/ubiquitous language (inherit directly)
- Anti-corruption layer (inherit, may refine)
- High-level work items (to be decomposed)
- Any confirmed decisions

### 2. Identify Technical Decisions Needed

Analyze the design plan for:
- Gaps that require implementation-level decisions
- Choices between approaches (data structures, algorithms, patterns)
- Performance/security/quality tradeoffs

### 3. Interactive Tradeoff Analysis

For each decision with equally viable paths that have quality implications:

**Ask the user**:
> "The design plan specifies {goal}. I see two viable approaches:
>
> **Option A**: {description}
> - Pros: {pros}
> - Cons: {cons}
>
> **Option B**: {description}
> - Pros: {pros}
> - Cons: {cons}
>
> Which aligns better with your priorities for this component?"

Document the decision and rationale in the plan.

**When NOT to ask**:
- One option is clearly superior
- The tradeoff is trivial (no meaningful quality impact)
- The design plan already specifies the approach

### 4. Generate the Implementation Plan

Create the file with the structure defined below.

### 5. Report and Invite Refinement

- Show the generated plan summary
- Invite discussion before finalizing
- Remind about `/stage` for lifecycle advancement

---

## File Naming

`draft-{product}-{domain}-{summary}-impl-plan.md`

Or with phase:
`draft-{product}-{domain}-{summary}-phase-{phase}-impl-plan.md`

Derive product/domain/summary from the parent design plan name.

**Examples**:
- Design: `myapp-audio-effects-plan.md`
- Impl: `draft-myapp-audio-effects-impl-plan.md`

- Design: `myapp-canvas-layer-system-plan.md` (multi-phase)
- Impl: `draft-myapp-canvas-layer-system-phase-1a-impl-plan.md`

---

## Implementation Plan Template

```markdown
# {Title} - Implementation Plan

**Parent Plan**: `{path-to-design-plan}`
**Phase**: {phase name, or "N/A" if not phased}
**Status**: DRAFT

## Lifecycle

| Stage | Date | Notes |
|-------|------|-------|
| DRAFT | {today} | Initial implementation plan |
| READY | — | |
| APPROVED | — | |
| COMPLETED | — | |

---

## Inherited Context

### Goals (from design plan)

{Copy or summarize the goals from the parent plan}

### Glossary

{Inherit the glossary/ubiquitous language from the design plan verbatim}

| Term | Classification | Definition |
|------|----------------|------------|
| ... | Entity/Value Object/Aggregate/Service | ... |

### Anti-Corruption Layer

{Inherit from design plan, refine if implementation reveals additional boundaries}

| Concept | What it might seem like | What it actually is |
|---------|------------------------|---------------------|
| ... | ... | ... |

---

## Technical Decisions

### Confirmed Decisions

{Decisions inherited from design plan, with any implementation-level refinements}

### Decision: {Decision Title}

**Problem**: {What needs to be decided}

**Options Considered**:
1. {Option A}: {description}
2. {Option B}: {description}

**Decision**: {Chosen option}

**Rationale**: {Why this option, including tradeoff analysis}

**Implications**: {What this means for implementation}

---

## Tradeoff Analysis

### {Tradeoff Title}

**Problem**: {The tension or competing concerns}

**Tradeoff**: {What we're trading—e.g., "memory for speed", "flexibility for simplicity"}

**Resolution**: {How we resolved it}

**Rationale**: {Why this resolution fits the project's priorities}

---

## File/Module Inventory

### New Files

| File | Purpose | Dependencies |
|------|---------|--------------|
| `src/foo/bar.rs` | {what it does} | `crate::baz` |

### Modified Files

| File | Changes |
|------|---------|
| `src/lib.rs` | Add `mod foo;` |

---

## Implementation Order

Work items in dependency order. Blocking annotations indicate what must complete first.

- [ ] **1. {Task title}**
  {Brief description}

- [ ] **2. {Task title}** *(blocked by: 1)*
  {Brief description}

- [ ] **3. {Task title}** *(blocked by: 1)*
  {Brief description}

- [ ] **4. {Task title}** *(blocked by: 2, 3)*
  {Brief description}

---

## Code Patterns

{Example structs, type signatures, key interfaces. Show the shape of the code.}

```rust
/// Brief doc comment
pub struct Foo {
    // fields
}

impl Foo {
    pub fn new() -> Self { ... }
}
```

---

## Error Handling Approach

{How errors flow through this component. Align with project conventions.}

- **Internal errors**: {approach}
- **User-facing errors**: {approach}
- **Recovery strategy**: {fail-fast, retry, graceful degradation}

---

## Configuration

{If applicable. Otherwise omit this section.}

```yaml
# Example configuration
setting_name: value
```

---

## Test Specifications

### Unit Tests

| Test | Verifies |
|------|----------|
| `test_foo_creates_bar` | Foo correctly creates Bar when... |

### Integration Tests

| Test | Verifies |
|------|----------|
| `test_end_to_end_flow` | Complete flow from... to... |

### Coverage Expectations

{Target coverage, areas that may be excluded with justification}

---

## Performance Targets

{If applicable. Otherwise omit this section.}

| Metric | Target | Measurement |
|--------|--------|-------------|
| {metric} | {target} | {how measured} |

---

## Acceptance Criteria

{Boolean checklist. These should be verifiable.}

- [ ] {Criterion 1}
- [ ] {Criterion 2}
- [ ] {Criterion 3}

---

## Verification Steps

{Concrete commands to confirm the implementation works}

```bash
# Run tests
cargo test --package {package}

# Check types
cargo check

# Verify behavior
{manual verification steps if needed}
```

---

## Post-Implementation

{Fill in after implementation is complete}

### Implementation Notes

**Completed**: {date}
**Implementer**: {human, AI, or collaborative}

{Summary of what was built}

### Variations from Plan

{Any divergences from the plan, with rationale}

| Planned | Actual | Rationale |
|---------|--------|-----------|
| ... | ... | ... |

### Files Created

{Actual file inventory after implementation}

```
src/
├── foo/
│   ├── mod.rs
│   └── bar.rs
```
```

---

## Section Optionality

Based on complexity, some sections may be omitted:

| Section | When to include |
|---------|-----------------|
| Configuration | Only if component has config |
| Performance Targets | Only if performance-sensitive |
| Error Handling Approach | Always for new modules; omit for small changes |
| Code Patterns | Always helpful; can be brief for simple changes |
| Tradeoff Analysis | Only when meaningful tradeoffs exist |

When omitting, don't leave empty sections—remove them entirely.

---

## Notes for Claude

When executing this skill:

1. **Read the design plan thoroughly** before starting
2. **Inherit, don't reinvent**: Glossary and anti-corruption layer come from the design plan
3. **Ask about tradeoffs**: When there are equally viable paths with quality implications, ask
4. **Don't over-ask**: If one option is clearly better, just document the decision
5. **Blocking annotations matter**: Implementation order should reflect real dependencies
6. **Code patterns are examples**: Show the shape, not the full implementation
7. **Acceptance criteria are boolean**: Each should be clearly verifiable as true/false
8. **Invite discussion**: Present the plan and wait for feedback before considering it complete

---

## Example Session

```
User: /impl-planning myapp-audio-effects-plan.md

Claude: I'll create an implementation plan from the Audio Effects design plan.

[Reads the design plan]

The design plan specifies an AudioEffect trait with chainable effects. I have a
few technical decisions to work through:

**Decision: Effect parameter storage**

The design plan says effects have configurable parameters but doesn't specify
storage strategy. I see two viable approaches:

**Option A**: Parameters as struct fields
- Pros: Simple, type-safe, good IDE support
- Cons: Adding parameters requires struct changes

**Option B**: Parameters as HashMap<String, ParameterValue>
- Pros: Flexible, effects can define arbitrary parameters
- Cons: Runtime type checking, stringly-typed

Which aligns better with your priorities? The effect set is likely to evolve,
so flexibility might matter—but type safety catches errors at compile time.

User: Option A. We'll define a clear set of effects and their parameters.

Claude: Noted. I'll document that decision with the rationale.

[Continues with other decisions if needed]

I've created the implementation plan at:
`~working/plans/draft-myapp-audio-effects-impl-plan.md`

**Summary**:
- 4 new files, 2 modified files
- 6 work items in dependency order
- 3 key decisions documented
- 8 unit tests, 2 integration tests specified

Would you like to review any section in detail, or shall I present the full plan?
```
