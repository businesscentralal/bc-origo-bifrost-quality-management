# Quality.Disposition.CreateNegativeAdjustment

Writes off the failed or passed quantity of one inspection with a negative inventory adjustment through Microsoft's standard Quality disposition interface (`Dispose with Negative Inventory Adjustment`). The adjustment lines are created in the item journal batch named in Quality Management Setup. They stay there unless `postImmediately=true`, which posts them and reduces stock.

Identify the exact inspection, including its re-inspection, with `inspectionSystemId`. Send `quantityBasis` (`failed` or `passed`) and `confirm=true`. Optional: `quantity` (a base quantity greater than zero, written off instead of the whole basis quantity), exact `sourceLocationCode` (10 characters) and `sourceBinCode` (20) with no filter syntax, `reasonCode` (10 characters) and `postImmediately` (default `false`, prepare only).

```json
{"type":"Quality.Disposition.CreateNegativeAdjustment","data":{"inspectionSystemId":"<inspection-SystemId>","quantityBasis":"failed","reasonCode":"SCRAP","postImmediately":false,"confirm":true,"expectedCount":1}}
```

The response states whether the lines were posted (`posted`), lists the journal lines left in the journal (`journalLines`) and the item ledger entries written (`ledgerEntries`).

Journal lines use the standard positive quantity with the Negative Adjmt. entry type. Posted item ledger entries carry the negative inventory quantity.

The caller needs `BIFROST QM Full ori` and the standard Microsoft item journal and posting permissions. The Read role and base roles are refused.

This is **not idempotent**. Posted entries change inventory and a repeated request can write off more stock. Prepared lines are duplicated by a repeat as well. There is no delete type and no "reverse adjustment" type. Do not retry a successful request automatically.

Microsoft's standard posting runs with commits suppressed and explicit commits prohibited. A refusal, such as a missing journal batch, a journal template that forces a posting report, insufficient stock or any late failure, rolls back lines and posting together. Locations with directed put-away and pick use the warehouse journal; only preparing is supported there. With `Omit Commit`, the calling extension owns the transaction.

Foundation also applies its standard irreversible-operation preview: send `expectedCount=1` for the single inspection. A count other than 1 is refused before any change. This does not replace `confirm=true`.

Every refusal before the standard disposition is typed with `parameter`, `expected` and `nextStep`: missing or malformed `inspectionSystemId`, `confirm` not true, unknown keys, filter syntax, unknown inspection, zero quantity and a reason code longer than 10 characters.
