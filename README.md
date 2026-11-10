# PR32 merged candidate verification

Litr (worker-9), 10 November 2026. Source: `90e766ec2e33c3e168b1b7d9a589dc3978025f7d` ([immutable candidate](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/commit/90e766ec2e33c3e168b1b7d9a589dc3978025f7d)). This evidence-only branch is not another implementation PR.

Main `854f1be3e965ddaad7db4f614dd5cbb80b88fb63` is merged into original Reopen candidate `40a54b4a484fa4ab7cc3ec9c812f12216021c0d2`. Five conflicts resolved by preserving both parents: README, CHANGELOG, object allocation,61 unique translated XLF units, and Full role permission union. All26 supplying-parent handler/test objects are byte-identical. Existing Reopen Read-role permission fix is preserved. No new skips, suppressed warnings, weakened assertions, pipeline edits or unrelated business changes.

Both apps compile at this source SHA with CodeCop/UICop/AppSourceCop:0 errors,0 warnings. First local compile used an incorrect analyzer folder and failed before compilation; corrected compiler paths passed. Test log contains one informational AA0477 inherited from main, no warning. Existing manifest analyzer configuration is unchanged.

Local BC29 tenant `w129-19`, CRONUS International Ltd., belongs solely to worker-9. Four worker-built Origo packages deployed at tenant scope; source/artifact/package hashes are in artifact-provenance.json. Dependency Foundation35f0efa31b85402fe5628ae764bc5ee2209664e2,28.0.13.0. First-use explicit operator Test.Eula.Set authorization follows local tenant binding.

- Cold existing Read-role regression:1 executed,1 passed,0 failed,0 skipped, before any other Quality test.
- Full configured suite:73 executed,73 passed,0 failed,0 skipped. Native exact-candidate source results; old37 and merge-checkout53 counts are not carried forward.
- Self-seeded MCP:28 executed,28 passed,0 failed,0 skipped in1033/1039. Reopen16 covers help, happy, repeat, missing/invalid/unknown input and native later-reinspection refusal.12 additional scenarios protect merged purchase-return and SetTestValue behavior, checking success and missing/unknown input. Eight supporting state/cleanup assertions are separate from28 message scenarios.
- UI:2 executed,2 passed,0 failed,0 skipped. Native Reopen/Enduropna moves Finished/Lokið to Open/Opið in1033/1039. Native Finish prepares MCP inputs without setting shipping status around validation. Screenshots capture final headings while confirmation overlays are closing; Playwright completion and MCP persisted-state readbacks corroborate the result. Provisioned SUPER used for UI/MCP; least privilege is covered by native exact-role tests. Language restored to English; browser closed.
- Cleanup:18 filtered fixture readbacks show zero remaining Reopen, purchase-return or SetTestValue records/setup; owned Origo apps uninstalled with extension-data deletion and unpublished.84 Microsoft apps retained. No foreign tenant used.

Gateway Layer1:21/23 categories pass; two reviewed false positives (AL parameter separators, locked public message identifier caption). Layer2 covers exact permission union, source/test preservation, contracts, docs, object allocation and unchanged public API. Snapshot52ba4754cfd614e4a7c50af87b30149b18b313e3 was captured2November, not freshly synchronized. Refer acceptance-matrix.json for AC01–AC08 and finding-matrix.json for previous amendment and wider suggestions. Independent Claude/Grok verification, approval, Architect merge/deploy and Tester UAT remain separate stages. This is not issue completion.

Paired CI evidence is in [ci.json](ci.json), with actual tested checkout SHA and native counts recorded separately from local evidence.
