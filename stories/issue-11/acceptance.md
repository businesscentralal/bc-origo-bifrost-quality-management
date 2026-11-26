# Issue 11: Quality.Inspection.AddPicture

Source: https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/11

Gunnar approved the new type on 26 November 2026 (decision card
`d-20261126-qm-backlog-message-types`, recorded in issue comment 7194410653).
No implementation or validation pass is claimed by this planning draft.

| Criterion | Implemented | Verified | Remaining |
| --- | --- | --- | --- |
| AC01 registration, write discovery, bilingual contract | No | No | Implement after staging contract clarification |
| AC02 base64/staging JPEG, PNG, BMP and response | No | No | Public non-consuming staging access or clarified transaction semantics |
| AC03 typed refusals before any write | No | No | Resolve pre-write staging validation requirement, then implement all refusals |
| AC04 expectedCount and staging lifetime | No | No | Prove success consumes and all failures preserve staging |
| AC05 Full capability, Read/base refusal, native modify permission | No | No | Dedicated marker and dispatcher permission tests |
| AC06 translations, guides, README, changelog and guards | No | No | Produce with implementation; no help pages or manifest URL change |

## Dependency assessment

Downloaded Foundation symbols from worker-6 tenant `w129-16` on 26 November
2026. Request minimum was 28.0.15.6; the actual symbol package is 28.0.17.0.
Codeunit 10078382 `Blob Staging ori` exposes `Create`, two `Take` overloads,
`NormalizeMetadata` and `Exists`. `Read` is internal. Its table is also internal.
Both `Take` overloads delete the owned staging row in the caller transaction
before returning bytes. `Exists` does not return bytes or their size.

The story requires byte-format and size validation before **any write** and
staging consumption only after success. A transactional Take followed by an
error could roll back consumption, but still performs a staging delete before
validating its bytes. Do not silently substitute that interpretation for the
literal pre-write requirement. Do not bypass the facade using generic record
access, add a friend assembly, or change Foundation in this repository.

Recommendation: arrange a public non-consuming, ownership-scoped Foundation
read API, retaining the existing same-user/company boundary, then validate
bytes and use Take within the picture-write transaction. Alternatively, an
explicit story clarification may authorize Take plus rollback for staging
validation while requiring all inspection/media writes after validation.

Microsoft BCApps `releases/28.0` inspection-header source confirms public
`Most Recent Picture` (field 41), internal interactive import procedures, and
local additional-picture handling. The intended implementation must avoid
camera/file dialogs and OneDrive calls. The story permits reporting
`additionalHandlingApplied=false` with a documented limitation.

## Reserved IDs and continuation

The reserved app block is 10035294–10035297; tests are 97264–97267. The
project object map records these as reservations, not implemented objects.
Main source and currently open PRs were checked; none uses this block.
Continue this branch/PR rather than opening another one. On resolution,
implement the public dispatcher path, generated-byte tests, bilingual contract
and guides, then run the required ordered checks on worker-6's local tenant.

Product/test compilation, targeted AL tests, MCP and UI: NOT_RUN, because no
AL implementation exists in this draft. No page or action is changed.
Licence-path checks: NOT_RUN; verified before release.
