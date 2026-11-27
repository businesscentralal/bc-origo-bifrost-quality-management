namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Foundation.UOM;
using Microsoft.QualityManagement.Document;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Issue 14: real standard transfer order creation, refusals, rollback and permissions through the dispatcher.</summary>
codeunit 97268 "Quality Transfer Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        FixtureCode: Code[10];

    /// <summary>The new message type keeps its published ordinal.</summary>
    [Test]
    procedure Scenario_AC01_Ordinal_IsPinned()
    begin
        // Story #14, AC01 | Time: No date dependency | Risk: none
        Assert.AreEqual(10035298, Enum::"Message Type ori"::"Quality.Disposition.CreateTransferOrder".AsInteger(), 'The published ordinal must never change.');
    end;

    /// <summary>The contract declares the write effect, the not-idempotent warning and Icelandic help.</summary>
    [Test]
    procedure Scenario_AC01_Discovery_DeclaresNotIdempotentWrite()
    var
        Contract: Interface "Msg Contract ori";
        Effect: JsonObject;
        Token: JsonToken;
        Overview: Text;
        Notes: Text;
    begin
        // Story #14, AC01 | Time: No date dependency | Risk: none
        Contract := Enum::"Message Type ori"::"Quality.Disposition.CreateTransferOrder";
        Assert.IsTrue(Contract.GetEffect(Effect), 'The effect chapter must exist.');
        Effect.Get('effect', Token);
        Assert.AreEqual('irreversible', Token.AsValue().AsText(), 'The type must be classified as irreversible.');
        Effect.Get('idempotent', Token);
        Assert.IsFalse(Token.AsValue().AsBoolean(), 'The type is not idempotent.');
        Assert.IsTrue(Contract.GetNotes(Notes), 'Notes must exist.');
        Assert.IsTrue(Notes.Contains('Not idempotent'), 'The notes must warn about repeats.');
        Assert.IsTrue(Contract.GetOverview(Overview), 'Overview must exist.');
        Assert.IsTrue(Overview.Contains('expectedCount counts the one quality inspection'), 'The count unit must be named.');
        GlobalLanguage(1039);
        Contract.GetNotes(Notes);
        Contract.GetOverview(Overview);
        GlobalLanguage(1033);
        Assert.IsTrue(Notes.Contains('ídempótent'), 'The Icelandic notes must carry the warning.');
        Assert.IsTrue(Overview.Contains('millilagerfærslur'), 'The Icelandic overview must exist.');
    end;

    /// <summary>A failed quantity becomes one unposted direct transfer order.</summary>
    [Test]
    procedure Scenario_AC02_Direct_CreatesUnpostedTransferOrder()
    begin
        // Story #14, AC02 | Time: WorkDate | Risk: owned Q14 fixtures only
        VerifyScenario('direct', 1033);
        VerifyScenario('direct', 1039);
    end;

    /// <summary>An in-transit location produces an in-transit transfer order.</summary>
    [Test]
    procedure Scenario_AC02_InTransit_CreatesInTransitTransferOrder()
    begin
        // Story #14, AC02 | Time: WorkDate | Risk: owned Q14 fixtures only
        VerifyScenario('inTransit', 1033);
        VerifyScenario('inTransit', 1039);
    end;

    /// <summary>The passed basis and an explicit quantity select the transferred quantity.</summary>
    [Test]
    procedure Scenario_AC02_PassedAndSpecificQuantity_SelectQuantity()
    begin
        // Story #14, AC02 | Time: WorkDate | Risk: owned Q14 fixtures only
        VerifyScenario('passed', 1033);
        VerifyScenario('specific', 1033);
    end;

    /// <summary>Each malformed identifier is refused with the typed MissingParameter error.</summary>
    [Test]
    procedure Scenario_AC03_InspectionId_RefusedTyped()
    begin
        // Story #14, AC03 | Time: No date dependency | Risk: owned Q14 fixtures only
        VerifyScenario('missingId', 1033);
        VerifyScenario('emptyId', 1033);
        VerifyScenario('malformedId', 1033);
        VerifyScenario('nullId', 1039);
        VerifyScenario('nonTextId', 1033);
    end;

    /// <summary>A missing destination is refused before any change.</summary>
    [Test]
    procedure Scenario_AC03_MissingDestination_RefusedTyped()
    begin
        // Story #14, AC03 | Time: No date dependency | Risk: owned Q14 fixtures only
        VerifyScenario('noDestination', 1033);
        VerifyScenario('noDestination', 1039);
    end;

    /// <summary>Confirmation, unknown keys, filter syntax and zero quantities are refused typed.</summary>
    [Test]
    procedure Scenario_AC03_InvalidInput_RefusedTyped()
    begin
        // Story #14, AC03 | Time: No date dependency | Risk: owned Q14 fixtures only
        VerifyScenario('noConfirm', 1033);
        VerifyScenario('falseConfirm', 1033);
        VerifyScenario('unknown', 1033);
        VerifyScenario('filterLocation', 1033);
        VerifyScenario('filterBin', 1033);
        VerifyScenario('unknownInspection', 1033);
        VerifyScenario('zeroInspection', 1033);
        VerifyScenario('zeroQuantity', 1033);
        VerifyScenario('badBasis', 1033);
    end;

    /// <summary>A Microsoft refusal and a late failure leave no transfer order behind.</summary>
    [Test]
    procedure Scenario_AC03_MicrosoftRefusalAndLateFailure_RollBack()
    begin
        // Story #14, AC03 | Time: No date dependency | Risk: owned Q14 fixtures only
        VerifyScenario('unknownDestination', 1033);
        VerifyScenario('late', 1033);
    end;

    /// <summary>A count other than one is refused before any change; an omitted count only previews.</summary>
    [Test]
    procedure Scenario_AC04_ExpectedCount_IsEnforced()
    begin
        // Story #14, AC04 | Time: No date dependency | Risk: owned Q14 fixtures only
        VerifyScenario('count0', 1033);
        VerifyScenario('count2', 1033);
        VerifyScenario('omittedCount', 1033);
    end;

    /// <summary>Roles without the transfer capability are refused; the full role succeeds.</summary>
    [Test]
    procedure Scenario_AC05_RoleMatrix()
    begin
        // Story #14, AC05 | Time: WorkDate | Risk: permissions restored
        VerifyScenario('noRole', 1033);
        VerifyScenario('readRole', 1033);
        VerifyScenario('fullRole', 1033);
    end;

    local procedure VerifyScenario(Scenario: Text; LanguageId: Integer)
    var
        Inspection: Record "Qlty. Inspection Header";
        Setup: Record "Setup ori";
        Fault: Codeunit "Quality Transfer Fault ori";
        Request: JsonObject;
        Response: JsonObject;
        PriorConfirm: Boolean;
        ExpectSuccess: Boolean;
    begin
        // [GIVEN] All business fixture records are created for this test, including the locations.
        LowerPermissions.SetOutsideO365Scope();
        CreateFixture(Inspection);
        Request.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Request.Add('quantityBasis', 'failed');
        Request.Add('sourceLocationCode', FixtureCode);
        Request.Add('destinationLocationCode', 'D' + CopyStr(FixtureCode, 2));
        Request.Add('confirm', true);
        Request.Add('expectedCount', 1);
        ExpectSuccess := Scenario in ['direct', 'inTransit', 'passed', 'specific', 'fullRole'];
        case Scenario of
            'inTransit':
                Request.Add('inTransitLocationCode', 'T' + CopyStr(FixtureCode, 2));
            'passed':
                Request.Replace('quantityBasis', 'passed');
            'specific':
                Request.Add('quantity', 1);
            'missingId':
                Request.Remove('inspectionSystemId');
            'emptyId':
                Request.Replace('inspectionSystemId', '');
            'malformedId':
                Request.Replace('inspectionSystemId', 'not-a-guid');
            'nullId':
                Request.Replace('inspectionSystemId', '00000000-0000-0000-0000-000000000000');
            'nonTextId':
                Request.Replace('inspectionSystemId', 42);
            'unknownInspection':
                Request.Replace('inspectionSystemId', Format(CreateGuid(), 0, 4));
            'noDestination':
                Request.Remove('destinationLocationCode');
            'noConfirm':
                Request.Remove('confirm');
            'falseConfirm':
                Request.Replace('confirm', false);
            'unknown':
                Request.Add('unexpected', true);
            'filterLocation':
                Request.Replace('sourceLocationCode', '*');
            'filterBin':
                Request.Add('sourceBinCode', 'A|B');
            'zeroInspection':
                begin
                    Inspection."Fail Quantity" := 0;
                    Inspection.Modify(false);
                end;
            'zeroQuantity':
                Request.Add('quantity', 0);
            'badBasis':
                Request.Replace('quantityBasis', 'sample');
            'unknownDestination':
                Request.Replace('destinationLocationCode', 'NOSUCH');
            'count0':
                Request.Replace('expectedCount', 0);
            'count2':
                Request.Replace('expectedCount', 2);
            'omittedCount':
                Request.Remove('expectedCount');
        end;
        Setup.InsertIfNotExists();
        if Scenario = 'omittedCount' then
            PriorConfirm := SetIrreversibleConfirm(true);
        Commit();
        case Scenario of
            'noRole':
                begin
                    LowerPermissions.SetExactPermissionSet('BIFROST API ori');
                    LowerPermissions.AddPermissionSet('QltyMgmt - Inspector');
                    LowerPermissions.AddPermissionSet('QM Transfer Test ori');
                end;
            'readRole':
                begin
                    LowerPermissions.SetExactPermissionSet('BIFROST API ori');
                    LowerPermissions.AddPermissionSet('BIFROST QM Read ori');
                    LowerPermissions.AddPermissionSet('QM Transfer Test ori');
                end;
            'fullRole':
                begin
                    LowerPermissions.SetExactPermissionSet('BIFROST API ori');
                    LowerPermissions.AddPermissionSet('BIFROST QM Full ori');
                    LowerPermissions.AddPermissionSet('D365 BUS FULL ACCESS');
                    LowerPermissions.AddPermissionSet('QM Transfer Test ori');
                end;
        end;
        if Scenario = 'late' then
            BindSubscription(Fault);
        // [WHEN] The real dispatcher executes the standard disposition.
        Response := Dispatch(Request, LanguageId);
        if Scenario = 'late' then
            UnbindSubscription(Fault);
        LowerPermissions.SetOutsideO365Scope();
        // [THEN] The transfer orders match the request, or nothing was created.
        if ExpectSuccess then
            VerifySuccess(Response, Scenario)
        else
            VerifyRefusal(Response, Scenario, LanguageId);
        if Scenario = 'omittedCount' then
            SetIrreversibleConfirm(PriorConfirm);
        Cleanup(Inspection);
    end;

    local procedure SetIrreversibleConfirm(NewValue: Boolean) Prior: Boolean
    var
        Setup: Record "Setup ori";
        SetupRef: RecordRef;
        ConfirmField: FieldRef;
        FieldIndex: Integer;
    begin
        // The field is protected; the reference lets the test restore the prior setting exactly.
        Setup.Get();
        SetupRef.GetTable(Setup);
        for FieldIndex := 1 to SetupRef.FieldCount() do
            if SetupRef.FieldIndex(FieldIndex).Name() = 'Require Irreversible Confirm' then
                ConfirmField := SetupRef.FieldIndex(FieldIndex);
        Prior := ConfirmField.Value();
        ConfirmField.Value(NewValue);
        SetupRef.Modify(false);
        Commit();
    end;

    local procedure VerifySuccess(Response: JsonObject; Scenario: Text)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemLedger: Record "Item Ledger Entry";
        Numbers: JsonArray;
        Token: JsonToken;
        ExpectedQuantity: Decimal;
    begin
        if ReadText(Response, 'status') <> 'Success' then
            Assert.Fail(ReadText(Response, 'error'));
        Response.Get('transferOrderNos', Token);
        Numbers := Token.AsArray();
        Assert.AreEqual(1, Numbers.Count(), 'One transfer order must be reported.');
        Numbers.Get(0, Token);
        TransferHeader.Get(Token.AsValue().AsText());
        Assert.AreEqual(FixtureCode, TransferHeader."Transfer-from Code", 'Source location must be the stock location.');
        Assert.AreEqual('D' + CopyStr(FixtureCode, 2), TransferHeader."Transfer-to Code", 'The destination must be validated by standard code.');
        Assert.AreEqual(FixtureCode, TransferHeader."Qlty. Inspection No.", 'The order must reference the inspection.');
        if Scenario = 'inTransit' then begin
            Assert.AreEqual('T' + CopyStr(FixtureCode, 2), TransferHeader."In-Transit Code", 'The in-transit location must be used.');
            Assert.IsFalse(TransferHeader."Direct Transfer", 'An in-transit transfer is not direct.');
        end else
            Assert.IsTrue(TransferHeader."Direct Transfer", 'Without an in-transit location the transfer is direct.');
        Assert.AreEqual(TransferHeader.Status::Open, TransferHeader.Status, 'The order must stay open.');
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        Assert.AreEqual(1, TransferLine.Count(), 'One standard line is expected.');
        TransferLine.FindFirst();
        Assert.AreEqual(FixtureCode, TransferLine."Item No.", 'Only the inspection item may move.');
        case Scenario of
            'passed':
                ExpectedQuantity := 2;
            'specific':
                ExpectedQuantity := 1;
            else
                ExpectedQuantity := 3;
        end;
        Assert.AreEqual(ExpectedQuantity, TransferLine.Quantity, 'The quantity must come from the selected basis.');
        Assert.AreEqual(0, TransferLine."Quantity Shipped", 'Nothing may be shipped.');
        ItemLedger.SetRange("Item No.", FixtureCode);
        Assert.IsTrue(ItemLedger.IsEmpty(), 'Nothing may be posted.');
    end;

    local procedure VerifyRefusal(Response: JsonObject; Scenario: Text; LanguageId: Integer)
    var
        TransferHeader: Record "Transfer Header";
    begin
        Assert.AreEqual('Error', ReadText(Response, 'status'), 'The operation must return a refusal.');
        TransferHeader.SetRange("Qlty. Inspection No.", FixtureCode);
        Assert.IsTrue(TransferHeader.IsEmpty(), 'A refusal must leave no transfer order.');
        case Scenario of
            'missingId', 'emptyId', 'malformedId', 'nullId', 'nonTextId':
                VerifyTyped(Response, 'MissingParameter', 'inspectionSystemId', LanguageId);
            'noDestination':
                VerifyTyped(Response, 'MissingParameter', 'destinationLocationCode', LanguageId);
            'noConfirm', 'falseConfirm':
                VerifyTyped(Response, 'InvalidParameter', 'confirm', LanguageId);
            'unknown':
                VerifyTyped(Response, 'UnknownParameter', 'unexpected', LanguageId);
            'filterLocation':
                VerifyTyped(Response, 'InvalidParameter', 'sourceLocationCode', LanguageId);
            'filterBin':
                VerifyTyped(Response, 'InvalidParameter', 'sourceBinCode', LanguageId);
            'unknownInspection':
                VerifyTyped(Response, 'RecordNotFound', 'inspectionSystemId', LanguageId);
            'zeroInspection':
                VerifyTyped(Response, 'PreconditionFailed', 'quantityBasis', LanguageId);
            'zeroQuantity':
                VerifyTyped(Response, 'InvalidParameter', 'quantity', LanguageId);
            'badBasis':
                VerifyTyped(Response, 'InvalidParameter', 'quantityBasis', LanguageId);
            'noRole', 'readRole':
                Assert.IsTrue(ReadText(Response, 'error') <> '', 'The refusal must carry a message.');
            'late':
                Assert.IsTrue(ReadText(Response, 'error').Contains('Q14 late failure'), 'The fault must occur after real line creation.');
        end;
    end;

    local procedure VerifyTyped(Response: JsonObject; Code: Text; Parameter: Text; LanguageId: Integer)
    begin
        Assert.AreEqual(Code, ReadText(Response, 'code'), 'The refusal must retain its typed code.');
        Assert.AreEqual(Parameter, ReadText(Response, 'parameter'), 'Identify the invalid parameter.');
        Assert.IsTrue(ReadText(Response, 'expected') <> '', 'Describe what is expected.');
        Assert.IsTrue(ReadText(Response, 'nextStep') <> '', 'Provide a next step.');
        if LanguageId = 1039 then
            Assert.IsTrue(ReadText(Response, 'nextStep') <> ReadText(Response, 'expected'), 'Recovery guidance must be translated.');
    end;

    local procedure CreateFixture(var Inspection: Record "Qlty. Inspection Header")
    var
        Item: Record Item;
        Unit: Record "Unit of Measure";
        ItemUnit: Record "Item Unit of Measure";
        Location: Record Location;
    begin
        FixtureCode := CopyStr('Q14-' + DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 10);
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
        Location.Code := 'T' + CopyStr(FixtureCode, 2);
        Location."Use As In-Transit" := true;
        Location.Insert(false);
        Inspection."No." := FixtureCode;
        Inspection."Source Item No." := FixtureCode;
        Inspection."Location Code" := FixtureCode;
        Inspection."Source Quantity (Base)" := 5;
        Inspection."Fail Quantity" := 3;
        Inspection."Pass Quantity" := 2;
        Inspection.Insert(false);
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
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Quality.Disposition.CreateTransferOrder", Enum::"Message Version ori"::"1.0", '', 'quality14-tests', 'application/json', RequestContent, TaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
    end;

    local procedure ReadText(Response: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Response.Get(PropertyName, Token) then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure Cleanup(Inspection: Record "Qlty. Inspection Header")
    var
        Item: Record Item;
        Unit: Record "Unit of Measure";
        ItemUnit: Record "Item Unit of Measure";
        Location: Record Location;
        TransferHeader: Record "Transfer Header";
    begin
        if CopyStr(FixtureCode, 1, 4) <> 'Q14-' then
            Error('Only owned Q14 fixtures may be removed.');
        TransferHeader.SetRange("Qlty. Inspection No.", FixtureCode);
        TransferHeader.DeleteAll(true);
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
        Location.Get('T' + CopyStr(FixtureCode, 2));
        Location.Delete(false);
    end;
}
