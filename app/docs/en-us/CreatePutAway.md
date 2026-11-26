# Quality.Disposition.CreatePutAway

```json
{
  "type": "Quality.Disposition.CreatePutAway",
  "data": {
    "inspectionSystemId": "00000000-0000-0000-0000-000000000001",
    "kind": "internal",
    "quantityBasis": "failed",
    "confirm": true,
    "expectedCount": 1
  }
}
```

Creates an internal or warehouse put-away through the standard Microsoft disposition interface. Nothing is registered or posted.

Not idempotent: repeating a successful call can create another document.

Use `kind=internal` or `kind=warehouse`, and `quantityBasis=failed` or `quantityBasis=passed`. Optional `quantity` is a positive base quantity no greater than the selected inspection quantity. `sourceLocationCode` (10 characters) and `sourceBinCode` (20 characters) are exact codes, without filter syntax. `releaseImmediately` defaults to false and is refused for warehouse put-away, even if false. Internal release does not register stock.

`confirm=true` is required. `expectedCount` counts exactly one inspection, not documents or lines. A supplied value other than 1 is refused. Omitting it previews without changes when Require Confirmation for Irreversible Messages is enabled. The response returns `documentNumbers`, `kind`, `released` and `registered=false`.

The caller needs BIFROST QM Full ori and native warehouse permissions. Standard locations, bins, numbering, put-away templates and sufficient stock must be configured. Native refusals and late failures roll back every document. Typed input errors identify `parameter`, `expected` and `nextStep`.
