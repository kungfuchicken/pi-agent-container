---
name: planning
description: Collaborative planning through dialogue. Explores the problem space, surfaces assumptions, and refines understanding before creating a plan document. The act of planning matters more than the plan artifact.
argument-hint: [product] [topic] | --scaffold [product] [domain] [summary]
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion
---

# Planning Skill

Engage in collaborative dialogue to explore a problem space before committing to a plan document. **The plan is less important than the act of planning.**

## Invocation

- `/planning [topic]` — Begin discursive exploration (default)
- `/planning [product] [topic]` — Explore with product context established
- `/planning --scaffold [product] [domain] [summary]` — Skip dialogue, create plan file immediately

**Arguments received**: $ARGUMENTS

---

## Philosophy

Planning is a collaborative act of discovery, not a bureaucratic form-filling exercise. This skill prioritizes:

1. **Dialogue over documentation** — The conversation itself creates alignment
2. **Questions over answers** — Assumptions surfaced early save rework later
3. **Options over decisions** — Present choices with tradeoffs before committing
4. **Checkpoints over flow** — Explicit pauses prevent premature commitment

The plan file is the *conclusion* of planning, not the activity itself.

---

## Modes

### Explore Mode (default)

When invoked without `--scaffold`, enter discursive dialogue.

**Argument parsing:**
- If a known product name is provided first (e.g., `myapp`, `tracker`, `organizer`), capture it as context and use the remainder as the topic
- If no recognized product, treat the entire argument as the topic
- When product is established upfront, skip asking for it later during file creation

**Phase 1: Understand the Territory**
- What is the user trying to accomplish?
- What triggered this need now?
- Who/what is affected?
- What does success look like?

**Phase 2: Challenge Assumptions**
- What are we taking for granted?
- What similar problems have different solutions?
- Are there constraints we haven't named?
- Is this the right problem to solve?

**Phase 3: Surface Options**
- What are the possible approaches?
- What are the tradeoffs of each?
- What do we not know yet?
- What would we need to learn?

**Phase 4: Checkpoint**
After sufficient exploration, explicitly ask:

> "I think we've explored this enough to draft a plan. Ready to create a plan file, or is there more to discuss?"

Only proceed to file creation after explicit agreement.

**Phase 5: Scaffold with Understanding**
When the user is ready:
1. Gather file metadata (product, domain, summary)
2. Create the plan file pre-populated with insights from the dialogue
3. The Context, Goals, Non-Goals, and Open Questions sections should reflect the conversation—not be empty placeholders

### Scaffold Mode (`--scaffold`)

For users who know exactly what they want:

`/planning --scaffold myapp audio real-time-effects`

1. Parse arguments: product, domain, summary
2. Create the plan file immediately with the template
3. Report the path

This mode exists for efficiency when exploration isn't needed, not as the default path.

---

## Dialogue Principles

When exploring, Claude should:

1. **Ask probing questions** — Don't accept the first framing. "What problem does this solve?" "Why now?"

2. **Challenge gently** — "Have you considered..." "What if we..." "Another way to look at this..."

3. **Synthesize and reflect back** — Periodically summarize understanding: "So if I understand correctly, you want X because Y, and the main constraints are Z. Is that right?"

4. **Present options with tradeoffs** — "We could approach this three ways: A (simple but limited), B (flexible but complex), or C (novel but risky). Which resonates?"

5. **Name what's unclear** — "I notice we haven't discussed how this interacts with X. Is that intentional?"

6. **Resist premature closure** — If the user seems to rush toward a solution, ask: "Are we confident this is the right approach, or should we explore alternatives first?"

7. **Use systems thinking** — Connect local decisions to broader context. "This choice affects not just X, but also Y and Z downstream."

---

## File Naming Convention

`draft-{product}-{domain}-{summary}-plan.md`

