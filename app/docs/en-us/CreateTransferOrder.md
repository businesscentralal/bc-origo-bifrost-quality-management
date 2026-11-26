# Quality.Disposition.CreateTransferOrder

Creates transfer order(s) for the failed or passed stock of one inspection through Microsoft's standard Quality disposition interface (`Create Transfer Order`), for example to send failed stock to a quarantine location. The transfer order is created and left open: nothing is shipped, received or posted. The response lists `transferOrderNos`.

Identify the exact inspection, including its re-inspection, with `inspectionSystemId`. Send `quantityBasis` (`failed` or `passed`), the required `destinationLocationCode` and `confirm=true`. Optional: `quantity` (a specific base quantity greater than zero), exact `sourceLocationCode` (10 characters) and `sourceBinCode` (20), `destinationBinCode` (20; Microsoft transfer orders carry no destination bin) and `inTransitLocationCode` (10). Filter syntax in location or bin codes is refused. Without an in-transit location, Microsoft uses the transfer route between the locations, otherwise the transfer is direct.

```json
{"type":"Quality.Disposition.CreateTransferOrder","data":{"inspectionSystemId":"<inspection-SystemId>","quantityBasis":"failed","destinationLocationCode":"QUARANTINE","confirm":true,"expectedCount":1}}
```

The caller needs `BIFROST QM Full ori` and the native Microsoft transfer order permissions; the Read and base roles are refused. A refusal from Microsoft (setup, locations, bins) or a late failure rolls back everything the call did. With `Omit Commit` the calling extension owns the transaction.

This is **not idempotent**. A repeated successful request can create another transfer order. Do not retry a successful request automatically. No delete or cancel message type exists; remove an unwanted transfer order in Business Central.

Foundation applies its standard irreversible-operation preview: send `expectedCount=1` for the single inspection (not the number of transfer orders). A count other than 1 is refused before any change; omitting it reads the count and changes nothing while Require Confirmation for Irreversible Messages is enabled.

Refusals are typed (`code`, `parameter`, `expected`, `nextStep`): `MissingParameter` for a missing or malformed `inspectionSystemId` or missing `destinationLocationCode`, `InvalidParameter` for `confirm`, filter syntax, quantity or basis, `UnknownParameter`, `RecordNotFound` for an unknown inspection and `PreconditionFailed` when the inspection quantity is zero.
