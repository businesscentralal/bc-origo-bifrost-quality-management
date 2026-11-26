# Quality.Disposition.ChangeItemTracking

Changes the lot, serial or package number, or the expiration date, of the failed or passed quantity of one inspection through Microsoft's standard Quality disposition (`Change Item Tracking`, codeunit `Qlty. Disp. Change Tracking`). It creates an item reclassification line, or a warehouse reclassification line at a location with directed put-away and pick, in the batch named in Quality Management Setup. `postImmediately=true` posts it in the same call.

Identify the exact inspection, including its re-inspection, with `inspectionSystemId`. The inspection must name a lot, serial or package number; this type does not add tracking to untracked stock. Send at least one of `newLotNo`, `newSerialNo`, `newPackageNo` (each up to 50 characters) or `newExpirationDate` (`YYYY-MM-DD`), plus `quantityBasis` (`failed` or `passed`) and `confirm=true`. Optional `quantity` (a positive base quantity) changes less than the basis quantity. Optional exact `sourceLocationCode` (10 characters) and `sourceBinCode` (20) constrain the standard source selection; filter syntax is refused. `postImmediately` defaults to false (prepare only).

```json
{"type":"Quality.Disposition.ChangeItemTracking","data":{"inspectionSystemId":"<inspection-SystemId>","quantityBasis":"failed","newLotNo":"LOT-QA-01","confirm":true,"expectedCount":1}}
```

The response states `posted` and lists what this call created: `journalLines` (with the current and new lot, serial, package number and new expiration date), `warehouseJournalLines`, and after posting `ledgerEntries` (the outbound and inbound transfer entries) and `warehouseEntries`.

Refusals before any change return typed errors with `parameter`, `expected` and `nextStep`: no new value, a value over 50 characters, a malformed date, a missing or malformed `inspectionSystemId`, `confirm` not true, unknown keys, filter syntax, an unknown inspection, an untracked inspection and a zero quantity. Microsoft refusals (missing reclassification batch, insufficient stock, or a new expiration date for only part of a lot: Microsoft changes the date of a lot only for its whole remaining quantity) and any late failure leave neither lines nor entries.

The caller needs `BIFROST QM Full ori` and the standard Microsoft item journal, item tracking and posting permissions; no Microsoft permission is elevated. The Read and base roles are refused.

This is **not idempotent**. Posted entries change the identity of stock and cannot be undone by repeating the request; a repeated request changes stock again. There is no delete type and no undo type.

Microsoft's ordinary quality posting commits before individual lines. The wrapper binds standard posting with commit suppression and prohibits explicit commits, so a refusal rolls back line creation and posting together. With `Omit Commit`, the calling extension owns the transaction. No trial, licence, consent or external-provider state is changed.

Foundation applies its irreversible-operation preview: `expectedCount` counts the one inspection (send `1`). Any other value is refused before any change. With Require Confirmation for Irreversible Messages enabled in Bifrost Setup (on by default), omitting `expectedCount` reads the count and changes nothing. This does not replace `confirm=true`.
