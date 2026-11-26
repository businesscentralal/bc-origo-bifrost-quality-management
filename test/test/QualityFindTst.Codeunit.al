namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Document;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Verifies issue 9 through the public dispatcher with self-seeded and removed native fixtures.</summary>
codeunit 97260 "Quality Find Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>Verifies AC02_DefaultLatest through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_DefaultLatest()
    begin
        // Story #9, AC02 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('latest');
    end;

    /// <summary>Verifies AC02_AllReinspections through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_AllReinspections()
    begin
        // Story #9, AC02 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('all');
    end;

    /// <summary>Verifies AC02_ItemMatch through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_ItemMatch()
    begin
        // Story #9, AC02 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('item');
    end;

    /// <summary>Verifies AC02_TrackingMatch through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_TrackingMatch()
    begin
        // Story #9, AC02 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('tracking');
    end;

    /// <summary>Verifies AC02_CombinedMatch through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_CombinedMatch()
    begin
        // Story #9, AC02 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('combined');
    end;

    /// <summary>Verifies AC03_EmptyResult through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_EmptyResult()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('empty');
    end;

    /// <summary>Verifies AC03_UnknownRecord through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_UnknownRecord()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('notFound');
    end;

    /// <summary>Verifies AC03_MissingTable through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_MissingTable()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('missingTable');
    end;

    /// <summary>Verifies AC03_MissingId through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_MissingId()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('missingId');
    end;

    /// <summary>Verifies AC03_MissingMatch through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_MissingMatch()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('missingMatch');
    end;

    /// <summary>Verifies AC03_EmptyMatch through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_EmptyMatch()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('emptyMatch');
    end;

    /// <summary>Verifies AC03_UnknownMatch through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_UnknownMatch()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('unknownMatch');
    end;

    /// <summary>Verifies AC03_WrongMatchType through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_WrongMatchType()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('wrongMatch');
    end;

    /// <summary>Verifies AC03_NullMatch through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_NullMatch()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('nullMatch');
    end;

    /// <summary>Verifies AC03_WrongMatchMember through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_WrongMatchMember()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('wrongMember');
    end;

    /// <summary>Verifies AC03_BadGuid through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_BadGuid()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('badGuid');
    end;

    /// <summary>Verifies AC03_ZeroGuid through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_ZeroGuid()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('zeroGuid');
    end;

    /// <summary>Verifies AC03_ZeroTable through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_ZeroTable()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('zeroTable');
    end;

    /// <summary>Verifies AC03_StringTable through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_StringTable()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('stringTable');
    end;

    /// <summary>Verifies AC03_UnknownTable through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_UnknownTable()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('unknownTable');
    end;

    /// <summary>Verifies AC03_WrongBoolean through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_WrongBoolean()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('badBoolean');
    end;

    /// <summary>Verifies AC03_UnknownKey through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_UnknownKey()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('unknown');
    end;

    /// <summary>Verifies AC03_UnknownFirst through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_UnknownFirst()
    begin
        // Story #9, AC03 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('unknownFirst');
    end;

    /// <summary>Verifies AC05_ReadRole through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC05_ReadRole()
    begin
        // Story #9, AC05 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('read');
    end;

    /// <summary>Verifies AC05_NativeReadDenied through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC05_NativeReadDenied()
    begin
        // Story #9, AC05 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('denied');
    end;

    /// <summary>Verifies AC04_NoChanges through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC04_NoChanges()
    begin
        // Story #9, AC04 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('unchanged');
    end;

    /// <summary>Verifies AC02_Limit100 through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_Limit100()
    begin
        // Story #9, AC02 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('limit100');
    end;

    /// <summary>Verifies AC02_Limit101 through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_Limit101()
    begin
        // Story #9, AC02 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('limit101');
    end;

    /// <summary>Verifies AC06_Icelandic through the dispatcher.</summary>
    [Test]
    procedure Scenario_AC06_Icelandic()
    begin
        // Story #9, AC06 | Time: SystemCreatedAt ordering; WorkDate ignored | Risk: owned fixtures only
        VerifyScenario('icelandic');
    end;

    /// <summary>Checks discovery, stable ordinal and both contract languages.</summary>
    [Test]
    procedure Scenario_AC01_ReadDiscovery()
    var
        Discovery: Interface "Msg Interface ori";
        Contract: Interface "Msg Contract ori";
        Effect: JsonObject;
        Token: JsonToken;
        Parameters: JsonArray;
        Overview: Text;
        English: Text;
        PreviousLanguage: Integer;
    begin
        // Story #9, AC01 | Time: none | Risk: enum ordinal is public
        Assert.AreEqual(10035291, Enum::"Message Type ori"::"Quality.Inspection.FindForRecord".AsInteger(), 'Pin the published ordinal.');
        Discovery := Enum::"Message Type ori"::"Quality.Inspection.FindForRecord";
        Assert.AreEqual(Enum::"Msg Direction ori"::Outbound, Discovery.GetMessageDirection(), 'Discovery is read/outbound.');
        Contract := Enum::"Message Type ori"::"Quality.Inspection.FindForRecord";
        Assert.IsTrue(Contract.GetEffect(Effect), 'Effect exists.');
        Effect.Get('effect', Token);
        Assert.AreEqual('read', Token.AsValue().AsText(), 'Foundation classifies a read.');
        Assert.IsTrue(Contract.GetParameters(Parameters), 'Parameters exist.');
        Assert.AreEqual(4, Parameters.Count(), 'Four declared inputs.');
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        Contract.GetOverview(English);
        GlobalLanguage(1039);
        Contract.GetOverview(Overview);
        GlobalLanguage(PreviousLanguage);
        Assert.AreNotEqual(English, Overview, 'Contract must be translated.');
    end;

    local procedure VerifyScenario(Scenario: Text)
    var
        Source: Record "Quality Find Source ori";
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        Rows: JsonArray;
        Token: JsonToken;
        First: JsonObject;
        BeforeState: Text;
        ExpectedCode: Text;
        ExpectedParameter: Text;
        LanguageId: Integer;
        Index: Integer;
    begin
        LowerPermissions.SetOutsideO365Scope();
        Cleanup();
        Seed(Source);
        Request.Add('tableId', Database::"Quality Find Source ori");
        Request.Add('systemId', Format(Source.SystemId, 0, 4));
        Rows.Add('document');
        Request.Add('matchOn', Rows);
        LanguageId := 1033;
        ExpectedCode := 'InvalidParameter';
        ExpectedParameter := 'matchOn';
        case Scenario of
            'all': Request.Add('latestOnly', false);
        end;
        if Scenario in ['item', 'tracking', 'combined'] then begin
            Clear(Rows);
            if Scenario in ['item', 'combined'] then
                Rows.Add('item');
            if Scenario in ['tracking', 'combined'] then
                Rows.Add('tracking');
            Request.Replace('matchOn', Rows);
        end;
        case Scenario of
            'empty': begin
                Inspection.SetRange("Source Document No.", 'XQ9-DOC');
                Inspection.DeleteAll(false);
            end;
            'notFound': begin
                Request.Replace('systemId', Format(CreateGuid(), 0, 4));
                ExpectedCode := 'RecordNotFound';
                ExpectedParameter := 'systemId';
            end;
            'missingTable': begin
                Request.Remove('tableId');
                ExpectedCode := 'MissingParameter';
                ExpectedParameter := 'tableId';
            end;
            'missingId': begin
                Request.Remove('systemId');
                ExpectedCode := 'MissingParameter';
                ExpectedParameter := 'systemId';
            end;
            'missingMatch': begin
                Request.Remove('matchOn');
                ExpectedCode := 'MissingParameter';
            end;
            'emptyMatch': begin
                Clear(Rows);
                Request.Replace('matchOn', Rows);
            end;
            'unknownMatch': begin
                Clear(Rows);
                Rows.Add('unknown');
                Request.Replace('matchOn', Rows);
            end;
            'wrongMatch': Request.Replace('matchOn', 'document');
            'nullMatch': begin
                Token.ReadFrom('null');
                Request.Replace('matchOn', Token);
            end;
            'wrongMember': begin
                Clear(Rows);
                Rows.Add(1);
                Request.Replace('matchOn', Rows);
            end;
            'badGuid', 'zeroGuid': begin
                if Scenario = 'badGuid' then
                    Request.Replace('systemId', 'not-a-guid')
                else
                    Request.Replace('systemId', '00000000-0000-0000-0000-000000000000');
                ExpectedParameter := 'systemId';
            end;
            'zeroTable', 'unknownTable', 'stringTable': begin
                case Scenario of
                    'zeroTable': Request.Replace('tableId', 0);
                    'unknownTable': Request.Replace('tableId', 2147483647);
                    'stringTable': Request.Replace('tableId', '97262');
                end;
                ExpectedParameter := 'tableId';
            end;
            'badBoolean': begin
                Request.Add('latestOnly', 'true');
                ExpectedParameter := 'latestOnly';
            end;
            'unknown', 'unknownFirst': begin
                Request.Add('typo', true);
                if Scenario = 'unknownFirst' then
                    Request.Remove('tableId');
                ExpectedCode := 'UnknownParameter';
                ExpectedParameter := 'typo';
            end;
            'icelandic': LanguageId := 1039;
            'denied': begin
                ExpectedCode := 'PermissionDenied';
                ExpectedParameter := 'permissionSet';
            end;
            'limit100', 'limit101': begin
                Inspection.SetRange("Source Document No.", 'XQ9-DOC');
                Inspection.DeleteAll(false);
                for Index := 1 to 100 do
                    InsertInspection('XQ9-' + Format(Index, 0, '<Integer,3><Filler Character,0>'), 0, true);
                if Scenario = 'limit101' then
                    InsertInspection('XQ9-101', 0, true);
            end;
        end;
        BeforeState := Snapshot();
        // Real Foundation Read role and separate native permissions; no Full role is assigned.
        LowerPermissions.SetExactPermissionSet('BIFROST Read ori');
        LowerPermissions.AddPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet('QM Find Test ori');
        if Scenario <> 'denied' then
            LowerPermissions.AddPermissionSet('QM Find Read ori');
        Response := Dispatch(Request, LanguageId);
        LowerPermissions.SetOutsideO365Scope();
        Assert.AreEqual(BeforeState, Snapshot(), 'No header or line count, SystemId or modification time may change.');
        if Scenario in ['latest', 'all', 'item', 'tracking', 'combined', 'empty', 'read', 'unchanged', 'limit100', 'limit101', 'icelandic'] then begin
            Assert.AreEqual('Success', ReadText(Response, 'status'), 'Read must succeed: ' + Format(Response));
            Response.Get('inspections', Token);
            Rows := Token.AsArray();
            case Scenario of
                'empty': Assert.AreEqual(0, Rows.Count(), 'No match is an empty success.');
                'all': Assert.AreEqual(3, Rows.Count(), 'Include superseded re-inspections.');
                'limit100', 'limit101': Assert.AreEqual(100, Rows.Count(), 'Return at most 100 rows.');
                else Assert.AreEqual(2, Rows.Count(), 'Only latest re-inspections by default.');
            end;
            Response.Get('truncated', Token);
            Assert.AreEqual(Scenario = 'limit101', Token.AsValue().AsBoolean(), 'Truncated only above the boundary.');
            if not (Scenario in ['empty', 'limit100', 'limit101']) then begin
                Rows.Get(0, Token);
                First := Token.AsObject();
                Assert.AreEqual('XQ9-Z', ReadText(First, 'no'), 'Newest re-inspection first.');
                First.Get('reinspectionNo', Token);
                Assert.AreEqual(1, Token.AsValue().AsInteger(), 'Most recent revision first.');
                Rows.Get(1, Token);
                First := Token.AsObject();
                Assert.AreEqual('XQ9-A', ReadText(First, 'no'), 'Creation time precedes document number.');
                Assert.AreEqual('Open', ReadText(First, 'status'), 'Stable English enum name.');
                Assert.AreEqual('PASS', ReadText(First, 'result'), 'Result is the native code.');
            end;
        end else begin
            Assert.AreEqual('Error', ReadText(Response, 'status'), 'Typed refusal required: ' + Format(Response));
            Assert.AreEqual(ExpectedCode, ReadText(Response, 'code'), 'Stable refusal code: ' + Format(Response));
            Assert.AreEqual(ExpectedParameter, ReadText(Response, 'parameter'), 'Parameter must identify the refusal.');
            Assert.AreNotEqual('', ReadText(Response, 'expected'), 'Expected input is required.');
            Assert.AreNotEqual('', ReadText(Response, 'nextStep'), 'Next step is required.');
        end;
        Cleanup();
    end;

    local procedure Seed(var Source: Record "Quality Find Source ori")
    var
        Item: Record Item;
        Config: Record "Qlty. Inspect. Source Config.";
        Inspection: Record "Qlty. Inspection Header";
    begin
        Source.Init();
        Source."No." := 'XQ9-DOC';
        Source."Item No." := 'XQ9-ITEM';
        Source."Lot No." := 'XQ9-LOT';
        Source.Insert(false);
        Item."No." := Source."Item No.";
        Item.Insert(false);
        Config.Code := 'XQ9';
        Config.Enabled := true;
        Config."From Table No." := Database::"Quality Find Source ori";
        Config."To Table No." := Database::"Qlty. Inspection Header";
        Config."To Type" := Config."To Type"::Inspection;
        Config.Insert(false);
        MapField(10000, Source.FieldNo("No."), Inspection.FieldNo("Source Document No."));
        MapField(20000, Source.FieldNo("Item No."), Inspection.FieldNo("Source Item No."));
        MapField(30000, Source.FieldNo("Lot No."), Inspection.FieldNo("Source Lot No."));
        InsertInspection('XQ9-Z', 0, false);
        Sleep(5);
        InsertInspection('XQ9-A', 0, true);
        Sleep(5);
        InsertInspection('XQ9-Z', 1, true);
    end;

    local procedure MapField(LineNo: Integer; FromField: Integer; ToField: Integer)
    var
        Mapping: Record "Qlty. Inspect. Src. Fld. Conf.";
    begin
        Mapping.Code := 'XQ9';
        Mapping."From Table No." := Database::"Quality Find Source ori";
        Mapping."To Table No." := Database::"Qlty. Inspection Header";
        Mapping."Line No." := LineNo;
        Mapping."From Field No." := FromField;
        Mapping."To Field No." := ToField;
        Mapping."To Type" := Mapping."To Type"::Inspection;
        Mapping.Insert(false);
    end;

    local procedure InsertInspection(Number: Code[20]; Revision: Integer; Latest: Boolean)
    var
        Inspection: Record "Qlty. Inspection Header";
        Line: Record "Qlty. Inspection Line";
    begin
        Inspection."No." := Number;
        Inspection."Re-inspection No." := Revision;
        Inspection."Most Recent Re-inspection" := Latest;
        Inspection."Source Document No." := 'XQ9-DOC';
        Inspection."Source Item No." := 'XQ9-ITEM';
        Inspection."Source Lot No." := 'XQ9-LOT';
        Inspection."Result Code" := 'PASS';
        Inspection.Insert(false);
        Line."Inspection No." := Number;
        Line."Re-inspection No." := Revision;
        Line."Line No." := 10000;
        Line.Insert(false);
    end;

    local procedure Cleanup()
    var
        Item: Record Item;
        Source: Record "Quality Find Source ori";
        Config: Record "Qlty. Inspect. Source Config.";
        Mapping: Record "Qlty. Inspect. Src. Fld. Conf.";
        Inspection: Record "Qlty. Inspection Header";
        Line: Record "Qlty. Inspection Line";
    begin
        Line.SetFilter("Inspection No.", 'XQ9-*');
        Line.DeleteAll(false);
        Inspection.SetFilter("No.", 'XQ9-*');
        Inspection.DeleteAll(false);
        Mapping.SetRange(Code, 'XQ9');
        Mapping.DeleteAll(false);
        Config.SetRange(Code, 'XQ9');
        Config.DeleteAll(false);
        Source.SetRange("No.", 'XQ9-DOC');
        Source.DeleteAll(false);
        Item.SetRange("No.", 'XQ9-ITEM');
        Item.DeleteAll(false);
    end;

    local procedure Snapshot() State: Text
    var
        Inspection: Record "Qlty. Inspection Header";
        Line: Record "Qlty. Inspection Line";
    begin
        Inspection.SetLoadFields(SystemId, SystemModifiedAt);
        Line.SetLoadFields(SystemId, SystemModifiedAt);
        State := Format(Inspection.Count(), 0, 9) + '/' + Format(Line.Count(), 0, 9);
        if Inspection.FindSet() then
            repeat
                State += Format(Inspection.SystemId, 0, 4) + Format(Inspection.SystemModifiedAt, 0, 9);
            until Inspection.Next() = 0;
        if Line.FindSet() then
            repeat
                State += Format(Line.SystemId, 0, 4) + Format(Line.SystemModifiedAt, 0, 9);
            until Line.Next() = 0;
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
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Quality.Inspection.FindForRecord", Enum::"Message Version ori"::"1.0", '', 'quality9-tests', 'application/json', RequestContent, TaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
    end;

    local procedure ReadText(Response: JsonObject; Name: Text): Text
    var
        Token: JsonToken;
    begin
        if Response.Get(Name, Token) then
            exit(Token.AsValue().AsText());
    end;
}
