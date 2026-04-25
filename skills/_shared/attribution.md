# Attribution Guidelines

Shared reference for tracking and attributing contributions from AI assistants and external sources.

## When to Attribute

Attribution is intellectual honesty about collaborative work. Include attribution when a contribution **meaningfully shaped** the implementation.

### Attribute When

- Gemini review identified a bug or security issue you fixed
- Gemini review suggested an approach you adopted
- Claude assistance helped write the code (always)
- External source (Stack Overflow, blog, paper) provided the solution
- Plan contributors made design decisions you're implementing

### Don't Attribute When

- Minor fixes (typos, formatting, obvious corrections)
- Generic suggestions anyone would make
- You would have found the issue yourself anyway

**Threshold**: If you wouldn't have found the issue yourself, and fixing it meaningfully improves the code, attribute it.

## Attribution Formats

### Git Commits

Use `Co-Authored-By` trailers:

```
<commit message>

Co-Authored-By: Gemini <noreply@google.com>
Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

### For Gemini Review Feedback

When committing fixes that address Gemini review feedback:

```
Address review feedback: {brief description}

{Details of what was fixed}

Review feedback from: Gemini

Co-Authored-By: Gemini <noreply@google.com>
```

### For Claude Assistance

All substantive code written with Claude assistance:

```
Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

(Adjust model name as appropriate: `Claude Sonnet 4`, etc.)

### For External Sources

In code comments near the derived code:

```rust
// Approach adapted from: https://stackoverflow.com/a/12345678
// Algorithm: Knuth-Morris-Pratt string matching
```

For significant external influence, maintain `SOURCES.md` or `ACKNOWLEDGMENTS.md`.

## Attribution by Source

| Source | When to Attribute | Format |
|--------|-------------------|--------|
| Gemini review | Bug fixes, security patches, adopted suggestions | `Co-Authored-By: Gemini <noreply@google.com>` |
| Claude assistance | Always for substantive code | `Co-Authored-By: Claude <model> <noreply@anthropic.com>` |
| Plan contributors | When implementing their design decisions | Note in commit body |
| Stack Overflow | Derived solutions | Comment + SOURCES.md |
| Blog posts / Papers | Algorithms, patterns, approaches | Comment + SOURCES.md |

## Tracking During Implementation

When working on code:

1. **Note review feedback**: If implementing something suggested by a Gemini review, track it
2. **Check plan Contributors**: If the plan lists contributors, their work flows through
3. **Track external sources**: When you look something up, note the source

## Checkpoint vs Final Commits

- **Checkpoint commits**: No attribution needed (they get squashed)
- **Final commits**: Include all appropriate `Co-Authored-By` trailers

## Attribution Flow

Attribution flows through the workflow:

```
Plan (Contributors section)
    ↓
Implementation (track sources)
    ↓
Gemini Review (feedback adopted)
    ↓
Final Commits (Co-Authored-By trailers)
```

If a plan incorporated Gemini feedback (check Contributors section), and you're implementing that part, the attribution carries through.

## Follow-Up Tickets

When creating tickets based on review feedback:

```markdown
**Origin**: Identified in Gemini merge review of PR #42
```

## PR Descriptions

For significant architectural insights from reviews:

```markdown
## Review Notes

Gemini review identified {issue}. Addressed by {change}.
```
