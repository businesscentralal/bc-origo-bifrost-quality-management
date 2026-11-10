# Quality.Disposition.CreatePurchaseReturn

```json
{"type":"Quality.Disposition.CreatePurchaseReturn","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001","reasonCode":"QUALITY","vendorCreditMemoNo":"VC-001"}}
```

Creates an **unposted purchase return order** for the inspection’s failed quantity through Microsoft `Qlty. Disp. Purchase Return`. Requires a Purchase Line source, positive failed quantity, sufficient received quantity, purchase setup and `BIFROST QM Full ori` plus native purchase permissions. `reasonCode` (10 characters) and `vendorCreditMemoNo` (35 characters) are optional strings. Unknown/missing/invalid inputs and business refusals change nothing. It does not post a vendor credit memo. **Not idempotent:** retries can create additional returns. No explicit Commit occurs on the standard path; explicit subscriber commits are prohibited. Normal processing rolls back on refusal; Omit Commit requires caller rollback.

```json
{"status":"Success","inspectionSystemId":"00000000-0000-0000-0000-000000000001","returnOrderNo":"PRO00001"}
```

| Code | Parameter | Recovery |
| --- | --- | --- |
| `MissingParameter` | `inspectionSystemId` | Supply a non-empty inspection SystemId. |
| `RecordNotFound` | `inspectionSystemId` | Read an existing inspection; `received` repeats the unknown GUID. |
| `InvalidParameter` | Invalid GUID or optional text | Correct the format or length. |
| `PermissionDenied` | `permissionSet` | Request the documented app/native permissions. |
| `PreconditionFailed` | `inspectionSystemId` | Select a purchase inspection and check disposition setup/subscribers. |

Each app-owned refusal includes `parameter`, `expected` and `nextStep`. Native Business Central validations keep their standard error classification. A post-write refusal rolls back the return.
