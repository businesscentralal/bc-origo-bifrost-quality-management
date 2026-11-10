# Changelog

## [28.0.0.0] - Unreleased

- Repository scaffolded from Bifrost Subscription Billing setup.

### Added

- [#3](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/3): `Quality.Inspection.Create` resolves one source record by table ID and SystemId and calls the standard Microsoft creation API, with optional template selection, native generation rules and atomic refusal handling (codeunits 10035250–10035251, enum extension 10035241 and permission capability table 10035243). Full access and native Quality permissions are required; Read access cannot create inspections. Includes English/Icelandic contract help and regression codeunit 97210.

- [#1](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/1): Foundation application registration (codeunit 10035235), base/full/read permission sets (10035236–10035238) and Foundation role extensions (10035239–10035240). The scaffold adds no message types or Microsoft business-data grants.
- Registration, repeat-discovery and English/Icelandic licence-admin setup coverage in test codeunit 97200 (platform-only test permission set 97201), with Icelandic permission captions and the `quality-management` help entry.
- Corrected keyword-translation validation for the message-free scaffold; message declarations without keyword coverage still fail the guard, with regression checks for both cases.
