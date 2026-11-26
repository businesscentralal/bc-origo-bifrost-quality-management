namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;
using System.Utilities;

/// <summary>Story 22: Quality.Report.Print through the public Foundation dispatcher; mock-only fixture.</summary>
codeunit 97255 "Quality Report Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>The ordinal of the new enum value is fixed.</summary>
    [Test]
    procedure Scenario_AC01_OrdinalPin()
    begin
        // Story #22, AC01 | Time: none | Risk: None
        Assert.AreEqual(10035318, Enum::"Message Type ori"::"Quality.Report.Print".AsInteger(), 'The enum ordinal must not change.');
    end;

    /// <summary>The contract describes a read and the three report values.</summary>
    [Test]
    procedure Scenario_AC01_Contract_IsRead()
    var
        Impl: Interface "Msg Contract ori";
        Effect: JsonObject;
        Parameters: JsonArray;
    begin
        // Story #22, AC01 | Time: none | Risk: None
        Impl := Enum::"Message Type ori"::"Quality.Report.Print";
        Assert.IsTrue(Impl.GetEffect(Effect), 'Effect chapter must exist.');
        Assert.AreEqual('read', Effect.GetText('effect'), 'The type is a read.');
        Assert.IsTrue(Impl.GetParameters(Parameters), 'Parameters must exist.');
        Assert.AreEqual(3, Parameters.Count(), 'inspectionSystemId, report and languageCode.');
    end;

    /// <summary>Discovery text changes with the session language.</summary>
    [Test]
    procedure Scenario_AC06_Icelandic_DiscoveryIsTranslated()
    var
        Impl: Interface "Msg Interface ori";
        English: Text;
        Icelandic: Text;
        PreviousLanguage: Integer;
    begin
        // Story #22, AC06 | Time: none | Risk: Session language restored
        Impl := Enum::"Message Type ori"::"Quality.Report.Print";
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        English := Impl.GetDescription();
        GlobalLanguage(1039);
        Icelandic := Impl.GetDescription();
        GlobalLanguage(PreviousLanguage);
        Assert.AreNotEqual(English, Icelandic, 'Icelandic discovery must be translated.');
    end;

    /// <summary>The Certificate of Analysis is staged as a PDF.</summary>
    [Test]
    procedure Scenario_AC02_CertificateOfAnalysis_StagesPdf()
    begin
        // Story #22, AC02 | Time: none | Risk: None
        AssertStagesPdf('certificateOfAnalysis', '');
    end;

    /// <summary>The Non-Conformance report is staged as a PDF.</summary>
    [Test]
    procedure Scenario_AC02_NonConformance_StagesPdf()
    begin
        // Story #22, AC02 | Time: none | Risk: None
        AssertStagesPdf('nonConformance', '');
    end;

    /// <summary>The general inspection report is staged as a PDF in Icelandic.</summary>
    [Test]
    procedure Scenario_AC02_General_StagesPdfInIcelandic()
    begin
        // Story #22, AC02 | Time: none | Risk: Session language restored
        AssertStagesPdf('general', 'is-IS');
    end;

    /// <summary>Request refusals happen before rendering and leave no staging row.</summary>
    [Test]
    procedure Scenario_AC03_MissingId_Refuses()
    begin
        // Story #22, AC03 | Time: none | Risk: None
        AssertRefusal('{"report":"general"}', 'MissingParameter');
    end;

    /// <summary>A malformed id is refused.</summary>
    [Test]
    procedure Scenario_AC03_MalformedId_Refuses()
    begin
        // Story #22, AC03 | Time: none | Risk: None
        AssertRefusal('{"inspectionSystemId":"nope","report":"general"}', 'InvalidParameter');
    end;

    /// <summary>A missing report is refused.</summary>
    [Test]
    procedure Scenario_AC03_MissingReport_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
    begin
        // Story #22, AC03 | Time: none | Risk: None
        Initialize(Inspection);
        AssertRefusal(StrSubstNo('{"inspectionSystemId":"%1"}', Format(Inspection.SystemId, 0, 4)), 'MissingParameter');
    end;

    /// <summary>An unknown report value is refused.</summary>
    [Test]
    procedure Scenario_AC03_UnknownReport_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
    begin
        // Story #22, AC03 | Time: none | Risk: None
        Initialize(Inspection);
        AssertRefusal(StrSubstNo('{"inspectionSystemId":"%1","report":"invoice"}', Format(Inspection.SystemId, 0, 4)), 'InvalidParameter');
    end;

    /// <summary>An unknown language is refused.</summary>
    [Test]
    procedure Scenario_AC03_UnknownLanguage_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
    begin
        // Story #22, AC03 | Time: none | Risk: None
        Initialize(Inspection);
        AssertRefusal(StrSubstNo('{"inspectionSystemId":"%1","report":"general","languageCode":"de-DE"}', Format(Inspection.SystemId, 0, 4)), 'InvalidParameter');
    end;

    /// <summary>An unknown key is refused.</summary>
    [Test]
    procedure Scenario_AC03_UnknownKey_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
    begin
        // Story #22, AC03 | Time: none | Risk: None
        Initialize(Inspection);
        AssertRefusal(StrSubstNo('{"inspectionSystemId":"%1","report":"general","copies":2}', Format(Inspection.SystemId, 0, 4)), 'UnknownParameter');
    end;

    /// <summary>An unknown inspection is RecordNotFound.</summary>
    [Test]
    procedure Scenario_AC03_UnknownInspection_RecordNotFound()
    begin
        // Story #22, AC03 | Time: none | Risk: None
        AssertRefusal(StrSubstNo('{"inspectionSystemId":"%1","report":"general"}', Format(CreateGuid(), 0, 4)), 'RecordNotFound');
    end;

    /// <summary>A result over the size limit is refused, nothing is staged and the language is restored.</summary>
    [Test]
    procedure Scenario_AC03_AC04_Oversize_RefusesAndRestoresLanguage()
    var
        Inspection: Record "Qlty. Inspection Header";
        Limit: Codeunit "Quality Report Limit ori";
        Response: JsonObject;
        BeforeStaging: Integer;
        PreviousLanguage: Integer;
    begin
        // Story #22, AC03/AC04 | Time: none | Risk: Session language restored
        Initialize(Inspection);
        BeforeStaging := StagingCount();
        PreviousLanguage := GlobalLanguage();
        BindSubscription(Limit);
        Response := Invoke(StrSubstNo('{"inspectionSystemId":"%1","report":"general","languageCode":"is-IS"}', Format(Inspection.SystemId, 0, 4)));
        UnbindSubscription(Limit);
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual('LimitExceeded', Response.GetText('code'), Serialize(Response));
        Assert.AreEqual(BeforeStaging, StagingCount(), 'No staging row may remain.');
        Assert.AreEqual(PreviousLanguage, GlobalLanguage(), 'The session language must be restored.');
    end;

    /// <summary>A Read caller with the Microsoft read set succeeds.</summary>
    [Test]
    procedure Scenario_AC05_ReadRole_Succeeds()
    var
        Inspection: Record "Qlty. Inspection Header";
        Response: JsonObject;
    begin
        // Story #22, AC05 | Time: none | Risk: permissions restored
        Initialize(Inspection);
        LowerPermissions.SetExactPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet('BIFROST QM Read ori');
        LowerPermissions.AddPermissionSet('QltyMgmt - Read');
        LowerPermissions.AddPermissionSet('D365 BASIC');
        Response := Invoke(StrSubstNo('{"inspectionSystemId":"%1","report":"certificateOfAnalysis"}', Format(Inspection.SystemId, 0, 4)));
        LowerPermissions.SetOutsideO365Scope();
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
    end;

    /// <summary>A caller without native read access is denied.</summary>
    [Test]
    procedure Scenario_AC05_NoNativeRead_PermissionDenied()
    var
        Inspection: Record "Qlty. Inspection Header";
        Response: JsonObject;
    begin
        // Story #22, AC05 | Time: none | Risk: permissions restored
        Initialize(Inspection);
        LowerPermissions.SetExactPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet('BIFROST QM Read ori');
        Response := Invoke(StrSubstNo('{"inspectionSystemId":"%1","report":"certificateOfAnalysis"}', Format(Inspection.SystemId, 0, 4)));
        LowerPermissions.SetOutsideO365Scope();
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual('PermissionDenied', Response.GetText('code'), Serialize(Response));
    end;

    local procedure AssertStagesPdf(Kind: Text; LanguageCode: Text)
    var
        Inspection: Record "Qlty. Inspection Header";
        Line: Record "Qlty. Inspection Line";
        BlobStaging: Codeunit "Blob Staging ori";
        TempBlob: Codeunit "Temp Blob";
        Response: JsonObject;
        Result: JsonObject;
        Token: JsonToken;
        InStr: InStream;
        Header: Text;
        ContentType: Text;
        FileName: Text;
        BeforeHeaders: Integer;
        BeforeLines: Integer;
        PreviousLanguage: Integer;
        Request: Text;
        StagingId: Guid;
    begin
        Initialize(Inspection);
        BeforeHeaders := Inspection.Count();
        BeforeLines := Line.Count();
        PreviousLanguage := GlobalLanguage();
        Request := StrSubstNo('{"inspectionSystemId":"%1","report":"%2"', Format(Inspection.SystemId, 0, 4), Kind);
        if LanguageCode <> '' then
            Request += StrSubstNo(',"languageCode":"%1"', LanguageCode);
        Response := Invoke(Request + '}');
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
        Response.Get('result', Token);
        Result := Token.AsArray().GetObject(0);
        Assert.AreEqual('application/pdf', Result.GetText('contentType'), 'contentType');
        Assert.IsTrue(StrPos(Result.GetText('fileName'), Inspection."No.") = 1, 'fileName names the inspection.');
        Assert.IsTrue(StrPos(Result.GetText('fileName'), Kind) > 0, 'fileName names the report.');
        Assert.IsTrue(Evaluate(StagingId, Result.GetText('stagingId')) and BlobStaging.Take(StagingId, TempBlob, ContentType, FileName), 'The caller reads the staged PDF.');
        Assert.AreEqual(Result.GetText('sizeBytes'), Format(TempBlob.Length()), 'sizeBytes matches.');
        TempBlob.CreateInStream(InStr);
        InStr.Read(Header, 4);
        Assert.AreEqual('%PDF', Header, 'The staged content is a PDF.');
        Assert.AreEqual(BeforeHeaders, Inspection.Count(), 'No inspection is added or removed.');
        Assert.AreEqual(BeforeLines, Line.Count(), 'No line is added or removed.');
        Assert.AreEqual(PreviousLanguage, GlobalLanguage(), 'The session language must be restored.');
    end;

    local procedure AssertRefusal(RequestText: Text; ExpectedCode: Text)
    var
        Response: JsonObject;
        BeforeStaging: Integer;
        PreviousLanguage: Integer;
    begin
        BeforeStaging := StagingCount();
        PreviousLanguage := GlobalLanguage();
        Response := Invoke(RequestText);
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual(ExpectedCode, Response.GetText('code'), Serialize(Response));
        Assert.AreEqual(BeforeStaging, StagingCount(), 'A refusal must leave no staging row.');
        Assert.AreEqual(PreviousLanguage, GlobalLanguage(), 'The language is restored after a refusal.');
    end;

    local procedure Initialize(var Inspection: Record "Qlty. Inspection Header")
    var
        Setup: Record "Qlty. Management Setup";
        InspectionTemplate: Record "Qlty. Inspection Template Hdr.";
        Line: Record "Qlty. Inspection Line";
        BifrostSetup: Record "Setup ori";
    begin
        BifrostSetup.InsertIfNotExists();
        if not Setup.Get() then
            Setup.Insert();
        InspectionTemplate.Code := CopyStr('Q22' + DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 20);
        InspectionTemplate.Insert();
        Inspection."No." := InspectionTemplate.Code;
        Inspection."Template Code" := InspectionTemplate.Code;
        Inspection.Status := Inspection.Status::Finished;
        Inspection."Most Recent Re-inspection" := true;
        Inspection.Insert();
        Line."Inspection No." := Inspection."No.";
        Line."Re-inspection No." := Inspection."Re-inspection No.";
        Line."Line No." := 10000;
        Line."Template Code" := InspectionTemplate.Code;
        Line.Insert();
        Commit(); // Required before the public dispatcher starts a caught native codeunit transaction.
    end;

    local procedure StagingCount(): Integer
    var
        StagingRef: RecordRef;
    begin
        // The staging table is internal to Foundation; count it by object number.
        StagingRef.Open(10078382);
        exit(StagingRef.Count());
    end;

    local procedure Serialize(Value: JsonObject) Result: Text
    begin
        Value.WriteTo(Result);
    end;

    local procedure Invoke(RequestText: Text) Response: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        ResponseContentType: Text[100];
        ResponseText: Text;
    begin
        RequestContent.AddText(RequestText);
        Dispatcher.Execute(Enum::"Message Type ori"::"Quality.Report.Print", Enum::"Message Version ori"::"1.0", '', 'issue22-tests', 'application/json', RequestContent, ResponseContent, ResponseContentType, false);
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
    end;
}
