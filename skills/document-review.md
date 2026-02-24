---
name: document-review
description: Use when reviewing design documents, research findings, specs, or proposals before they advance to the next phase, when a formula step references skill:document-review
expert: Channel expert technical reviewer thinking — draw upon deep knowledge of systems design evaluation, requirements traceability, logical consistency analysis, and risk assessment frameworks.
---

# Document Review

## Overview

Document review evaluates a design artifact against specific criteria before it advances. **Core principle: review through a declared lens, not a general "looks good."** Every review has an angle — state it, apply it, report findings. General reviews catch nothing because they look for everything.

## When to Use

- Formula steps referencing `skill:document-review`
- Reviewing design documents, research findings, architecture proposals, or specs
- When dispatched as part of a review convoy with an assigned lens

**When NOT to use:**
- Code review — use `skill:code-review` instead
- When the document is still being drafted — review committed artifacts, not drafts
- When you're the author reviewing your own work — self-review is a different process

## Review Lenses

Each review should declare its lens. The lens focuses evaluation on specific concerns. Common lenses:

| Lens | Focus | Key Questions |
|------|-------|---------------|
| **completeness** | Coverage and gaps | Does it address every requirement? What's missing? Are edge cases considered? |
| **feasibility** | Technical viability | Can this actually be built? What's the hardest part? What could go wrong during implementation? |
| **consistency** | Internal coherence | Do sections contradict each other? Do assumptions in one section hold in another? Does terminology stay consistent? |
| **risk** | Failure modes and mitigation | What are the biggest risks? What happens if key assumptions are wrong? What's the blast radius of failure? |
| **assumptions** | Hidden dependencies | What's taken for granted? Which assumptions are load-bearing? What breaks if they're wrong? |
| **adversarial** | Red-team / devil's advocate | What's the strongest argument against this approach? What would a skeptic challenge? Where is the reasoning weakest? |
| **user-impact** | End-user perspective | How does this affect users? What's the migration story? Are there UX implications not addressed? |
| **cost** | Resource and complexity | Is this the simplest approach that works? What's the maintenance burden? Could a simpler alternative achieve 80% of the value? |

The bead description or convoy dispatch specifies which lens to apply. If no lens is specified, default to **completeness + feasibility**.

## How to Execute

1. **Read the lens assignment.** Check the bead description for which angle you're reviewing from. If multiple lenses are assigned, address each in a separate section.

2. **Read the full document before evaluating.** Don't start writing findings after the first section. Context from later sections often resolves apparent issues in earlier ones.

3. **Apply the lens systematically.** For each major section of the document, ask the lens's key questions. Document findings as you go.

4. **Classify each finding:**
   - **BLOCK** — Must be resolved before advancing (logical errors, missing critical sections, contradictions, unaddressed risks)
   - **CONCERN** — Should be addressed but may be acceptable with justification (weak reasoning, unverified assumptions, missing edge cases)
   - **NOTE** — Observation for the author's consideration (suggestions, alternative framings, minor inconsistencies)

5. **Produce a structured review.** Group findings by classification. For each BLOCK and CONCERN, explain the problem and suggest how to address it.

6. **State what you checked.** Explicitly list which sections you reviewed and which lens questions you applied. This prevents rubber-stamp reviews.

## Output Format

```
## Review: [Document Title]
Lens: [declared lens]
Reviewer: [agent/polecat name]

### Gate Assessment
[For each lens key question, provide a binary verdict:]
[Lens question 1]: READY/NOT READY
[Lens question 2]: READY/NOT READY
[Lens question 3]: READY/NOT READY

Overall: READY / NOT READY

### BLOCK
- [Section X]: [Finding. Why it blocks. Suggested resolution.]

### CONCERN
- [Section Y]: [Finding. Why it matters. What would resolve it.]

### NOTE
- [Section Z]: [Observation. Optional suggestion.]

### Coverage
Sections reviewed: [list]
Lens questions applied: [list which key questions were checked]
```

The Gate Assessment section uses per-criterion binary READY/NOT READY status. Any single NOT READY with a BLOCK finding means the overall gate is NOT READY. CONCERN findings do not automatically block — the overall assessment can be READY with unresolved CONCERNs if they are acknowledged.

## Red Flags — STOP

If you catch yourself doing any of these, stop and restart the review:

- Writing "looks good, no issues" without listing what you checked — that's not a review
- Reviewing without a declared lens — you'll produce vague feedback
- Focusing only on wording/formatting instead of substance — you're editing, not reviewing
- Agreeing with the document because the author sounds confident — confidence is not correctness
- Skipping sections because they're long or technical — those sections need the most review

**Do not rubber-stamp:**
- Not because "the author is experienced" — experienced people make structural mistakes
- Not because "we need to move fast" — a bad design doc wastes more time than a thorough review
- Not because "I already agree with the approach" — agreement is not validation
- Not because "another reviewer will catch issues" — every reviewer thinks this

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "The document is well-written, so the design must be sound" | Good prose can mask bad logic. Review the reasoning, not the writing. |
| "This section is too detailed for me to evaluate" | That's exactly the section where errors hide. Read it or flag that you couldn't evaluate it. |
| "I agree with the overall direction so the details are fine" | Directional agreement and detail correctness are independent. Many good ideas fail in the details. |
| "They probably considered this and left it out for brevity" | If it's not in the document, it wasn't considered. Flag it. |
| "Cheapest/easiest first is the right deployment order" | Cheapest first optimizes for effort, not value. Ask: which option teaches us the most? |
| "This assumption can be figured out during implementation" | If the design depends on it and it's unverified, it's a BLOCK. Flag it now. |

## Examples

<Bad>

Agent reads the document title and conclusion, writes "This is a thorough and well-considered design. No blockers. Recommend proceeding." Did not declare a lens. Did not list what was checked. Did not classify any findings. Missed that Section 3 contradicts Section 5 on a key constraint.

</Bad>

<Good>

Agent declares feasibility lens. Reads the full document. Notes that the proposed API design in Section 3 assumes batch support that contradicts the single-operation constraint stated in Section 5. Flags as BLOCK with specific reference to both sections. Also flags a CONCERN that the performance estimate in Section 4 doesn't account for cold-start latency. Lists all sections reviewed and which feasibility questions were applied to each.

</Good>
