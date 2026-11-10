namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Exercises issue 6 through the public dispatcher with self-created inspection data.</summary>
codeunit 97202 "Quality Set Value Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>ValidValue RecalculatesResult.</summary>
    [Test]
    procedure Scenario_AC03_ValidValue_RecalculatesResult()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyValue(1033);
    end;

    /// <summary>IcelandicValue RecalculatesResult.</summary>
    [Test]
    procedure Scenario_AC06_IcelandicValue_RecalculatesResult()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyValue(1039);
    end;

    /// <summary>MissingKey RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC02_MissingKey_RefusesWithoutWrite()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyRefusal('missing', 1033);
    end;

    /// <summary>UnknownKey RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC02_UnknownKey_RefusesWithoutWrite()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyRefusal('unknown', 1033);
    end;

    /// <summary>NonTextValue RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC02_NonTextValue_RefusesWithoutWrite()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyRefusal('number', 1033);
    end;

    /// <summary>LongValue RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC02_LongValue_RefusesWithoutWrite()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyRefusal('longValue', 1033);
    end;

    /// <summary>LongCode RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC02_LongCode_RefusesWithoutWrite()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyRefusal('longCode', 1033);
    end;

    /// <summary>InvalidGuid RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC02_InvalidGuid_RefusesWithoutWrite()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyRefusal('guid', 1033);
    end;

    /// <summary>Finished RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC04_Finished_RefusesWithoutWrite()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyRefusal('finished', 1033);
    end;

    /// <summary>UnknownTest RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC04_UnknownTest_RefusesWithoutWrite()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyRefusal('test', 1033);
    end;

    /// <summary>DuplicateTest RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC04_DuplicateTest_RefusesWithoutWrite()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyRefusal('duplicate', 1033);
    end;

    /// <summary>InvalidValue RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC04_InvalidValue_RefusesWithoutWrite()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyRefusal('invalid', 1033);
    end;

    /// <summary>MissingTemplate RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC04_MissingTemplate_RefusesWithoutWrite()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyRefusal('template', 1033);
    end;

    /// <summary>LateFailure RollsBackAllWrites.</summary>
    [Test]
    procedure Scenario_AC04_LateFailure_RollsBackAllWrites()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyRefusal('late', 1033);
    end;

    /// <summary>IcelandicRefusal IsTranslated.</summary>
    [Test]
    procedure Scenario_AC06_IcelandicRefusal_IsTranslated()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyRefusal('missing', 1039);
    end;

    /// <summary>ReadRole RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC05_ReadRole_RefusesWithoutWrite()
    begin
        // Story #6, AC02–AC08 | Time: no date-dependent inputs; WorkDate ignored | Risk: owned fixture only
        VerifyRefusal('permission', 1033);
    end;

    /// <summary>Checks discovery and the published write contract through Foundation's public API.</summary>
    [Test]
    procedure Scenario_AC01_RegisteredType_HasWriteContract()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        EffectToken: JsonToken;
        IdempotentToken: JsonToken;
        Effect: JsonObject;
    begin
        // Story #6, AC01/AC07 | Time: independent of Today and WorkDate | Risk: None
        // [GIVEN] The app's enum extension is installed.
        Initialize();
        // [WHEN] Foundation resolves the public contract.
        Assert.IsTrue(ContractMgt.GetContract(Enum::"Message Type ori"::"Quality.Inspection.SetTestValue", Contract), 'The registered type must expose its contract.');
        // [THEN] The contract reports its effect and conservative idempotency.
        Assert.IsTrue(Contract.Get('effect', EffectToken), 'The effect chapter is required.');
        Effect := EffectToken.AsObject();
        Assert.AreEqual('write', ReadText(Effect, 'effect'), 'Expected write effect.');
        Assert.IsTrue(Effect.Get('idempotent', IdempotentToken), 'Idempotency must be declared.');
        Assert.IsFalse(IdempotentToken.AsValue().AsBoolean(), 'Subscriber effects prevent an idempotency guarantee.');
        Assert.AreEqual('BIFROST QM Full ori', ReadText(Effect, 'permissionSet'), 'The write role must be documented.');
        Assert.IsTrue(Contract.Contains('overview'), 'The help chapter must exist.');
    end;

    /// <summary>Verifies that a GUID selects the exact re-inspection and preserves the original.</summary>
    [Test]
    procedure Scenario_AC02_Reinspection_ChangesOnlySelectedRecord()
    var
        Inspection: Record "Qlty. Inspection Header";
        Reinspection: Record "Qlty. Inspection Header";
        InspectionLine: Record "Qlty. Inspection Line";
        ReinspectionLine: Record "Qlty. Inspection Line";
        Response: JsonObject;
    begin
        // Story #6, AC02/AC03 | Time: independent of Today and WorkDate | Risk: owned fixture only
        // [GIVEN] Two inspections with the same number and different re-inspection counters.
        Initialize();
        CreateFixture(Inspection, InspectionLine);
        Reinspection := Inspection;
        Reinspection."Re-inspection No." := 1;
        Clear(Reinspection.SystemId);
        Reinspection.Insert(false);
        ReinspectionLine := InspectionLine;
        ReinspectionLine."Re-inspection No." := 1;
        Clear(ReinspectionLine.SystemId);
        ReinspectionLine.Insert(false);
        Commit();
        // [WHEN] The request names the re-inspection SystemId.
        Response := Dispatch(MakeRequest(Reinspection, ReinspectionLine), 1033);
        // [THEN] Only the selected re-inspection changes.
        if ReadText(Response, 'status') <> 'Success' then
            Assert.Fail(ReadText(Response, 'error'));
        InspectionLine.Get(Inspection."No.", 0, 10000);
        ReinspectionLine.Get(Inspection."No.", 1, 10000);
        Assert.AreEqual('1', InspectionLine."Test Value", 'Original inspection must remain unchanged.');
        Assert.AreEqual('20', ReinspectionLine."Test Value", 'The selected re-inspection must change.');
        Cleanup(Inspection, InspectionLine);
    end;

    /// <summary>Rejects a caller with native write permissions but no app execution grant.</summary>
    [Test]
    procedure Scenario_AC05_NoAppGrant_RefusesWithoutWrite()
    begin
        // Story #6, AC05 | Time: independent of Today and WorkDate | Risk: owned fixture only
        VerifyRefusal('permissionNoApp', 1033);
    end;

    /// <summary>Rejects an unknown inspection SystemId.</summary>
    [Test]
    procedure Scenario_AC02_UnknownInspection_RefusesWithoutWrite()
    begin
        // Story #6, AC02 | Time: independent of Today and WorkDate | Risk: owned fixture only
        VerifyRefusal('notFound', 1033);
    end;

    local procedure VerifyValue(LanguageId: Integer)
    var
        Inspection: Record "Qlty. Inspection Header";
        InspectionLine: Record "Qlty. Inspection Line";
        Request: JsonObject;
        Response: JsonObject;
    begin
        // [GIVEN] An open inspection with an integer test and an owned passing condition.
        Initialize();
        CreateFixture(Inspection, InspectionLine);
        Request := MakeRequest(Inspection, InspectionLine);
        Commit();
        // [WHEN] The public dispatcher invokes the Microsoft test validation.
        LowerPermissions.SetExactPermissionSet('D365 BASIC');
        LowerPermissions.AddPermissionSet('BIFROST Full ori');
        LowerPermissions.AddPermissionSet('QM Message Test ori');
        Response := Dispatch(Request, LanguageId);
        LowerPermissions.SetOutsideO365Scope();
        // [THEN] The line value and both result codes are recalculated and persisted.
        if ReadText(Response, 'status') <> 'Success' then
            Assert.Fail(ReadText(Response, 'error'));
        InspectionLine.Get(InspectionLine."Inspection No.", 0, 10000);
        Inspection.GetBySystemId(Inspection.SystemId);
        Assert.AreEqual('20', InspectionLine."Test Value", 'Native validation must persist the value.');
        Assert.AreEqual(InspectionLine."Test Code", InspectionLine."Result Code", 'Owned result condition must be evaluated.');
        Assert.AreEqual(InspectionLine."Result Code", Inspection."Result Code", 'Header result must match the evaluated line.');
        Assert.AreEqual(Inspection."Result Code", ReadText(Response, 'resultCode'), 'Response must match persisted result.');
        Cleanup(Inspection, InspectionLine);
    end;

    local procedure VerifyRefusal(Scenario: Text; LanguageId: Integer)
    var
        Inspection: Record "Qlty. Inspection Header";
        InspectionLine: Record "Qlty. Inspection Line";
        DuplicateLine: Record "Qlty. Inspection Line";
        InspectionTemplateLine: Record "Qlty. Inspection Template Line";
        Fault: Codeunit "Quality Value Fault ori";
        Request: JsonObject;
        Response: JsonObject;
        OriginalStatus: Enum "Qlty. Inspection Status";
    begin
        // [GIVEN] Self-created data and one deliberately invalid input or business state.
        Initialize();
        CreateFixture(Inspection, InspectionLine);
        Request := MakeRequest(Inspection, InspectionLine);
        case Scenario of
            'missing': Request.Remove('value');
            'unknown': Request.Add('unexpected', true);
            'number': Request.Replace('value', 20);
            'longValue': Request.Replace('value', PadStr('x', 251, 'x'));
            'longCode': Request.Replace('testCode', PadStr('x', 21, 'x'));
            'guid': Request.Replace('inspectionSystemId', 'invalid');
            'notFound': Request.Replace('inspectionSystemId', Format(CreateGuid(), 0, 4));
            'finished': begin
                Inspection.Status := Inspection.Status::Finished;
                Inspection.Modify(false);
            end;
            'test': Request.Replace('testCode', 'UNKNOWN');
            'duplicate': begin
                DuplicateLine := InspectionLine;
                DuplicateLine."Line No." := 20000;
                DuplicateLine.Insert(false);
            end;
            'invalid': Request.Replace('value', 'not an integer');
            'template': begin
                InspectionTemplateLine.Get(InspectionLine."Template Code", 10000);
                InspectionTemplateLine.Delete(false);
            end;
        end;
        OriginalStatus := Inspection.Status;
        Commit();
        if Scenario = 'permission' then begin
            LowerPermissions.SetExactPermissionSet('BIFROST Read ori');
            LowerPermissions.AddPermissionSet('QM Message Test ori');
        end;
        if Scenario = 'permissionNoApp' then begin
            LowerPermissions.SetExactPermissionSet('BIFROST API ori');
            LowerPermissions.AddPermissionSet('QltyMgmt - Inspector');
            LowerPermissions.AddPermissionSet('QM Message Test ori');
        end;
        if Scenario = 'late' then
            BindSubscription(Fault);
        // [WHEN] The complete public pipeline processes the refusal.
        Response := Dispatch(Request, LanguageId);
        if Scenario = 'late' then
            UnbindSubscription(Fault);
        LowerPermissions.SetOutsideO365Scope();
        // [THEN] A structured refusal is returned and neither header nor line changed.
        Assert.AreEqual('Error', ReadText(Response, 'status'), 'The dispatcher must return a refusal.');
        case Scenario of
            'missing', 'number': Assert.IsTrue(ReadText(Response, 'error').Contains('value'), 'The refusal must identify the value input.');
            'unknown': Assert.AreEqual('UnknownParameter', ReadText(Response, 'code'), 'Foundation must reject unknown keys.');
            'longValue', 'longCode': Assert.IsTrue(ReadText(Response, 'error').Contains('exceeds'), 'The length guard must refuse truncation.');
            'guid': Assert.IsTrue(ReadText(Response, 'error').Contains('inspectionSystemId'), 'The identifier error must name the key.');
            'finished': Assert.IsTrue(ReadText(Response, 'error').Contains('Status'), 'Microsoft must reject the finished status.');
            'test', 'duplicate': Assert.IsTrue(ReadText(Response, 'error').Contains('matching inspection line'), 'Microsoft must reject the test selection.');
            'invalid': Assert.IsTrue(ReadText(Response, 'error').Contains('not allowed'), 'Microsoft must reject the invalid integer.');
            'template': Assert.IsTrue(ReadText(Response, 'error').Contains('does not exist'), 'Microsoft must reject missing setup.');
            'late': Assert.IsTrue(ReadText(Response, 'error').Contains('Injected late'), 'The failure must occur after the native line write.');
            'permission', 'permissionNoApp': Assert.IsTrue(LowerCase(ReadText(Response, 'error')).Contains('permission'), 'The call must be refused for missing permissions.');
            'notFound': Assert.IsTrue(ReadText(Response, 'error').Contains('inspection was not found'), 'The missing inspection must be identified.');
        end;
        if Scenario in ['permission', 'permissionNoApp', 'finished'] then begin
            if Scenario = 'finished' then
                Assert.AreEqual('PreconditionFailed', ReadText(Response, 'code'), 'Typed status refusal')
            else
                Assert.AreEqual('PermissionDenied', ReadText(Response, 'code'), 'Typed access refusal');
            Assert.IsTrue(ReadText(Response, 'expected') <> '', 'Actionable expected state or permission');
            Assert.IsTrue(ReadText(Response, 'nextStep') <> '', 'Actionable next step');
        end;
        if (Scenario = 'missing') and (LanguageId = 1039) then
            Assert.IsTrue(ReadText(Response, 'error').Contains('Nauðsynlega'), 'The refusal must be translated.');
        InspectionLine.Get(InspectionLine."Inspection No.", 0, 10000);
        Inspection.GetBySystemId(Inspection.SystemId);
        Assert.AreEqual('1', InspectionLine."Test Value", 'Refusal must preserve the previous value.');
        Assert.AreEqual('', InspectionLine."Result Code", 'Refusal must preserve the previous line result.');
        Assert.AreEqual('', Inspection."Result Code", 'Refusal must preserve the previous header result.');
        Assert.AreEqual(OriginalStatus, Inspection.Status, 'Refusal must preserve status.');
        Cleanup(Inspection, InspectionLine);
    end;

    local procedure Initialize()
    begin
        LowerPermissions.SetOutsideO365Scope();
    end;

    local procedure CreateFixture(var Inspection: Record "Qlty. Inspection Header"; var InspectionLine: Record "Qlty. Inspection Line")
    var
        FixtureCode: Code[20];
    begin
        FixtureCode := CopyStr('BIFTQ6-' + DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 20);
        SeedFixture(FixtureCode, Inspection, InspectionLine);
    end;

    /// <summary>Creates only a uniquely named owned fixture for native, MCP and UI acceptance tests.</summary>
    procedure SeedFixture(FixtureCode: Code[20]; var Inspection: Record "Qlty. Inspection Header"; var InspectionLine: Record "Qlty. Inspection Line")
    var
        QualityTest: Record "Qlty. Test";
        InspectionTemplateHeader: Record "Qlty. Inspection Template Hdr.";
        InspectionTemplateLine: Record "Qlty. Inspection Template Line";
        InspectionResult: Record "Qlty. Inspection Result";
        ResultCondition: Record "Qlty. I. Result Condit. Conf.";
    begin
        if CopyStr(FixtureCode, 1, 7) <> 'BIFTQ6-' then
            Error('Only BIFTQ6- owned fixtures are permitted.');
        QualityTest.Code := FixtureCode;
        QualityTest."Test Value Type" := QualityTest."Test Value Type"::"Value Type Integer";
        QualityTest.Insert(false);
        InspectionTemplateHeader.Code := FixtureCode;
        InspectionTemplateHeader.Insert(false);
        InspectionTemplateLine."Template Code" := FixtureCode;
        InspectionTemplateLine."Line No." := 10000;
        InspectionTemplateLine."Test Code" := FixtureCode;
        InspectionTemplateLine.Insert(false);
        InspectionResult.Code := FixtureCode;
        InspectionResult.Insert(false);
        Inspection."No." := FixtureCode;
        Inspection."Template Code" := FixtureCode;
        Inspection."Assigned User ID" := CopyStr(UserId(), 1, MaxStrLen(Inspection."Assigned User ID"));
        Inspection.Insert(false);
        InspectionLine."Inspection No." := FixtureCode;
        InspectionLine."Line No." := 10000;
        InspectionLine."Template Code" := FixtureCode;
        InspectionLine."Template Line No." := 10000;
        InspectionLine."Test Code" := FixtureCode;
        InspectionLine."Test Value" := '1';
        InspectionLine.Insert(false);
        ResultCondition."Condition Type" := ResultCondition."Condition Type"::Inspection;
        ResultCondition."Target Code" := FixtureCode;
        ResultCondition."Target Line No." := 10000;
        ResultCondition."Test Code" := FixtureCode;
        ResultCondition."Result Code" := FixtureCode;
        ResultCondition.Condition := '10..100';
        ResultCondition.Insert(false);
    end;

    local procedure MakeRequest(Inspection: Record "Qlty. Inspection Header"; InspectionLine: Record "Qlty. Inspection Line") Request: JsonObject
    begin
        Request.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Request.Add('testCode', InspectionLine."Test Code");
        Request.Add('value', '20');
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
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Quality.Inspection.SetTestValue", Enum::"Message Version ori"::"1.0", '', 'quality6-tests', 'application/json', RequestContent, TaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
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

    /// <summary>Deletes only the owned BIFTQ6- inspection and its fixture setup.</summary>
    procedure Cleanup(Inspection: Record "Qlty. Inspection Header"; InspectionLine: Record "Qlty. Inspection Line")
    var
        QualityTest: Record "Qlty. Test";
        InspectionTemplateHeader: Record "Qlty. Inspection Template Hdr.";
        InspectionTemplateLine: Record "Qlty. Inspection Template Line";
        InspectionResult: Record "Qlty. Inspection Result";
        ResultCondition: Record "Qlty. I. Result Condit. Conf.";
    begin
        if CopyStr(Inspection."No.", 1, 7) <> 'BIFTQ6-' then
            Error('Only BIFTQ6- owned fixtures can be deleted.');
        ResultCondition.SetRange("Target Code", Inspection."No.");
        ResultCondition.DeleteAll(false);
        InspectionLine.SetRange("Inspection No.", Inspection."No.");
        InspectionLine.DeleteAll(false);
        Inspection.SetRange("No.", Inspection."No.");
        Inspection.DeleteAll(false);
        InspectionTemplateLine.SetRange("Template Code", Inspection."No.");
        InspectionTemplateLine.DeleteAll(false);
        InspectionTemplateHeader.Get(Inspection."No.");
        InspectionTemplateHeader.Delete(false);
        QualityTest.Get(Inspection."No.");
        QualityTest.Delete(false);
        InspectionResult.Get(Inspection."No.");
        InspectionResult.Delete(false);
    end;
}
