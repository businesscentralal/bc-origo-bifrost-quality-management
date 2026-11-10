# Quality.Inspection.CreateReinspection

Creates a re-inspection through `Qlty. Inspection Header.CreateReinspection(var header)` and the standard `Qlty. Inspection - Create` codeunit. Requires `BIFROST QM Full ori` and native Quality Inspector data permissions; the Foundation Full role includes the Bifrost action permission. The Read role cannot execute it.

```json
{"type":"Quality.Inspection.CreateReinspection","data":{"inspectionSystemId":"<source-systemId>"}}
```

`inspectionSystemId` is the only accepted data key and must be a non-empty GUID identifying a visible inspection. Missing, malformed, unknown record IDs and unknown keys return a coded refusal before changing business data. The response contains one result: `systemId`, `inspectionNo`, `reinspectionNo`, and `sourceSystemId`.

An open source is finished using native checks first. Creation uses the latest revision with the same inspection number even if the requested source is older. The new revision is open, its completion and result values are cleared, template lines are regenerated, and the preceding revision loses its most-recent flag. Standard setup, result, tracking and permissions checks apply.

**Not idempotent:** each successful retry creates another revision. Inspect the previous response before retrying. The native table path contains no explicit Commit; the page action's later Commit is not called. The wrapper rejects explicit subscriber commits. A normal task commits after success, while a caught native error rolls back all native changes. In omit-commit mode the error propagates to the enclosing task transaction so that it can roll back the entire chain. No live-provider calls are made.

Translated discovery and refusal text is available in en-US and is-IS. The same contract is available through `Help.Implementation.Get` / `get_message_type_help`.
