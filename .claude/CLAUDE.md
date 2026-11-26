# Extension: Bifrost Quality Management

## Customer
Origo / AppSource

## Prefix
(none - objects use raw names with the mandatory `ori` suffix inside the `Origo.Bifrost.QualityManagement` namespace; same as Bifrost Subscription Billing)

## Namespace
Origo.Bifrost.QualityManagement (tests: Origo.Bifrost.QualityManagement.Test)

## Object ID Range
App:   10035235-10035334
Tests: 97200-97299

| Type | ID | Name |
| --- | --- | --- |
| Codeunit | 10035235 | Quality Registration ori |
| Permission set | 10035236 | BIFROST Quality ori |
| Permission set | 10035237 | BIFROST QM Full ori |
| Permission set | 10035238 | BIFROST QM Read ori |
| Permission set extension | 10035239 | Quality Full Role ori |
| Permission set extension | 10035240 | Quality Read Role ori |
| Table | 10035320 | Quality Reinspect Access ori |
| Codeunit | 10035321 | Quality Reinspect Impl ori |
| Codeunit | 10035322 | Quality Reinspect Proc ori |
| Enum extension | 10035323 | Quality Reinspect Types ori |
| Test codeunit | 97207 | Quality Reinspect Tst ori |
| Test codeunit | 97208 | Quality Action Perm Tst ori |
| Enum extension | 10035255 | Quality Reopen Types ori (`Quality.Inspection.Reopen`) |
| Codeunit | 10035256 | Quality Reopen Impl ori |
| Table | 10035258 | Quality Reopen Access ori |
| Enum extension | 10035241 | Quality Message Types ori (shared by issues 3 and 6) |
| Codeunit | 10035242 | Quality Set Value Impl ori |
| Table | 10035243 | Quality Write Access ori (shared empty permission capability) |
| Codeunit | 10035250 | Quality Create Impl ori |
| Codeunit | 10035251 | Quality Create Context ori |
| Test codeunit | 97202 | Quality Set Value Tst ori |
| Test codeunit | 97203 | Quality Value Fault ori |
| Test permission set | 97204 | QM Message Test ori |
| Test enum extension | 97205 | Quality Fixture Types ori |
| Test codeunit | 97209 | Quality Value Errors Tst ori (issue 34 typed refusals) |
| Test codeunit | 97206 | Quality Value Fixture ori |
| Test codeunit | 97240 | Quality Create Tst ori |
| Test enum extension | 97211 | Quality Create Fixtures ori |
| Test codeunit | 97242 | Quality Create Fixture Mgt ori |
| Test codeunit | 97213 | Quality Create Fault ori |
| Test permission set | 97244 | QM Create Test ori |
| Test table | 97215 | Quality Create Fixture ori |
| Test codeunit | 97200 | Quality Scaffold Tst ori |
| Test codeunit | 97220 | Quality Reopen Tst ori |
| Test codeunit | 97221 | Quality Reopen Perm Tst ori |
| Test codeunit | 97250 | Quality Move Tst ori |
| Test codeunit | 97251 | Quality Move Fault ori |
| Test permission set | 97252 | QM Move Test ori |
| Test codeunit | 97253 | Quality Move MCP Seed ori |
| Test page | 97254 | Quality Move MCP Fixture ori |
| Test permission set | 97201 | QM Setup Test ori |

| Enum extension | 10035244 | Quality Return Types ori |
| Codeunit | 10035245 | Quality Purch Return Impl ori |
| Table | 10035246 | Quality Return Access ori (permission capability) |
| Codeunit | 10035247 | Quality Return Receipt ori |
| Test codeunit | 97210 | Quality Return Tst ori |
| Test codeunit | 97211 | Quality Return Fault ori |
| Test codeunit | 97212 | Quality Return Fixture ori |
| Test enum extension | 97213 | Quality Return Fixtures ori |
| Test permission set | 97214 | QM Return Test ori |
| Test codeunit | 97215 | Quality Return Errors Tst ori |

| Enum extension | 10035280 | Qlty Finish MsgType ori |
| Codeunit | 10035281 | Qlty Insp Finish Ctr ori |
| Codeunit | 10035282 | Qlty Insp Finish Impl ori |
| Codeunit | 10035283 | Qlty Insp Finish Proc ori |
| Table | 10035284 | Qlty Finish Access ori (empty permission capability) |
| Test codeunit | 97230 | Qlty Insp Finish Tst ori |
| Enum extension | 10035310 | Quality Track Types ori (`Quality.Disposition.ChangeItemTracking`, value 10035310, issue 17) |
| Codeunit | 10035311 | Quality Track Impl ori |
| Table | 10035312 | Quality Track Access ori (permission capability) |
| Reserved | 10035313 | issue 17 reserve (unused) |
| Test codeunit | 97280 | Quality Track Tst ori |
| Test codeunit | 97281 | Quality Track Fault ori |
| Reserved | 97282-97283 | issue 17 reserve (unused) |
| Enum extension | 10035318 | Quality Report Types ori (`Quality.Report.Print`) |
| Codeunit | 10035319 | Quality Report Impl ori |
| Codeunit | 10035332 | Quality Report Proc ori |
| Test codeunit | 97255 | Quality Report Tst ori |
| Test codeunit | 97256 | Quality Report Limit ori |