- All lowercase, kebab-case
- Always starts with `draft-` (DRAFT stage)
- Always ends with `-plan.md`
- Optional: `-yymmdd` suffix before `-plan.md` for time-bound tactical plans

**Examples**:
- `draft-myapp-canvas-layer-system-plan.md`
- `draft-tracker-persistence-sqlite-migration-plan.md`
- `draft-organizer-tasks-recurring-items-plan-260201.md` (time-bound)

---

## File Location

Plans are created in `~working/plans/` relative to the workspace root.

**To find the workspace**:
1. Look for `~working/plans/` in current directory
2. Walk up parent directories looking for `~working/plans/`
3. If not found, ask the user where to create it

---

## Plan Template

Create the file with this structure. **Pre-populate sections based on dialogue findings rather than leaving empty placeholders.**

```markdown
# {Title from Summary}

**Product**: {product}
**Domain**: {domain}
**Status**: DRAFT

## Lifecycle

| Stage | Date | Notes |
|-------|------|-------|
| DRAFT | {today YYYY-MM-DD} | Initial plan created |
| READY | — | |
| APPROVED | — | |
| COMPLETED | — | |

## Context

{Why is this plan needed? What problem does it solve? Pre-populate from dialogue.}

## Goals

{What does success look like? What are the specific outcomes? Pre-populate from dialogue.}

## Non-Goals

{What is explicitly out of scope? What similar-sounding things are we NOT doing? Pre-populate from dialogue—this section is especially valuable when assumptions were challenged.}

## Glossary

{Define domain terms. What vocabulary will this plan use consistently?}

| Term | Definition | Classification |
|------|------------|----------------|
| | | Entity / Value Object / Aggregate / Service |

## Design

{The proposed approach. Include diagrams where helpful. Pre-populate if approach was discussed.}

## Work Items

{Ordered list of implementation steps. These become todos during implementation.}

- [ ] Item 1
- [ ] Item 2
- [ ] Item 3

## Open Questions

{Unresolved decisions or unknowns. Pre-populate from dialogue—these are questions that emerged but weren't resolved. Resolve or explicitly defer before READY.}

## Risks & Mitigations

{What could go wrong? How do we address it? Pre-populate if risks were discussed.}

## References

{Links to related docs, prior art, external resources.}
```

---

## After Creation

1. Report the full path to the created file
2. Note which sections were pre-populated vs. need attention
3. Remind user of next steps:
   - Review and refine the pre-populated sections
   - Fill in remaining sections (Design, Work Items, etc.)
   - Use `/stage set ready <path>` when plan is complete
   - Use `/stage set approved <path>` after reflection and approval decision

---

## Notes for Claude

When executing this skill:

1. **Default to dialogue** — Unless `--scaffold` is specified, start with exploration
2. **Don't rush to the file** — The conversation is the value; the file is just a record
3. **Ask before creating** — Always checkpoint before transitioning to file creation
4. **Pre-populate meaningfully** — Capture insights from dialogue, don't create empty scaffolds
5. **Validate inputs**: kebab-case the summary, lowercase everything
6. **Check for existing plans**: If a similar-named file exists, warn before creating
7. **Use today's date** for the DRAFT lifecycle entry (YYYY-MM-DD format)
8. **Title generation**: Convert summary to title case (e.g., `layer-system` → `Layer System`)

---

## Example Session (Explore Mode with Product)

