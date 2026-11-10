# PR 32 verification evidence — amendment open

**Current disposition: AMEND REQUIRED.** Claude reported one independent BC29 permission failure at this source SHA after these local passes. See [review-amendment.json](review-amendment.json). Local and CI passes do not clear the finding. The guarded review handoff refused the open `pr:amend`; no clearance or handoff is claimed. The proposed base-permission change exceeds this assignment’s mechanical conflict-repair boundary and is escalated to Architect.

Source candidate: `60ddc3d33cfc6f8244195cffbe04db8da6bfc3af` ([immutable source](https://github.com/businesscentralal/bc-origo-bifrost-quality-management/commit/60ddc3d33cfc6f8244195cffbe04db8da6bfc3af)). Evidence only; this branch is not an implementation candidate or a second PR.

Litr (worker-9), 10 November 2026. Merge of main `24190982c82e26ca55e415bed8569502dca50c61` into the original Reopen branch. The resolution unions README documentation, all 41 translation units and the approved permission grants; handlers and tests from both parents remain byte-identical. No assertions, guards or pipeline configuration were weakened.

Both Quality apps compile with CodeCop, UICop and AppSourceCop: 0 errors, 0 warnings. Own compiled packages were tenant-published to local BC29 `w129-19`; provenance includes dependency SHA, package IDs and SHA256 hashes. Existing rulesets remain unchanged.

Full configured native suite: 37 executed, 37 passed, 0 failed, 0 skipped. Independent automatic paired CI also reports 37/37/0/0; see ci.json for immutable run/job links.

UI: finished inspections reopened successfully in LCIDs 1033 and 1039 (two scenarios); screenshots show before/after. Language restored to English and browser closed. Provisioned SUPER identity is disclosed; least-privilege behavior is proved separately by native permission tests.

MCP: 22 message scenarios passed, zero failed/skipped, plus five supporting state assertions. Reopen covers help, success, idempotency, malformed/missing/unknown keys/IDs and a later-reinspection business refusal in both languages. PurchaseReturn regression covers success and missing/unknown-key refusals in both languages, protecting the behavior merged from main. Fixture setup is synthetic and worker-owned. Unposted return orders 1001/1002 were removed by the existing test-fixture cleanup; twelve filtered readbacks confirm zero fixture records. All four locally built Origo extensions were uninstalled with data deletion, unpublished and confirmed absent; 84 Microsoft extensions remain.

Issue 5 acceptance: AC01 contract/catalogue and AC07 help are covered by native contract assertion and bilingual MCP help; AC02 translated validation refusals by native/MCP checks; AC03 standard ReopenInspection by source preservation, native success, MCP and UI; AC04 business-refusal atomicity by native/MCP state checks; AC05 role grants by native permission tests and the exact union of approved grants; AC06 bilingual text/XLF by 41-unit preservation and bilingual UI/MCP; AC08 all four required native test families passed.

Gateway static checks: 21/23 categories pass; the two findings are reviewed false positives (locked public type identifier caption, and AL procedure-parameter semicolons). No source was altered to silence those findings. Standards snapshot: 52ba4754cfd614e4a7c50af87b30149b18b313e3, captured 2 November; not represented as freshly synchronized.

Independent Claude verification, Grok clearance, non-author approval, Architect merge/deployment and Tester UAT remain separate pending stages. This evidence does not claim issue completion.
