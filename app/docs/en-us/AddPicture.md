# Quality.Inspection.AddPicture

```json
{
  "type": "Quality.Inspection.AddPicture",
  "data": {
    "inspectionSystemId": "<inspection-systemId>",
    "stagingId": "<owned-upload-systemId>",
    "fileName": "inspection-photo",
    "expectedCount": 1
  }
}
```

Replaces the **Most Recent Picture** of one open quality inspection. Use exactly one of
`base64` (encoded image bytes) and `stagingId` (a Foundation upload owned by the current
user in the current company). JPEG, PNG and BMP are accepted. The image decoder verifies
the bytes; a misleading name or MIME claim cannot enable another format.
The maximum decoded size is **1 MiB (1048576 bytes)**. An image exactly at the limit is accepted.
The base64 text is also bounded to 1398104 characters before decoding.

| Parameter | Rule |
| --- | --- |
| `inspectionSystemId` | Required non-empty SystemId GUID of an open inspection |
| `base64` | Image bytes encoded as non-empty base64; excludes `stagingId` |
| `stagingId` | Non-empty GUID of the caller's staged upload; excludes `base64` |
| `fileName` | Optional 1–250 character name without path separators; default `inspection-picture` |
| `expectedCount` | Optional integer; must equal 1 (one inspection) |

The detected image extension is appended to the name; the base name is shortened to keep the stored name within 250 characters. Unknown keys are refused.

```json
{
  "status": "Success",
  "inspectionSystemId": "<inspection-systemId>",
  "additionalHandlingApplied": false
}
```

The write replaces the media field and does not retain earlier pictures. It does not capture
camera images, open file dialogs, create extra document attachments or upload to OneDrive.
Microsoft's additional-picture handling procedure is local/internal, so it cannot be called
through the public Quality Management API. `additionalHandlingApplied` is always `false`.

| Refusal | Examples |
| --- | --- |
| `MissingParameter` | Inspection ID or both image sources missing |
| `InvalidParameter` | Invalid GUID, both sources, malformed/non-image bytes, unsupported format, over 1 MiB, invalid file name |
| `UnknownParameter` | Any undeclared key |
| `PreconditionFailed` | Finished inspection or `expectedCount` other than integer 1 |
| `RecordNotFound` | Unknown inspection or unavailable staging ID |
| `PermissionDenied` | Full capability or native inspection Modify permission missing |
| `BusinessCentralError` | Native media or database write failed |

Typed refusals include `parameter`, `expected` and `nextStep`. Unknown, foreign-user and
foreign-company staging IDs receive the same non-disclosing refusal.
`BIFROST QM Full ori` grants the dedicated capability. Read and base roles cannot write;
the caller still needs native inspection Modify permission.

1. Stage an image with Foundation, or encode a small image as base64.
2. Read the intended open inspection SystemId.
3. Send the request. On success, staging is consumed. On any refusal or failure it remains
   available, and the inspection's previous picture remains unchanged.

The public `Blob Staging ori.Take` and the media write run in one transaction.
Validation after Take raises on failure so the delete rolls back. Explicit subscriber commits
are prohibited. In omit-commit mode the caller owns commit and rollback and must not catch
an error without rolling back. Base64 retries replace the picture with new media and are not
idempotent; a staged upload can succeed only once. No external provider is called.

Discovery and refusals follow the caller's language. Foundation intentionally returns public
contract chapters in English, including for LCID 1039. The app owns English and Icelandic
contract labels and guides; no help page or contextSensitiveHelpUrl change is needed.
