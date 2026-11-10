# Changelog

## [28.0.0.0]

### Added
- #13: `Quality.Disposition.CreatePurchaseReturn` wraps the standard failed-quantity purchase return disposition, with strict inputs, transaction rollback, permission capability, bilingual contract/help and tests (10035244–10035247; tests 97210–97214). - Unreleased

- Repository scaffolded from Bifrost Subscription Billing setup.

### Added

- [#5](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/5): `Quality.Inspection.Reopen` (enum extension 10035255, codeunit 10035256, permission marker table 10035258). The type calls `Qlty. Inspection Header.ReopenInspection` and does not write Status or quantities itself. `BIFROST QM Full ori` (10035237) includes `QltyMgmt - Admin` so the role can run the action; Microsoft still requires that admin role, or SUPER, to be assigned to the user. Tests 97220 and 97221.
- [#1](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/issues/1): Foundation application registration (codeunit 10035235), base/full/read permission sets (10035236–10035238) and Foundation role extensions (10035239–10035240). The scaffold adds no message types or Microsoft business-data grants.
- Registration, repeat-discovery and English/Icelandic licence-admin setup coverage in test codeunit 97200 (platform-only test permission set 97201), with Icelandic permission captions and the `quality-management` help entry.
- Corrected keyword-translation validation for the message-free scaffold; message declarations without keyword coverage still fail the guard, with regression checks for both cases.
