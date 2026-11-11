---
title: Quality.Inspection.Reopen
audience: developer, admin
keywords: quality, inspection, reopen
locale: en-us
---

```json
{"type":"Quality.Inspection.Reopen","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001"}}
```

Reopens one finished inspection by calling Microsoft `Qlty. Inspection Header.ReopenInspection`. The message does not write Status or quantities itself.

| Required key | Value |
| --- | --- |
| `inspectionSystemId` | SystemId of the inspection and re-inspection to reopen |

A missing key, a key that is not a non-empty GUID, an unknown key, or an unknown inspection is refused before a write. Microsoft refuses the action when the user is not Quality Admin & Supervisor or SUPER, or when a later re-inspection exists. That refusal is `status: Error` and leaves the inspection unchanged.

Effect: a finished inspection becomes open. On this Business Central version `ReopenInspection` then saves the record, and the pass and fail quantities that were already stored stay. The action is idempotent: calling it again on the open inspection changes nothing. There is no `Commit` on the standard path. A business refusal rolls back. With `Omit Commit`, the caller owns rollback.

Assign `BIFROST QM Full ori` with a Foundation processing role. The Read and base sets cannot execute this operation. Microsoft still checks that Quality Admin & Supervisor, or SUPER, is assigned to the user. No external provider is called.

Use Foundation `Data.Records.Get` for ordinary reads. A direct `Data.Records.Set` of Status is not this operation.
