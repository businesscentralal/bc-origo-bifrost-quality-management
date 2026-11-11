# Changelog

## [28.0.0.0] - Unreleased

### Fixed

- #3: Reconcile creation with the merged purchase-return implementation, preserving Microsoft Inspector permissions and both app capabilities. Allocate creation test objects 97240/97242/97244 to avoid collisions with purchase-return tests.

- #31: Purchase-return refusals now provide typed codes, parameter details and translated recovery guidance. Missing or empty inspection IDs use `MissingParameter`; unknown IDs use `RecordNotFound`. App-owned permission, format, source and result checks preserve transaction rollback (codeunit 10035245; tests 97210/97215).

### Added
- #13: `Quality.Disposition.CreatePurchaseReturn` wraps the standard failed-quantity purchase return disposition, with strict inputs, transaction rollback, permission capability, bilingual contract/help and tests (10035244–10035247; tests 97210–97214).

- Repository scaffolded from Bifrost Subscription Billing setup.

### Added

- [#3](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/3): `Quality.Inspection.Create` resolves one source record by table ID and SystemId and calls the standard Microsoft creation API, with optional template selection, native generation rules and atomic refusal handling and typed refusals (MissingParameter, InvalidParameter, UnknownParameter, RecordNotFound, PermissionDenied, PreconditionFailed) with parameter, expected and nextStep (codeunits 10035250–10035251, enum extension 10035241 and permission capability table 10035243). Full access and native Quality permissions are required; Read access cannot create inspections. Includes English/Icelandic contract help and regression codeunit 97240.
- [#6](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/6): `Quality.Inspection.SetTestValue` validates a named test and recalculates the open inspection result through Microsoft’s standard methods. Added enum extension 10035241, implementation 10035242, empty write-permission capability table 10035243, Full-role inspector permissions, bilingual help and regression tests and owned fixture helpers 97202–97206. Missing, malformed, unknown and overlong parameters are refused; transaction failures preserve header and line data.

- [#1](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/1): Foundation application registration (codeunit 10035235), base/full/read permission sets (10035236–10035238) and Foundation role extensions (10035239–10035240). The scaffold adds no message types or Microsoft business-data grants.
- Registration, repeat-discovery and English/Icelandic licence-admin setup coverage in test codeunit 97200 (platform-only test permission set 97201), with Icelandic permission captions and the `quality-management` help entry.
- Corrected keyword-translation validation for the message-free scaffold; message declarations without keyword coverage still fail the guard, with regression checks for both cases.