```
User: /planning myapp authentication for the API

Claude: Planning for **myapp** — let's explore API authentication together before committing to a plan document.

**Understanding the territory:**
- What's prompting the need for API authentication now? Is there currently no auth, or are you looking to change an existing approach?
- Who are the API consumers—internal services, third-party integrations, or end users?
- What are the security requirements? (Token-based, OAuth, API keys, etc.)

User: We have basic API keys now but need something more secure for third-party integrations. Mainly B2B partners.

Claude: Got it—evolving from simple API keys to something suitable for B2B partner integrations.

**Challenging assumptions:**
- When you say "more secure," what specific threats or compliance requirements are you addressing? (e.g., key rotation, audit trails, scope limitation)
- Have you considered whether the current API key system could be extended (adding scopes, expiration) vs. replacing it entirely?
- What's the partner onboarding experience like? Some auth systems add significant friction.

User: We need audit trails for compliance, and partners have asked for scoped access to specific resources. Onboarding friction is a concern.

Claude: So the key drivers are: audit trails (compliance), granular scopes (partner request), and low onboarding friction (business need).

**Surfacing options:**

| Approach | Pros | Cons |
|----------|------|------|
| OAuth 2.0 + Client Credentials | Industry standard, great tooling | Can be complex to implement correctly |
| Enhanced API Keys (scoped + logged) | Simpler migration from current system | Less standardized, may not satisfy compliance auditors |
| JWT with Claims | Self-contained, scalable | Token size, revocation complexity |

Given your constraints, I'd lean toward OAuth 2.0 with Client Credentials flow—it's what B2B partners expect, has excellent audit capabilities, and libraries handle the complexity.

**Open questions I'm noting:**
- How are partners currently managed? Is there a partner database?
- What's the timeline pressure here?
- Do you have OAuth infrastructure already, or is this greenfield?

User: We don't have OAuth infrastructure. Partners are in a simple database table. Timeline is flexible.

Claude: That's helpful context. Building OAuth infrastructure is non-trivial, but with flexible timeline, it's achievable and worthwhile for B2B.

**Checkpoint:**
I think we've explored this enough to draft a plan. We've identified:
- **Product**: myapp (established at invocation)
- **Goal**: Replace API keys with scoped, auditable auth for B2B partners
- **Approach**: OAuth 2.0 Client Credentials
- **Key constraints**: Low onboarding friction, compliance audit trails
- **Open questions**: Infrastructure needs, partner management integration

Ready to create a plan file, or is there more to discuss?

User: Ready, let's create it.

Claude: Since we're planning for myapp, I just need:

**Domain**: I'd suggest `auth` or `security`—preference?

User: auth

Claude: Creating:
`~working/plans/draft-myapp-auth-oauth-partner-access-plan.md`

[Creates file with Context, Goals, Non-Goals, and Open Questions pre-populated from the dialogue]

Created plan at: /path/to/~working/plans/draft-myapp-auth-oauth-partner-access-plan.md

**Pre-populated sections:**
- Context (the "why now" and drivers)
- Goals (audit trails, scopes, low friction)
- Non-Goals (can add: "not replacing internal service-to-service auth")
- Open Questions (infrastructure, partner management integration)

**Still needs attention:**
- Glossary (OAuth terms worth defining for the team)
- Design (specific OAuth flows, token structure)
- Work Items (implementation steps)
- Risks & Mitigations

Next steps:
- Review the pre-populated sections for accuracy
- Fill in the Design and Work Items
- `/stage set ready <path>` when complete
```

## Example Session (Explore Mode without Product)

```
User: /planning a caching layer for expensive computations

Claude: Let's explore this together before committing to a plan document.

**Understanding the territory:**
- Which computations are you looking to cache? Are these in a specific product or a shared concern?
- What makes them expensive—CPU, I/O, external API calls?
- What's the access pattern? (Read-heavy, write-heavy, TTL requirements?)

[... dialogue continues, product is asked during file creation phase ...]
```

## Example Session (Scaffold Mode)

```
User: /planning --scaffold myapp audio real-time-effects

Claude: Creating plan file directly:
`~working/plans/draft-myapp-audio-real-time-effects-plan.md`

Created plan at: /path/to/~working/plans/draft-myapp-audio-real-time-effects-plan.md

The template is ready with empty sections. Next steps:
- Fill in Context, Goals, Design, etc.
- `/stage set ready <path>` when complete
- `/stage set approved <path>` after reflection
```
