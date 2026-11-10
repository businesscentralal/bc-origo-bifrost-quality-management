namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>Issue 7: exercises the registered action through the public Foundation dispatcher.</summary>
codeunit 97207 "Quality Reinspect Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>Creates a revision and regenerates the template line.</summary>
    [Test]
    [HandlerFunctions('ConfirmYes')]
    procedure Scenario_AC03_FinishedSource_CreatesNativeRevision()
    var
        Source: Record "Qlty. Inspection Header";
        Created: Record "Qlty. Inspection Header";
        Line: Record "Qlty. Inspection Line";
        Response: JsonObject;
    begin
        // Story #7, AC03 | Time: WorkDate for native numbering; no expiry | Risk: None
        // [GIVEN] A private finished inspection and template.
        Initialize(Source);
        AddTemplateLine(Source."Template Code");
        // [WHEN] The real dispatcher resolves the registered enum implementation.
        Response := Invoke(IdRequest(Source.SystemId));
        // [THEN] Native revision, result resets, and template line creation are visible.
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
        Created.Get(Source."No.", 1);
        Assert.AreEqual(Created.Status::Open, Created.Status, 'New revision must be open.');
        Assert.AreEqual('', Created."Result Code", 'Native creation clears the result.');
        Assert.AreEqual(0DT, Created."Finished Date", 'Native creation clears the finish date.');
        Line.Get(Created."No.", 1, 10000);
        Assert.AreEqual(Source."Template Code", Line."Template Code", 'Native template lines must be generated.');
        Source.Get(Source."No.", 0);
        Assert.IsFalse(Source."Most Recent Re-inspection", 'Native action clears the preceding latest flag.');
    end;

    /// <summary>Repeated requests create consecutive revisions.</summary>
    [Test]
    [HandlerFunctions('ConfirmYes')]
    procedure Scenario_AC01_OlderSource_UsesLatestRevision()
    var
        Source: Record "Qlty. Inspection Header";
        Created: Record "Qlty. Inspection Header";
        Response: JsonObject;
    begin
        // Story #7, AC01 | Time: No date dependency | Risk: None
        Initialize(Source);
        Response := Invoke(IdRequest(Source.SystemId));
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
        Response := Invoke(IdRequest(Source.SystemId));
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
        Created.Get(Source."No.", 2);
        Assert.AreEqual(2, Created."Re-inspection No.", 'The operation is not idempotent.');
    end;

    /// <summary>Missing input refuses without writing.</summary>
    [Test]
    procedure Scenario_AC02_MissingId_RefusesWithoutChanges()
    begin
        // Story #7, AC02 | Time: No date dependency | Risk: None
        AssertInputRefusal('{}', 'MissingParameter');
    end;

    /// <summary>Malformed GUID refuses without writing.</summary>
    [Test]
    procedure Scenario_AC02_InvalidId_RefusesWithoutChanges()
    begin
        // Story #7, AC02 | Time: No date dependency | Risk: None
        AssertInputRefusal('{"inspectionSystemId":"invalid"}', 'InvalidParameter');
    end;

    /// <summary>Null input refuses without writing.</summary>
    [Test]
    procedure Scenario_AC02_NullId_RefusesWithoutChanges()
    begin
        // Story #7, AC02 | Time: No date dependency | Risk: None
        AssertInputRefusal('{"inspectionSystemId":null}', 'InvalidParameter');
    end;

    /// <summary>Structured input is refused rather than causing a JSON conversion error.</summary>
    [Test]
    procedure Scenario_AC02_ObjectId_RefusesWithoutChanges()
    begin
        // Story #7, AC02 | Time: No date dependency | Risk: None
        AssertInputRefusal('{"inspectionSystemId":{}}', 'InvalidParameter');
    end;

    /// <summary>A zero GUID is not a record identifier.</summary>
    [Test]
    procedure Scenario_AC02_ZeroGuid_RefusesWithoutChanges()
    begin
        // Story #7, AC02 | Time: No date dependency | Risk: None
        AssertInputRefusal('{"inspectionSystemId":"00000000-0000-0000-0000-000000000000"}', 'InvalidParameter');
    end;

    /// <summary>An unknown record produces a translated refusal.</summary>
    [Test]
    procedure Scenario_AC02_UnknownId_RefusesWithoutChanges()
    begin
        // Story #7, AC02 | Time: No date dependency | Risk: None
        AssertInputRefusal(IdRequest(CreateGuid()), 'RecordNotFound');
    end;

    /// <summary>Unknown keys cannot silently change the intended operation.</summary>
    [Test]
    procedure Scenario_AC02_UnknownKey_RefusesBeforeCreation()
    var
        Source: Record "Qlty. Inspection Header";
        Response: JsonObject;
        Request: JsonObject;
    begin
        // Story #7, AC02 | Time: No date dependency | Risk: None
        Initialize(Source);
        Request.ReadFrom(IdRequest(Source.SystemId));
        Request.Add('skip', 1);
        Response := Invoke(Serialize(Request));
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual('UnknownParameter', Response.GetText('code'), Serialize(Response));
        Source.SetRange("No.", Source."No.");
        Assert.AreEqual(1, Source.Count(), 'Unknown keys must not create a revision.');
    end;

    /// <summary>Native setup refusal rolls back an intermediate most-recent update.</summary>
    [Test]
    [HandlerFunctions('ConfirmYes')]
    procedure Scenario_AC04_MissingSetup_RefusesWithoutPartialRevision()
    var
        Source: Record "Qlty. Inspection Header";
        Setup: Record "Qlty. Management Setup";
        Response: JsonObject;
    begin
        // Story #7, AC04 | Time: No date dependency | Risk: Setup restored by test isolation
        Initialize(Source);
        Setup.DeleteAll();
        Commit();
        Response := Invoke(IdRequest(Source.SystemId));
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual('BusinessCentralError', Response.GetText('code'), Serialize(Response));
        Assert.IsFalse(Response.GetText('error').Contains('Unhandled UI'), 'The test must reach native validation, not fail on a missing UI handler.');
        Source.Get(Source."No.", 0);
        Assert.IsTrue(Source."Most Recent Re-inspection", 'A business refusal must preserve source flags.');
        Source.SetRange("No.", Source."No.");
        Assert.AreEqual(1, Source.Count(), 'A business refusal must not create a revision.');
    end;

    /// <summary>A native blocked result refuses the open-source finish.</summary>
    [Test]
    procedure Scenario_AC04_BlockedResult_LeavesSourceOpen()
    var
        Source: Record "Qlty. Inspection Header";
        InspectionResult: Record "Qlty. Inspection Result";
        Response: JsonObject;
    begin
        // Story #7, AC04 | Time: Native finish uses CurrentDateTime | Risk: None
        Initialize(Source);
        InspectionResult.Code := Source."No.";
        InspectionResult."Finish Allowed" := InspectionResult."Finish Allowed"::"Do not allow finish";
        InspectionResult.Insert();
        Source.Status := Source.Status::Open;
        Source."Result Code" := InspectionResult.Code;
        Source.Modify();
        Commit();
        Response := Invoke(IdRequest(Source.SystemId));
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual('BusinessCentralError', Response.GetText('code'), Serialize(Response));
        Assert.IsFalse(Response.GetText('error').Contains('Unhandled UI'), 'The test must reach native validation, not fail on a missing UI handler.');
        Source.Get(Source."No.", 0);
        Assert.AreEqual(Source.Status::Open, Source.Status, 'Native refusal must not finish the source.');
        Assert.AreEqual(0DT, Source."Finished Date", 'Native refusal must preserve finish date.');
        Assert.IsTrue(Source."Most Recent Re-inspection", 'Native refusal must preserve latest flag.');
    end;

    /// <summary>A failure after native insertion restores the source and removes the partial revision.</summary>
    [Test]
    [HandlerFunctions('ConfirmYes')]
    procedure Scenario_AC04_InvalidTemplateLine_RollsBackNativeWrites()
    var
        Source: Record "Qlty. Inspection Header";
        InspectionTemplateLine: Record "Qlty. Inspection Template Line";
        InspectionLine: Record "Qlty. Inspection Line";
        Response: JsonObject;
    begin
        // Story #7, AC04 | Time: No date dependency | Risk: None
        // [GIVEN] A template line whose missing test fails after the new header is inserted.
        Initialize(Source);
        InspectionTemplateLine."Template Code" := Source."Template Code";
        InspectionTemplateLine."Line No." := 10000;
        InspectionTemplateLine."Test Code" := Source."No.";
        InspectionTemplateLine.Insert();
        Commit();
        // [WHEN] The standard action inserts the header then fails validating its template line.
        Response := Invoke(IdRequest(Source.SystemId));
        // [THEN] All native changes are rolled back, including the old most-recent flag.
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual('BusinessCentralError', Response.GetText('code'), Serialize(Response));
        Assert.IsFalse(Response.GetText('error').Contains('Unhandled UI'), 'The test must reach native validation, not fail on a missing UI handler.');
        Source.Get(Source."No.", 0);
        Assert.IsTrue(Source."Most Recent Re-inspection", 'The intermediate latest-flag update must roll back.');
        Source.SetRange("No.", Source."No.");
        Assert.AreEqual(1, Source.Count(), 'The partial new header must roll back.');
        InspectionLine.SetRange("Inspection No.", Source."No.");
        Assert.IsTrue(InspectionLine.IsEmpty(), 'The partial result lines must roll back.');
    end;

    /// <summary>The contract identifies its write effect and retry behavior.</summary>
    [Test]
    procedure Scenario_AC01_Contract_DescribesWriteAndPermissions()
    var
        Impl: Interface "Msg Contract ori";
        Effect: JsonObject;
        Parameters: JsonArray;
    begin
        // Story #7, AC01 | Time: No date dependency | Risk: None
        Impl := Enum::"Message Type ori"::"Quality.Inspection.CreateReinspection";
        Assert.IsTrue(Impl.GetEffect(Effect), 'Effect chapter must exist.');
        Assert.AreEqual('write', Effect.GetText('effect'), 'Effect must describe a write.');
        Assert.IsFalse(Effect.GetBoolean('idempotent'), 'Each success creates a new revision.');
        Assert.AreEqual('BIFROST QM Full ori', Effect.GetText('permissionSet'), 'Contract must name the app role.');
        Assert.IsTrue(Impl.GetParameters(Parameters), 'Parameters must exist.');
        Assert.AreEqual(1, Parameters.Count(), 'Only the documented source ID is accepted.');
    end;

    /// <summary>Discovery and notes change with the session language.</summary>
    [Test]
    procedure Scenario_AC06_Icelandic_DiscoveryIsTranslated()
    var
        Impl: Interface "Msg Interface ori";
        English: Text;
        Icelandic: Text;
        PreviousLanguage: Integer;
    begin
        // Story #7, AC06 | Time: No date dependency | Risk: Session language restored
        Impl := Enum::"Message Type ori"::"Quality.Inspection.CreateReinspection";
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        English := Impl.GetDescription();
        GlobalLanguage(1039);
        Icelandic := Impl.GetDescription();
        GlobalLanguage(PreviousLanguage);
        Assert.AreNotEqual(English, Icelandic, 'Icelandic discovery must be translated.');
    end;

    /// <summary>Confirms the native action in the interactive test client.</summary>
    [ConfirmHandler]
    procedure ConfirmYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(Question <> '', 'The native confirmation must have a question.');
        Reply := true;
    end;

    local procedure AssertInputRefusal(RequestText: Text; ExpectedCode: Text)
    var
        Source: Record "Qlty. Inspection Header";
        Response: JsonObject;
        BeforeCount: Integer;
    begin
        // [GIVEN] An initialized platform and private inspection fixture.
        Initialize(Source);
        BeforeCount := Source.Count();
        // [WHEN] The registered message receives invalid input.
        Response := Invoke(RequestText);
        // [THEN] The coded refusal leaves all inspection rows unchanged.
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual(ExpectedCode, Response.GetText('code'), Serialize(Response));
        Assert.AreEqual(BeforeCount, Source.Count(), 'Input refusal must change nothing.');
    end;

    local procedure Initialize(var Inspection: Record "Qlty. Inspection Header")
    var
        Setup: Record "Qlty. Management Setup";
        InspectionTemplate: Record "Qlty. Inspection Template Hdr.";
        BifrostSetup: Record "Setup ori";
    begin
        BifrostSetup.InsertIfNotExists();
        if not Setup.Get() then
            Setup.Insert();
        InspectionTemplate.Code := CopyStr('Q7' + DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 20);
        InspectionTemplate.Insert();
        Inspection."No." := InspectionTemplate.Code;
        Inspection."Template Code" := InspectionTemplate.Code;
        Inspection.Status := Inspection.Status::Finished;
        Inspection."Most Recent Re-inspection" := true;
        Inspection.Insert();
        Commit(); // Required before the public dispatcher starts a caught native codeunit transaction.
    end;

    local procedure AddTemplateLine(TemplateCode: Code[20])
    var
        QualityTest: Record "Qlty. Test";
        InspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        QualityTest.Code := TemplateCode;
        QualityTest."Test Value Type" := QualityTest."Test Value Type"::"Value Type Text";
        QualityTest.Insert();
        InspectionTemplateLine."Template Code" := TemplateCode;
        InspectionTemplateLine."Line No." := 10000;
        InspectionTemplateLine."Test Code" := QualityTest.Code;
        InspectionTemplateLine.Insert();
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
    var
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        ResponseContentType: Text[100];
        ResponseText: Text;
    begin
        RequestContent.AddText(RequestText);
        Dispatcher.Execute(Enum::"Message Type ori"::"Quality.Inspection.CreateReinspection", Enum::"Message Version ori"::"1.0", '', 'issue7-tests', 'application/json', RequestContent, ResponseContent, ResponseContentType, false);
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
    end;
}
