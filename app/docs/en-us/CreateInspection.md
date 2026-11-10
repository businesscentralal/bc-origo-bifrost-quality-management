---
title: Create a quality inspection
audience: integrator
keywords: [quality, inspection, create]
locale: en-us
---

# Create a quality inspection

```json
{"type":"Quality.Inspection.Create","data":{"sourceTableId":39,"sourceSystemId":"00000000-0000-0000-0000-000000000001","templateCode":"RECEIPT"}}
```

`sourceTableId` is a positive integer and `sourceSystemId` is the GUID of one visible record in the current company. `templateCode` is optional, non-empty when supplied and at most 20 characters. Without it, Microsoft generation rules choose the template. Unknown keys and invalid identifiers are refused before creation.

The operation calls Microsoft’s Create Inspection API and `Qlty. Inspection - Create`. The optional template is supplied through its native event; template validation, source mapping, numbering and workflow events still run. It does not post a source document or call an external provider.

Assign `BIFROST QM Full ori` (included by Foundation Full) and appropriate native source/Quality Management permissions. Foundation Read/API roles alone do not grant creation.

The response contains `status`, `inspectionSystemId`, `inspectionNo`, `reinspectionNo` and `templateCode`. Creation is **not idempotent**: repeated calls follow Microsoft setup, which can reuse an inspection or create a new one. The normal transaction rolls back all writes on a refusal, including a failure after native insertion. There is no explicit Commit on the standard creation path; explicit subscriber commits are prohibited. With Omit Commit the caller owns rollback.

Configure Quality Management, number series and source mappings before use. Generation rules are required when templateCode is omitted. A missing source, invalid template, missing setup or permission failure returns a structured refusal. Runtime help is available through Foundation’s message catalogue and contract API.
