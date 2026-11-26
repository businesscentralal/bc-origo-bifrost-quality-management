# Find inspections for a source record

```json
{
  "type": "Quality.Inspection.FindForRecord",
  "data": {
    "tableId": 39,
    "systemId": "00000000-0000-0000-0000-000000000001",
    "matchOn": [
      "document"
    ],
    "latestOnly": true
  }
}
```

Returns up to 100 inspections using Microsoft's public `SetRecordFiltersToFindInspectionFor` matching method. This call never creates or changes an inspection.

| Input | Meaning |
| --- | --- |
| `tableId` | Required positive integer source-table ID in the current company. |
| `systemId` | Required non-empty GUID of a visible source record. |
| `matchOn` | Required non-empty array of `item`, `tracking`, `document`. Selected filters are combined using native source configuration. |
| `latestOnly` | Optional Boolean, default `true`. Selects the most recent re-inspection of each inspection; `false` includes superseded revisions. |

The response has `status: Success`, an `inspections` array and `truncated`. Each inspection has `inspectionSystemId`, `no`, `reinspectionNo`, `status` (the English enum name) and `result` (the native result code). Rows are ordered by creation time descending, then inspection number and re-inspection number descending to break ties. At most 100 visible rows are returned; `truncated` is true only when more match. No match returns an empty array.

Run with the Foundation Read role, `BIFROST QM Read ori` (already included by Foundation Read), and native read permissions on the source and `Qlty. Inspection Header`. Full is not required. Native source configuration must map all selected matching dimensions. No write confirmation is accepted or required.

Missing required keys are `MissingParameter`; malformed IDs, unknown tables, invalid `matchOn`, unavailable selected source values or invalid booleans are `InvalidParameter`; an unknown key is `UnknownParameter`. Validation runs before inspection reads. An unknown source record is `RecordNotFound`; absent native read permission is `PermissionDenied`. Each refusal includes `parameter`, `expected`, and `nextStep`.
