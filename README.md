# Bifröst Quality Management

**App name:** Bifrost Quality Management
**Publisher:** Origo — **Version:** 28.0.0.0 — **Target:** Cloud (BC 28.5, runtime 17.0)
**App ID:** `d3ca6790-e2c1-44c1-a026-fd75a3f5b52d` — **Test app ID:** `9193f6a2-0926-49bb-9fec-3c36a60c8b0e`
**Object ID range:** 10035235–10035334 (tests 97200–97299) — **Namespace:** `Origo.Bifrost.QualityManagement`

Bifrost Quality Management makes Microsoft's **Quality Management** app callable from outside Business Central through
Bifröst message types, so an agent can operate it end to end. It is built on the same basis as
[Bifrost Subscription Billing](https://github.com/businesscentralal/bc-origo-bifrost-subscription-billing).

**Microsoft source:** <https://github.com/microsoft/BCApps/tree/main/src/Apps/W1/Quality%20Management>

**Status:** implements `Quality.Disposition.MoveInventory` through Microsoft's standard disposition interface, with explicit confirmation and optional atomic reclassification posting.

See the [English](app/docs/en-us/MoveInventory.md) and [Icelandic](app/docs/is-is/MoveInventory.md) call guides, or read the live contract with `Help.Implementation.Get`. Repeated successful calls can create additional movements; this operation is not idempotent.

Foundation discovers this app on **Bifrost Setup** through its application registry. All setup notifications stay on that Foundation page. Quality Management has no setup page of its own.

Assign `BIFROST Quality ori`, `BIFROST QM Full ori` or `BIFROST QM Read ori` alongside the appropriate Foundation role. Foundation Full and Read already include the matching Quality Management set. The Full set also grants the inventory disposition entry point and its capability. The caller still needs the appropriate Microsoft Quality Management and inventory permissions; these Bifröst roles do not elevate business-data access.

The app manifest exposes the `quality-management` documentation entry in English and Icelandic. The complete object allocation is recorded in [.claude/CLAUDE.md](.claude/CLAUDE.md).

---

## Object ranges

| Object | Range |
| --- | --- |
| App (`app/`) | 10035235-10035334 |
| Test app (`test/`) | 97200-97299 |

---

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
| `app/` | The AppSource app (`Bifrost Quality Management`), registration, disposition and permissions |
| `test/` | Test app (`Bifrost Quality Management - Tests`) |
| `tools/` | Pipeline guard scripts |
| `.AL-Go/`, `.github/`, `.alpaca/` | AL-Go for GitHub / COSMO Alpaca pipeline configuration |