## Issue 11 objects

| Type | ID | Name |
| --- | --- | --- |
| Enum extension | 10035294 | Quality Picture Types ori |
| Codeunit | 10035295 | Quality Picture Impl ori |
| Table | 10035296 | Quality Picture Access ori |
| Codeunit | 10035297 | Quality Picture Proc ori |
| Test codeunit | 97264 | Quality Picture Tst ori |
| Test fixture codeunit | 97265 | Quality Picture Fixture ori |
| Test permission set | 97266 | QM Picture Test ori |
| Test fault codeunit | 97266 | Quality Picture Fault ori |
| Test enum extension | 97267 | Quality Picture Fixtures ori |
| Enum extension | 10035298 | Quality Transfer Types ori (`Quality.Disposition.CreateTransferOrder`) |
| Codeunit | 10035299 | Quality Transfer Impl ori |
| Table | 10035300 | Quality Transfer Access ori (permission capability) |
| Codeunit | 10035301 | Quality Transfer Capture ori |
| Test codeunit | 97268 | Quality Transfer Tst ori |
| Test codeunit | 97269 | Quality Transfer Fault ori |
| Test permission set | 97270 | QM Transfer Test ori |

## Microsoft source
Wrapped Microsoft app: Quality Management (`bc7b3891-f61b-4883-bbb3-384cdef88bec`, 28.5.0.0). Source: https://github.com/microsoft/BCApps/tree/main/src/Apps/W1/Quality%20Management
Read it there before designing message types.

## Setup Notifications
Setup notifications live **only** on Bifröst Foundation's `Setup ori` page. This app never raises a `Notification` of its own.
It makes itself known to Foundation by subscribing to `App Registry ori.OnRegisterApps` and calling `AddApp` with this
app's module id, its display name and its setup page id (`0` while the app has no setup page). Follow
`app/src/Common/SubRegistration.Codeunit.al` in Bifrost Subscription Billing.

## Target BC Version
28.5 (application 28.5.0.0, platform 28.0.0.0, runtime 17.0)

## Source Control
Platform: GitHub
Organization: businesscentralal
Repository: bc-origo-bifrost-quality-management
Default branch: main

## Dependencies
- Bifrost Foundation (`7505e808-6e52-4b96-a328-82573391297a`, 28.0.15.6, current released Foundation minimum for first-release readiness)
- Quality Management (Microsoft, 28.5.0.0; application floor 28.5.0.0)

## Naming Rules
- Every object carries the `ori` suffix (AppSource mandatory affix), max 30 characters.
- The brand name "Bifrost" lives in the namespace, the app name ("Bifrost Quality Management"), the permission sets and
  user-facing captions - never as an object-name prefix.
- Message type names have three parts: `Domain.Entity.Action`.
- Icelandic captions use "Bifröst".

## Development Standards

This project follows the **Origo BC Development Standards** (https://github.com/OrigoSoftwareSolutions/bc-dev-standards).

Before writing any AL code, load the relevant skills: `origo-bc-al-coding-standards`, `origo-bc-test-writer`, `origo-bc-documentation-writer`.

Key rules always in effect:
- Namespace `Origo.Bifrost.QualityManagement` at the top of every app file (`Origo.Bifrost.QualityManagement.Test` in tests)
- XML documentation on every object and non-local procedure
- Bilingual captions (en-US + is-IS) on all user-facing text
- `SetLoadFields` on all record reads
- `Format(guid, 0, 4)` for GUIDs, `Format(value, 0, 9)` / `Evaluate(var, text, 9)` for culture-invariant serialization
- Never use `Format()` / `Evaluate()` on enum values - use `.Names()`, `.Ordinals()`, `.AsInteger()`, `.FromInteger()`
- Implementation = code + tests + documentation (the contract chapters of `Msg Contract ori`)

## Development Environment
- COSMO Alpaca containers are defined in `app/.vscode/launch.json` (git-ignored, the authority for instance ids).
- Compile locally with alc.exe + CodeCop/UICop/AppSourceCop; AL-Go CI is the gate for AppSource affix rules (AS0011).
- `app/AppSourceCop.json` sets `mandatoryAffixes`/`mandatorySuffix` to `ori` and the supported countries.
- Reference implementation: Bifrost Subscription Billing (businesscentralal/bc-origo-bifrost-subscription-billing).

## Message Type Conventions
- One enum extension of Foundation's `Message Type ori` with one value per type, named `Domain.Entity.Action`. These
  keys are the published external API contract and must never be renamed or removed.
- Each type has an Impl codeunit implementing `Msg Interface ori`, `Msg Discovery ori` and `Msg Contract ori`, with
  `TableNo = "Message Argument ori"` and an `OnRun` that runs its own write, as in Bifrost Subscription Billing.
- Errors are returned as `status = Error` with a helpful message; never let an unhandled exception reach the API.

## Test App Rules
- The test app uses Bifröst Foundation's public API only. Run message types through the public `Dispatcher ori`.

## Testing Through the MCP Server
- Keep MCP calls serial - parallel bursts crash the server.
