namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>Issue 18: copies an inspection template with its lines through the public Foundation dispatcher.</summary>
codeunit 97284 "Quality Template Copy Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>A three-line template is copied line for line with its conditions; the source is unchanged.</summary>
    [Test]
    procedure Scenario_AC02_Copy_CreatesTargetWithAllLines()
    var
        TargetTemplate: Record "Qlty. Inspection Template Hdr.";
        SourceLine: Record "Qlty. Inspection Template Line";
        TargetLine: Record "Qlty. Inspection Template Line";
        Response: JsonObject;
        Result: JsonToken;
        SourceCode: Code[20];
        TargetCode: Code[20];
    begin
        // Story #18, AC02 | Time: no date-dependent inputs | Risk: owned fixture deleted before asserts
        Initialize(SourceCode, TargetCode);
        Response := Invoke(CopyRequest(SourceCode, TargetCode, 'Copied template', 1));
        TargetTemplate.Get(TargetCode);
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
        Response.GetArray('result').Get(0, Result);
        Assert.AreEqual(TargetCode, Result.AsObject().GetText('templateCode'), Serialize(Response));
        Assert.AreEqual(3, Result.AsObject().GetInteger('linesCopied'), Serialize(Response));
        Assert.AreEqual(SourceCode, Result.AsObject().GetText('copiedFromTemplateCode'), Serialize(Response));
        Assert.AreEqual('Copied template', TargetTemplate.Description, 'The target description must be applied.');
        Assert.AreEqual(SourceCode, TargetTemplate."Copied From Template Code", 'The header must point at the source.');
        Assert.AreEqual(25, TargetTemplate."Sample Percentage", 'The header settings must be copied.');
        SourceLine.SetRange("Template Code", SourceCode);
        Assert.AreEqual(3, SourceLine.Count(), 'The source lines must be unchanged.');
        SourceLine.FindSet();
        repeat
            Assert.IsTrue(TargetLine.Get(TargetCode, SourceLine."Line No."), 'Every source line must be copied with its line number.');
            Assert.AreEqual(SourceLine."Test Code", TargetLine."Test Code", 'The test must be copied.');
            Assert.AreEqual(SourceLine.Description, TargetLine.Description, 'The description must be copied.');
            Assert.AreEqual(SourceLine."Allowable Values", TargetLine."Allowable Values", 'The allowable values must be copied.');
            Assert.AreEqual(SourceCode, TargetLine."Copied From Template Code", 'The line must point at the source.');
            Assert.AreEqual('', SourceLine."Copied From Template Code", 'The source line must be unchanged.');
            Assert.AreEqual(ConditionText(SourceCode, SourceLine."Line No."), ConditionText(TargetCode, SourceLine."Line No."), 'The result conditions must be copied.');
        until SourceLine.Next() = 0;
        Cleanup(SourceCode, TargetCode);
    end;

    /// <summary>Without targetDescription the source description is used.</summary>
    [Test]
    procedure Scenario_AC02_NoDescription_UsesSourceDescription()
    var
        TargetTemplate: Record "Qlty. Inspection Template Hdr.";
        Response: JsonObject;
        SourceCode: Code[20];
        TargetCode: Code[20];
    begin
        // Story #18, AC02 | Time: no date-dependent inputs | Risk: owned fixture deleted before asserts
        Initialize(SourceCode, TargetCode);
        Response := Invoke(CopyRequest(SourceCode, TargetCode, '', 1));
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
        TargetTemplate.Get(TargetCode);
        Cleanup(SourceCode, TargetCode);
        Assert.AreEqual('Issue 18 source', TargetTemplate.Description, 'The source description is the default.');
    end;

    /// <summary>An existing target is refused and keeps its own lines.</summary>
    [Test]
    procedure Scenario_AC03_TargetExists_RefusedWithoutMerge()
    var
        TargetTemplate: Record "Qlty. Inspection Template Hdr.";
        TargetLine: Record "Qlty. Inspection Template Line";
        Response: JsonObject;
        SourceCode: Code[20];
        TargetCode: Code[20];
    begin
        // Story #18, AC03 | Time: no date-dependent inputs | Risk: owned fixture deleted before asserts
        Initialize(SourceCode, TargetCode);
        TargetTemplate.Code := TargetCode;
        TargetTemplate.Description := 'Existing target';
        TargetTemplate.Insert(false);
        Commit();
        Response := Invoke(CopyRequest(SourceCode, TargetCode, '', 1));
        TargetLine.SetRange("Template Code", TargetCode);
        Assert.AreEqual(0, TargetLine.Count(), 'An existing target must not receive lines.');
        Cleanup(SourceCode, TargetCode);
        AssertRefusal(Response, 'PreconditionFailed', 'targetTemplateCode');
    end;

    /// <summary>An unknown source is a RecordNotFound refusal.</summary>
    [Test]
    procedure Scenario_AC03_UnknownSource_RecordNotFound()
    var
        SourceCode: Code[20];
        TargetCode: Code[20];
    begin
        // Story #18, AC03 | Time: no date-dependent inputs | Risk: none
        NewCodes(SourceCode, TargetCode);
        AssertNoChange(CopyRequest(SourceCode, TargetCode, '', 1), TargetCode, 'RecordNotFound', 'sourceTemplateCode');
    end;

    /// <summary>Missing source or target is refused before any change.</summary>
    [Test]
    procedure Scenario_AC03_MissingCodes_Refused()
    var
        SourceCode: Code[20];
        TargetCode: Code[20];
    begin
        // Story #18, AC03 | Time: no date-dependent inputs | Risk: owned fixture deleted before asserts
        Initialize(SourceCode, TargetCode);
        AssertNoChange('{"targetTemplateCode":"' + TargetCode + '","expectedCount":1}', TargetCode, 'MissingParameter', 'sourceTemplateCode');
        AssertNoChange('{"sourceTemplateCode":"' + SourceCode + '","expectedCount":1}', TargetCode, 'MissingParameter', 'targetTemplateCode');
        AssertNoChange('{"sourceTemplateCode":"' + SourceCode + '","targetTemplateCode":"","expectedCount":1}', TargetCode, 'MissingParameter', 'targetTemplateCode');
        Cleanup(SourceCode, TargetCode);
    end;

    /// <summary>Too long codes and descriptions, unknown keys, non-text values and source equal to target are refused.</summary>
    [Test]
    procedure Scenario_AC03_InvalidInput_Refused()
    var
        SourceCode: Code[20];
        TargetCode: Code[20];
    begin
        // Story #18, AC03 | Time: no date-dependent inputs | Risk: owned fixture deleted before asserts
        Initialize(SourceCode, TargetCode);
        AssertNoChange(CopyRequest(SourceCode, PadStr(TargetCode, 21, 'X'), '', 1), TargetCode, 'InvalidParameter', 'targetTemplateCode');
        AssertNoChange(CopyRequest(PadStr(SourceCode, 21, 'X'), TargetCode, '', 1), TargetCode, 'InvalidParameter', 'sourceTemplateCode');
        AssertNoChange(CopyRequest(SourceCode, TargetCode, PadStr('', 101, 'd'), 1), TargetCode, 'InvalidParameter', 'targetDescription');
        AssertNoChange(CopyRequest(SourceCode, SourceCode, '', 1), TargetCode, 'InvalidParameter', 'targetTemplateCode');
        AssertNoChange('{"sourceTemplateCode":"' + SourceCode + '","targetTemplateCode":"' + TargetCode + '","overwrite":true,"expectedCount":1}', TargetCode, 'UnknownParameter', 'overwrite');
        AssertNoChange('{"sourceTemplateCode":"' + SourceCode + '","targetTemplateCode":5,"expectedCount":1}', TargetCode, 'InvalidParameter', 'targetTemplateCode');
        Cleanup(SourceCode, TargetCode);
    end;

    /// <summary>A source without description needs targetDescription.</summary>
    [Test]
    procedure Scenario_AC03_SourceWithoutDescription_NeedsTargetDescription()
    var
        SourceTemplate: Record "Qlty. Inspection Template Hdr.";
        SourceCode: Code[20];
        TargetCode: Code[20];
    begin
        // Story #18, AC03 edge | Time: no date-dependent inputs | Risk: owned fixture deleted before asserts
        Initialize(SourceCode, TargetCode);
        SourceTemplate.Get(SourceCode);
        SourceTemplate.Description := '';
        SourceTemplate.Modify(false);
        Commit();
        AssertNoChange(CopyRequest(SourceCode, TargetCode, '', 1), TargetCode, 'MissingParameter', 'targetDescription');
        Cleanup(SourceCode, TargetCode);
    end;

    /// <summary>The refusal is translated in Icelandic.</summary>
    [Test]
    procedure Scenario_AC06_UnknownSource_RefusedInIcelandic()
    var
        Response: JsonObject;
        SourceCode: Code[20];
        TargetCode: Code[20];
    begin
        // Story #18, AC06 | Time: no date-dependent inputs | Risk: none
        NewCodes(SourceCode, TargetCode);
        Response := InvokeInLanguage(CopyRequest(SourceCode, TargetCode, '', 1), 1039);
        AssertRefusal(Response, 'RecordNotFound', 'sourceTemplateCode');
        Assert.IsTrue(Serialize(Response).Contains('Engu var breytt'), Serialize(Response));
    end;

    /// <summary>An expectedCount other than 1 is refused before any change.</summary>
    [Test]
    procedure Scenario_AC04_WrongExpectedCount_Refused()
    var
        SourceCode: Code[20];
        TargetCode: Code[20];
    begin
        // Story #18, AC04 | Time: no date-dependent inputs | Risk: owned fixture deleted before asserts
        Initialize(SourceCode, TargetCode);
        AssertNoChange(CopyRequest(SourceCode, TargetCode, '', 2), TargetCode, 'ConfirmationMismatch', 'expectedCount');
        AssertNoChange(CopyRequest(SourceCode, TargetCode, '', 0), TargetCode, 'ConfirmationMismatch', 'expectedCount');
        Cleanup(SourceCode, TargetCode);
    end;

    /// <summary>With required confirmation enabled, omitting expectedCount previews 1 and changes nothing.</summary>
    [Test]
    procedure Scenario_AC04_RequiredConfirmation_PreviewsCount()
    var
        Response: JsonObject;
        SourceCode: Code[20];
        TargetCode: Code[20];
        Previous: Boolean;
    begin
        // Story #18, AC04 | Time: no date-dependent inputs | Risk: setting restored, owned fixture deleted
        Initialize(SourceCode, TargetCode);
        Previous := SetRequireConfirm(true);
        Response := Invoke(CopyRequest(SourceCode, TargetCode, '', -1));
        SetRequireConfirm(Previous);
        AssertRefusal(Response, 'ConfirmationRequired', 'expectedCount');
        Assert.IsTrue(Serialize(Response).Contains('"expected":"1"'), Serialize(Response));
        AssertTargetAbsent(TargetCode);
        Cleanup(SourceCode, TargetCode);
    end;

    /// <summary>With required confirmation disabled, a call without expectedCount copies.</summary>
    [Test]
    procedure Scenario_AC04_ConfirmationOff_CopiesWithoutCount()
    var
        TargetLine: Record "Qlty. Inspection Template Line";
        Response: JsonObject;
        SourceCode: Code[20];
        TargetCode: Code[20];
        Previous: Boolean;
    begin
        // Story #18, AC04 | Time: no date-dependent inputs | Risk: setting restored, owned fixture deleted
        Initialize(SourceCode, TargetCode);
        Previous := SetRequireConfirm(false);
        Response := Invoke(CopyRequest(SourceCode, TargetCode, '', -1));
        SetRequireConfirm(Previous);
        TargetLine.SetRange("Template Code", TargetCode);
        Assert.AreEqual(3, TargetLine.Count(), Serialize(Response));
        Cleanup(SourceCode, TargetCode);
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
    end;

    /// <summary>The enum value ordinal is the published contract.</summary>
    [Test]
    procedure Scenario_AC01_OrdinalPinned()
    begin
        // Story #18, AC01 | Time: no date-dependent inputs | Risk: none
        Assert.AreEqual(10035316, Enum::"Message Type ori"::"Quality.Template.Copy".AsInteger(), 'The ordinal of Quality.Template.Copy must not change.');
    end;

    /// <summary>Discovery lists the type as a write with complete chapters in both languages.</summary>
    [Test]
    procedure Scenario_AC01_Contract_IsWriteInBothLanguages()
    var
        Contract: Interface "Msg Contract ori";
        Discovery: Interface "Msg Interface ori";
        Effect: JsonObject;
        Parameters: JsonArray;
        Errors: JsonArray;
        Overview: Text;
        Notes: Text;
        PreviousLanguage: Integer;
    begin
        // Story #18, AC01/AC06 | Time: no date-dependent inputs | Risk: session language restored
        Contract := Enum::"Message Type ori"::"Quality.Template.Copy";
        Discovery := Enum::"Message Type ori"::"Quality.Template.Copy";
        Assert.IsTrue(Contract.GetEffect(Effect), 'The effect chapter must exist.');
        Assert.AreEqual('write', Effect.GetText('effect'), 'The effect must be a write.');
        Assert.IsFalse(Effect.GetBoolean('idempotent'), 'A second copy is refused, so the type is not idempotent.');
        Assert.AreEqual('BIFROST QM Full ori', Effect.GetText('permissionSet'), 'The contract must name the app permission set.');
        Assert.IsTrue(Contract.GetParameters(Parameters), 'The parameter chapter must exist.');
        Assert.AreEqual(4, Parameters.Count(), 'Four parameters are declared.');
        Assert.IsTrue(Contract.GetErrors(Errors), 'The error chapter must exist.');
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        Assert.IsTrue(Contract.GetOverview(Overview), 'The overview must exist.');
        Assert.IsTrue(Contract.GetNotes(Notes), 'The notes must exist.');
        Assert.IsTrue(Notes.Contains('Not idempotent'), Notes);
        Assert.IsTrue(Discovery.GetDescription().Contains('Copies'), 'English description.');
        GlobalLanguage(1039);
        Contract.GetOverview(Overview);
        Contract.GetNotes(Notes);
        Assert.IsTrue(Overview.Contains('Afritar'), Overview);
        Assert.IsTrue(Notes.Contains('Ekki ídempotent'), Notes);
        Assert.IsTrue(Discovery.GetDescription().Contains('Afritar'), 'Icelandic description.');
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure AssertNoChange(RequestText: Text; TargetCode: Code[20]; ExpectedCode: Text; ExpectedParameter: Text)
    begin
        AssertRefusal(Invoke(RequestText), ExpectedCode, ExpectedParameter);
        AssertTargetAbsent(TargetCode);
    end;

    local procedure AssertTargetAbsent(TargetCode: Code[20])
    var
        TargetTemplate: Record "Qlty. Inspection Template Hdr.";
        TargetLine: Record "Qlty. Inspection Template Line";
    begin
        TargetTemplate.SetRange(Code, TargetCode);
        Assert.RecordIsEmpty(TargetTemplate);
        TargetLine.SetRange("Template Code", TargetCode);
        Assert.RecordIsEmpty(TargetLine);
    end;

    local procedure AssertRefusal(Response: JsonObject; ExpectedCode: Text; ExpectedParameter: Text)
    begin
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual(ExpectedCode, Response.GetText('code'), Serialize(Response));
        Assert.IsTrue(Serialize(Response).Contains('"parameter":"' + ExpectedParameter + '"'), Serialize(Response));
        Assert.IsTrue(Response.Contains('nextStep') or Serialize(Response).Contains('"nextStep"'), Serialize(Response));
    end;

    local procedure NewCodes(var SourceCode: Code[20]; var TargetCode: Code[20])
    var
        Suffix: Text;
    begin
        Suffix := CopyStr(DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 12);
        SourceCode := CopyStr('Q18S' + Suffix, 1, 20);
        TargetCode := CopyStr('Q18T' + Suffix, 1, 20);
    end;

    local procedure Initialize(var SourceCode: Code[20]; var TargetCode: Code[20])
    var
        BifrostSetup: Record "Setup ori";
        SourceTemplate: Record "Qlty. Inspection Template Hdr.";
        LineNo: Integer;
    begin
        BifrostSetup.InsertIfNotExists();
        NewCodes(SourceCode, TargetCode);
        SourceTemplate.Code := SourceCode;
        SourceTemplate.Description := 'Issue 18 source';
        SourceTemplate."Sample Percentage" := 25;
        SourceTemplate.Insert(false);
        for LineNo := 1 to 3 do
            AddLine(SourceCode, LineNo);
        Commit();
    end;

    local procedure AddLine(TemplateCode: Code[20]; Index: Integer)
    var
        InspTemplateLine: Record "Qlty. Inspection Template Line";
        Condition: Record "Qlty. I. Result Condit. Conf.";
    begin
        InspTemplateLine."Template Code" := TemplateCode;
        InspTemplateLine."Line No." := Index * 10000;
        InspTemplateLine."Test Code" := CopyStr('Q18TEST' + Format(Index, 0, 9), 1, 20);
        InspTemplateLine.Description := CopyStr('Issue 18 test ' + Format(Index, 0, 9), 1, 100);
        InspTemplateLine."Allowable Values" := CopyStr('0..' + Format(Index * 10, 0, 9), 1, 500);
        InspTemplateLine.Insert(false);
        Condition."Condition Type" := Condition."Condition Type"::Template;
        Condition."Target Code" := TemplateCode;
        Condition."Target Line No." := InspTemplateLine."Line No.";
        Condition."Test Code" := InspTemplateLine."Test Code";
        Condition."Result Code" := 'PASS';
        Condition.Condition := CopyStr('<=' + Format(Index * 5, 0, 9), 1, 500);
        Condition.Insert(false);
        Condition."Result Code" := 'FAIL';
        Condition.Condition := CopyStr('>' + Format(Index * 5, 0, 9), 1, 500);
        Condition.Insert(false);
    end;

    local procedure ConditionText(TemplateCode: Code[20]; LineNo: Integer) Result: Text
    var
        Condition: Record "Qlty. I. Result Condit. Conf.";
    begin
        Condition.SetRange("Condition Type", Condition."Condition Type"::Template);
        Condition.SetRange("Target Code", TemplateCode);
        Condition.SetRange("Target Line No.", LineNo);
        if Condition.FindSet() then
            repeat
                Result += Condition."Test Code" + ':' + Condition."Result Code" + '=' + Condition.Condition + ';';
            until Condition.Next() = 0;
        Assert.AreNotEqual('', Result, 'Each line must have result conditions.');
    end;

    local procedure Cleanup(SourceCode: Code[20]; TargetCode: Code[20])
    var
        InspTemplate: Record "Qlty. Inspection Template Hdr.";
        InspTemplateLine: Record "Qlty. Inspection Template Line";
        Condition: Record "Qlty. I. Result Condit. Conf.";
    begin
        Condition.SetRange("Condition Type", Condition."Condition Type"::Template);
        Condition.SetFilter("Target Code", '%1|%2', SourceCode, TargetCode);
        Condition.DeleteAll(false);
        InspTemplateLine.SetFilter("Template Code", '%1|%2', SourceCode, TargetCode);
        InspTemplateLine.DeleteAll(false);
        InspTemplate.SetFilter(Code, '%1|%2', SourceCode, TargetCode);
        InspTemplate.DeleteAll(false);
        Commit();
    end;

    /// <summary>Sets Foundation's internal Require Confirmation for Irreversible Messages field (36) by number.</summary>
    local procedure SetRequireConfirm(NewValue: Boolean) Previous: Boolean
    var
        BifrostSetup: Record "Setup ori";
        SetupRef: RecordRef;
        RequireField: FieldRef;
    begin
        BifrostSetup.InsertIfNotExists();
        SetupRef.Open(Database::"Setup ori");
        SetupRef.FindFirst();
        RequireField := SetupRef.Field(36);
        Previous := RequireField.Value();
        RequireField.Value(NewValue);
        SetupRef.Modify(false);
        Commit();
    end;

    local procedure CopyRequest(SourceCode: Text; TargetCode: Text; TargetDescription: Text; ExpectedCount: Integer): Text
    var
        Request: JsonObject;
    begin
        Request.Add('sourceTemplateCode', SourceCode);
        Request.Add('targetTemplateCode', TargetCode);
        if TargetDescription <> '' then
            Request.Add('targetDescription', TargetDescription);
        if ExpectedCount >= 0 then
            Request.Add('expectedCount', ExpectedCount);
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
            Dispatcher.Execute(Enum::"Message Type ori"::"Quality.Template.Copy", Enum::"Message Version ori"::"1.0", '', 'issue18-tests', 'application/json', RequestContent, ResponseContent, ResponseContentType, false)
        else
            Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Quality.Template.Copy", Enum::"Message Version ori"::"1.0", '', 'issue18-tests', 'application/json', RequestContent, EmptyTaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
    end;
}
