# Changelog

## [28.0.0.0] - Unreleased

### Fixed

- #31: Purchase-return refusals now provide typed codes, parameter details and translated recovery guidance. Missing or empty inspection IDs use `MissingParameter`; unknown IDs use `RecordNotFound`. App-owned permission, format, source and result checks preserve transaction rollback (codeunit 10035245; tests 97210/97215).

### Added
- #13: `Quality.Disposition.CreatePurchaseReturn` wraps the standard failed-quantity purchase return disposition, with strict inputs, transaction rollback, permission capability, bilingual contract/help and tests (10035244–10035247; tests 97210–97214).

- Repository scaffolded from Bifrost Subscription Billing setup.

### Added

- [#6](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/6): `Quality.Inspection.SetTestValue` validates a named test and recalculates the open inspection result through Microsoft’s standard methods. Added enum extension 10035241, implementation 10035242, empty write-permission capability table 10035243, Full-role inspector permissions, bilingual help and regression tests and owned fixture helpers 97202–97206. Missing, malformed, unknown and overlong parameters are refused; transaction failures preserve header and line data.
- [#12](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/12): `Quality.Disposition.MoveInventory`, standard disposition interface wrapper with explicit confirmation, atomic item/warehouse posting, capability check and bilingual help (enumextension/codeunit 10035270, capability table 10035271, bound posting codeunit 10035272). Native dispatcher tests and late-failure injection use 97220–97222; the owned MCP fixture builder and explicit test UI use 97224–97225 without changing write guards or licensing.

- [#1](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/1): Foundation application registration (codeunit 10035235), base/full/read permission sets (10035236–10035238) and Foundation role extensions (10035239–10035240). The scaffold adds no message types or Microsoft business-data grants.
- Registration, repeat-discovery and English/Icelandic licence-admin setup coverage in test codeunit 97200 (platform-only test permission set 97201), with Icelandic permission captions and the `quality-management` help entry.
- Corrected keyword-translation validation for the message-free scaffold; message declarations without keyword coverage still fail the guard, with regression checks for both cases.
