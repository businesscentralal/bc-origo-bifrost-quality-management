namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Issue 12: real standard journal creation, validation, rollback and permission refusals through the dispatcher.</summary>
codeunit 97250 "Quality Move Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        PriorSetup: Record "Qlty. Management Setup";
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        FixtureCode: Code[10];
        HadSetup: Boolean;

    /// <summary>FailedQuantity PreparesStandardLine.</summary>
    [Test]
    procedure Scenario_AC03_FailedQuantity_PreparesStandardLine()
    begin
        // Story #12, AC03 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('failed', 1033);
    end;

    /// <summary>PassedQuantity PreparesStandardLine.</summary>
    [Test]
    procedure Scenario_AC03_PassedQuantity_PreparesStandardLine()
    begin
        // Story #12, AC03 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('passed', 1033);
    end;

    /// <summary>Icelandic PreparesStandardLine.</summary>
    [Test]
    procedure Scenario_AC03_Icelandic_PreparesStandardLine()
    begin
        // Story #12, AC03 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('failed', 1039);
    end;

    /// <summary>MissingKey RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC02_MissingKey_RefusesWithoutWrite()
    begin
        // Story #12, AC02 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('missing', 1033);
    end;

    /// <summary>UnknownKey RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC02_UnknownKey_RefusesWithoutWrite()
    begin
        // Story #12, AC02 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('unknown', 1033);
    end;

    /// <summary>InvalidBoolean RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC02_InvalidBoolean_RefusesWithoutWrite()
    begin
        // Story #12, AC02 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('boolean', 1033);
    end;

    /// <summary>MissingConfirm RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC02_MissingConfirm_RefusesWithoutWrite()
    begin
        // Story #12, AC02 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('confirm', 1033);
    end;

    /// <summary>BlockedItem RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC04_BlockedItem_RefusesWithoutWrite()
    begin
        // Story #12, AC04 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('blocked', 1033);
    end;

    /// <summary>ZeroQuantity RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC04_ZeroQuantity_RefusesWithoutWrite()
    begin
        // Story #12, AC04 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('zero', 1033);
    end;

    /// <summary>LateFailure RollsBackCreatedLine.</summary>
    [Test]
    procedure Scenario_AC04_LateFailure_RollsBackCreatedLine()
    begin
        // Story #12, AC04 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('late', 1033);
    end;

    /// <summary>PostFailure RollsBackPreparedLine.</summary>
    [Test]
    procedure Scenario_AC04_PostFailure_RollsBackPreparedLine()
    begin
        // Story #12, AC04 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('postFailure', 1033);
    end;

    /// <summary>NoAppRole RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC05_NoAppRole_RefusesWithoutWrite()
    begin
        // Story #12, AC05 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('permission', 1033);
    end;

    /// <summary>IcelandicRefusal IsTranslated.</summary>
    [Test]
    procedure Scenario_AC06_IcelandicRefusal_IsTranslated()
    begin
        // Story #12, AC06 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('missing', 1039);
    end;

    /// <summary>LongCode RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC02_LongCode_RefusesWithoutWrite()
    begin
        // Story #12, AC02 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('long', 1033);
    end;

    /// <summary>FilterCode RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC02_FilterCode_RefusesWithoutWrite()
    begin
        // Story #12, AC02 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('filter', 1033);
    end;

    /// <summary>WorksheetPost RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC02_WorksheetPost_RefusesWithoutWrite()
    begin
        // Story #12, AC02 | Time: standard journal uses WorkDate; no Today dependency | Risk: owned Q12 fixtures only
        VerifyScenario('worksheetPost', 1033);
    end;

    /// <summary>A stale expected count refuses before any movement.</summary>
    [Test]
    procedure Scenario_AC02_ExpectedCountMismatch_RefusesWithoutWrite()
    begin
        // Story #12, AC02 | Time: WorkDate | Risk: owned Q12 fixtures only
        VerifyScenario('count', 1033);
    end;

    /// <summary>Posts a standard reclassification against self-seeded inventory and verifies ledger quantities.</summary>
    [Test]
    procedure Scenario_AC03_ImmediatePost_MovesInventory()
    begin
        // Story #12, AC03/AC04 | Time: standard posting uses WorkDate | Risk: owned zero-cost test inventory only
        VerifyScenario('postSuccess', 1033);
    end;

    /// <summary>A failure after standard posting restores both original stock and the journal.</summary>
    [Test]
    procedure Scenario_AC04_LatePostFailure_RollsBackInventory()
    begin
        // Story #12, AC04 | Time: WorkDate | Risk: owned zero-cost inventory only
        VerifyScenario('latePost', 1033);
    end;

    /// <summary>Discovers the type and verifies its effect and help chapters through Foundation.</summary>
    [Test]
    procedure Scenario_AC01_Discovery_DeclaresAtomicEffect()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Effect: JsonObject;
        Token: JsonToken;
    begin
        // Story #12, AC01/AC07 | Time: none | Risk: read only
        Initialize();
        Assert.IsTrue(ContractMgt.GetContract(Enum::"Message Type ori"::"Quality.Disposition.MoveInventory", Contract), 'Registered type must have a contract.');
        Contract.Get('effect', Token);
        Effect := Token.AsObject();
        Assert.AreEqual('irreversible', ReadText(Effect, 'effect'), 'Optional posting must be conservatively classified.');
        Effect.Get('idempotent', Token);
        Assert.IsFalse(Token.AsValue().AsBoolean(), 'Repeated preparation can create another line.');
        Assert.AreEqual('BIFROST QM Full ori', ReadText(Effect, 'permissionSet'), 'Contract must name the app role.');
        Assert.IsTrue(Contract.Contains('overview'), 'The help chapter is required.');
    end;

    local procedure VerifyScenario(Scenario: Text; LanguageId: Integer)
    var
        Inspection: Record "Qlty. Inspection Header";
        Item: Record Item;
        JournalLine: Record "Item Journal Line";
        Fault: Codeunit "Quality Move Fault ori";
        Request: JsonObject;
        Response: JsonObject;
        ExpectSuccess: Boolean;
    begin
        // [GIVEN] All business fixture records are created for this test, including both locations and the journal batch.
        Initialize();
        CreateFixture(Inspection);
        if Scenario in ['postSuccess', 'latePost'] then
            SeedStock(Inspection);
        Request.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Request.Add('quantityBasis', 'failed');
        Request.Add('method', 'itemReclassification');
        Request.Add('sourceLocationCode', FixtureCode);
        Request.Add('destinationLocationCode', 'D' + CopyStr(FixtureCode, 2));
        Request.Add('confirm', true);
        Request.Add('expectedCount', 1);
        ExpectSuccess := Scenario in ['failed', 'passed', 'postSuccess'];
        case Scenario of
            'passed': Request.Replace('quantityBasis', 'passed');
            'count': Request.Replace('expectedCount', 0);
            'missing': Request.Remove('quantityBasis');
            'unknown': Request.Add('unexpected', true);
            'boolean': Request.Add('postImmediately', 'true');
            'confirm': Request.Remove('confirm');
            'long': Request.Replace('destinationLocationCode', PadStr('x', 11, 'x'));
            'filter': Request.Replace('sourceLocationCode', '*');
            'blocked': begin
                Item.Get(FixtureCode);
                Item.Blocked := true;
                Item.Modify(false);
            end;
            'zero': begin
                Inspection."Fail Quantity" := 0;
                Inspection.Modify(false);
            end;
            'postFailure', 'postSuccess', 'latePost': Request.Add('postImmediately', true);
            'worksheetPost': begin
                Request.Replace('method', 'movementWorksheet');
                Request.Add('postImmediately', true);
            end;
        end;
        Commit();
        if Scenario = 'permission' then begin
            LowerPermissions.SetExactPermissionSet('BIFROST API ori');
            LowerPermissions.AddPermissionSet('QltyMgmt - Inspector');
            LowerPermissions.AddPermissionSet('QM Move Test ori');
        end;
        if Scenario = 'latePost' then
            Fault.SetPostingFault();
        if Scenario in ['late', 'latePost'] then
            BindSubscription(Fault);
        // [WHEN] The real dispatcher executes the standard disposition.
        Response := Dispatch(Request, LanguageId);
        if Scenario in ['late', 'latePost'] then
            UnbindSubscription(Fault);
        LowerPermissions.SetOutsideO365Scope();
        JournalLine.SetRange("Journal Template Name", FixtureCode);
        JournalLine.SetRange("Journal Batch Name", FixtureCode);
        // [THEN] Standard journal fields match the request, or every created line is rolled back.
        if ExpectSuccess then begin
            if ReadText(Response, 'status') <> 'Success' then
                Assert.Fail(ReadText(Response, 'error'));
            if Scenario = 'postSuccess' then begin
                VerifyPostedInventory();
                // Real ledger entries remain consistent until the test runner rolls back this isolated codeunit.
                // A separate MCP read after the full suite verifies that no Q12 fixture remains.
                exit;
            end;
            Assert.AreEqual(1, JournalLine.Count(), 'Standard disposition must create exactly one owned line.');
            JournalLine.FindFirst();
            Assert.AreEqual(JournalLine."Entry Type"::Transfer, JournalLine."Entry Type", 'A reclassification must use the standard transfer entry type.');
            Assert.AreEqual(FixtureCode, JournalLine."Item No.", 'Only the inspection item may move.');
            Assert.AreEqual(FixtureCode, JournalLine."Location Code", 'Source location must be retained.');
            Assert.AreEqual('D' + CopyStr(FixtureCode, 2), JournalLine."New Location Code", 'Destination must be validated by standard code.');
            if Scenario = 'passed' then
                Assert.AreEqual(2, JournalLine.Quantity, 'Pass quantity must come from the selected inspection.')
            else
                Assert.AreEqual(3, JournalLine.Quantity, 'Fail quantity must come from the selected inspection.');
        end else begin
            Assert.AreEqual('Error', ReadText(Response, 'status'), 'The operation must return a refusal.');
            Assert.AreEqual(0, JournalLine.Count(), 'A refusal must leave no prepared lines.');
            if Scenario = 'latePost' then
                Assert.IsTrue(ReadText(Response, 'error').Contains('Q12 late posting failure'), 'The refusal must occur after real standard posting.');
            if Scenario = 'late' then
                Assert.IsTrue(ReadText(Response, 'error').Contains('Q12 late failure'), 'The fault must occur after real line creation.');
            if (Scenario = 'missing') and (LanguageId = 1039) then
                Assert.IsTrue(ReadText(Response, 'error').Contains('færibreytu'), 'The refusal must be Icelandic.');
        end;
        if Scenario = 'latePost' then begin
            VerifyPostedRefusalInventory();
            exit; // The isolated test runner rolls back the self-seeded stock and setup.
        end;
        Cleanup(Inspection);
    end;

    local procedure Initialize()
    begin
        LowerPermissions.SetOutsideO365Scope();
    end;

    local procedure CreateFixture(var Inspection: Record "Qlty. Inspection Header")
    var
        Item: Record Item;
        Unit: Record "Unit of Measure";
        ItemUnit: Record "Item Unit of Measure";
        Location: Record Location;
        JournalTemplate: Record "Item Journal Template";
        JournalBatch: Record "Item Journal Batch";
        Setup: Record "Qlty. Management Setup";
    begin
        FixtureCode := CopyStr('Q12-' + DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 10);
        Unit.Code := FixtureCode;
        Unit.Insert(false);
        Item."No." := FixtureCode;
        Item.Description := FixtureCode;
        Item."Base Unit of Measure" := FixtureCode;
        Item.Insert(false);
        ItemUnit."Item No." := FixtureCode;
        ItemUnit.Code := FixtureCode;
        ItemUnit."Qty. per Unit of Measure" := 1;
        ItemUnit.Insert(false);
        Location.Code := FixtureCode;
        Location.Insert(false);
        Location.Code := 'D' + CopyStr(FixtureCode, 2);
        Location.Insert(false);
        JournalTemplate.Name := FixtureCode;
        JournalTemplate.Type := JournalTemplate.Type::Transfer;
        JournalTemplate."Page ID" := Page::"Item Reclass. Journal";
        JournalTemplate.Insert(false);
        JournalBatch."Journal Template Name" := FixtureCode;
        JournalBatch.Name := FixtureCode;
        JournalBatch.Insert(false);
        HadSetup := Setup.Get();
        if HadSetup then
            PriorSetup := Setup
        else
            Setup.Insert(false);
        Setup."Item Reclass. Batch Name" := FixtureCode;
        Setup.Modify(false);
        Inspection."No." := FixtureCode;
        Inspection."Source Item No." := FixtureCode;
        Inspection."Location Code" := FixtureCode;
        Inspection."Source Quantity (Base)" := 5;
        Inspection."Fail Quantity" := 3;
        Inspection."Pass Quantity" := 2;
        Inspection.Insert(false);
    end;

    local procedure SeedStock(Inspection: Record "Qlty. Inspection Header")
    var
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
        JournalTemplate: Record "Item Journal Template";
        JournalLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        LocationCode: Code[10];
        LocationIndex: Integer;
    begin
        // All posting groups, their account, and both location setups belong to this fixture.
        GLAccount."No." := FixtureCode;
        GLAccount.Name := FixtureCode;
        GLAccount."Direct Posting" := true;
        GLAccount.Insert(false);
        SourceCode.Code := FixtureCode;
        SourceCode.Insert(false);
        InventoryPostingGroup.Code := FixtureCode;
        InventoryPostingGroup.Insert(false);
        GenProductPostingGroup.Code := FixtureCode;
        GenProductPostingGroup.Insert(false);
        GeneralPostingSetup."Gen. Prod. Posting Group" := FixtureCode;
        GeneralPostingSetup."Inventory Adjmt. Account" := FixtureCode;
        GeneralPostingSetup."Direct Cost Applied Account" := FixtureCode;
        GeneralPostingSetup."COGS Account" := FixtureCode;
        GeneralPostingSetup.Insert(false);
        for LocationIndex := 1 to 2 do begin
            if LocationIndex = 1 then
                LocationCode := FixtureCode
            else
                LocationCode := 'D' + CopyStr(FixtureCode, 2);
            InventoryPostingSetup.Init();
            InventoryPostingSetup."Location Code" := LocationCode;
            InventoryPostingSetup."Invt. Posting Group Code" := FixtureCode;
            InventoryPostingSetup."Inventory Account" := FixtureCode;
            InventoryPostingSetup.Insert(false);
        end;
        Item.Get(FixtureCode);
        Item."Inventory Posting Group" := FixtureCode;
        Item."Gen. Prod. Posting Group" := FixtureCode;
        Item.Modify(false);
        JournalTemplate.Get(FixtureCode);
        JournalTemplate."Source Code" := FixtureCode;
        JournalTemplate.Modify(false);
        JournalLine."Journal Template Name" := FixtureCode;
        JournalLine."Journal Batch Name" := FixtureCode;
        JournalLine."Line No." := 1000;
        JournalLine."Entry Type" := JournalLine."Entry Type"::"Positive Adjmt.";
        JournalLine.Validate("Posting Date", WorkDate());
        JournalLine."Document No." := Inspection."No.";
        JournalLine.Validate("Item No.", FixtureCode);
        JournalLine.Validate("Location Code", FixtureCode);
        JournalLine.Validate(Quantity, 5);
        JournalLine."Source Code" := FixtureCode;
        ItemJnlPostLine.RunWithCheck(JournalLine);
    end;

    local procedure VerifyPostedInventory()
    var
        Ledger: Record "Item Ledger Entry";
        JournalLine: Record "Item Journal Line";
    begin
        Ledger.SetRange("Item No.", FixtureCode);
        Ledger.SetRange("Location Code", 'D' + CopyStr(FixtureCode, 2));
        Ledger.CalcSums(Quantity);
        Assert.AreEqual(3, Ledger.Quantity, 'Immediate posting must move the failed quantity into the destination ledger.');
        Ledger.SetRange("Location Code", FixtureCode);
        Ledger.CalcSums(Quantity);
        Assert.AreEqual(2, Ledger.Quantity, 'The source ledger must retain the passed quantity.');
        JournalLine.SetRange("Journal Template Name", FixtureCode);
        // Standard non-recurring posting retains one blank starter line when the batch has no number series.
        JournalLine.SetFilter("Item No.", '<>%1', '');
        Assert.IsTrue(JournalLine.IsEmpty(), 'No movement line may remain after posting.');
        JournalLine.SetRange("Item No.");
        if JournalLine.FindFirst() then begin
            Assert.AreEqual('', JournalLine."Item No.", 'Only a blank standard starter line may remain.');
            Assert.AreEqual(0, JournalLine.Quantity, 'The starter line must carry no movement quantity.');
        end;
    end;

    local procedure VerifyPostedRefusalInventory()
    var
        Ledger: Record "Item Ledger Entry";
    begin
        Ledger.SetRange("Item No.", FixtureCode);
        Ledger.SetRange("Location Code", 'D' + CopyStr(FixtureCode, 2));
        Ledger.CalcSums(Quantity);
        Assert.AreEqual(0, Ledger.Quantity, 'A late refusal must roll back every destination ledger entry.');
        Ledger.SetRange("Location Code", FixtureCode);
        Ledger.CalcSums(Quantity);
        Assert.AreEqual(5, Ledger.Quantity, 'A late refusal must preserve the original self-seeded stock.');
    end;

    local procedure Dispatch(Request: JsonObject; LanguageId: Integer) Response: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        RequestText: Text;
        ResponseText: Text;
        ResponseContentType: Text[100];
        MessageId: Guid;
        TaskId: Guid;
        ResponseTime: Duration;
    begin
        Request.WriteTo(RequestText);
        RequestContent.AddText(RequestText);
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Quality.Disposition.MoveInventory", Enum::"Message Version ori"::"1.0", '', 'quality12-tests', 'application/json', RequestContent, TaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
    end;

    local procedure ReadText(Response: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Response.Get(PropertyName, Token), 'Response property missing: ' + PropertyName);
        exit(Token.AsValue().AsText());
    end;

    local procedure Cleanup(Inspection: Record "Qlty. Inspection Header")
    var
        Item: Record Item;
        Unit: Record "Unit of Measure";
        ItemUnit: Record "Item Unit of Measure";
        Location: Record Location;
        JournalLine: Record "Item Journal Line";
        JournalTemplate: Record "Item Journal Template";
        JournalBatch: Record "Item Journal Batch";
        Setup: Record "Qlty. Management Setup";
    begin
        if CopyStr(FixtureCode, 1, 4) <> 'Q12-' then
            Error('Only owned Q12 fixtures may be removed.');
        JournalLine.SetRange("Journal Template Name", FixtureCode);
        JournalLine.DeleteAll(false);
        JournalBatch.SetRange("Journal Template Name", FixtureCode);
        JournalBatch.DeleteAll(false);
        JournalTemplate.Get(FixtureCode);
        JournalTemplate.Delete(false);
        Inspection.Delete(false);
        ItemUnit.SetRange("Item No.", FixtureCode);
        ItemUnit.DeleteAll(false);
        Item.Get(FixtureCode);
        Item.Delete(false);
        Unit.Get(FixtureCode);
        Unit.Delete(false);
        Location.Get(FixtureCode);
        Location.Delete(false);
        Location.Get('D' + CopyStr(FixtureCode, 2));
        Location.Delete(false);
        if HadSetup then begin
            Setup.Get();
            Setup."Item Reclass. Batch Name" := PriorSetup."Item Reclass. Batch Name";
            Setup.Modify(false);
        end else
            if Setup.Get() then
                Setup.Delete(false);
    end;
}
