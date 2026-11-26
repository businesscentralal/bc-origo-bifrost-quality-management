# Issue 11: Quality.Inspection.AddPicture

Source: https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/11
PR: https://github.com/businesscentralal/bc-origo-bifrost-quality-management/pull/46

Gunnar approved this message type on 26 November 2026. The Architect accepted
transactional Take plus rollback in issue comment 7196544393 and aligned public
contract chapters with Foundation's English help convention. No core change is needed.

| Criterion | Implemented | Verified | Remaining |
| --- | --- | --- | --- |
| AC01 registration, write discovery, bilingual app-owned contract | Yes | Static: enum/three interfaces and translated labels | Runtime discovery/help in 1033/1039 |
| AC02 base64/staging JPEG, PNG, BMP and response | Yes | Dispatcher tests implemented for both paths, replacement and exact size/name boundaries | Final-head AL/MCP evidence |
| AC03 typed refusals before inspection/media writes | Yes | Strict keys, GUIDs, source exclusivity, decoder/size, status, permission checks | Final-head AL/MCP evidence |
| AC04 count and staging lifetime | Yes | Take only through public facade; raising boundary; old-picture/Exists assertions and late media-write failure injection | Final-head AL/MCP evidence |
| AC05 Full capability, Read/base refusal, native Modify | Yes | Dedicated capability table; strict dispatcher tests including capability without native Modify | Final-head AL evidence |
| AC06 translations, guides, README, changelog and guards | Yes | en-US/is-IS guides and contract labels; XLF generated; object IDs documented | Final-head build/guard report |

## Transaction and ownership review

Foundation's public `Blob Staging ori.Take` restricts the row to the current
company and platform-stamped creator. AddPicture never reads the internal table,
uses a generic-table bypass or calls internal Foundation methods. Unknown and
foreign identifiers take the same non-disclosing refusal branch. Foundation owns
that boundary; this app tests unknown identifiers and its own staging transaction.

All post-Take validation refusals raise collected typed errors. Normal execution
uses Boolean Codeunit.Run and Foundation RespondWithLastError after rollback;
omit-commit mode propagates the error to the caller's transaction. Explicit
subscriber commits are prohibited. Tests assert Exists after invalid format/size,
finished/count refusals and a failure after media import, and consumption after success.

Microsoft BCApps releases/28.0 inspection-header source confirms Most Recent Picture
(field 41) is public, interactive import procedures are internal, and additional
handling is local. The implementation uses Media.ImportStream directly, reports
additionalHandlingApplied=false and does not call camera, attachment or OneDrive paths.

App objects: enum extension 10035294, implementation 10035295, capability table
10035296, processor 10035297. Test objects: regression codeunit 97264, fixture
codeunit 97265, permission set and fault codeunit 97266 (different object kinds),
fixture enum extension 97267. Main and open PRs use the reserved story blocks.

UI scope: no page or action changes, so Web Client runtime checks and UI clips are
not applicable. Licence-path checks: NOT_RUN; verified before release.
The exact-head Current state PR comment records final runtime evidence and the CI URL.
