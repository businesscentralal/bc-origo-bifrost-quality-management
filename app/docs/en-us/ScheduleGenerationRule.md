---
title: Schedule generation rules
description: Create one recurring quality-inspection job with explicit activation.
---

# Schedule generation rules

```json
{"type":"Quality.GenerationRule.Schedule","data":{"scheduleGroup":"QM","startTime":"08:00:00","daysOfWeek":[1,2,3,4,5],"repeatEveryMinutes":60,"activate":false,"expectedCount":1}}
```

This admin write creates one standard Job Queue Entry for Microsoft's `Qlty. Schedule Inspection` report. It does not execute the report or create inspections during the call. The job starts **On Hold**. Set `activate: true` to make it **Ready** through the standard scheduler; future runs can then create inspections.

| Parameter | Format and default |
| --- | --- |
| `scheduleGroup` | Code of 1–20 characters; default `QM`. Standard code normalization applies. |
| `startTime` | Required `HH:mm:ss`, `00:00:00`–`23:59:59`, in the scheduling user's time zone; maps to Starting Time. Midnight uses standard `0T`. |
| `daysOfWeek` | Nonempty array of unique integers, 1=Monday to 7=Sunday. Default all seven days. Maps to the seven Run on … fields. |
| `repeatEveryMinutes` | Integer 1–2147483647; default 1440 (daily). Maps to No. of Minutes between Runs. |
| `activate` | JSON boolean; default false. |
| `expectedCount` | One job queue entry, **not future inspections**. A supplied value must equal 1. |

When **Require Confirmation for Irreversible Messages** is enabled in Bifrost Setup, omit `expectedCount` to read `expected: "1"` in a `ConfirmationRequired` response without changing anything. Resend the same request with `expectedCount: 1`. When that setting is disabled, omission permits creation; a supplied count is always checked. The declared effect is `write`.

The response contains `status: "Success"`, `noOfRecords: 1`, `jobQueueEntryId` (GUID), `jobStatus` (`On Hold` or `Ready`), `scheduleGroup` and the invariant enum name in `inspectionCreationOption`. A translated `warning` is included for **Always create new inspection** and **Always create re-inspection**, because these settings can generate inspections on every run even when inspections already exist.

Before creation, the group must contain at least one generation rule, and **every rule** must have a condition, item or item-attribute filter, including disabled rules. Missing rules or setup, unfiltered rules and existing report jobs covering the group return `PreconditionFailed`. Existing jobs created through the standard UI are also detected. Unreadable existing report parameters conservatively prevent creation; review them on Job Queue Entries. Unknown keys, invalid JSON types, overlong/blank groups, invalid times/days and recurrence limits return typed input refusals with `parameter`, `expected` and `nextStep`. Every refusal leaves the job queue unchanged.

Assign `BIFROST QM Full ori` (also included by Foundation Full) and the Foundation API role. The Full role grants the dedicated schedule capability and native job queue permissions. Base and Read roles cannot schedule. Native permissions still apply to any future report execution. No rules or setup are changed. Edit an existing job on **Job Queue Entries**; this type never replaces, deletes, pauses or runs an existing job.

Creation and activation share one transaction. Success commits once; a native error rolls back the entire write. In Omit Commit mode, the caller owns the transaction. This operation is not idempotent: a retry after success is a duplicate refusal.

Implementation uses public BC 28 objects and standard report-parameter XML. Microsoft scheduling helpers are internal and are not called or copied. No page/action or help URL changes are needed.
