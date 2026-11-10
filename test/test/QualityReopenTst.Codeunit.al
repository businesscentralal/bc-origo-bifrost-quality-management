namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>Issue 5: reopens a finished inspection through the public Foundation dispatcher.</summary>
codeunit 97220 "Quality Reopen Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>A finished inspection becomes open. ReopenInspection persists the quantities already stored.</summary>
    [Test]
    [HandlerFunctions('ConfirmYes')]
    procedure Scenario_AC03_FinishedInspection_BecomesOpen()
    var
        Inspection: Record "Qlty. Inspection Header";
        Response: JsonObject;
        InspectionNo: Code[20];
    begin
        // Story #5, AC03/AC08 | Time: no date-dependent inputs | Risk: owned fixture deleted before asserts
        Initialize(Inspection);
        InspectionNo := Inspection."No.";
        Response := Invoke(IdRequest(Inspection.SystemId));
        Inspection.Get(InspectionNo, 0);
        Cleanup(InspectionNo);
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual(Inspection.Status::Open, Inspection.Status, 'Standard ReopenInspection must open the inspection.');
        Assert.AreEqual(4, Inspection."Pass Quantity", 'ReopenInspection persists the pass quantity already stored.');
        Assert.AreEqual(1, Inspection."Fail Quantity", 'ReopenInspection persists the fail quantity already stored.');
    end;

    /// <summary>A second call on the open inspection changes nothing.</summary>
    [Test]
    [HandlerFunctions('ConfirmYes')]
    procedure Scenario_AC01_SecondCall_LeavesOpenInspectionUnchanged()
    var
        Inspection: Record "Qlty. Inspection Header";
        Response: JsonObject;
        InspectionNo: Code[20];
        PassQuantity: Decimal;
        FailQuantity: Decimal;
    begin
        // Story #5, AC01 | Time: no date-dependent inputs | Risk: owned fixture deleted before asserts
        Initialize(Inspection);
        InspectionNo := Inspection."No.";
        Response := Invoke(IdRequest(Inspection.SystemId));
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
        Inspection.Get(InspectionNo, 0);
        PassQuantity := Inspection."Pass Quantity";
        FailQuantity := Inspection."Fail Quantity";
        Response := Invoke(IdRequest(Inspection.SystemId));
        Inspection.Get(InspectionNo, 0);
        Cleanup(InspectionNo);
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual(Inspection.Status::Open, Inspection.Status, 'The second call must leave the inspection open.');
        Assert.AreEqual(PassQuantity, Inspection."Pass Quantity", 'The second call must not change the pass quantity.');
        Assert.AreEqual(FailQuantity, Inspection."Fail Quantity", 'The second call must not change the fail quantity.');
    end;

    /// <summary>A missing key is a translated refusal and writes nothing.</summary>
    [Test]
    procedure Scenario_AC02_MissingKey_RefusesWithoutChanges()
    begin
        // Story #5, AC02/AC06 | Time: no date-dependent inputs | Risk: none
        AssertInputRefusal('{}', 'MissingParameter', 1033, 'required');
    end;

    /// <summary>The same missing-key refusal is translated in Icelandic.</summary>
    [Test]
    procedure Scenario_AC06_MissingKey_RefusesInIcelandic()
    var
        Response: JsonObject;
    begin
        // Story #5, AC06 | Time: no date-dependent inputs | Risk: none
        // Execute uses Bifrost Setup's default language. The public enqueue path accepts the Windows language id.
        Response := InvokeInLanguage('{}', 1039);
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual('MissingParameter', Response.GetText('code'), Serialize(Response));
        Assert.IsTrue(Serialize(Response).Contains('áskilið'), Serialize(Response));
    end;

    /// <summary>An unknown key is refused before the native action.</summary>
    [Test]
    procedure Scenario_AC02_UnknownKey_RefusesWithoutChanges()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        InspectionNo: Code[20];
    begin
        // Story #5, AC02 | Time: no date-dependent inputs | Risk: owned fixture deleted before asserts
        Initialize(Inspection);
        InspectionNo := Inspection."No.";
        Request.ReadFrom(IdRequest(Inspection.SystemId));
        Request.Add('skip', 1);
        Response := Invoke(Serialize(Request));
        Inspection.Get(InspectionNo, 0);
        Cleanup(InspectionNo);
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual('UnknownParameter', Response.GetText('code'), Serialize(Response));
        Assert.AreEqual(Inspection.Status::Finished, Inspection.Status, 'An unknown key must not reopen the inspection.');
        Assert.AreEqual(4, Inspection."Pass Quantity", 'An unknown key must not clear quantities.');
    end;

    /// <summary>A non-GUID value is refused.</summary>
    [Test]
    procedure Scenario_AC02_InvalidId_RefusesWithoutChanges()
    begin
        // Story #5, AC02 | Time: no date-dependent inputs | Risk: none
        AssertInputRefusal('{"inspectionSystemId":"invalid"}', 'InvalidParameter', 1033, '');
    end;

    /// <summary>An unknown inspection is refused.</summary>
    [Test]
    procedure Scenario_AC02_UnknownId_RefusesWithoutChanges()
    begin
        // Story #5, AC02 | Time: no date-dependent inputs | Risk: none
        AssertInputRefusal(IdRequest(CreateGuid()), 'RecordNotFound', 1033, '');
    end;

    /// <summary>Microsoft refuses a reopen when a later re-inspection exists, and the finished row stays finished.</summary>
    [Test]
    procedure Scenario_AC04_LaterReinspection_RefusesWithoutChanges()
    var
        Inspection: Record "Qlty. Inspection Header";
        Later: Record "Qlty. Inspection Header";
        Response: JsonObject;
        InspectionNo: Code[20];
    begin
        // Story #5, AC04 | Time: no date-dependent inputs | Risk: owned fixture deleted before asserts
        Initialize(Inspection);
        InspectionNo := Inspection."No.";
        Later := Inspection;
        Later."Re-inspection No." := 1;
        Clear(Later.SystemId);
        Later.Insert();
        Commit();
        Response := Invoke(IdRequest(Inspection.SystemId));
        Inspection.Get(InspectionNo, 0);
        Cleanup(InspectionNo);
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual('BusinessCentralError', Response.GetText('code'), Serialize(Response));
        Assert.AreEqual(Inspection.Status::Finished, Inspection.Status, 'A native refusal must leave the inspection finished.');
        Assert.AreEqual(4, Inspection."Pass Quantity", 'A native refusal must leave the pass quantity.');
        Assert.AreEqual(1, Inspection."Fail Quantity", 'A native refusal must leave the fail quantity.');
    end;

    /// <summary>The contract states the write effect, idempotency and the app permission set.</summary>
    [Test]
    procedure Scenario_AC01_Contract_StatesEffectAndIdempotency()
    var
        Contract: Interface "Msg Contract ori";
        Effect: JsonObject;
        Overview: Text;
        Notes: Text;
        PreviousLanguage: Integer;
    begin
        // Story #5, AC01/AC07 | Time: no date-dependent inputs | Risk: session language restored
        Contract := Enum::"Message Type ori"::"Quality.Inspection.Reopen";
        Assert.IsTrue(Contract.GetEffect(Effect), 'The effect chapter must exist.');
        Assert.AreEqual('write', Effect.GetText('effect'), 'The effect must be a write.');
        Assert.IsTrue(Effect.GetBoolean('idempotent'), 'Reopening an open inspection changes nothing.');
        Assert.AreEqual('BIFROST QM Full ori', Effect.GetText('permissionSet'), 'The contract must name the app permission set.');
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        Assert.IsTrue(Contract.GetOverview(Overview), 'The help overview must exist.');
        Assert.IsTrue(Contract.GetNotes(Notes), 'The help notes must exist.');
        Assert.IsTrue(Notes.Contains('Idempotent'), 'The help notes must state idempotency.');
        Assert.IsTrue(Notes.Contains('Commit'), 'The help notes must state the commit behaviour.');
        GlobalLanguage(PreviousLanguage);
    end;

    /// <summary>Confirms the native reopen question in the interactive test client.</summary>
    [ConfirmHandler]
    procedure ConfirmYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(Question <> '', 'The native confirmation must have a question.');
        Reply := true;
    end;

    local procedure AssertInputRefusal(RequestText: Text; ExpectedCode: Text; LanguageId: Integer; ExpectedFragment: Text)
    var
        Setup: Record "Setup ori";
        Response: JsonObject;
        PreviousLanguage: Integer;
    begin
        Setup.InsertIfNotExists();
        Commit();
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Response := Invoke(RequestText);
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual(ExpectedCode, Response.GetText('code'), Serialize(Response));
        if ExpectedFragment <> '' then
            Assert.IsTrue(Serialize(Response).Contains(ExpectedFragment), Serialize(Response));
    end;

    local procedure Initialize(var Inspection: Record "Qlty. Inspection Header")
    var
        InspectionTemplate: Record "Qlty. Inspection Template Hdr.";
        BifrostSetup: Record "Setup ori";
    begin
        BifrostSetup.InsertIfNotExists();
        InspectionTemplate.Code := CopyStr('Q5' + DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 20);
        InspectionTemplate.Insert();
        Inspection.Init();
        Inspection."No." := InspectionTemplate.Code;
        Inspection."Re-inspection No." := 0;
        Inspection."Template Code" := InspectionTemplate.Code;
        Inspection.Status := Inspection.Status::Finished;
        Inspection."Pass Quantity" := 4;
        Inspection."Fail Quantity" := 1;
        Inspection.Insert();
        Commit();
    end;

    local procedure Cleanup(InspectionNo: Code[20])
    var
        Inspection: Record "Qlty. Inspection Header";
        InspectionTemplate: Record "Qlty. Inspection Template Hdr.";
    begin
        Inspection.SetRange("No.", InspectionNo);
        Inspection.DeleteAll(true);
        if InspectionTemplate.Get(InspectionNo) then
            InspectionTemplate.Delete(true);
        Commit();
    end;

    local procedure IdRequest(InspectionId: Guid): Text
    var
        Request: JsonObject;
    begin
        Request.Add('inspectionSystemId', Format(InspectionId, 0, 4));
        exit(Serialize(Request));
    end;

    local procedure Serialize(Value: JsonObject) Result: Text
    begin
        Value.WriteTo(Result);
    end;

    local procedure Invoke(RequestText: Text) Response: JsonObject
    begin
        Response := InvokeInLanguage(RequestText, 0);
    end;

    local procedure InvokeInLanguage(RequestText: Text; LanguageId: Integer) Response: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        ResponseContentType: Text[100];
        ResponseText: Text;
        EmptyTaskId: Guid;
        MessageId: Guid;
        ResponseTime: Duration;
    begin
        RequestContent.AddText(RequestText);
        if LanguageId = 0 then
            Dispatcher.Execute(Enum::"Message Type ori"::"Quality.Inspection.Reopen", Enum::"Message Version ori"::"1.0", '', 'issue5-tests', 'application/json', RequestContent, ResponseContent, ResponseContentType, false)
        else
            Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Quality.Inspection.Reopen", Enum::"Message Version ori"::"1.0", '', 'issue5-tests', 'application/json', RequestContent, EmptyTaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
    end;
}
