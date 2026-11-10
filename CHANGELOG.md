# Changelog

## [28.0.0.0] - Unreleased

- Repository scaffolded from Bifrost Subscription Billing setup.

### Added

- [#7](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/7): `Quality.Inspection.CreateReinspection` wraps the native header action with strict source-ID validation, transactional refusal handling, translated discovery/help and full-role authorization (table 10035320, codeunits 10035321–10035322, enum extension 10035323; tests 97207–97208).

- [#1](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/1): Foundation application registration (codeunit 10035235), base/full/read permission sets (10035236–10035238) and Foundation role extensions (10035239–10035240). The scaffold adds no message types or Microsoft business-data grants.
- Registration, repeat-discovery and English/Icelandic licence-admin setup coverage in test codeunit 97200 (platform-only test permission set 97201), with Icelandic permission captions and the `quality-management` help entry.
- Corrected keyword-translation validation for the message-free scaffold; message declarations without keyword coverage still fail the guard, with regression checks for both cases.
