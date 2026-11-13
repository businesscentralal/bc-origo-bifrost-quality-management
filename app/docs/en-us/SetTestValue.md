---
title: Quality.Inspection.SetTestValue
audience: developer, admin
keywords: quality, inspection, test, result
locale: en-us
---

```json
{"type":"Quality.Inspection.SetTestValue","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001","testCode":"TEMP","value":"20"}}
```

Validates one test value on an open inspection and recalculates its overall result using Microsoft's `SetTestValue` and `UpdateResultFromLines` methods.

| Required key | Value |
| --- | --- |
| `inspectionSystemId` | SystemId of the exact inspection and re-inspection |
| `testCode` | Test code, maximum 20 characters; exactly one line must match |
| `value` | Text, maximum 250 characters; empty text clears the value if Microsoft permits |

Unknown keys, absent keys, non-text values, invalid identifiers and overlong values are refused before a write. Microsoft rejects finished inspections, ambiguous or absent tests, invalid values and missing setup. A refusal returns `status: Error`. Normal execution rolls back line and header changes together. With `Omit Commit`, the caller owns rollback. There is no explicit `Commit` on the standard path, and explicit commits in subscribers are prohibited.

Success returns `status`, `inspectionSystemId`, `inspectionNo`, `reinspectionNo`, `testCode` and `resultCode`. The line value, related expressions and header result may change; Microsoft triggers and subscribers run. Repeating the value is **not guaranteed idempotent**. Assign `BIFROST QM Full ori` with a Foundation processing role; the Full set includes Microsoft's inspector permissions. The Read and base sets cannot execute this operation. No external provider is called.

Use Foundation `Data.Records.Get` for ordinary reads. A direct `Data.Records.Set` is not equivalent to this operation's validation and result recalculation.

Own input, access, not-found and status checks return `MissingParameter`, `InvalidParameter`, `UnknownParameter`, `PermissionDenied`, `RecordNotFound` or `PreconditionFailed`. The response includes `parameter`, `expected` and `nextStep`, plus `received` when available. Codes and parameter names are language-neutral; guidance is translated. Native Microsoft validation can return `BusinessCentralError`.
