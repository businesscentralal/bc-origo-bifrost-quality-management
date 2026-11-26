namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Issue 15: negative adjustment through the standard disposition, prepared or posted, with typed refusals, rollback and role checks.</summary>
codeunit 97272 "Quality Neg Adj Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        PriorSetup: Record "Qlty. Management Setup";
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        FixtureCode: Code[10];
        TemplateCode: Code[10];
        PriorForceReport: Boolean;
        PriorWorkDate: Date;
        HadSetup: Boolean;

    /// <summary>The ordinal of the new enum value is pinned.</summary>
    [Test]
    procedure Scenario_AC01_Ordinal_IsPinned()
    begin
        // Story #15, AC01 | Time: none | Risk: read only
        Assert.AreEqual(10035302, Enum::"Message Type ori"::"Quality.Disposition.CreateNegativeAdjustment".AsInteger(), 'The enum ordinal must never change.');
    end;

    /// <summary>Discovery declares an irreversible, non-idempotent write with the app role.</summary>
    [Test]
    procedure Scenario_AC01_Discovery_DeclaresIrreversibleEffect()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Effect: JsonObject;
        Token: JsonToken;
    begin
        // Story #15, AC01/AC04 | Time: none | Risk: read only
        Initialize();
        Assert.IsTrue(ContractMgt.GetContract(Enum::"Message Type ori"::"Quality.Disposition.CreateNegativeAdjustment", Contract), 'Registered type must have a contract.');
        Contract.Get('effect', Token);
        Effect := Token.AsObject();
        Assert.AreEqual('irreversible', ReadText(Effect, 'effect'), 'Posting makes the type irreversible.');
        Effect.Get('idempotent', Token);
        Assert.IsFalse(Token.AsValue().AsBoolean(), 'A repeat can write off more stock.');
        Assert.AreEqual('BIFROST QM Full ori', ReadText(Effect, 'permissionSet'), 'Contract must name the app role.');
        Assert.IsTrue(ReadText(Effect, 'changes').Contains('The expectedCount unit is the one quality inspection'), 'effect.changes must name the count unit.');
        Assert.IsTrue(Contract.Contains('overview'), 'The help chapter is required.');
    end;

    /// <summary>Prepare only leaves the journal line and writes no ledger entry.</summary>
    [Test]
    procedure Scenario_AC02_Prepare_LeavesJournalLine()
    begin
        // Story #15, AC02 | Time: WorkDate | Risk: owned Q15 fixtures only
        VerifyScenario('prepare', 1033);
    end;

    /// <summary>Prepare in Icelandic behaves the same.</summary>
    [Test]
    procedure Scenario_AC02_PrepareIcelandic_LeavesJournalLine()
    begin
        // Story #15, AC02 | Time: WorkDate | Risk: owned Q15 fixtures only
        VerifyScenario('prepare', 1039);
    end;

    /// <summary>Passed basis writes off the pass quantity.</summary>
    [Test]
    procedure Scenario_AC02_PassedBasis_UsesPassQuantity()
    begin
        // Story #15, AC02 | Time: WorkDate | Risk: owned Q15 fixtures only
        VerifyScenario('passed', 1033);
    end;

    /// <summary>An explicit quantity replaces the basis quantity.</summary>
    [Test]
    procedure Scenario_AC02_ExplicitQuantity_UsesQuantity()
    begin
        // Story #15, AC02 | Time: WorkDate | Risk: owned Q15 fixtures only
        VerifyScenario('quantity', 1033);
    end;

    /// <summary>Posting writes negative ledger entries and reduces stock.</summary>
    [Test]
    procedure Scenario_AC02_Post_ReducesStock()
    begin
        // Story #15, AC02 | Time: WorkDate | Risk: owned zero-cost inventory only
        VerifyScenario('post', 1033);
    end;

    /// <summary>A late failure after line creation removes the line.</summary>
    [Test]
    procedure Scenario_AC03_LateFailure_RollsBackLine()
    begin
        // Story #15, AC03 | Time: WorkDate | Risk: owned Q15 fixtures only
        VerifyScenario('late', 1033);
    end;

    /// <summary>A failure after standard posting restores stock and journal.</summary>
    [Test]
    procedure Scenario_AC03_LatePostFailure_RollsBackStock()
    begin
        // Story #15, AC03 | Time: WorkDate | Risk: owned zero-cost inventory only
        VerifyScenario('latePost', 1033);
    end;

    /// <summary>Insufficient stock refuses and leaves no line or entry.</summary>
    [Test]
    procedure Scenario_AC03_InsufficientStock_LeavesNothing()
    begin
        // Story #15, AC03 | Time: WorkDate | Risk: owned Q15 fixtures only
        VerifyScenario('insufficient', 1033);
    end;

    /// <summary>A missing journal batch refuses and leaves nothing.</summary>
    [Test]
    procedure Scenario_AC03_MissingBatch_LeavesNothing()
    begin
        // Story #15, AC03 | Time: WorkDate | Risk: owned Q15 fixtures only
        VerifyScenario('noBatch', 1033);
    end;

    /// <summary>A template that forces a posting report refuses posting and leaves nothing.</summary>
    [Test]
    procedure Scenario_AC03_ForcedReport_LeavesNothing()
    begin
        // Story #15, AC03 | Time: WorkDate | Risk: owned Q15 fixtures; template flag restored
        VerifyScenario('forcedReport', 1033);
    end;

    /// <summary>Typed refusal: missing identifier.</summary>
    [Test]
    procedure Scenario_AC03_MissingId_TypedRefusal()
    begin
        // Story #15, AC03 | Time: none | Risk: owned Q15 fixtures only
        VerifyScenario('missingId', 1033);
        VerifyScenario('missingId', 1039);
    end;

    /// <summary>Typed refusal: malformed identifier.</summary>
    [Test]
    procedure Scenario_AC03_MalformedId_TypedRefusal()
    begin
        // Story #15, AC03 | Time: none | Risk: owned Q15 fixtures only
        VerifyScenario('malformedId', 1033);
    end;

    /// <summary>Typed refusal: confirm not true.</summary>
    [Test]
    procedure Scenario_AC03_ConfirmFalse_TypedRefusal()
    begin
        // Story #15, AC03 | Time: none | Risk: owned Q15 fixtures only
        VerifyScenario('confirm', 1033);
    end;

    /// <summary>Typed refusal: unknown key.</summary>
    [Test]
    procedure Scenario_AC03_UnknownKey_TypedRefusal()
    begin
        // Story #15, AC03 | Time: none | Risk: owned Q15 fixtures only
        VerifyScenario('unknown', 1033);
    end;

    /// <summary>Typed refusal: filter syntax.</summary>
    [Test]
    procedure Scenario_AC03_FilterSyntax_TypedRefusal()
    begin
        // Story #15, AC03 | Time: none | Risk: owned Q15 fixtures only
        VerifyScenario('filter', 1033);
    end;

    /// <summary>Typed refusal: unknown inspection.</summary>
    [Test]
    procedure Scenario_AC03_UnknownInspection_TypedRefusal()
    begin
        // Story #15, AC03 | Time: none | Risk: owned Q15 fixtures only
        VerifyScenario('notFound', 1033);
    end;

    /// <summary>Typed refusal: zero quantity.</summary>
    [Test]
    procedure Scenario_AC03_ZeroQuantity_TypedRefusal()
    begin
        // Story #15, AC03 | Time: none | Risk: owned Q15 fixtures only
        VerifyScenario('zero', 1033);
    end;

    /// <summary>Typed refusal: reason code too long.</summary>
    [Test]
    procedure Scenario_AC03_LongReason_TypedRefusal()
    begin
        // Story #15, AC03 | Time: none | Risk: owned Q15 fixtures only
        VerifyScenario('longReason', 1033);
    end;

    /// <summary>An inspection with no failed quantity writes nothing.</summary>
    [Test]
    procedure Scenario_AC03_NoFailedQuantity_LeavesNothing()
    begin
        // Story #15, AC03 | Time: none | Risk: owned Q15 fixtures only
        VerifyScenario('noFail', 1033);
    end;

    /// <summary>An expectedCount other than 1 refuses before any change.</summary>
    [Test]
    procedure Scenario_AC04_CountMismatch_RefusesBeforeChange()
    begin
        // Story #15, AC04 | Time: none | Risk: owned Q15 fixtures only
        VerifyScenario('count', 1033);
    end;

    /// <summary>Without the app role the call is refused.</summary>
    [Test]
    procedure Scenario_AC05_NoAppRole_Refused()
    begin
        // Story #15, AC05 | Time: none | Risk: owned Q15 fixtures only
        VerifyScenario('permission', 1033);
    end;

    /// <summary>The read role is refused.</summary>
    [Test]
    procedure Scenario_AC05_ReadRole_Refused()
    begin
        // Story #15, AC05 | Time: none | Risk: owned Q15 fixtures only
        VerifyScenario('readRole', 1033);
    end;

    /// <summary>Unknown parameter guidance is fully Icelandic.</summary>
    [Test]
    procedure Scenario_AC03_UnknownKeyIcelandic_Translated()
    begin
        // Story #15, AC03/AC06 | Time: none | Risk: owned Q15 fixtures only
        VerifyScenario('unknown', 1039);
    end;

    /// <summary>A non-string basis has typed English guidance.</summary>
    [Test]
    procedure Scenario_AC03_NonStringBasis_Refused()
    begin
        // Story #15, AC03/AC06 | Time: none | Risk: owned Q15 fixtures only
        VerifyScenario('invalidText', 1033);
    end;

    /// <summary>A non-string basis has typed Icelandic guidance.</summary>
    [Test]
    procedure Scenario_AC03_NonStringBasisIcelandic_Translated()
    begin
        // Story #15, AC03/AC06 | Time: none | Risk: owned Q15 fixtures only
        VerifyScenario('invalidText', 1039);
    end;

    local procedure VerifyScenario(Scenario: Text; LanguageId: Integer)
    var
        Inspection: Record "Qlty. Inspection Header";
        JournalLine: Record "Item Journal Line";
        JournalTemplate: Record "Item Journal Template";
        Setup: Record "Qlty. Management Setup";
        Fault: Codeunit "Quality Neg Adj Fault ori";
        Request: JsonObject;
        Response: JsonObject;
        ExpectSuccess: Boolean;
        Posting: Boolean;
    begin
        // [GIVEN] All business fixtures are created for this test, including the location, item and journal batch.
        Initialize();
        CreateFixture(Inspection);
        Posting := Scenario in ['post', 'latePost', 'insufficient', 'forcedReport'];
        if Scenario in ['post', 'latePost', 'forcedReport'] then
            SeedStock(Inspection);
        Request.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Request.Add('quantityBasis', 'failed');
        Request.Add('sourceLocationCode', FixtureCode);
        Request.Add('confirm', true);
        Request.Add('expectedCount', 1);
        if Posting then
            Request.Add('postImmediately', true);
        ExpectSuccess := Scenario in ['prepare', 'passed', 'quantity', 'post'];
        case Scenario of
            'passed':
                Request.Replace('quantityBasis', 'passed');
            'quantity':
                Request.Add('quantity', 1);
            'count':
                Request.Replace('expectedCount', 0);
            'missingId':
                Request.Remove('inspectionSystemId');
            'malformedId':
                Request.Replace('inspectionSystemId', 'not-a-guid');
            'notFound':
                Request.Replace('inspectionSystemId', Format(CreateGuid(), 0, 4));
            'confirm':
                Request.Replace('confirm', false);
            'invalidText':
                Request.Replace('quantityBasis', 42);
            'unknown':
                Request.Add('unexpected', true);
            'filter':
                Request.Replace('sourceLocationCode', '*');
            'zero':
                Request.Add('quantity', 0);
            'longReason':
                Request.Add('reasonCode', PadStr('x', 11, 'x'));
            'noFail':
                begin
                    Inspection."Fail Quantity" := 0;
                    Inspection.Modify(false);
                end;
            'noBatch':
                begin
                    Setup.Get();
                    Setup."Item Journal Batch Name" := '';
                    Setup.Modify(false);
                end;
            'forcedReport':
                begin
                    JournalTemplate.Get(TemplateCode);
                    JournalTemplate."Force Posting Report" := true;
                    JournalTemplate.Modify(false);
                end;
        end;
        Commit();
        if Scenario in ['permission', 'readRole'] then begin
            LowerPermissions.SetExactPermissionSet('BIFROST API ori');
            LowerPermissions.AddPermissionSet('QltyMgmt - Inspector');
            LowerPermissions.AddPermissionSet('QM Move Test ori');
            if Scenario = 'readRole' then
                LowerPermissions.AddPermissionSet('BIFROST QM Read ori');
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
        JournalLine.SetRange("Journal Template Name", TemplateCode);
        JournalLine.SetRange("Journal Batch Name", FixtureCode);
        JournalLine.SetFilter("Item No.", '<>%1', '');
        // [THEN] The result matches the request, or nothing remains.
        if ExpectSuccess then begin
            if ReadText(Response, 'status') <> 'Success' then
                Assert.Fail(ReadText(Response, 'error'));
            if Scenario = 'post' then begin
                Assert.IsTrue(JournalLine.IsEmpty(), 'Posting must not leave an adjustment line.');
                Assert.AreEqual(-3, LedgerQuantity('Negative Adjmt.'), 'Posting must write the failed quantity as a negative adjustment.');
                Assert.AreEqual(2, LedgerQuantity(''), 'Stock must be reduced by the handled quantity.');
                Assert.AreEqual(1, ReadArrayCount(Response, 'ledgerEntries'), 'The response must list the entry created.');
                Assert.AreEqual(0, ReadArrayCount(Response, 'journalLines'), 'No line remains after posting.');
            end else begin
                Assert.AreEqual(1, JournalLine.Count(), 'Standard disposition must create exactly one owned line.');
                JournalLine.FindFirst();
                Assert.AreEqual(JournalLine."Entry Type"::"Negative Adjmt.", JournalLine."Entry Type", 'The line must be a negative adjustment.');
                Assert.AreEqual(FixtureCode, JournalLine."Item No.", 'Only the inspection item may be adjusted.');
                Assert.AreEqual(ExpectedQuantity(Scenario), JournalLine.Quantity, 'The line quantity must follow the request.');
                Assert.AreEqual(0, LedgerQuantity('Negative Adjmt.'), 'Preparing must write no item ledger entry.');
                Assert.AreEqual(1, ReadArrayCount(Response, 'journalLines'), 'The response must list the line created.');
                Assert.AreEqual(0, ReadArrayCount(Response, 'ledgerEntries'), 'The response must list no entry.');
            end;
        end else begin
            Assert.AreEqual('Error', ReadText(Response, 'status'), 'The operation must return a refusal.');
            Assert.IsTrue(JournalLine.IsEmpty(), 'A refusal must leave no lines.');
            Assert.AreEqual(0, LedgerQuantity('Negative Adjmt.'), 'A refusal must leave no entries.');
            if Scenario in ['missingId', 'malformedId', 'notFound', 'confirm', 'unknown', 'invalidText', 'filter', 'zero', 'longReason'] then
                VerifyTyped(Response, Scenario, LanguageId);
            if Scenario = 'late' then
                Assert.IsTrue(ReadText(Response, 'error').Contains('Q15 late failure'), 'The fault must occur after real line creation.');
            if Scenario = 'latePost' then begin
                Assert.IsTrue(ReadText(Response, 'error').Contains('Q15 late posting failure'), 'The refusal must occur after real standard posting.');
                Assert.AreEqual(5, LedgerQuantity(''), 'A late refusal must preserve the original stock.');
            end;
        end;
        Cleanup(Inspection);
    end;

    local procedure ExpectedQuantity(Scenario: Text): Decimal
    begin
        case Scenario of
            'passed':
                exit(2);
            'quantity':
                exit(1);
            else
                exit(3);
        end;
    end;

    local procedure VerifyTyped(Response: JsonObject; Scenario: Text; LanguageId: Integer)
    var
        Expected: Text;
    begin
        case Scenario of
            'missingId', 'malformedId', 'notFound':
                Expected := 'inspectionSystemId';
            'confirm':
                Expected := 'confirm';
            'invalidText':
                Expected := 'quantityBasis';
            'unknown':
                Expected := 'unexpected';
            'filter':
                Expected := 'sourceLocationCode';
            'zero':
                Expected := 'quantity';
            'longReason':
                Expected := 'reasonCode';
        end;
        Assert.AreEqual(Expected, ReadText(Response, 'parameter'), 'Identify the invalid parameter.');
        Assert.IsTrue(ReadText(Response, 'expected') <> '', 'Describe what is expected.');
        Assert.IsTrue(ReadText(Response, 'nextStep') <> '', 'Give a next step.');
        if (LanguageId = 1039) and (Scenario = 'unknown') then
            Assert.AreEqual('skilgreind beiðniviðföng', ReadText(Response, 'expected'), 'Expected parameters must be Icelandic.');
        if Scenario = 'invalidText' then
            if LanguageId = 1039 then
                Assert.AreEqual('JSON textastrengur', ReadText(Response, 'expected'), 'Expected value type must be Icelandic.')
            else
                Assert.AreEqual('a JSON string', ReadText(Response, 'expected'), 'Expected value type must be English.');
        if (LanguageId = 1039) and (Scenario = 'missingId') then
            Assert.IsTrue(ReadText(Response, 'nextStep').Contains('Lestu'), 'Recovery guidance must be Icelandic.');
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
        InventoryPeriod: Record "Inventory Period";
        Setup: Record "Qlty. Management Setup";
    begin
        PriorWorkDate := WorkDate();
        InventoryPeriod.SetRange(Closed, true);
        if InventoryPeriod.FindLast() then
            if WorkDate() <= InventoryPeriod."Ending Date" then
                WorkDate(InventoryPeriod."Ending Date" + 1);
        FixtureCode := CopyStr('Q15-' + DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 10);
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
        // Microsoft selects the standard item journal template; use the one it will find.
        JournalTemplate.SetRange(Type, JournalTemplate.Type::Item);
        JournalTemplate.SetRange("Page ID", Page::"Item Journal");
        JournalTemplate.SetRange(Recurring, false);
        JournalTemplate.FindFirst();
        TemplateCode := JournalTemplate.Name;
        PriorForceReport := JournalTemplate."Force Posting Report";
        JournalBatch."Journal Template Name" := TemplateCode;
        JournalBatch.Name := FixtureCode;
        JournalBatch.Insert(false);
        HadSetup := Setup.Get();
        if HadSetup then
            PriorSetup := Setup
        else
            Setup.Insert(false);
        Setup."Item Journal Batch Name" := FixtureCode;
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
        JournalLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
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
        InventoryPostingSetup.Init();
        InventoryPostingSetup."Location Code" := FixtureCode;
        InventoryPostingSetup."Invt. Posting Group Code" := FixtureCode;
        InventoryPostingSetup."Inventory Account" := FixtureCode;
        InventoryPostingSetup.Insert(false);
        Item.Get(FixtureCode);
        Item."Inventory Posting Group" := FixtureCode;
        Item."Gen. Prod. Posting Group" := FixtureCode;
        Item.Modify(false);
        JournalLine."Journal Template Name" := TemplateCode;
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

    local procedure LedgerQuantity(EntryTypeFilter: Text): Decimal
    var
        Ledger: Record "Item Ledger Entry";
    begin
        Ledger.SetRange("Item No.", FixtureCode);
        if EntryTypeFilter = 'Negative Adjmt.' then
            Ledger.SetRange("Entry Type", Ledger."Entry Type"::"Negative Adjmt.");
        Ledger.CalcSums(Quantity);
        exit(Ledger.Quantity);
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
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Quality.Disposition.CreateNegativeAdjustment", Enum::"Message Version ori"::"1.0", '', 'quality15-tests', 'application/json', RequestContent, TaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
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

    local procedure ReadArrayCount(Response: JsonObject; PropertyName: Text): Integer
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Response.Get(PropertyName, Token), 'Response property missing: ' + PropertyName);
        exit(Token.AsArray().Count());
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
        if CopyStr(FixtureCode, 1, 4) <> 'Q15-' then
            Error('Only owned Q15 fixtures may be removed.');
        JournalLine.SetRange("Journal Template Name", TemplateCode);
        JournalLine.SetRange("Journal Batch Name", FixtureCode);
        JournalLine.DeleteAll(false);
        JournalBatch.SetRange("Journal Template Name", TemplateCode);
        JournalBatch.SetRange(Name, FixtureCode);
        JournalBatch.DeleteAll(false);
        JournalTemplate.Get(TemplateCode);
        if JournalTemplate."Force Posting Report" <> PriorForceReport then begin
            JournalTemplate."Force Posting Report" := PriorForceReport;
            JournalTemplate.Modify(false);
        end;
        Inspection.Delete(false);
        ItemUnit.SetRange("Item No.", FixtureCode);
        ItemUnit.DeleteAll(false);
        Item.Get(FixtureCode);
        Item.Delete(false);
        Unit.Get(FixtureCode);
        Unit.Delete(false);
        Location.Get(FixtureCode);
        Location.Delete(false);
        WorkDate(PriorWorkDate);
        if HadSetup then begin
            Setup.Get();
            Setup."Item Journal Batch Name" := PriorSetup."Item Journal Batch Name";
            Setup.Modify(false);
        end else
            if Setup.Get() then
                Setup.Delete(false);
    end;
}
