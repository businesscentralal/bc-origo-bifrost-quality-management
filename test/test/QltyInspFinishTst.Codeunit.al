namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Configuration;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Document;
using Origo.Bifrost;
using Origo.Bifrost.QualityManagement;
using System.Security.AccessControl;
using System.Security.User;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;
using System.Utilities;

/// <summary>
/// Native tests for Quality.Inspection.Finish.
/// Fixtures are created by the test and removed before it returns.
/// </summary>
codeunit 97202 "Qlty Insp Finish Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [HandlerFunctions('ConfirmFinish')]
    procedure AC01_FinishOpenInspection_LocksTheResult()
    var
        Header: Record "Qlty. Inspection Header";
        Response: JsonObject;
    begin
        LowerPermissions.SetOutsideO365Scope();
        // [GIVEN] An open inspection with no result that would block finishing
        CreateOpenInspection(Header, '');
        Commit();

        // [WHEN] The inspection is finished through the message type
        Response := Finish(Header."No.", -1, false);

        // [THEN] Business Central recorded the finish. A direct status write would not set the finish user.
        AssertSuccess(Response);
        Assert.AreEqual('Open', GetText(Response, 'previousStatus'), 'previousStatus');
        Assert.AreEqual('Finished', GetText(Response, 'recordStatus'), 'recordStatus');
        Assert.AreEqual(0, GetInteger(Response, 'reinspectionNo'), 'reinspectionNo');
        Assert.IsTrue(GetBoolean(Response, 'changed'), 'changed');
        Header.Get(Header."No.", Header."Re-inspection No.");
        Assert.AreEqual(Header.Status::Finished, Header.Status, 'status');
        Assert.AreNotEqual('', Header."Finished By User ID", 'finished by');
        Assert.AreNotEqual(0DT, Header."Finished Date", 'finished date');
        DeleteInspection(Header."No.");
    end;

    [Test]
    procedure AC01_SecondFinish_DoesNotWriteAgain()
    var
        Header: Record "Qlty. Inspection Header";
        FinishedDate: DateTime;
        Response: JsonObject;
    begin
        LowerPermissions.SetOutsideO365Scope();
        // [GIVEN] An inspection that is already finished. Validate runs the finish checks without the screen question.
        CreateOpenInspection(Header, '');
        Header.Validate(Status, Header.Status::Finished);
        FinishedDate := Header."Finished Date";
        Commit();

        // [WHEN] Finish is requested again
        Response := Finish(Header."No.", 0, false);

        // [THEN] The call succeeds and does not change the recorded finish
        AssertSuccess(Response);
        Assert.AreEqual('Finished', GetText(Response, 'previousStatus'), 'previousStatus');
        Assert.AreEqual('Finished', GetText(Response, 'recordStatus'), 'recordStatus');
        Assert.IsFalse(GetBoolean(Response, 'changed'), 'changed');
        Header.Get(Header."No.", 0);
        Assert.AreEqual(Header.Status::Finished, Header.Status, 'status');
        Assert.AreEqual(FinishedDate, Header."Finished Date", 'finished date unchanged');
        DeleteInspection(Header."No.");
    end;

    [Test]
    procedure AC02_MissingNo_RefusesAndChangesNothing()
    var
        Before: Integer;
        Response: JsonObject;
    begin
        LowerPermissions.SetOutsideO365Scope();
        Before := CountOwnedInspections();
        Response := Finish('', -1, true);
        AssertRefusal(Response, 'MissingParameter', 'no');
        Assert.AreEqual(Before, CountOwnedInspections(), 'no inspection created');
    end;

    [Test]
    procedure AC02_UnknownKey_Refuses()
    var
        Request: JsonObject;
        Response: JsonObject;
    begin
        LowerPermissions.SetOutsideO365Scope();
        Request.Add('no', 'XQM4UNKNOWN');
        Request.Add('status', 'Finished');
        Response := Invoke(Request, true);
        AssertRefusal(Response, 'UnknownParameter', 'status');
    end;

    [Test]
    procedure AC02_ReinspectionNotInteger_Refuses()
    var
        Request: JsonObject;
        Response: JsonObject;
    begin
        LowerPermissions.SetOutsideO365Scope();
        Request.Add('no', 'XQM4FORMAT');
        Request.Add('reinspectionNo', 'first');
        Response := Invoke(Request, true);
        AssertRefusal(Response, 'InvalidParameterFormat', 'reinspectionNo');
    end;

    [Test]
    procedure AC04_MissingInspection_Refuses()
    var
        Response: JsonObject;
    begin
        LowerPermissions.SetOutsideO365Scope();
        Response := Finish('XQM4MISSING0000001', 0, true);
        AssertRefusal(Response, 'RecordNotFound', 'XQM4MISSING0000001');
    end;

    [Test]
    [HandlerFunctions('ConfirmFinish')]
    procedure AC04_DisallowedResult_RefusesAndLeavesOpen()
    var
        Header: Record "Qlty. Inspection Header";
        Result: Record "Qlty. Inspection Result";
        Response: JsonObject;
    begin
        LowerPermissions.SetOutsideO365Scope();
        // [GIVEN] An open inspection whose result is configured to disallow finishing.
        // Modify(false) keeps the result. Modify(true) would clear it when the inspection has no lines.
        CreateOpenInspection(Header, '');
        CreateDisallowFinishResult(Result);
        Header."Result Code" := Result.Code;
        Header.Modify(false);
        Commit();

        // [WHEN] Finish is requested
        Response := Finish(Header."No.", 0, false);

        // [THEN] Business Central refuses and the inspection stays open
        AssertRefusal(Response, 'BusinessCentralError', Result.Code);
        Header.Get(Header."No.", 0);
        Assert.AreEqual(Header.Status::Open, Header.Status, 'status stays open');
        Assert.AreEqual(0DT, Header."Finished Date", 'no finish timestamp');
        DeleteInspection(Header."No.");
        DeleteDisallowFinishResult();
    end;

    [Test]
    procedure AC05_ReadSet_CannotRunTheType()
    begin
        LowerPermissions.SetOutsideO365Scope();
        // Story #4, AC05 | Time: none | Risk: owned inspection only
        VerifyMissingAppRole(false);
    end;

    [Test]
    procedure AC05_ApiAndNativeData_WithoutAppRole_Refuses()
    begin
        LowerPermissions.SetOutsideO365Scope();
        // Story #4, AC05 | Time: none | Risk: owned inspection only
        VerifyMissingAppRole(true);
    end;

    local procedure VerifyMissingAppRole(UseApiRole: Boolean)
    var
        Header: Record "Qlty. Inspection Header";
        TempPermission: Record "Expanded Permission" temporary;
        PermissionsMock: Codeunit "Permissions Mock";
        UserPermissions: Codeunit "User Permissions";
        Response: JsonObject;
    begin
        LowerPermissions.SetOutsideO365Scope();
        Assert.IsTrue(PermissionsMock.IsStarted(), 'The test runner must enable permission mocking.');
        CreateOpenInspection(Header, '');
        Commit();
        if UseApiRole then
            LowerPermissions.SetExactPermissionSet('BIFROST API ori')
        else
            LowerPermissions.SetExactPermissionSet('BIFROST Read ori');
        LowerPermissions.AddPermissionSet('QltyMgmt - Inspector');
        LowerPermissions.AddPermissionSet('QM Setup Test ori');
        TempPermission := UserPermissions.GetEffectivePermission(TempPermission."Object Type"::"Table Data", Database::"Qlty. Inspection Header");
        Assert.IsTrue(TempPermission."Modify Permission" = TempPermission."Modify Permission"::Yes, 'The caller must have native Modify permission for this regression.');
        Response := Finish(Header."No.", 0, false);
        LowerPermissions.SetOutsideO365Scope();
        AssertRefusal(Response, 'PermissionDenied', 'permission');
        Header.Get(Header."No.", 0);
        Assert.AreEqual(Header.Status::Open, Header.Status, 'App permission refusal must not finish the inspection.');
        Assert.AreEqual(0DT, Header."Finished Date", 'No partial finish timestamp.');
        DeleteInspection(Header."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmFinish')]
    procedure AC05_FullAndNativeData_FinishesInspection()
    var
        Header: Record "Qlty. Inspection Header";
        Response: JsonObject;
    begin
        // Story #4, AC05 | Time: native finish timestamp only | Risk: owned inspection only
        LowerPermissions.SetOutsideO365Scope();
        CreateOpenInspection(Header, '');
        Commit();
        LowerPermissions.SetExactPermissionSet('BIFROST Full ori');
        LowerPermissions.AddPermissionSet('QltyMgmt - Inspector');
        LowerPermissions.AddPermissionSet('QM Setup Test ori');
        Response := Finish(Header."No.", 0, false);
        LowerPermissions.SetOutsideO365Scope();
        AssertSuccess(Response);
        Header.Get(Header."No.", 0);
        Assert.AreEqual(Header.Status::Finished, Header.Status, 'Full app role plus native data permission must permit finishing.');
        DeleteInspection(Header."No.");
    end;

    [Test]
    procedure AC05_FullSet_ReachesTheParameterCheck()
    var
        Request: JsonObject;
        Response: JsonObject;
    begin
        LowerPermissions.SetOutsideO365Scope();
        Request.Add('reinspectionNo', 0);
        LowerPermissions.SetOutsideO365Scope();
        LowerPermissions.SetExactPermissionSet('BIFROST Full ori');
        LowerPermissions.AddPermissionSet('QM Setup Test ori');
        Response := Invoke(Request, true);
        LowerPermissions.SetOutsideO365Scope();
        AssertRefusal(Response, 'MissingParameter', 'no');
    end;

    [Test]
    procedure AC05_FullSetWithoutTablePermission_IsPermissionDenied()
    var
        Response: JsonObject;
    begin
        LowerPermissions.SetOutsideO365Scope();
        LowerPermissions.SetExactPermissionSet('BIFROST Full ori');
        LowerPermissions.AddPermissionSet('QM Setup Test ori');
        Response := Finish('XQM4NOPERM', 0, true);
        LowerPermissions.SetOutsideO365Scope();
        AssertRefusal(Response, 'PermissionDenied', 'permission');
    end;

    [Test]
    procedure AC07_ContractStatesEffectAndIdempotency()
    var
        Impl: Codeunit "Qlty Insp Finish Impl ori";
        Effect: JsonObject;
        Token: JsonToken;
        Overview: Text;
        EffectText: Text;
    begin
        LowerPermissions.SetOutsideO365Scope();
        Assert.IsTrue(Impl.GetOverview(Overview), 'overview');
        Assert.IsTrue(Overview.Contains('idempotent'), Overview);
        Assert.IsTrue(Overview.Contains('FinishInspection'), Overview);
        Assert.IsTrue(Impl.GetEffect(Effect), 'effect');
        Assert.IsTrue(Effect.Get('idempotent', Token), 'idempotent key');
        Assert.IsTrue(Token.AsValue().AsBoolean(), 'idempotent');
        Assert.IsTrue(Effect.Get('effect', Token), 'effect key');
        Assert.AreEqual('write', Token.AsValue().AsText(), 'effect');
        Assert.IsTrue(Effect.Get('permissionSet', Token), 'permissionSet');
        Assert.AreEqual('BIFROST QM Full ori', Token.AsValue().AsText(), 'permission set');
        Assert.IsTrue(Effect.Get('changes', Token), 'changes');
        EffectText := Token.AsValue().AsText();
        Assert.IsTrue(EffectText.Contains('FinishInspection'), EffectText);
        Assert.IsTrue(EffectText.Contains('Commit'), EffectText);
    end;

    [Test]
    procedure AC06_IcelandicHelp_HasTranslatedEffectAndNotes()
    var
        Impl: Codeunit "Qlty Insp Finish Impl ori";
        Effect: JsonObject;
        Overview: Text;
        Notes: Text;
        Changes: Text;
        PriorLanguage: Integer;
    begin
        // Story #4, AC06/AC07 | Time: none | Risk: no data writes
        LowerPermissions.SetOutsideO365Scope();
        PriorLanguage := GlobalLanguage();
        GlobalLanguage(1039);
        Impl.GetOverview(Overview);
        Impl.GetNotes(Notes);
        Impl.GetEffect(Effect);
        Changes := GetText(Effect, 'changes');
        GlobalLanguage(PriorLanguage);
        Assert.IsTrue(Overview.Contains('Lýkur') and Overview.Contains('ítrekunaröruggt'), 'Icelandic overview must describe the effect and idempotency.');
        Assert.IsTrue(Notes.Contains('staðfestingu') and Notes.Contains('Codeunit.Run'), 'Icelandic notes must explain confirmation and commit behavior.');
        Assert.IsTrue(Changes.Contains('vörurekjanleika'), 'The effect changes chapter must be translated.');
    end;

    [ConfirmHandler]
    procedure ConfirmFinish(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure CreateOpenInspection(var Header: Record "Qlty. Inspection Header"; ResultCode: Code[20])
    var
        Configure: Codeunit "Qlty. Auto Configure";
    begin
        Configure.EnsureBasicSetupExists(false);
        Header.Init();
        Header."No." := NewNo();
        Header."Re-inspection No." := 0;
        Header.Description := 'QM4 finish test';
        Header.Insert(true);
        if ResultCode <> '' then begin
            Header."Result Code" := ResultCode;
            Header.Modify(false);
        end;
    end;

    local procedure CreateDisallowFinishResult(var Result: Record "Qlty. Inspection Result")
    begin
        if Result.Get('XQM4NOFIN') then
            Result.Delete(true);
        Result.Init();
        Result.Code := 'XQM4NOFIN';
        Result.Description := 'QM4 finish blocked';
        Result."Finish Allowed" := Result."Finish Allowed"::"Do Not Allow Finish";
        Result.Insert(true);
    end;

    local procedure DeleteDisallowFinishResult()
    var
        Result: Record "Qlty. Inspection Result";
    begin
        if Result.Get('XQM4NOFIN') then
            Result.Delete(true);
        Commit();
    end;

    local procedure Finish(InspectionNo: Code[20]; ReinspectionNo: Integer; OmitCommit: Boolean) Response: JsonObject
    var
        Request: JsonObject;
    begin
        if InspectionNo <> '' then
            Request.Add('no', InspectionNo);
        if ReinspectionNo >= 0 then
            Request.Add('reinspectionNo', ReinspectionNo);
        Response := Invoke(Request, OmitCommit);
    end;

    local procedure Invoke(RequestJson: JsonObject; OmitCommit: Boolean) ResponseJson: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        ResponseTempBlob: Codeunit "Temp Blob";
        RequestContent: BigText;
        ResponseStream: InStream;
        MessageId: Guid;
        TaskId: Guid;
        ResponseTime: Duration;
        RequestText: Text;
        ResponseText: Text;
        ResponseContentType: Text[100];
    begin
        RequestJson.WriteTo(RequestText);
        RequestContent.AddText(RequestText);
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Quality.Inspection.Finish", Enum::"Message Version ori"::"1.0", '', 'XQM4', 'application/json', RequestContent, TaskId, GlobalLanguage(), MessageId, ResponseTempBlob, ResponseContentType, ResponseTime, OmitCommit);
        ResponseTempBlob.CreateInStream(ResponseStream, TextEncoding::UTF8);
        ResponseStream.ReadText(ResponseText);
        Assert.IsTrue(ResponseJson.ReadFrom(ResponseText), 'The dispatcher must answer with JSON: ' + ResponseText);
    end;

    local procedure DeleteInspection(InspectionNo: Code[20])
    var
        Header: Record "Qlty. Inspection Header";
    begin
        Header.SetRange("No.", InspectionNo);
        if Header.FindSet() then
            repeat
                Header.Delete(true);
            until Header.Next() = 0;
        Commit();
    end;

    local procedure CountOwnedInspections(): Integer
    var
        Header: Record "Qlty. Inspection Header";
    begin
        Header.SetFilter("No.", 'XQM4*');
        exit(Header.Count());
    end;

    local procedure NewNo(): Code[20]
    begin
        exit(CopyStr('XQM4' + CopyStr(DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, 16), 1, 20));
    end;

    local procedure AssertSuccess(ResponseJson: JsonObject)
    var
        ResponseText: Text;
    begin
        ResponseJson.WriteTo(ResponseText);
        Assert.AreEqual('Success', GetText(ResponseJson, 'status'), 'Expected Success: ' + ResponseText);
    end;

    local procedure AssertRefusal(ResponseJson: JsonObject; ExpectedCode: Text; ExpectedFragment: Text)
    var
        ResponseText: Text;
    begin
        ResponseJson.WriteTo(ResponseText);
        Assert.AreEqual('Error', GetText(ResponseJson, 'status'), 'Expected a refusal: ' + ResponseText);
        Assert.AreEqual(ExpectedCode, GetText(ResponseJson, 'code'), 'Unexpected error code: ' + ResponseText);
        Assert.IsTrue(ResponseText.Contains(ExpectedFragment), 'The refusal must contain ''' + ExpectedFragment + ''': ' + ResponseText);
    end;

    local procedure GetText(ResponseJson: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(ResponseJson.Get(PropertyName, Token), 'Missing response property: ' + PropertyName);
        exit(Token.AsValue().AsText());
    end;

    local procedure GetBoolean(ResponseJson: JsonObject; PropertyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(ResponseJson.Get(PropertyName, Token), 'Missing response property: ' + PropertyName);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure GetInteger(ResponseJson: JsonObject; PropertyName: Text): Integer
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(ResponseJson.Get(PropertyName, Token), 'Missing response property: ' + PropertyName);
        exit(Token.AsValue().AsInteger());
    end;
}
