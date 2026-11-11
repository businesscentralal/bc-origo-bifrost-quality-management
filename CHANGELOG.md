# Changelog

## [28.0.0.0] - Unreleased

### Fixed

- #31: Purchase-return refusals now provide typed codes, parameter details and translated recovery guidance. Missing or empty inspection IDs use `MissingParameter`; unknown IDs use `RecordNotFound`. App-owned permission, format, source and result checks preserve transaction rollback (codeunit 10035245; tests 97210/97215).

- #5 / PR #32: the base role (10035236) now grants Reopen handler execution (10035256) and read access to its capability marker (10035258), so Read callers can evaluate the disabled action on BC29. Marker writes remain exclusive to Full (10035237); tests 97220/97221 are unchanged.

### Added
- #13: `Quality.Disposition.CreatePurchaseReturn` wraps the standard failed-quantity purchase return disposition, with strict inputs, transaction rollback, permission capability, bilingual contract/help and tests (10035244–10035247; tests 97210–97214).

- Repository scaffolded from Bifrost Subscription Billing setup.

### Fixed

- [#4](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/4): the Full role (10035237) now includes the non-assignable permission set 10035285, which grants read access to My Notifications (table 1518). Since #32 added Quality Admin, Microsoft offers to assign a finished inspection to the user in interactive sessions and reads that setting; without the grant, `Quality.Inspection.Finish` under the Full role alone failed with a permission error.
- [#4](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/4): enforce the Full app role through empty capability table 10035284, including callers with Foundation API wildcard execution and native inspection permissions. Dispatcher tests verify read/API refusals without changing an inspection. Native Inspector users need Modify permission, not Delete permission. Contract help chapters and notes now have Icelandic translations.

### Added

- [#5](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/5): `Quality.Inspection.Reopen` (enum extension 10035255, codeunit 10035256, permission marker table 10035258). The type calls `Qlty. Inspection Header.ReopenInspection` and does not write Status or quantities itself. `BIFROST QM Full ori` (10035237) includes `QltyMgmt - Admin` so the role can run the action; Microsoft still requires that admin role, or SUPER, to be assigned to the user. Tests 97220 and 97221.
- [#6](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/6): `Quality.Inspection.SetTestValue` validates a named test and recalculates the open inspection result through Microsoft’s standard methods. Added enum extension 10035241, implementation 10035242, empty write-permission capability table 10035243, Full-role inspector permissions, bilingual help and regression tests and owned fixture helpers 97202–97206. Missing, malformed, unknown and overlong parameters are refused; transaction failures preserve header and line data.

- [#4](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/4): message type `Quality.Inspection.Finish` (enum extension 10035280, contract 10035281, implementation 10035282, process 10035283, capability table 10035284; test 97230). Calls `FinishInspection` on the quality inspection header. Execute permission is on `BIFROST QM Full ori` (10035237), which includes the Microsoft inspector role and which the Foundation full role extension already includes. The read role does not grant the type.
- [#1](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/1): Foundation application registration (codeunit 10035235), base/full/read permission sets (10035236–10035238) and Foundation role extensions (10035239–10035240). The scaffold adds no message types or Microsoft business-data grants.
- Registration, repeat-discovery and English/Icelandic licence-admin setup coverage in test codeunit 97200 (platform-only test permission set 97201), with Icelandic permission captions and the `quality-management` help entry.
- Corrected keyword-translation validation for the message-free scaffold; message declarations without keyword coverage still fail the guard, with regression checks for both cases.
