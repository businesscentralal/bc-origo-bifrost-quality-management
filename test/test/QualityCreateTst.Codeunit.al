namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Verifies issue 3 through the public dispatcher using isolated, self-created source and setup data.</summary>
codeunit 97240 "Quality Create Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>Rules CreateInspection.</summary>
    [Test]
    [HandlerFunctions('InspectionPageHandler')]
    procedure Scenario_AC03_Rules_CreateInspection()
    begin
        // Story #3 AC03 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('rules', 1033);
    end;

    /// <summary>Template CreateInspection.</summary>
    [Test]
    [HandlerFunctions('InspectionPageHandler')]
    procedure Scenario_AC03_Template_CreateInspection()
    begin
        // Story #3 AC03 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('template', 1033);
    end;

    /// <summary>Icelandic CreateInspection.</summary>
    [Test]
    [HandlerFunctions('InspectionPageHandler')]
    procedure Scenario_AC06_Icelandic_CreateInspection()
    begin
        // Story #3 AC06 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('template', 1039);
    end;

    /// <summary>MissingKey Refuses.</summary>
    [Test]
    procedure Scenario_AC02_MissingKey_Refuses()
    begin
        // Story #3 AC02 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('missing', 1033);
    end;

    /// <summary>UnknownKey Refuses.</summary>
    [Test]
    procedure Scenario_AC02_UnknownKey_Refuses()
    begin
        // Story #3 AC02 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('unknown', 1033);
    end;

    /// <summary>MalformedGuid Refuses.</summary>
    [Test]
    procedure Scenario_AC02_MalformedGuid_Refuses()
    begin
        // Story #3 AC02 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('guid', 1033);
    end;

    /// <summary>ZeroTable Refuses.</summary>
    [Test]
    procedure Scenario_AC02_ZeroTable_Refuses()
    begin
        // Story #3 AC02 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('table', 1033);
    end;

    /// <summary>StringTable Refuses.</summary>
    [Test]
    procedure Scenario_AC02_StringTable_Refuses()
    begin
        // Story #3 AC02 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('stringTable', 1033);
    end;

    /// <summary>LongTemplate Refuses.</summary>
    [Test]
    procedure Scenario_AC02_LongTemplate_Refuses()
    begin
        // Story #3 AC02 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('long', 1033);
    end;

    /// <summary>EmptyTemplate Refuses.</summary>
    [Test]
    procedure Scenario_AC02_EmptyTemplate_Refuses()
    begin
        // Story #3 AC02 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('empty', 1033);
    end;

    /// <summary>BlankTemplate Refuses.</summary>
    [Test]
    procedure Scenario_AC02_BlankTemplate_Refuses()
    begin
        // Story #3 AC02 | Time: WorkDate controls native numbering | Risk: owned fixture only
        VerifyScenario('blank', 1033);
    end;

    /// <summary>MissingTemplate Refuses.</summary>
    [Test]
    procedure Scenario_AC04_MissingTemplate_Refuses()
    begin
        // Story #3 AC04 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('badTemplate', 1033);
    end;

    /// <summary>MissingNumberSeries Refuses.</summary>
    [Test]
    procedure Scenario_AC04_MissingNumberSeries_Refuses()
    begin
        // Story #3 AC04 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('numberSeries', 1033);
    end;

    /// <summary>LateNativeError RollsBack.</summary>
    [Test]
    procedure Scenario_AC04_LateNativeError_RollsBack()
    begin
        // Story #3 AC04 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('late', 1033);
    end;

    /// <summary>ReadRole Refuses.</summary>
    [Test]
    procedure Scenario_AC05_ReadRole_Refuses()
    begin
        // Story #3 AC05 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('read', 1033);
    end;

    /// <summary>ApiWithoutApp Refuses.</summary>
    [Test]
    procedure Scenario_AC05_ApiWithoutApp_Refuses()
    begin
        // Story #3 AC05 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('noApp', 1033);
    end;

    /// <summary>IcelandicMissingKey Refuses.</summary>
    [Test]
    procedure Scenario_AC06_IcelandicMissingKey_Refuses()
    begin
        // Story #3 AC06 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('missing', 1039);
    end;

    /// <summary>RepeatedRequest RespectsSetup.</summary>
    [Test]
    [HandlerFunctions('InspectionPageHandler')]
    procedure Scenario_AC03_RepeatedRequest_RespectsSetup()
    begin
        // Story #3 AC03 | Time: WorkDate selects the native number series date | Risk: owned fixture only
        VerifyScenario('repeat', 1033);
    end;

    /// <summary>ForcedTemplate WithoutRuleCreates.</summary>
    [Test]
    [HandlerFunctions('InspectionPageHandler')]
    procedure Scenario_AC03_ForcedTemplate_WithoutRuleCreates()
    begin
        // Story #3 AC03 | Time: WorkDate controls native numbering | Risk: owned fixture only
        VerifyScenario('forced', 1033);
    end;

    /// <summary>MissingRule Refuses.</summary>
    [Test]
    procedure Scenario_AC04_MissingRule_Refuses()
    begin
        // Story #3 AC04 | Time: WorkDate controls native numbering | Risk: owned fixture only
        VerifyScenario('noRule', 1033);
    end;

    /// <summary>MissingSource Refuses.</summary>
    [Test]
    procedure Scenario_AC02_MissingSource_Refuses()
    begin
        // Story #3 AC02 | Time: WorkDate controls native numbering | Risk: owned fixture only
        VerifyScenario('noSource', 1033);
    end;

    /// <summary>NullGuid Refuses.</summary>
    [Test]
    procedure Scenario_AC02_NullGuid_Refuses()
    begin
        // Story #3 AC02 | Time: WorkDate controls native numbering | Risk: owned fixture only
        VerifyScenario('null', 1033);
    end;

    /// <summary>Verifies catalogue and effect/help chapters through the public contract API.</summary>
    [Test]
    procedure Scenario_AC01_RegisteredType_ExposesContract()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Effect: JsonToken;
        Idempotent: JsonToken;
    begin
        // Story #3 AC01/AC07 | Time: independent of dates | Risk: None
        Initialize();
        // [GIVEN] The installed enum extension.
        // [WHEN] Foundation resolves its contract.
        Assert.IsTrue(ContractMgt.GetContract(Enum::"Message Type ori"::"Quality.Inspection.Create", Contract), 'Expected registered contract.');
        // [THEN] The operation declares its write effect and non-idempotency, and has help.
        Contract.Get('effect', Effect);
        Assert.AreEqual('write', ReadText(Effect.AsObject(), 'effect'), 'Expected write effect.');
        Effect.AsObject().Get('idempotent', Idempotent);
        Assert.IsFalse(Idempotent.AsValue().AsBoolean(), 'Creation is not idempotent.');
        Assert.IsTrue(Contract.Contains('overview'), 'Help must be available.');
    end;

    local procedure VerifyScenario(Scenario: Text; LanguageId: Integer)
    var
        Item: Record Item;
        Inspection: Record "Qlty. Inspection Header";
        QualitySetup: Record "Qlty. Management Setup";
        InspectionLine: Record "Qlty. Inspection Line";
        GenerationRule: Record "Qlty. Inspection Gen. Rule";
        Fault: Codeunit "Quality Create Fault ori";
        SourceRef: RecordRef;
        Request: JsonObject;
        Response: JsonObject;
        FixtureCode: Code[20];
        InspectionId: Guid;
    begin
        Initialize();
        // [GIVEN] A unique source, template, matching generation rule and number series.
        FixtureCode := CopyStr('XQ3' + DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 20);
        SeedFixture(FixtureCode, Item);
        Request.Add('sourceTableId', Database::Item);
        Request.Add('sourceSystemId', Format(Item.SystemId, 0, 4));
        if not (Scenario in ['rules', 'noRule']) then
            Request.Add('templateCode', FixtureCode);
        case Scenario of
            'missing': Request.Remove('sourceSystemId');
            'null': Request.Replace('sourceSystemId', '00000000-0000-0000-0000-000000000000');
            'noSource': Request.Replace('sourceSystemId', Format(CreateGuid(), 0, 4));
            'forced', 'noRule':
                begin
                    GenerationRule.SetRange("Template Code", FixtureCode);
                    GenerationRule.DeleteAll(false);
                end;
            'unknown': Request.Add('skip', 1);
            'guid': Request.Replace('sourceSystemId', 'invalid');
            'table': Request.Replace('sourceTableId', 0);
            'stringTable': Request.Replace('sourceTableId', '27');
            'long': Request.Replace('templateCode', PadStr('X', 21, 'X'));
            'empty': Request.Replace('templateCode', '');
            'blank': Request.Replace('templateCode', '   ');
            'badTemplate': Request.Replace('templateCode', 'X-NO-SUCH-TEMPLATE');
            'numberSeries':
                begin
                    QualitySetup.Get();
                    QualitySetup."Quality Inspection Nos." := '';
                    QualitySetup.Modify(false);
                end;
        end;
        Commit();
        if Scenario in ['read', 'noApp'] then begin
            LowerPermissions.SetExactPermissionSet('BIFROST API ori');
            LowerPermissions.AddPermissionSet('QltyMgmt - Admin');
            LowerPermissions.AddPermissionSet('QM Create Test ori');
            if Scenario = 'read' then
                LowerPermissions.AddPermissionSet('BIFROST QM Read ori');
        end;
        if Scenario = 'template' then begin
            LowerPermissions.SetExactPermissionSet('BIFROST Full ori');
            LowerPermissions.AddPermissionSet('QltyMgmt - Admin');
            LowerPermissions.AddPermissionSet('QM Create Test ori');
        end;
        if Scenario = 'late' then
            BindSubscription(Fault);
        // [WHEN] The public dispatcher invokes the native action.
        Response := Dispatch(Request, LanguageId);
        if Scenario = 'late' then
            UnbindSubscription(Fault);
        LowerPermissions.SetOutsideO365Scope();
        // [THEN] Success identifies the actual source and template, or failure leaves no inspection.
        SourceRef.GetTable(Item);
        Inspection.SetRange("Source RecordId", SourceRef.RecordId());
        if Scenario in ['rules', 'template', 'repeat', 'forced'] then begin
            Assert.AreEqual('Success', ReadText(Response, 'status'), 'Expected creation: ' + ReadOptionalError(Response));
            Evaluate(InspectionId, ReadText(Response, 'inspectionSystemId'));
            Assert.IsTrue(Inspection.GetBySystemId(InspectionId), 'Returned inspection must exist.');
            Assert.AreEqual(SourceRef.RecordId(), Inspection."Source RecordId", 'Native source reference must match.');
            Assert.AreEqual(FixtureCode, Inspection."Template Code", 'Native template must match.');
            Assert.AreEqual(Item."No.", Inspection."Source Item No.", 'Native source mapping must run.');
            InspectionLine.SetRange("Inspection No.", Inspection."No.");
            InspectionLine.SetRange("Re-inspection No.", Inspection."Re-inspection No.");
            Assert.AreEqual(1, InspectionLine.Count(), 'Native creation must copy the template line.');
            InspectionLine.FindFirst();
            Assert.AreEqual(FixtureCode, InspectionLine."Test Code", 'Native test code must match.');
            Assert.AreEqual('XQ3 owned measurement', InspectionLine.Description, 'Native line description must match.');
            if Scenario = 'repeat' then begin
                Response := Dispatch(Request, LanguageId);
                Assert.AreEqual('Success', ReadText(Response, 'status'), 'Expected second creation.');
                Assert.AreEqual(2, Inspection.Count(), 'Always-new setup must create a second inspection.');
            end;
        end else begin
            Assert.AreEqual('Error', ReadText(Response, 'status'), 'Expected refusal.');
            Assert.IsTrue(Inspection.IsEmpty(), 'A refusal must leave no inspection.');
            case Scenario of
                'late': Assert.IsTrue(ReadText(Response, 'error').Contains('Injected late'), 'Error must occur after native insertion.');
                'read', 'noApp': Assert.IsTrue(LowerCase(ReadText(Response, 'error')).Contains('permission'), 'Missing app permission must be refused.');
                'missing':
                    begin
                        Assert.IsTrue(ReadText(Response, 'error').Contains('sourceSystemId'), 'Identify missing key.');
                        if LanguageId = 1039 then
                            Assert.IsTrue(ReadText(Response, 'error').Contains('Nauðsynlega'), 'Refusal must be Icelandic.');
                    end;
            end;
        end;
        CleanupFixture(FixtureCode);
    end;

    local procedure Initialize()
    begin
        LowerPermissions.SetOutsideO365Scope();
    end;

    /// <summary>Creates an owned source and configuration; records original setup for cleanup.</summary>
    procedure SeedFixture(FixtureCode: Code[20]; var Item: Record Item)
    var
        SavedSetup: Record "Quality Create Fixture ori";
        QualitySetup: Record "Qlty. Management Setup";
        InspectionTemplate: Record "Qlty. Inspection Template Hdr.";
        InspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QualityTest: Record "Qlty. Test";
        GenerationRule: Record "Qlty. Inspection Gen. Rule";
        SourceConfig: Record "Qlty. Inspect. Source Config.";
        FieldConfig: Record "Qlty. Inspect. Src. Fld. Conf.";
        Inspection: Record "Qlty. Inspection Header";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if CopyStr(FixtureCode, 1, 3) <> 'XQ3' then
            Error('Only XQ3 fixtures are permitted.');
        SavedSetup.Code := FixtureCode;
        SavedSetup."Setup Existed" := QualitySetup.Get();
        SavedSetup."Previous Series" := QualitySetup."Quality Inspection Nos.";
        SavedSetup."Previous Creation Option" := QualitySetup."Inspection Creation Option".AsInteger();
        SavedSetup.Insert(false);
        if not SavedSetup."Setup Existed" then
            QualitySetup.Insert(false);
        NoSeries.Code := FixtureCode;
        NoSeries."Default Nos." := true;
        NoSeries.Insert(false);
        NoSeriesLine."Series Code" := FixtureCode;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := CopyStr(FixtureCode, 1, 14) + '000001';
        NoSeriesLine."Ending No." := CopyStr(FixtureCode, 1, 14) + '999999';
        NoSeriesLine."Increment-by No." := 1;
        NoSeriesLine.Open := true;
        NoSeriesLine.Insert(false);
        QualitySetup."Quality Inspection Nos." := FixtureCode;
        QualitySetup."Inspection Creation Option" := QualitySetup."Inspection Creation Option"::"Always create new inspection";
        QualitySetup.Modify(false);
        Item."No." := FixtureCode;
        Item.Description := 'XQ3 owned source';
        Item.Insert(false);
        InspectionTemplate.Code := FixtureCode;
        InspectionTemplate.Insert(false);
        QualityTest.Code := FixtureCode;
        QualityTest.Description := 'XQ3 owned measurement';
        QualityTest."Test Value Type" := QualityTest."Test Value Type"::"Value Type Text";
        QualityTest.Insert(false);
        InspectionTemplateLine."Template Code" := FixtureCode;
        InspectionTemplateLine."Line No." := 10000;
        InspectionTemplateLine."Test Code" := FixtureCode;
        InspectionTemplateLine.Description := QualityTest.Description;
        InspectionTemplateLine.Insert(false);
        GenerationRule.LockTable();
        if GenerationRule.FindLast() then
            GenerationRule."Entry No." += 1
        else
            GenerationRule."Entry No." := 1;
        GenerationRule."Template Code" := FixtureCode;
        GenerationRule."Source Table No." := Database::Item;
        Item.SetRecFilter();
        GenerationRule."Condition Filter" := CopyStr(Item.GetView(false), 1, MaxStrLen(GenerationRule."Condition Filter"));
        GenerationRule."Activation Trigger" := GenerationRule."Activation Trigger"::"Manual only";
        GenerationRule.Insert(false);
        SourceConfig.Code := FixtureCode;
        SourceConfig.Enabled := true;
        SourceConfig."From Table No." := Database::Item;
        SourceConfig."From Table Filter" := CopyStr(Item.GetView(false), 1, MaxStrLen(SourceConfig."From Table Filter"));
        SourceConfig."To Table No." := Database::"Qlty. Inspection Header";
        SourceConfig."To Type" := SourceConfig."To Type"::Inspection;
        SourceConfig.Insert(false);
        FieldConfig.Code := FixtureCode;
        FieldConfig."From Table No." := Database::Item;
        FieldConfig."To Table No." := Database::"Qlty. Inspection Header";
        FieldConfig."Line No." := 10000;
        FieldConfig."From Field No." := Item.FieldNo("No.");
        FieldConfig."To Field No." := Inspection.FieldNo("Source Item No.");
        FieldConfig."To Type" := FieldConfig."To Type"::Inspection;
        FieldConfig.Insert(false);
    end;

    /// <summary>Deletes only the owned fixture and restores the exact setup fields changed by seeding.</summary>
    procedure CleanupFixture(FixtureCode: Code[20])
    var
        SavedSetup: Record "Quality Create Fixture ori";
        QualitySetup: Record "Qlty. Management Setup";
        Item: Record Item;
        InspectionTemplate: Record "Qlty. Inspection Template Hdr.";
        InspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QualityTest: Record "Qlty. Test";
        GenerationRule: Record "Qlty. Inspection Gen. Rule";
        SourceConfig: Record "Qlty. Inspect. Source Config.";
        FieldConfig: Record "Qlty. Inspect. Src. Fld. Conf.";
        Inspection: Record "Qlty. Inspection Header";
        InspectionLine: Record "Qlty. Inspection Line";
        ResultCondition: Record "Qlty. I. Result Condit. Conf.";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if CopyStr(FixtureCode, 1, 3) <> 'XQ3' then
            Error('Only XQ3 fixtures are permitted.');
        SavedSetup.Get(FixtureCode);
        Inspection.SetRange("Template Code", FixtureCode);
        if Inspection.FindSet() then
            repeat
                InspectionLine.SetRange("Inspection No.", Inspection."No.");
                InspectionLine.DeleteAll(false);
                ResultCondition.SetRange("Condition Type", ResultCondition."Condition Type"::Inspection);
                ResultCondition.SetRange("Target Code", Inspection."No.");
                ResultCondition.DeleteAll(false);
            until Inspection.Next() = 0;
        Inspection.DeleteAll(false);
        GenerationRule.SetRange("Template Code", FixtureCode);
        GenerationRule.DeleteAll(false);
        FieldConfig.SetRange(Code, FixtureCode);
        FieldConfig.DeleteAll(false);
        SourceConfig.Get(FixtureCode);
        SourceConfig.Delete(false);
        InspectionTemplateLine.SetRange("Template Code", FixtureCode);
        InspectionTemplateLine.DeleteAll(false);
        ResultCondition.Reset();
        ResultCondition.SetRange("Test Code", FixtureCode);
        ResultCondition.DeleteAll(false);
        if QualityTest.Get(FixtureCode) then
            QualityTest.Delete(false);
        InspectionTemplate.Get(FixtureCode);
        InspectionTemplate.Delete(false);
        Item.Get(FixtureCode);
        Item.Delete(false);
        QualitySetup.Get();
        if SavedSetup."Setup Existed" then begin
            QualitySetup."Quality Inspection Nos." := SavedSetup."Previous Series";
            QualitySetup."Inspection Creation Option" := Enum::"Qlty. Inspect. Creation Option".FromInteger(SavedSetup."Previous Creation Option");
            QualitySetup.Modify(false);
        end else
            QualitySetup.Delete(false);
        NoSeriesLine.SetRange("Series Code", FixtureCode);
        NoSeriesLine.DeleteAll(false);
        NoSeries.Get(FixtureCode);
        NoSeries.Delete(false);
        SavedSetup.Delete(false);
        Commit();
    end;

    /// <summary>Handles the native inspection card opened in interactive test sessions.</summary>
    [PageHandler]
    procedure InspectionPageHandler(var InspectionPage: TestPage "Qlty. Inspection")
    begin
        InspectionPage.Close();
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
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Quality.Inspection.Create", Enum::"Message Version ori"::"1.0", '', 'quality3-tests', 'application/json', RequestContent, TaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
    end;

    local procedure ReadOptionalError(Response: JsonObject): Text
    var
        Token: JsonToken;
    begin
        if Response.Get('error', Token) then
            exit(Token.AsValue().AsText());
    end;

    local procedure ReadText(Response: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Response.Get(PropertyName, Token), 'Missing property: ' + PropertyName);
        exit(Token.AsValue().AsText());
    end;
}
