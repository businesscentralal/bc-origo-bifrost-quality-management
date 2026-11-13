# Changelog

## [28.0.0.0] - Unreleased

### Fixed

- #12 / PR #30: missing or invalid `inspectionSystemId` returns `MissingParameter` with parameter details and bilingual recovery guidance across the isolated transaction (codeunit 10035270; tests 97250).

- #31: Purchase-return refusals now provide typed codes, parameter details and translated recovery guidance. Missing or empty inspection IDs use `MissingParameter`; unknown IDs use `RecordNotFound`. App-owned permission, format, source and result checks preserve transaction rollback (codeunit 10035245; tests 97210/97215).

- #5 / PR #32: the base role (10035236) now grants Reopen handler execution (10035256) and read access to its capability marker (10035258), so Read callers can evaluate the disabled action on BC29. Marker writes remain exclusive to Full (10035237); tests 97220/97221 are unchanged.
- #34: `Quality.Inspection.SetTestValue` now returns typed input, access, inspection-not-found and status refusals with actionable structured fields in English and Icelandic (codeunit 10035242; tests 97209). Native Microsoft validation and atomic rollback remain in place.
- #34 / PR #35 amendment: the published `errors` chapter of `Quality.Inspection.SetTestValue` now emits `{code, when, fix}` through the Foundation `ErrorEntry` contract (codeunit 10035242; test 97209 `Scenario_AC03_ErrorsChapter_PublishesStableCodes`).

### Added
- #13: `Quality.Disposition.CreatePurchaseReturn` wraps the standard failed-quantity purchase return disposition, with strict inputs, transaction rollback, permission capability, bilingual contract/help and tests (10035244–10035247; tests 97210–97214).

- Repository scaffolded from Bifrost Subscription Billing setup.

### Added

- [#7](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/7): `Quality.Inspection.CreateReinspection` wraps the native header action with strict source-ID validation, transactional refusal handling, translated discovery/help and full-role authorization (table 10035320, codeunits 10035321–10035322, enum extension 10035323; tests 97207–97208).
- [#5](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/5): `Quality.Inspection.Reopen` (enum extension 10035255, codeunit 10035256, permission marker table 10035258). The type calls `Qlty. Inspection Header.ReopenInspection` and does not write Status or quantities itself. `BIFROST QM Full ori` (10035237) includes `QltyMgmt - Admin` so the role can run the action; Microsoft still requires that admin role, or SUPER, to be assigned to the user. Tests 97220 and 97221.
- [#6](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/6): `Quality.Inspection.SetTestValue` validates a named test and recalculates the open inspection result through Microsoft’s standard methods. Added enum extension 10035241, implementation 10035242, empty write-permission capability table 10035243, Full-role inspector permissions, bilingual help and regression tests and owned fixture helpers 97202–97206. Missing, malformed, unknown and overlong parameters are refused; transaction failures preserve header and line data.
- [#12](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/12): `Quality.Disposition.MoveInventory`, standard disposition interface wrapper with explicit confirmation, atomic item/warehouse posting, capability check and bilingual help (enumextension/codeunit 10035270, capability table 10035271, bound posting codeunit 10035272). Native dispatcher tests and late-failure injection use 97250–97252; the owned MCP fixture builder and explicit test UI use 97253–97254 without changing write guards or licensing.

- [#1](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/1): Foundation application registration (codeunit 10035235), base/full/read permission sets (10035236–10035238) and Foundation role extensions (10035239–10035240). The scaffold adds no message types or Microsoft business-data grants.
- Registration, repeat-discovery and English/Icelandic licence-admin setup coverage in test codeunit 97200 (platform-only test permission set 97201), with Icelandic permission captions and the `quality-management` help entry.
- Corrected keyword-translation validation for the message-free scaffold; message declarations without keyword coverage still fail the guard, with regression checks for both cases.
