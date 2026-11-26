---
title: Quality.Report.Print
audience: developer, admin
keywords: quality, report, certificate of analysis, non-conformance, pdf
locale: en-us
---

```json
{"type":"Quality.Report.Print","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001","report":"certificateOfAnalysis","languageCode":"en-US"}}
```

Renders one of Microsoft's Quality Management reports for one inspection as a PDF and returns it through Foundation staging. It changes no business data; the only write is the Foundation staging row, which is scratch data.

| Key | Required | Value |
| --- | --- | --- |
| `inspectionSystemId` | yes | SystemId of the inspection |
| `report` | yes | `certificateOfAnalysis` (Certificate of Analysis), `nonConformance` (Non-Conformance report) or `general` (general purpose inspection report) |
| `languageCode` | no | `en-US` or `is-IS`; the session language is restored after rendering, also after a refusal |

Result: `stagingId` of the PDF, `fileName` (inspection number, re-inspection number and report), `contentType` (`application/pdf`) and `sizeBytes`. Read the PDF with the existing staging types using `stagingId`.

Refused before rendering with a typed error: a missing or malformed `inspectionSystemId`, a missing or unknown `report`, an unknown `languageCode`, unknown keys and an unknown inspection (`RecordNotFound`). A result over 10,485,760 bytes is refused with `LimitExceeded`, not truncated, and no staging row is left. Whatever the report itself refuses is returned as `BusinessCentralError`.

Permissions: assign `BIFROST QM Read ori` with the Microsoft Quality Management read permissions (`QltyMgmt - Read`) and the basic company data read access the reports use. A caller without read access to the inspection or execute permission for the report gets `PermissionDenied`.

The Microsoft report object is rendered with its default layout. A custom Report Selections entry is not used. No external provider is called.
