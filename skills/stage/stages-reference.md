# Plan Lifecycle Stages Reference

## Stage Definitions

| Stage | Meaning | File State | Location |
|-------|---------|------------|----------|
| **DRAFT** | Plan is being actively developed. May have gaps, open questions, or placeholder sections. Not yet coherent enough for review. | `draft-` prefix | `~working/plans/` |
| **READY** | Plan is complete and coherent. All sections filled in, questions resolved or explicitly deferred. Ready for approval decision. | `draft-` prefix | `~working/plans/` |
| **APPROVED** | Consciously committed to implementation. Resources allocated, other options foreclosed. | No prefix | `~working/plans/` |
| **COMPLETED** | All work items done. Plan is now historical reference. | No prefix | `~working/plans/completed/` |

## Transition Rules

```
DRAFT ──────────────────────────────────────────────────────> READY
         Update lifecycle table date
         No file rename

READY ──────────────────────────────────────────────────────> APPROVED
         Update lifecycle table date
         Update Status header
         Remove draft- prefix from filename

APPROVED ───────────────────────────────────────────────────> COMPLETED
         Update lifecycle table date
         Update Status header to "COMPLETED"
         Move file to completed/ subdirectory
         Update parent plan references
```

## The READY → APPROVED Decision

Plans can sit at READY indefinitely. The distinction:

- **READY** = "Shovel-ready" — if capacity appeared, this could be implemented
- **APPROVED** = "Shovel in ground" — this is happening next

The pause between READY and APPROVED is for:
- Sleeping on it / letting it marinate
- Validating the approach (rubber duck, AI critique, peer review)
- Deciding this is the right use of limited capacity
- Accepting the opportunity cost of not doing something else

## Scaling to Teams

| Context | Who Approves |
|---------|--------------|
| Solo | Self, after reflection |
| Small team | Lightweight alignment meeting |
| Open source | Maintainer review or RFC-style input |

## Lifecycle Table Template

```markdown
## Lifecycle

| Stage | Date | Notes |
|-------|------|-------|
| DRAFT | YYYY-MM-DD | Initial plan created |
| READY | — | |
| APPROVED | — | |
| COMPLETED | — | |
```

Update dates as the plan progresses. Use "—" for stages not yet reached.
