# Bifröst Quality Management

**App name:** Bifrost Quality Management
**Publisher:** Origo — **Version:** 28.0.0.0 — **Target:** Cloud (BC 28.5, runtime 17.0)
**App ID:** `d3ca6790-e2c1-44c1-a026-fd75a3f5b52d` — **Test app ID:** `9193f6a2-0926-49bb-9fec-3c36a60c8b0e`
**Object ID range:** 10035235–10035334 (tests 97200–97299) — **Namespace:** `Origo.Bifrost.QualityManagement`

Bifrost Quality Management will make Microsoft's **Quality Management** app callable from outside Business Central through
Bifröst message types, so an agent can operate it end to end. It is built on the same basis as
[Bifrost Subscription Billing](https://github.com/businesscentralal/bc-origo-bifrost-subscription-billing).

**Microsoft source:** <https://github.com/microsoft/BCApps/tree/main/src/Apps/W1/Quality%20Management>

**Message types:** `Quality.Inspection.Create` creates or resolves an inspection using Microsoft generation rules, optionally selecting a template; `Quality.Inspection.SetTestValue` validates a named test value and recalculates the open inspection result; `Quality.Disposition.CreatePurchaseReturn` creates a purchase return through the native disposition workflow. See the contract guides for [inspection creation](app/docs/en-us/CreateInspection.md) ([íslenska](app/docs/is-is/CreateInspection.md)) and [test values](app/docs/en-us/SetTestValue.md) ([íslenska](app/docs/is-is/SetTestValue.md)).

Foundation discovers this app on **Bifrost Setup** through its application registry. All setup notifications stay on that Foundation page. Quality Management has no setup page of its own.

Assign `BIFROST Quality ori`, `BIFROST QM Full ori` or `BIFROST QM Read ori` alongside the appropriate Foundation role. Foundation Full and Read already include the matching Quality Management set. The Full role grants inspection creation, test-value and purchase-return execution and includes Microsoft’s `QltyMgmt - Inspector` permissions. Callers also need native source-record permissions and, for purchase returns, purchase-document permissions. Dedicated empty capability tables enforce the app Full grant even when a Foundation API role grants wildcard codeunit execution. The Read and base sets grant registration only; they cannot execute these write operations.

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
| `Quality.Disposition.CreatePurchaseReturn` | Creates an unposted purchase return for the failed quantity | Not idempotent; a retry can create another return | [English](app/docs/en-us/CreatePurchaseReturn.md), [íslenska](app/docs/is-is/CreatePurchaseReturn.md) |

## Documentation

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
| `app/` | The AppSource app (`Bifrost Quality Management`), registration and permissions |
| `test/` | Test app (`Bifrost Quality Management - Tests`) |
| `tools/` | Pipeline guard scripts |
| `.AL-Go/`, `.github/`, `.alpaca/` | AL-Go for GitHub / COSMO Alpaca pipeline configuration |
