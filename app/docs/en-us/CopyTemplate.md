---
title: Quality.Template.Copy
audience: developer, admin
keywords: quality, inspection template, copy, duplicate
locale: en-us
---

```json
{"type":"Quality.Template.Copy","data":{"sourceTemplateCode":"INCOMING","targetTemplateCode":"INCOMING-V2","targetDescription":"Incoming goods, version 2","expectedCount":1}}
```

Copies one quality inspection template, with all its lines and their result conditions, to a new template code in one call. It runs Microsoft report `Qlty. Inspection Copy Template` (20402) on its single-copy path (Create from Item Nos. off), so the copy is the standard one: every line keeps its line number, test and values, and both the new header and its lines show the source in `Copied From Template Code`.

| Key | Required | Value |
| --- | --- | --- |
| `sourceTemplateCode` | Yes | Code of an existing template, at most 20 characters |
| `targetTemplateCode` | Yes | New code, at most 20 characters; must not exist and must differ from the source |
| `targetDescription` | No | At most 100 characters; defaults to the source description (required when the source has none) |
| `expectedCount` | See below | The one new template, so `1` |

The response returns `templateCode`, `description`, `copiedFromTemplateCode` and `linesCopied` (the number of lines of the new template).

Refusals, all before any change and with `parameter`, `expected` and `nextStep`: a missing code (`MissingParameter`), an unknown source (`RecordNotFound`), a target that already exists (`PreconditionFailed`), a code or description that is too long, a non-text value or source equal to target (`InvalidParameter`), and an unknown key (`UnknownParameter`).

This type only creates a template. It never adds lines to an existing template, and it never changes or deletes a template or a line. To merge into an existing template, use the Copy Template action in Business Central yourself.

`expectedCount` counts the one new template. A value other than `1` is refused (`ConfirmationMismatch`) and nothing changes. With Require Confirmation for Irreversible Messages enabled in Bifrost Setup, a call without `expectedCount` returns `ConfirmationRequired` with the expected count and changes nothing.

Effect: inserts one template header, its lines and their result conditions. Not idempotent: a second call with the same target is refused because the target now exists. There is no `Commit` on the standard path; a refusal or error rolls back the whole copy. With `Omit Commit`, the caller owns rollback.

Assign `BIFROST QM Full ori` with a Foundation processing role. The Read and base sets cannot execute this operation. The caller also needs native insert permission on the template header, template line and result condition tables (Microsoft `QltyMgmt - Admin`, which the Full set includes). No external provider is called.

Copying from items (bulk copy) is not supported: that path of the report asks for confirmation.
