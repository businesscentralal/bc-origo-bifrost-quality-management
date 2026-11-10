# Quality.Disposition.MoveInventory

Moves the failed or passed quantity of one inspection through Microsoft's standard Quality disposition interface. It creates item or warehouse reclassification lines, internal movements or movement worksheet lines. `postImmediately=true` posts reclassification immediately. Worksheet and internal movement methods prepare only.

Identify the exact inspection, including its re-inspection, with `inspectionSystemId`. Send `quantityBasis` (`failed` or `passed`), `method` (`automatic`, `itemReclassification`, `warehouseReclassification`, `movementWorksheet`, `internalMovement`), a destination location and/or bin, and `confirm=true`. Optional exact `sourceLocationCode` (10 characters) and `sourceBinCode` (20) constrain the standard source selection; filter syntax is refused. Destination limits are 10 and 20 characters. Unknown keys, malformed values and missing required keys are refused before any movement. `postImmediately` defaults to false.

```json
{"type":"Quality.Disposition.MoveInventory","data":{"inspectionSystemId":"<inspection-SystemId>","quantityBasis":"failed","method":"itemReclassification","destinationLocationCode":"QUARANTINE","confirm":true,"expectedCount":1}}
```

The caller needs `BIFROST QM Full ori` and the standard Microsoft permissions for the selected inventory operation. The Full role includes Microsoft's `QltyMgmt - Inspector` permissions; no other inventory permissions are elevated. Microsoft validates inventory, locations, bins and movement setup. The inspection's Pass Quantity or Fail Quantity must be positive. Use the help contract for the exact response fields.

This is **not idempotent**. A repeated successful request may create another movement. Do not automatically retry a successful request. Posted entries affect inventory and cannot be undone by repeating the request.

Microsoft's ordinary quality posting commits before individual lines. The wrapper binds standard item/warehouse posting with commit suppression and prohibits explicit commits during the disposition. A business refusal rolls back line creation and posting together. Normal success commits once through the isolated wrapper. With `Omit Commit`, the calling extension owns the transaction and rollback. No trial, licence, consent or external-provider state is changed.

Foundation also applies its standard irreversible-operation preview: send `expectedCount=1` for the single inspection. A stale count is refused before movement. This does not replace `confirm=true`.
