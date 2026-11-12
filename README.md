# Bifröst Quality Management

**App name:** Bifrost Quality Management
**Publisher:** Origo — **Version:** 28.0.0.0 — **Target:** Cloud (BC 28.5, runtime 17.0)
**App ID:** `d3ca6790-e2c1-44c1-a026-fd75a3f5b52d` — **Test app ID:** `9193f6a2-0926-49bb-9fec-3c36a60c8b0e`
**Object ID range:** 10035235–10035334 (tests 97200–97299) — **Namespace:** `Origo.Bifrost.QualityManagement`

Bifrost Quality Management makes Microsoft's **Quality Management** app callable from outside Business Central through
Bifröst message types, so an agent can operate it end to end. It is built on the same basis as
[Bifrost Subscription Billing](https://github.com/businesscentralal/bc-origo-bifrost-subscription-billing).

**Microsoft source:** <https://github.com/microsoft/BCApps/tree/main/src/Apps/W1/Quality%20Management>

**Status:** registration, Foundation roles, `Quality.Inspection.Reopen`, `Quality.Inspection.SetTestValue`, `Quality.Disposition.CreatePurchaseReturn` `Quality.Inspection.CreateReinspection` and `Quality.Disposition.MoveInventory` are implemented; see the [test-value contract](app/docs/en-us/SetTestValue.md) ([íslenska](app/docs/is-is/SetTestValue.md)) and the [inventory movement call guide](app/docs/en-us/MoveInventory.md) ([íslenska](app/docs/is-is/MoveInventory.md)), or read the live contract with `Help.Implementation.Get`. `Quality.Disposition.MoveInventory` uses Microsoft's standard disposition interface with explicit confirmation and optional atomic reclassification posting; repeated successful calls can create additional movements, so it is not idempotent.

Foundation discovers this app on **Bifrost Setup** through its application registry. All setup notifications stay on that Foundation page. Quality Management has no setup page of its own.

Assign `BIFROST Quality ori`, `BIFROST QM Full ori` or `BIFROST QM Read ori` alongside the appropriate Foundation role. Foundation Full and Read already include the matching Quality Management set. The Full role grants inspection reopen, test-value, purchase-return, re-inspection and inventory disposition execution and includes Microsoft `QltyMgmt - Admin` and `QltyMgmt - Inspector` permissions. Microsoft `ReopenInspection` still requires the Quality Admin & Supervisor role, or SUPER, to be assigned to the user. Purchase-return and inventory-movement callers also need the native purchase-document or inventory permissions for the documents they touch. The base and Read roles grant registration and permission-safe Reopen discovery; the Reopen capability marker is read-only, so the action remains disabled. Dedicated empty capability tables enforce the app Full grant even when a Foundation API role grants wildcard codeunit execution. Neither role grants these write operations.

The app manifest exposes the `quality-management` documentation entry in English and Icelandic. The complete object allocation is recorded in [.claude/CLAUDE.md](.claude/CLAUDE.md).

---

## Object ranges

| Object | Range |
| --- | --- |
| App (`app/`) | 10035235-10035334 |
| Test app (`test/`) | 97200-97299 |

---

## Message types

| Type | Effect | Retry behavior | Help |
| --- | --- | --- | --- |
| `Quality.Inspection.Reopen` | Reopens an inspection through Microsoft `ReopenInspection` | Idempotent; an already open inspection stays open | [English](app/docs/en-us/Reopen.md), [íslenska](app/docs/is-is/Reopen.md) |
| `Quality.Disposition.CreatePurchaseReturn` | Creates an unposted purchase return for the failed quantity | Not idempotent; a retry can create another return | [English](app/docs/en-us/CreatePurchaseReturn.md), [íslenska](app/docs/is-is/CreatePurchaseReturn.md) |
| `Quality.Inspection.CreateReinspection` | Creates the next revision of a quality inspection | Not idempotent | [English](docs/en-us/quality-inspection-create-reinspection.md), [íslenska](docs/is-is/quality-inspection-create-reinspection.md) |

## Documentation

- Re-inspection request, effects and retry behavior: [English](docs/en-us/quality-inspection-create-reinspection.md) / [Íslenska](docs/is-is/quality-inspection-create-reinspection.md).
- The live contract is available through `Help.Implementation.Get` for `Quality.Inspection.CreateReinspection`.

All public documentation lives in the [businesscentralal/bifrost](https://github.com/businesscentralal/bifrost)
site repository and is published at <https://docs.bifrost.origo.is>.

| What | Where |
| --- | --- |
| Product documentation | <https://docs.bifrost.origo.is/en-us/quality-management/> |
| Bifröst documentation home | <https://docs.bifrost.origo.is> |
| Release notes | [CHANGELOG.md](CHANGELOG.md) |

---

## Dependencies

| App | ID | Publisher | Version |
| --- | --- | --- | --- |
| Bifrost Foundation | `7505e808-6e52-4b96-a328-82573391297a` | Origo | 28.0.5.590 |
| Quality Management | `bc7b3891-f61b-4883-bbb3-384cdef88bec` | Microsoft | 28.5.0.0 |

---

## Repository layout

| Folder | Content |
| --- | --- |
| `app/` | The AppSource app (`Bifrost Quality Management`), registration, disposition and permissions |
| `test/` | Test app (`Bifrost Quality Management - Tests`) |
| `tools/` | Pipeline guard scripts |
| `.AL-Go/`, `.github/`, `.alpaca/` | AL-Go for GitHub / COSMO Alpaca pipeline configuration |
