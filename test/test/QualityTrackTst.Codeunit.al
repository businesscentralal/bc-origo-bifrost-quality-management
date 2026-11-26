namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Origo.Bifrost;
using Origo.Bifrost.QualityManagement;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Issue 17: item tracking change through the standard disposition, prepared or posted, with typed refusals, rollback, count handling and role checks.</summary>
codeunit 97280 "Quality Track Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        PriorSetup: Record "Qlty. Management Setup";
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        FixtureCode: Code[10];
        TemplateCode: Code[10];
        HadSetup: Boolean;
        HadBifrostSetup: Boolean;
        ChangedBifrostSetup: Boolean;
        PriorAllowFrom: Date;
        PriorAllowTo: Date;
        PriorIrreversibleConfirm: Boolean;
        LotTxt: Label 'Q17LOT1', Locked = true;
        NewLotTxt: Label 'Q17-NEWLOT', Locked = true;
        SerialTxt: Label 'Q17SN1', Locked = true;
        NewSerialTxt: Label 'Q17SN2', Locked = true;

    /// <summary>The ordinal of the new enum value is pinned.</summary>
    [Test]
    procedure Scenario_AC01_Ordinal_IsPinned()
    begin
        // Story #17, AC01 | Time: none | Risk: read only
        Assert.AreEqual(10035310, Enum::"Message Type ori"::"Quality.Disposition.ChangeItemTracking".AsInteger(), 'The enum ordinal must never change.');
    end;

    /// <summary>Discovery declares an irreversible, non-idempotent write with the app role and both help languages.</summary>
    [Test]
    procedure Scenario_AC01_Discovery_DeclaresIrreversibleEffect()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Effect: JsonObject;
        Token: JsonToken;
        Overview: Text;
    begin
        // Story #17, AC01 | Time: none | Risk: read only
        Initialize();
        Assert.IsTrue(ContractMgt.GetContract(Enum::"Message Type ori"::"Quality.Disposition.ChangeItemTracking", Contract), 'Registered type must have a contract.');
        Contract.Get('effect', Token);
        Effect := Token.AsObject();
        Assert.AreEqual('irreversible', ReadText(Effect, 'effect'), 'Posting makes the type irreversible.');
        Effect.Get('idempotent', Token);
        Assert.IsFalse(Token.AsValue().AsBoolean(), 'A repeat changes stock again.');
        Assert.AreEqual('BIFROST QM Full ori', ReadText(Effect, 'permissionSet'), 'Contract must name the app role.');
        Assert.IsTrue(ReadText(Effect, 'changes').Contains('The expectedCount unit is the one quality inspection'), 'effect.changes must name the count unit.');
        Assert.IsTrue(Contract.Contains('overview'), 'The help chapter is required.');
        Overview := OverviewIn(1039);
        Assert.IsTrue(Overview.Contains('Breytir lotu-'), 'The is-IS overview must be translated.');
        Overview := OverviewIn(1033);
        Assert.IsTrue(Overview.Contains('Changes the lot'), 'The en-US overview must be present.');
    end;

    /// <summary>Prepare only leaves a reclassification line carrying the new lot and writes no ledger entry.</summary>
    [Test]
    procedure Scenario_AC02_PrepareLot_LeavesLineWithNewLot()
    begin
        // Story #17, AC02 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('prepareLot', 1033);
    end;

    /// <summary>Prepare only in Icelandic leaves a line carrying the new expiration date.</summary>
    [Test]
    procedure Scenario_AC02_PrepareExpiryIcelandic_LeavesLineWithNewDate()
    begin
        // Story #17, AC02 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('prepareExpiry', 1039);
    end;

    /// <summary>Prepare only on a serial-tracked item carries the new serial number.</summary>
    [Test]
    procedure Scenario_AC02_PrepareSerial_LeavesLineWithNewSerial()
    begin
        // Story #17, AC02 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('prepareSerial', 1033);
    end;

    /// <summary>The passed basis uses the inspection pass quantity.</summary>
    [Test]
    procedure Scenario_AC02_PassedBasis_UsesPassQuantity()
    begin
        // Story #17, AC02 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('passed', 1033);
    end;

    /// <summary>An explicit quantity overrides the basis quantity.</summary>
    [Test]
    procedure Scenario_AC02_ExplicitQuantity_UsesQuantity()
    begin
        // Story #17, AC02 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('quantity', 1033);
    end;

    /// <summary>Posting writes entries that carry the new lot.</summary>
    [Test]
    procedure Scenario_AC02_PostLot_EntriesCarryNewLot()
    begin
        // Story #17, AC02 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('postLot', 1033);
    end;

    /// <summary>Posting writes entries that carry the new expiration date.</summary>
    [Test]
    procedure Scenario_AC02_PostExpiry_EntriesCarryNewDate()
    begin
        // Story #17, AC02 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('postExpiry', 1033);
    end;

    /// <summary>Microsoft refuses a new expiration date for part of a lot; nothing remains.</summary>
    [Test]
    procedure Scenario_AC03_PartialLotExpiry_LeavesNothing()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('partialExpiry', 1033);
    end;

    /// <summary>No new value is refused with a typed error.</summary>
    [Test]
    procedure Scenario_AC03_NoNewValue_TypedRefusal()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('noValue', 1033);
    end;

    /// <summary>No new value is refused with Icelandic guidance.</summary>
    [Test]
    procedure Scenario_AC03_NoNewValueIcelandic_TypedRefusal()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('noValue', 1039);
    end;

    /// <summary>A lot number over 50 characters is refused.</summary>
    [Test]
    procedure Scenario_AC03_LongLot_TypedRefusal()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('longLot', 1033);
    end;

    /// <summary>A package number over 50 characters is refused.</summary>
    [Test]
    procedure Scenario_AC03_LongPackage_TypedRefusal()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('longPackage', 1033);
    end;

    /// <summary>An impossible date is refused.</summary>
    [Test]
    procedure Scenario_AC03_InvalidDate_TypedRefusal()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('badDate', 1033);
    end;

    /// <summary>A locale date form is refused.</summary>
    [Test]
    procedure Scenario_AC03_LocaleDate_TypedRefusal()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('localeDate', 1033);
    end;

    /// <summary>A missing inspection SystemId is refused.</summary>
    [Test]
    procedure Scenario_AC03_MissingId_TypedRefusal()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('missingId', 1039);
    end;

    /// <summary>A malformed inspection SystemId is refused.</summary>
    [Test]
    procedure Scenario_AC03_MalformedId_TypedRefusal()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('malformedId', 1033);
    end;

    /// <summary>confirm=false is refused.</summary>
    [Test]
    procedure Scenario_AC03_ConfirmFalse_TypedRefusal()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('confirm', 1033);
    end;

    /// <summary>An unknown key is refused.</summary>
    [Test]
    procedure Scenario_AC03_UnknownKey_TypedRefusal()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('unknown', 1033);
    end;

    /// <summary>Filter syntax in a source code is refused.</summary>
    [Test]
    procedure Scenario_AC03_FilterSyntax_TypedRefusal()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('filter', 1033);
    end;

    /// <summary>An unknown inspection is refused.</summary>
    [Test]
    procedure Scenario_AC03_UnknownInspection_TypedRefusal()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('notFound', 1033);
    end;

    /// <summary>A zero quantity is refused.</summary>
    [Test]
    procedure Scenario_AC03_ZeroQuantity_TypedRefusal()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('zero', 1033);
    end;

    /// <summary>An inspection without tracking is refused before any change.</summary>
    [Test]
    procedure Scenario_AC03_UntrackedInspection_TypedRefusal()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('untracked', 1033);
    end;

    /// <summary>Microsoft's missing reclassification batch refusal leaves nothing.</summary>
    [Test]
    procedure Scenario_AC03_MissingBatch_LeavesNothing()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('noBatch', 1033);
    end;

    /// <summary>Posting without stock is refused and leaves nothing.</summary>
    [Test]
    procedure Scenario_AC03_InsufficientStock_LeavesNothing()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('insufficient', 1033);
    end;

    /// <summary>A failure after line creation rolls the line back.</summary>
    [Test]
    procedure Scenario_AC03_LateFailure_RollsBackLine()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('late', 1033);
    end;

    /// <summary>A failure after posting rolls lines and entries back.</summary>
    [Test]
    procedure Scenario_AC03_LatePostFailure_RollsBackEntries()
    begin
        // Story #17, AC03 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('latePost', 1033);
    end;

    /// <summary>expectedCount other than 1 is refused before any change.</summary>
    [Test]
    procedure Scenario_AC04_CountMismatch_RefusesBeforeChange()
    begin
        // Story #17, AC04 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('count', 1033);
    end;

    /// <summary>Omitting expectedCount with confirmation required reads the count and changes nothing.</summary>
    [Test]
    procedure Scenario_AC04_OmittedCount_PreviewsWithoutChange()
    begin
        // Story #17, AC04 | Time: none | Risk: owned Q17 fixtures only; Bifrost Setup flag restored
        VerifyScenario('preview', 1033);
    end;

    /// <summary>A caller without the app role is refused.</summary>
    [Test]
    procedure Scenario_AC05_NoAppRole_Refused()
    begin
        // Story #17, AC05 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('permission', 1033);
    end;

    /// <summary>The read role is refused.</summary>
    [Test]
    procedure Scenario_AC05_ReadRole_Refused()
    begin
        // Story #17, AC05 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('readRole', 1033);
    end;

    /// <summary>The Full role alone does not replace native item journal permissions.</summary>
    [Test]
    procedure Scenario_AC05_FullRoleWithoutNativePermissions_Refused()
    begin
        // Story #17, AC05 | Time: none | Risk: owned Q17 fixtures only
        VerifyScenario('nativePermission', 1033);
    end;

    local procedure VerifyScenario(Scenario: Text; LanguageId: Integer)
    var
        Inspection: Record "Qlty. Inspection Header";
        Setup: Record "Qlty. Management Setup";
        Fault: Codeunit "Quality Track Fault ori";
        Request: JsonObject;
        Response: JsonObject;
        ResponseText: Text;
        ExpectSuccess: Boolean;
        Serial: Boolean;
    begin
        // [GIVEN] All business fixtures are created for this test: unit, tracking code, item, location, journal batch, stock and inspection.
        Initialize();
        Serial := Scenario = 'prepareSerial';
        CreateFixture(Inspection, Serial);
        if Scenario <> 'insufficient' then
            SeedStock(Inspection, Serial);
        Request.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Request.Add('quantityBasis', 'failed');
        Request.Add('sourceLocationCode', FixtureCode);
        Request.Add('confirm', true);
        Request.Add('expectedCount', 1);
        if Serial then
            Request.Add('newSerialNo', NewSerialTxt)
        else
            if not (Scenario in ['prepareExpiry', 'postExpiry', 'partialExpiry', 'noValue']) then
                Request.Add('newLotNo', NewLotTxt);
        if Scenario in ['prepareExpiry', 'postExpiry', 'partialExpiry'] then
            Request.Add('newExpirationDate', '2027-06-30');
        if Scenario = 'postExpiry' then begin
            // Microsoft changes the expiration date of a lot only for its whole remaining quantity.
            Inspection."Fail Quantity" := 5;
            Inspection."Pass Quantity" := 0;
            Inspection.Modify(false);
        end;
        if Scenario in ['postLot', 'postExpiry', 'partialExpiry', 'insufficient', 'latePost'] then
            Request.Add('postImmediately', true);
        ExpectSuccess := Scenario in ['prepareLot', 'prepareExpiry', 'prepareSerial', 'passed', 'quantity', 'postLot', 'postExpiry'];
        case Scenario of
            'passed':
                Request.Replace('quantityBasis', 'passed');
            'quantity':
                Request.Add('quantity', 1);
            'count':
                Request.Replace('expectedCount', 2);
            'preview':
                begin
                    Request.Remove('expectedCount');
                    RequireIrreversibleConfirm();
                end;
            'longLot':
                Request.Replace('newLotNo', PadStr('', 51, 'L'));
            'longPackage':
                Request.Add('newPackageNo', PadStr('', 51, 'P'));
            'badDate':
                Request.Add('newExpirationDate', '2027-13-45');
            'localeDate':
                Request.Add('newExpirationDate', '30.06.2027');
            'missingId':
                Request.Remove('inspectionSystemId');
            'malformedId':
                Request.Replace('inspectionSystemId', 'not-a-guid');
            'notFound':
                Request.Replace('inspectionSystemId', Format(CreateGuid(), 0, 4));
            'confirm':
                Request.Replace('confirm', false);
            'unknown':
                Request.Add('unexpected', true);
            'filter':
                Request.Replace('sourceLocationCode', '*');
            'zero':
                Request.Add('quantity', 0);
            'untracked':
                begin
                    Inspection."Source Lot No." := '';
                    Inspection.Modify(false);
                end;
            'noBatch':
                begin
                    Setup.Get();
                    Setup."Item Reclass. Batch Name" := '';
                    Setup.Modify(false);
                end;
        end;
        Commit();
        if Scenario in ['permission', 'readRole', 'nativePermission'] then begin
            LowerPermissions.SetExactPermissionSet('BIFROST API ori');
            LowerPermissions.AddPermissionSet('QM Move Test ori');
            if Scenario = 'nativePermission' then
                LowerPermissions.AddPermissionSet('BIFROST QM Full ori')
            else
                LowerPermissions.AddPermissionSet('QltyMgmt - Inspector');
            if Scenario = 'readRole' then
                LowerPermissions.AddPermissionSet('BIFROST QM Read ori');
        end;
        if Scenario = 'latePost' then
            Fault.SetPostingFault();
        if Scenario in ['late', 'latePost'] then
            BindSubscription(Fault);
        // [WHEN] The real dispatcher executes the standard disposition.
        Response := Dispatch(Request, LanguageId);
        if Scenario in ['late', 'latePost'] then
            UnbindSubscription(Fault);
        LowerPermissions.SetOutsideO365Scope();
        Response.WriteTo(ResponseText);
        // [THEN] The result matches the request, or nothing remains.
        if ExpectSuccess then begin
            if ReadText(Response, 'status') <> 'Success' then
                Assert.Fail(ResponseText);
            if Scenario in ['postLot', 'postExpiry'] then
                VerifyPosted(Response, Scenario)
            else
                VerifyPrepared(Response, Scenario);
        end else begin
            Assert.AreEqual('Error', ReadText(Response, 'status'), 'The operation must return a refusal: ' + ResponseText);
            Assert.AreEqual(0, OwnedLineCount(), 'A refusal must leave no reclassification lines.');
            Assert.AreEqual(0, OwnedReservationCount(), 'A refusal must leave no tracking lines.');
            Assert.AreEqual(0, TransferEntryCount(), 'A refusal must leave no entries.');
            if Scenario in ['noValue', 'longLot', 'longPackage', 'badDate', 'localeDate', 'missingId', 'malformedId', 'notFound', 'confirm', 'unknown', 'filter', 'zero', 'untracked', 'permission', 'readRole'] then
                VerifyTyped(Response, Scenario, LanguageId);
            case Scenario of
                'late':
                    Assert.IsTrue(ResponseText.Contains('Q17 late failure'), 'The fault must occur after real line creation.');
                'latePost':
                    begin
                        Assert.IsTrue(ResponseText.Contains('Q17 late posting failure'), 'The refusal must occur after real standard posting.');
                        Assert.AreEqual(5, LotQuantity(LotTxt), 'A late refusal must preserve the original lot.');
                    end;
                'count':
                    Assert.IsTrue(ResponseText.Contains('ConfirmationMismatch'), 'A wrong count must be a confirmation mismatch: ' + ResponseText);
                'preview':
                    Assert.IsTrue(ResponseText.Contains('ConfirmationRequired'), 'An omitted count must return the preview: ' + ResponseText);
                'partialExpiry':
                    begin
                        Assert.IsTrue(ResponseText.Contains('New Expiration Date'), 'Microsoft must refuse the partial expiry change: ' + ResponseText);
                        Assert.AreEqual(5, LotQuantity(LotTxt), 'The lot must keep its stock.');
                    end;
                'nativePermission':
                    Assert.IsFalse(ResponseText.Contains('BIFROST QM Full ori permission set is required'), 'The app role is present; the refusal must come from native permissions.');
            end;
        end;
        Cleanup(Inspection);
    end;

    local procedure VerifyPrepared(Response: JsonObject; Scenario: Text)
    var
        Reservation: Record "Reservation Entry";
        JournalLine: Record "Item Journal Line";
        Line: JsonObject;
    begin
        Assert.AreEqual(1, OwnedLineCount(), 'Standard disposition must create exactly one owned line.');
        FilterOwnedLines(JournalLine);
        JournalLine.FindFirst();
        Assert.AreEqual(JournalLine."Entry Type"::Transfer, JournalLine."Entry Type", 'The line must be a reclassification.');
        Assert.AreEqual(FixtureCode, JournalLine."Item No.", 'Only the inspection item may be reclassified.');
        Assert.AreEqual(ExpectedQuantity(Scenario), JournalLine.Quantity, 'The line quantity must follow the request.');
        FilterOwnedReservations(Reservation);
        Assert.IsTrue(Reservation.FindFirst(), 'The line must carry its tracking.');
        case Scenario of
            'prepareExpiry':
                Assert.AreEqual(DMY2Date(30, 6, 2027), Reservation."New Expiration Date", 'The tracking line must carry the new expiration date.');
            'prepareSerial':
                Assert.AreEqual(NewSerialTxt, Reservation."New Serial No.", 'The tracking line must carry the new serial number.');
            else
                Assert.AreEqual(NewLotTxt, Reservation."New Lot No.", 'The tracking line must carry the new lot number.');
        end;
        Assert.AreEqual(0, TransferEntryCount(), 'Preparing must write no item ledger entry.');
        Assert.AreEqual(1, ReadArrayCount(Response, 'journalLines'), 'The response must list the line created.');
        Assert.AreEqual(0, ReadArrayCount(Response, 'ledgerEntries'), 'The response must list no entry.');
        Line := FirstArrayObject(Response, 'journalLines');
        case Scenario of
            'prepareExpiry':
                Assert.AreEqual('2027-06-30', ReadText(Line, 'newExpirationDate'), 'The response must show the new date.');
            'prepareSerial':
                Assert.AreEqual(NewSerialTxt, ReadText(Line, 'newSerialNo'), 'The response must show the new serial number.');
            else
                Assert.AreEqual(NewLotTxt, ReadText(Line, 'newLotNo'), 'The response must show the new lot number.');
        end;
        Assert.IsFalse(ReadBoolean(Response, 'posted'), 'Prepare only must report posted=false.');
    end;

    local procedure VerifyPosted(Response: JsonObject; Scenario: Text)
    var
        Ledger: Record "Item Ledger Entry";
    begin
        Assert.AreEqual(0, OwnedLineCount(), 'Posting must not leave a reclassification line.');
        Assert.AreEqual(2, TransferEntryCount(), 'Posting writes one outbound and one inbound transfer entry.');
        Assert.AreEqual(2, ReadArrayCount(Response, 'ledgerEntries'), 'The response must list the entries created.');
        Assert.IsTrue(ReadBoolean(Response, 'posted'), 'Posting must report posted=true.');
        Ledger.SetRange("Item No.", FixtureCode);
        Ledger.SetRange("Entry Type", Ledger."Entry Type"::Transfer);
        Ledger.SetRange(Positive, true);
        Ledger.FindFirst();
        if Scenario = 'postLot' then begin
            Assert.AreEqual(3, Ledger.Quantity, 'The failed quantity is reclassified.');
            Assert.AreEqual(NewLotTxt, Ledger."Lot No.", 'The posted entry must carry the new lot.');
            Assert.AreEqual(3, LotQuantity(NewLotTxt), 'The new lot holds the failed quantity.');
            Assert.AreEqual(2, LotQuantity(LotTxt), 'The original lot keeps the rest.');
        end else begin
            Assert.AreEqual(5, Ledger.Quantity, 'The whole lot is reclassified.');
            Assert.AreEqual(LotTxt, Ledger."Lot No.", 'An expiry change keeps the lot.');
            Assert.AreEqual(DMY2Date(30, 6, 2027), Ledger."Expiration Date", 'The posted entry must carry the new expiration date.');
        end;
    end;

    local procedure ExpectedQuantity(Scenario: Text): Decimal
    begin
        case Scenario of
            'passed':
                exit(2);
            'quantity', 'prepareSerial':
                exit(1);
            else
                exit(3);
        end;
    end;

    local procedure VerifyTyped(Response: JsonObject; Scenario: Text; LanguageId: Integer)
    var
        Expected: Text;
    begin
        case Scenario of
            'noValue', 'longLot':
                Expected := 'newLotNo';
            'longPackage':
                Expected := 'newPackageNo';
            'badDate', 'localeDate':
                Expected := 'newExpirationDate';
            'missingId', 'malformedId', 'notFound', 'untracked':
                Expected := 'inspectionSystemId';
            'confirm':
                Expected := 'confirm';
            'unknown':
                Expected := 'unexpected';
            'filter':
                Expected := 'sourceLocationCode';
            'zero':
                Expected := 'quantity';
            'permission', 'readRole':
                Expected := 'permissionSet';
        end;
        Assert.AreEqual(Expected, ReadText(Response, 'parameter'), 'Identify the invalid parameter.');
        Assert.IsTrue(ReadText(Response, 'expected') <> '', 'Describe what is expected.');
        Assert.IsTrue(ReadText(Response, 'nextStep') <> '', 'Give a next step.');
        if LanguageId = 1039 then
            case Scenario of
                'missingId':
                    Assert.IsTrue(ReadText(Response, 'nextStep').Contains('Lestu'), 'Recovery guidance must be Icelandic.');
                'noValue':
                    Assert.IsTrue(ReadText(Response, 'nextStep').Contains('Sendu newLotNo'), 'Recovery guidance must be Icelandic.');
            end;
    end;

    local procedure Initialize()
    begin
        LowerPermissions.SetOutsideO365Scope();
    end;

    local procedure OverviewIn(LanguageId: Integer) Overview: Text
    var
        TrackImpl: Codeunit "Quality Track Impl ori";
        PriorLanguage: Integer;
    begin
        PriorLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        TrackImpl.GetOverview(Overview);
        GlobalLanguage(PriorLanguage);
    end;

    local procedure RequireIrreversibleConfirm()
    var
        BifrostSetup: Record "Setup ori";
    begin
        // The field is internal to Foundation; the test reaches it by number on its own tenant and restores it.
        HadBifrostSetup := BifrostSetup.Get();
        if not HadBifrostSetup then begin
            BifrostSetup.Init();
            BifrostSetup.Insert(false);
        end;
        ChangedBifrostSetup := true;
        PriorIrreversibleConfirm := SetIrreversibleConfirm(true);
    end;

    local procedure SetIrreversibleConfirm(NewValue: Boolean) PriorValue: Boolean
    var
        SetupRef: RecordRef;
        ConfirmField: FieldRef;
    begin
        SetupRef.Open(Database::"Setup ori");
        SetupRef.FindFirst();
        ConfirmField := SetupRef.Field(36);
        Assert.AreEqual('Require Irreversible Confirm', ConfirmField.Name(), 'Foundation field 36 must be the irreversible confirmation flag.');
        PriorValue := ConfirmField.Value();
        ConfirmField.Value(NewValue);
        SetupRef.Modify(false);
        SetupRef.Close();
    end;

    local procedure CreateFixture(var Inspection: Record "Qlty. Inspection Header"; Serial: Boolean)
    var
        Item: Record Item;
        Unit: Record "Unit of Measure";
        ItemUnit: Record "Item Unit of Measure";
        TrackingCode: Record "Item Tracking Code";
        Location: Record Location;
        JournalTemplate: Record "Item Journal Template";
        JournalBatch: Record "Item Journal Batch";
        Setup: Record "Qlty. Management Setup";
        GLSetup: Record "General Ledger Setup";
    begin
        FixtureCode := CopyStr('Q17-' + DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 10);
        // Posting happens at the work date; a company posting window must not decide the outcome. Restored in Cleanup.
        GLSetup.Get();
        PriorAllowFrom := GLSetup."Allow Posting From";
        PriorAllowTo := GLSetup."Allow Posting To";
        GLSetup."Allow Posting From" := 0D;
        GLSetup."Allow Posting To" := 0D;
        GLSetup.Modify(false);
        Unit.Code := FixtureCode;
        Unit.Insert(false);
        TrackingCode.Code := FixtureCode;
        if Serial then
            TrackingCode."SN Specific Tracking" := true
        else begin
            TrackingCode."Lot Specific Tracking" := true;
            TrackingCode."Use Expiration Dates" := true;
        end;
        TrackingCode.Insert(false);
        Item."No." := FixtureCode;
        Item.Description := FixtureCode;
        Item."Base Unit of Measure" := FixtureCode;
        Item."Item Tracking Code" := FixtureCode;
        Item.Insert(false);
        ItemUnit."Item No." := FixtureCode;
        ItemUnit.Code := FixtureCode;
        ItemUnit."Qty. per Unit of Measure" := 1;
        ItemUnit.Insert(false);
        Location.Code := FixtureCode;
        Location.Insert(false);
        // Microsoft selects the standard reclassification template; use the one it will find.
        JournalTemplate.SetRange(Type, JournalTemplate.Type::Transfer);
        JournalTemplate.SetRange("Page ID", Page::"Item Reclass. Journal");
        JournalTemplate.SetRange(Recurring, false);
        JournalTemplate.FindFirst();
        TemplateCode := JournalTemplate.Name;
        JournalBatch."Journal Template Name" := TemplateCode;
        JournalBatch.Name := FixtureCode;
        JournalBatch.Insert(false);
        HadSetup := Setup.Get();
        if HadSetup then
            PriorSetup := Setup
        else
            Setup.Insert(false);
        Setup."Item Reclass. Batch Name" := FixtureCode;
        Setup.Modify(false);
        Inspection."No." := FixtureCode;
        Inspection."Source Item No." := FixtureCode;
        Inspection."Location Code" := FixtureCode;
        if Serial then begin
            Inspection."Source Serial No." := SerialTxt;
            Inspection."Source Quantity (Base)" := 1;
            Inspection."Fail Quantity" := 1;
        end else begin
            Inspection."Source Lot No." := LotTxt;
            Inspection."Source Quantity (Base)" := 5;
            Inspection."Fail Quantity" := 3;
            Inspection."Pass Quantity" := 2;
        end;
        Inspection.Insert(false);
    end;

    local procedure SeedStock(Inspection: Record "Qlty. Inspection Header"; Serial: Boolean)
    var
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
        JournalLine: Record "Item Journal Line";
        Tracking: Record "Reservation Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        GLAccount."No." := FixtureCode;
        GLAccount.Name := FixtureCode;
        GLAccount."Direct Posting" := true;
        GLAccount.Insert(false);
        SourceCode.Code := FixtureCode;
        SourceCode.Insert(false);
        InventoryPostingGroup.Code := FixtureCode;
        InventoryPostingGroup.Insert(false);
        GenProductPostingGroup.Code := FixtureCode;
        GenProductPostingGroup.Insert(false);
        GeneralPostingSetup."Gen. Prod. Posting Group" := FixtureCode;
        GeneralPostingSetup."Inventory Adjmt. Account" := FixtureCode;
        GeneralPostingSetup."Direct Cost Applied Account" := FixtureCode;
        GeneralPostingSetup."COGS Account" := FixtureCode;
        GeneralPostingSetup.Insert(false);
        InventoryPostingSetup.Init();
        InventoryPostingSetup."Location Code" := FixtureCode;
        InventoryPostingSetup."Invt. Posting Group Code" := FixtureCode;
        InventoryPostingSetup."Inventory Account" := FixtureCode;
        InventoryPostingSetup.Insert(false);
        Item.Get(FixtureCode);
        Item."Inventory Posting Group" := FixtureCode;
        Item."Gen. Prod. Posting Group" := FixtureCode;
        Item.Modify(false);
        JournalLine."Journal Template Name" := TemplateCode;
        JournalLine."Journal Batch Name" := FixtureCode;
        JournalLine."Line No." := 1000;
        JournalLine."Entry Type" := JournalLine."Entry Type"::"Positive Adjmt.";
        JournalLine.Validate("Posting Date", WorkDate());
        JournalLine."Document No." := Inspection."No.";
        JournalLine.Validate("Item No.", FixtureCode);
        JournalLine.Validate("Location Code", FixtureCode);
        if Serial then
            JournalLine.Validate(Quantity, 1)
        else
            JournalLine.Validate(Quantity, 5);
        // Standard posting reads tracking from the line's reservation entry, as the Item Tracking Lines page creates it.
        Tracking."Entry No." := NextReservationEntryNo();
        Tracking.Positive := true;
        Tracking."Item No." := FixtureCode;
        Tracking."Location Code" := FixtureCode;
        Tracking."Reservation Status" := Tracking."Reservation Status"::Prospect;
        Tracking."Source Type" := Database::"Item Journal Line";
        Tracking."Source Subtype" := JournalLine."Entry Type"::"Positive Adjmt.".AsInteger();
        Tracking."Source ID" := TemplateCode;
        Tracking."Source Batch Name" := FixtureCode;
        Tracking."Source Ref. No." := JournalLine."Line No.";
        Tracking."Qty. per Unit of Measure" := 1;
        Tracking.Quantity := JournalLine.Quantity;
        Tracking."Quantity (Base)" := JournalLine.Quantity;
        Tracking."Qty. to Handle (Base)" := JournalLine.Quantity;
        Tracking."Qty. to Invoice (Base)" := JournalLine.Quantity;
        Tracking."Creation Date" := WorkDate();
        if Serial then
            Tracking."Serial No." := SerialTxt
        else begin
            Tracking."Lot No." := LotTxt;
            Tracking."Expiration Date" := DMY2Date(31, 1, 2027);
        end;
        Tracking.UpdateItemTracking();
        Tracking.Insert(false);
        JournalLine."Source Code" := FixtureCode;
        ItemJnlPostLine.RunWithCheck(JournalLine);
        Tracking.SetRange("Item No.", FixtureCode);
        Tracking.SetRange("Source Type", Database::"Item Journal Line");
        Tracking.DeleteAll(false);
    end;

    local procedure NextReservationEntryNo(): Integer
    var
        Reservation: Record "Reservation Entry";
    begin
        if Reservation.FindLast() then
            exit(Reservation."Entry No." + 1);
        exit(1);
    end;

    local procedure FilterOwnedLines(var JournalLine: Record "Item Journal Line")
    begin
        JournalLine.SetRange("Journal Template Name", TemplateCode);
        JournalLine.SetRange("Journal Batch Name", FixtureCode);
        JournalLine.SetFilter("Item No.", '<>%1', '');
    end;

    local procedure FilterOwnedReservations(var Reservation: Record "Reservation Entry")
    begin
        Reservation.SetRange("Item No.", FixtureCode);
        Reservation.SetRange("Source Type", Database::"Item Journal Line");
    end;

    local procedure OwnedLineCount(): Integer
    var
        JournalLine: Record "Item Journal Line";
    begin
        FilterOwnedLines(JournalLine);
        exit(JournalLine.Count());
    end;

    local procedure OwnedReservationCount(): Integer
    var
        Reservation: Record "Reservation Entry";
    begin
        FilterOwnedReservations(Reservation);
        exit(Reservation.Count());
    end;

    local procedure TransferEntryCount(): Integer
    var
        Ledger: Record "Item Ledger Entry";
    begin
        Ledger.SetRange("Item No.", FixtureCode);
        Ledger.SetRange("Entry Type", Ledger."Entry Type"::Transfer);
        exit(Ledger.Count());
    end;

    local procedure LotQuantity(LotNo: Code[50]): Decimal
    var
        Ledger: Record "Item Ledger Entry";
    begin
        Ledger.SetRange("Item No.", FixtureCode);
        Ledger.SetRange("Lot No.", LotNo);
        Ledger.CalcSums(Quantity);
        exit(Ledger.Quantity);
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
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Quality.Disposition.ChangeItemTracking", Enum::"Message Version ori"::"1.0", '', 'quality17-tests', 'application/json', RequestContent, TaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
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

    local procedure ReadBoolean(Response: JsonObject; PropertyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Response.Get(PropertyName, Token), 'Response property missing: ' + PropertyName);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure ReadArrayCount(Response: JsonObject; PropertyName: Text): Integer
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Response.Get(PropertyName, Token), 'Response property missing: ' + PropertyName);
        exit(Token.AsArray().Count());
    end;

    local procedure FirstArrayObject(Response: JsonObject; PropertyName: Text): JsonObject
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Response.Get(PropertyName, Token), 'Response property missing: ' + PropertyName);
        Token.AsArray().Get(0, Token);
        exit(Token.AsObject());
    end;

    local procedure Cleanup(Inspection: Record "Qlty. Inspection Header")
    var
        Item: Record Item;
        Unit: Record "Unit of Measure";
        ItemUnit: Record "Item Unit of Measure";
        TrackingCode: Record "Item Tracking Code";
        Location: Record Location;
        JournalLine: Record "Item Journal Line";
        JournalBatch: Record "Item Journal Batch";
        Reservation: Record "Reservation Entry";
        Setup: Record "Qlty. Management Setup";
        BifrostSetup: Record "Setup ori";
        GLSetup: Record "General Ledger Setup";
    begin
        if CopyStr(FixtureCode, 1, 4) <> 'Q17-' then
            Error('Only owned Q17 fixtures may be removed.');
        GLSetup.Get();
        GLSetup."Allow Posting From" := PriorAllowFrom;
        GLSetup."Allow Posting To" := PriorAllowTo;
        GLSetup.Modify(false);
        FilterOwnedReservations(Reservation);
        Reservation.DeleteAll(false);
        JournalLine.SetRange("Journal Template Name", TemplateCode);
        JournalLine.SetRange("Journal Batch Name", FixtureCode);
        JournalLine.DeleteAll(false);
        JournalBatch.SetRange("Journal Template Name", TemplateCode);
        JournalBatch.SetRange(Name, FixtureCode);
        JournalBatch.DeleteAll(false);
        if Inspection.Find() then
            Inspection.Delete(false);
        ItemUnit.SetRange("Item No.", FixtureCode);
        ItemUnit.DeleteAll(false);
        Item.Get(FixtureCode);
        Item.Delete(false);
        TrackingCode.Get(FixtureCode);
        TrackingCode.Delete(false);
        Unit.Get(FixtureCode);
        Unit.Delete(false);
        Location.Get(FixtureCode);
        Location.Delete(false);
        if HadSetup then begin
            Setup.Get();
            Setup."Item Reclass. Batch Name" := PriorSetup."Item Reclass. Batch Name";
            Setup.Modify(false);
        end else
            if Setup.Get() then
                Setup.Delete(false);
        if ChangedBifrostSetup and BifrostSetup.Get() then
            if HadBifrostSetup then
                SetIrreversibleConfirm(PriorIrreversibleConfirm)
            else
                BifrostSetup.Delete(false);
        ChangedBifrostSetup := false;
    end;
}
