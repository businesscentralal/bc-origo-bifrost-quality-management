namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Issue 16: standard put-away creation, refusals, count gate, permissions and rollback through Dispatcher.</summary>
codeunit 97276 "Quality PutAway Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>Verifies internal through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_Internal()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('internal');
    end;

    /// <summary>Verifies released through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_Released()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('released');
    end;

    /// <summary>Verifies warehouse through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_Warehouse()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('warehouse');
    end;

    /// <summary>Verifies passed through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_Passed()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('passed');
    end;

    /// <summary>Verifies quantity through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_Quantity()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('quantity');
    end;

    /// <summary>Verifies icelandic through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_Icelandic()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('icelandic');
    end;

    /// <summary>Verifies missingId through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_MissingId()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('missingId');
    end;

    /// <summary>Verifies malformedId through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_MalformedId()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('malformedId');
    end;

    /// <summary>Verifies nullId through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_NullId()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('nullId');
    end;

    /// <summary>Verifies numberId through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_NumberId()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('numberId');
    end;

    /// <summary>Verifies unknownId through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_UnknownId()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('unknownId');
    end;

    /// <summary>Verifies missingKind through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_MissingKind()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('missingKind');
    end;

    /// <summary>Verifies invalidKind through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_InvalidKind()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('invalidKind');
    end;

    /// <summary>Verifies releaseWarehouse through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_ReleaseWarehouse()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('releaseWarehouse');
    end;

    /// <summary>Verifies falseReleaseWarehouse through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_FalseReleaseWarehouse()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('falseReleaseWarehouse');
    end;

    /// <summary>Verifies missingConfirm through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_MissingConfirm()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('missingConfirm');
    end;

    /// <summary>Verifies falseConfirm through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_FalseConfirm()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('falseConfirm');
    end;

    /// <summary>Verifies invalidBoolean through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_InvalidBoolean()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('invalidBoolean');
    end;

    /// <summary>Verifies unknownKey through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_UnknownKey()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('unknownKey');
    end;

    /// <summary>Verifies filter through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_Filter()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('filter');
    end;

    /// <summary>Verifies binFilter through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_BinFilter()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('binFilter');
    end;

    /// <summary>Verifies rangeFilter through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_RangeFilter()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('rangeFilter');
    end;

    /// <summary>Verifies zero through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_ZeroInspection()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('zero');
    end;

    /// <summary>Verifies zeroQuantity through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_ZeroQuantity()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('zeroQuantity');
    end;

    /// <summary>Verifies tooMuchQuantity through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_TooMuchQuantity()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('tooMuchQuantity');
    end;

    /// <summary>Verifies stringQuantity through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_StringQuantity()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('stringQuantity');
    end;

    /// <summary>Verifies invalidBasis through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_InvalidBasis()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('invalidBasis');
    end;

    /// <summary>Verifies longLocation through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_LongLocation()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('longLocation');
    end;

    /// <summary>Verifies longBin through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_LongBin()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('longBin');
    end;

    /// <summary>Verifies noStock through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_NoStock()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('noStock');
    end;

    /// <summary>Verifies noBins through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_NoBins()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('noBins');
    end;

    /// <summary>Verifies nonWarehouse through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_NonWarehouse()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('nonWarehouse');
    end;

    /// <summary>Verifies late through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_LateFailure()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('late');
    end;

    /// <summary>Verifies lateWarehouse through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC03_LateWarehouseFailure()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('lateWarehouse');
    end;

    /// <summary>Verifies count through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC04_WrongCount()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('count');
    end;

    /// <summary>Verifies preview through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC04_Preview()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('preview');
    end;

    /// <summary>Verifies baseRole through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC05_BaseRole()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('baseRole');
    end;

    /// <summary>Verifies readRole through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC05_ReadRole()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('readRole');
    end;

    /// <summary>Verifies noNative through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC05_NoNativePermissions()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('noNative');
    end;

    /// <summary>Verifies fullRole through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC05_FullRole()
    begin
        // Story #16 | Time: WorkDate | Risk: self-seeded warehouse fixtures; isolated test runner restores setup.
        VerifyScenario('fullRole');
    end;

    /// <summary>Pins the new published enum ordinal.</summary>
    [Test]
    procedure Scenario_AC01_Ordinal()
    begin
        Assert.AreEqual(10035306, Enum::"Message Type ori"::"Quality.Disposition.CreatePutAway".AsInteger(), 'Published ordinal must remain stable.');
    end;

    local procedure VerifyScenario(Scenario: Text)
    var
        Inspection: Record "Qlty. Inspection Header";
        Location: Record Location;
        SourceBin: Record Bin;
        InternalHeader: Record "Whse. Internal Put-away Header";
        InternalLine: Record "Whse. Internal Put-away Line";
        WarehouseHeader: Record "Warehouse Activity Header";
        WarehouseLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        Fixture: Codeunit "Quality PutAway Fixture ori";
        Fault: Codeunit "Quality PutAway Fault ori";
        Request: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
        DocumentToken: JsonToken;
        ExpectedSuccess: Boolean;
        LanguageId: Integer;
        InitialEntries: Integer;
    begin
        LowerPermissions.SetOutsideO365Scope();
        Fixture.Seed(Inspection, Location, SourceBin);
        Request.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Request.Add('kind', 'internal');
        Request.Add('quantityBasis', 'failed');
        Request.Add('sourceLocationCode', Location.Code);
        Request.Add('sourceBinCode', SourceBin.Code);
        Request.Add('confirm', true);
        Request.Add('expectedCount', 1);
        ExpectedSuccess := Scenario in ['internal', 'released', 'warehouse', 'passed', 'quantity', 'icelandic', 'fullRole'];
        LanguageId := 1033;
        case Scenario of
            'released': Request.Add('releaseImmediately', true);
            'warehouse', 'lateWarehouse': Request.Replace('kind', 'warehouse');
            'passed': Request.Replace('quantityBasis', 'passed');
            'quantity': Request.Add('quantity', 1);
            'icelandic': LanguageId := 1039;
            'missingId': Request.Remove('inspectionSystemId');
            'malformedId': Request.Replace('inspectionSystemId', 'invalid-guid');
            'nullId': Request.Replace('inspectionSystemId', '00000000-0000-0000-0000-000000000000');
            'numberId': Request.Replace('inspectionSystemId', 17);
            'unknownId': Request.Replace('inspectionSystemId', Format(CreateGuid(), 0, 4));
            'missingKind': Request.Remove('kind');
            'invalidKind': Request.Replace('kind', 'invalid');
            'releaseWarehouse', 'falseReleaseWarehouse': begin
                Request.Replace('kind', 'warehouse');
                Request.Add('releaseImmediately', Scenario = 'releaseWarehouse');
            end;
            'missingConfirm': Request.Remove('confirm');
            'falseConfirm': Request.Replace('confirm', false);
            'invalidBoolean': Request.Add('releaseImmediately', 'true');
            'unknownKey': Request.Add('unexpected', true);
            'filter': Request.Replace('sourceLocationCode', '*');
            'binFilter': Request.Replace('sourceBinCode', 'A|B');
            'rangeFilter': Request.Replace('sourceLocationCode', 'A..B');
            'zero': begin
                Inspection."Fail Quantity" := 0;
                Inspection.Modify(false);
            end;
            'zeroQuantity': Request.Add('quantity', 0);
            'tooMuchQuantity': Request.Add('quantity', 4);
            'stringQuantity': Request.Add('quantity', '1');
            'invalidBasis': Request.Replace('quantityBasis', 'all');
            'longLocation': Request.Replace('sourceLocationCode', PadStr('x', 11, 'x'));
            'longBin': Request.Replace('sourceBinCode', PadStr('x', 21, 'x'));
            'noStock': begin
                WarehouseEntry.SetRange("Item No.", Inspection."Source Item No.");
                WarehouseEntry.DeleteAll(false);
            end;
            'noBins': Request.Replace('sourceBinCode', 'DOES-NOT-EXIST');
            'nonWarehouse': begin
                Location."Directed Put-away and Pick" := false;
                Location.Modify(false);
            end;
            'count': Request.Replace('expectedCount', 0);
            'preview': Request.Remove('expectedCount');
        end;
        WarehouseEntry.SetRange("Item No.", Inspection."Source Item No.");
        InitialEntries := WarehouseEntry.Count();
        Commit();
        case Scenario of
            'baseRole', 'readRole', 'fullRole', 'noNative': begin
                LowerPermissions.SetExactPermissionSet('BIFROST API ori');
                LowerPermissions.AddPermissionSet('QM PutAway Test ori');
                if Scenario = 'readRole' then
                    LowerPermissions.AddPermissionSet('BIFROST QM Read ori');
                if Scenario in ['fullRole', 'noNative'] then
                    LowerPermissions.AddPermissionSet('BIFROST QM Full ori');
                if Scenario = 'fullRole' then
                    LowerPermissions.AddPermissionSet('D365 BUS FULL ACCESS');
                    LowerPermissions.AddPermissionSet('D365 WHSE, EDIT');
            end;
        end;
        if Scenario in ['late', 'lateWarehouse'] then
            BindSubscription(Fault);
        Response := Dispatch(Request, LanguageId);
        if Scenario in ['late', 'lateWarehouse'] then
            UnbindSubscription(Fault);
        LowerPermissions.SetOutsideO365Scope();
        InternalHeader.SetRange("Location Code", Location.Code);
        WarehouseHeader.SetRange("Location Code", Location.Code);
        if ExpectedSuccess then begin
            Assert.AreEqual('Success', ReadText(Response, 'status'), Format(Response));
            Assert.IsTrue(Response.Get('documentNumbers', Token), 'Document numbers must be returned.');
            Assert.IsTrue(Token.AsArray().Count() > 0, 'At least one final document is required.');
            Token.AsArray().Get(0, DocumentToken);
            if Scenario = 'warehouse' then begin
                Assert.IsTrue(WarehouseHeader.Get(WarehouseHeader.Type::"Put-away", DocumentToken.AsValue().AsText()), 'Returned warehouse put-away must exist.');
                WarehouseLine.SetRange("Activity Type", WarehouseHeader.Type);
                WarehouseLine.SetRange("No.", WarehouseHeader."No.");
                Assert.IsFalse(WarehouseLine.IsEmpty(), 'Warehouse document must have lines.');
            end else begin
                Assert.IsTrue(InternalHeader.Get(DocumentToken.AsValue().AsText()), 'Returned internal put-away must exist.');
                if Scenario = 'released' then
                    Assert.AreEqual(InternalHeader.Status::Released, InternalHeader.Status, 'Release requested.')
                else
                    Assert.AreEqual(InternalHeader.Status::Open, InternalHeader.Status, 'Open by default.');
                InternalLine.SetRange("No.", InternalHeader."No.");
                InternalLine.FindFirst();
                case Scenario of
                    'passed': Assert.AreEqual(2, InternalLine.Quantity, 'Passed quantity.');
                    'quantity': Assert.AreEqual(1, InternalLine.Quantity, 'Explicit quantity.');
                    else
                        Assert.AreEqual(3, InternalLine.Quantity, 'Failed quantity.');
                end;
            end;
            Assert.AreEqual('false', ReadText(Response, 'registered'), 'Never register.');
        end else begin
            Assert.AreEqual('Error', ReadText(Response, 'status'), Format(Response));
            Assert.IsTrue(InternalHeader.IsEmpty(), 'Refusal rolls back internal documents.');
            Assert.IsTrue(WarehouseHeader.IsEmpty(), 'Refusal rolls back warehouse documents.');
            if Scenario in ['late', 'lateWarehouse'] then
                Assert.IsTrue(ReadText(Response, 'error').Contains('Q16 injected late failure'), 'Prove the native line insert was reached.');
            if not (Scenario in ['noStock', 'noBins', 'nonWarehouse', 'late', 'lateWarehouse', 'baseRole', 'readRole', 'noNative', 'preview', 'count']) then begin
                Assert.IsTrue(ReadText(Response, 'parameter') <> '', 'Typed parameter required.');
                Assert.IsTrue(ReadText(Response, 'expected') <> '', 'Typed expectation required.');
                Assert.IsTrue(ReadText(Response, 'nextStep') <> '', 'Typed recovery required.');
            end;
            if Scenario = 'preview' then
                Assert.AreEqual('ConfirmationRequired', ReadText(Response, 'code'), 'Preview must use count protocol.');
            if Scenario = 'count' then
                Assert.AreEqual('ConfirmationMismatch', ReadText(Response, 'code'), 'Mismatch must use count protocol.');
        end;
        Assert.AreEqual(InitialEntries, WarehouseEntry.Count(), 'No warehouse stock registration or posting.');
        Fixture.Cleanup(Inspection, Location);
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
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Quality.Disposition.CreatePutAway", Enum::"Message Version ori"::"1.0", '', 'quality16-tests', 'application/json', RequestContent, TaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
    end;

    local procedure ReadText(Response: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Response.Get(PropertyName, Token), 'Missing response field ' + PropertyName);
        exit(Token.AsValue().AsText());
    end;
}
