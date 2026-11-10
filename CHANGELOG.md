# Changelog

## [28.0.0.0] - Unreleased

- Repository scaffolded from Bifrost Subscription Billing setup.

### Added

- [#4](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/4): message type `Quality.Inspection.Finish` (enum extension 10035241, contract 10035242, implementation 10035243, process 10035244). Calls `FinishInspection` on the quality inspection header. Execute permission is on `BIFROST QM Full ori` (10035237), which the Foundation full role extension already includes. The read role does not grant the type.
- [#1](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/1): Foundation application registration (codeunit 10035235), base/full/read permission sets (10035236–10035238) and Foundation role extensions (10035239–10035240). The scaffold adds no message types or Microsoft business-data grants.
- Registration, repeat-discovery and English/Icelandic licence-admin setup coverage in test codeunit 97200 (platform-only test permission set 97201), with Icelandic permission captions and the `quality-management` help entry.
- Corrected keyword-translation validation for the message-free scaffold; message declarations without keyword coverage still fail the guard, with regression checks for both cases.
