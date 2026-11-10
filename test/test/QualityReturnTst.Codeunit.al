namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.QualityManagement.Document;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Verifies purchase return dispositions through the public dispatcher with owned synthetic receipt fixtures.</summary>
codeunit 97210 "Quality Return Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>Verifies HappyEnglish against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_HappyEnglish()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('happy', 1033);
    end;

    /// <summary>Verifies HappyIcelandic against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_HappyIcelandic()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('happy', 1039);
    end;

    /// <summary>Verifies MissingKey against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_MissingKey()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('missing', 1033);
    end;

    /// <summary>Verifies UnknownKey against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_UnknownKey()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('unknown', 1033);
    end;

    /// <summary>Verifies MalformedGuid against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_MalformedGuid()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('guid', 1033);
    end;

    /// <summary>Verifies UnknownInspection against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_UnknownInspection()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('notFound', 1033);
    end;

    /// <summary>Verifies WrongSource against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_WrongSource()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('source', 1033);
    end;

    /// <summary>Verifies ZeroFailedQuantity against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_ZeroFailedQuantity()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('zero', 1033);
    end;

    /// <summary>Verifies MissingReceipt against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_MissingReceipt()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('receipt', 1033);
    end;

    /// <summary>Verifies BlockedVendor against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_BlockedVendor()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('blocked', 1033);
    end;

    /// <summary>Verifies InvalidReasonRollsBack against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_InvalidReasonRollsBack()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('reason', 1033);
    end;

    /// <summary>Verifies LateFailureRollsBack against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_LateFailureRollsBack()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('late', 1033);
    end;

    /// <summary>Verifies ReadRoleRefused against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_ReadRoleRefused()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('permission', 1033);
    end;

    /// <summary>Verifies NoAppGrantRefused against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_NoAppGrantRefused()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('noApp', 1033);
    end;

    /// <summary>Verifies LongReason against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_LongReason()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('longReason', 1033);
    end;

    /// <summary>Verifies LongCredit against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_LongCredit()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('longCredit', 1033);
    end;

    /// <summary>Verifies NonTextOption against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_NonTextOption()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('option', 1033);
    end;

    /// <summary>Verifies IcelandicRefusal against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_IcelandicRefusal()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('missing', 1039);
    end;

    /// <summary>Verifies OptionalKeysOmitted against issue 13 acceptance.</summary>
    [Test]
    procedure Scenario_OptionalKeysOmitted()
    begin
        // #13 AC01–AC08 | Time: no date-dependent assertion | Risk: owned demonstration fixtures only.
        VerifyScenario('optional', 1033);
    end;

    /// <summary>Refuses a standard event-handled no-op without reporting success.</summary>
    [Test]
    procedure Scenario_NoOpIsRefused()
    begin
        // #13 AC03/AC04 | Time: independent of dates | Risk: owned fixtures only.
        VerifyScenario('noop', 1033);
    end;

    /// <summary>Prohibits an explicit subscriber commit after native writes and rolls them back.</summary>
    [Test]
    procedure Scenario_SubscriberCommitRollsBack()
    begin
        // #13 AC01/AC04 | Time: independent of dates | Risk: owned fixtures only.
        VerifyScenario('commit', 1033);
    end;

    local procedure VerifyScenario(Scenario: Text; LanguageId: Integer)
    var
        Inspection: Record "Qlty. Inspection Header";
        ReturnHeader: Record "Purchase Header";
        ReturnLine: Record "Purchase Line";
        Vendor: Record Vendor;
        ReceiptLine: Record "Purch. Rcpt. Line";
        Fault: Codeunit "Quality Return Fault ori";
        Request: JsonObject;
        Response: JsonObject;
        RunCode: Code[20];
    begin
        // [GIVEN] An owned purchase receipt for ten units and an inspection with three failed units.
        LowerPermissions.SetOutsideO365Scope();
        RunCode := CopyStr('BIFTQ13-' + DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 20);
        SeedFixture(RunCode, Inspection);
        Request.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Request.Add('reasonCode', CopyStr(RunCode, 9, 10));
        Request.Add('vendorCreditMemoNo', RunCode);
        case Scenario of
            'missing': Request.Remove('inspectionSystemId');
            'unknown': Request.Add('unexpected', true);
            'guid': Request.Replace('inspectionSystemId', 'invalid');
            'notFound': Request.Replace('inspectionSystemId', Format(CreateGuid(), 0, 4));
            'source': begin
                Inspection."Source Table No." := Database::Vendor;
                Inspection.Modify(false);
            end;
            'zero': begin
                Inspection."Fail Quantity" := 0;
                Inspection.Modify(false);
            end;
            'receipt': begin
                Inspection."Source Document Line No." := 99999;
                Inspection.Modify(false);
            end;
            'blocked': begin
                ReceiptLine.Get(RunCode, 10000);
                Vendor.Get(ReceiptLine."Buy-from Vendor No.");
                Vendor.Blocked := Vendor.Blocked::All;
                Vendor.Modify(false);
            end;
            'reason': Request.Replace('reasonCode', 'NO-SUCH');
            'longReason': Request.Replace('reasonCode', PadStr('x', 11, 'x'));
            'longCredit': Request.Replace('vendorCreditMemoNo', PadStr('x', 36, 'x'));
            'option': Request.Replace('reasonCode', 1);
            'optional': begin
                Request.Remove('reasonCode');
                Request.Remove('vendorCreditMemoNo');
            end;
        end;
        Commit();
        if Scenario in ['late', 'noop', 'commit'] then begin
            Fault.SetMode(Scenario);
            BindSubscription(Fault);
        end;
        case Scenario of
            'permission': LowerPermissions.SetExactPermissionSet('BIFROST Read ori');
            'noApp': begin
                LowerPermissions.SetExactPermissionSet('BIFROST API ori');
                LowerPermissions.AddPermissionSet('QltyMgmt - Inspector');
                LowerPermissions.AddPermissionSet('D365 PURCH DOC, EDIT');
            end;
            else begin
                LowerPermissions.SetExactPermissionSet('D365 BASIC');
                LowerPermissions.AddPermissionSet('BIFROST Full ori');
                LowerPermissions.AddPermissionSet('D365 PURCH DOC, EDIT');
            end;
        end;
        LowerPermissions.AddPermissionSet('QM Return Test ori');
        // [WHEN] The public dispatcher performs the real Microsoft disposition.
        Response := Dispatch(Request, LanguageId);
        if Scenario in ['late', 'noop', 'commit'] then
            UnbindSubscription(Fault);
        LowerPermissions.SetOutsideO365Scope();
        // [THEN] It creates exactly the failed quantity, or refuses without leaving any return header/line.
        ReturnHeader.SetRange("Document Type", ReturnHeader."Document Type"::"Return Order");
        ReceiptLine.Get(RunCode, 10000);
        ReturnHeader.SetRange("Buy-from Vendor No.", ReceiptLine."Buy-from Vendor No.");
        if Scenario in ['happy', 'optional'] then begin
            if ReadText(Response, 'status') <> 'Success' then
                Assert.Fail(ReadText(Response, 'error'));
            Assert.AreEqual(1, ReturnHeader.Count(), 'Exactly one return must be created.');
            ReturnHeader.FindFirst();
            Assert.AreEqual(ReturnHeader."No.", ReadText(Response, 'returnOrderNo'), 'Return number must come from the standard result.');
            ReturnLine.SetRange("Document Type", ReturnHeader."Document Type");
            ReturnLine.SetRange("Document No.", ReturnHeader."No.");
            ReturnLine.SetRange(Type, ReturnLine.Type::Item);
            Assert.IsTrue(ReturnLine.FindFirst(), 'Standard copying must create an item line.');
            Assert.AreEqual(3, ReturnLine.Quantity, 'Only failed quantity must be returned.');
            if Scenario = 'happy' then begin
                Assert.AreEqual(CopyStr(RunCode, 9, 10), ReturnLine."Return Reason Code", 'Return reason must be applied.');
                Assert.AreEqual(RunCode, ReturnHeader."Vendor Cr. Memo No.", 'Vendor credit number must be applied.');
            end;
        end else begin
            Assert.AreEqual('Error', ReadText(Response, 'status'), 'Invalid calls must be structured refusals.');
            Assert.IsTrue(ReturnHeader.IsEmpty(), 'Refusal must roll back every return header.');
            ReturnLine.Reset();
            ReturnLine.SetRange("Document Type", ReturnLine."Document Type"::"Return Order");
            ReturnLine.SetRange("No.", Inspection."Source Item No.");
            Assert.IsTrue(ReturnLine.IsEmpty(), 'Refusal must roll back every return line.');
            if (Scenario = 'missing') and (LanguageId = 1039) then
                Assert.IsTrue(ReadText(Response, 'error').Contains('Nauðsynlega'), 'Refusal must be translated.');
            if Scenario = 'late' then
                Assert.IsTrue(ReadText(Response, 'error').Contains('Injected late'), 'The refusal must originate after native writes.');
            if Scenario = 'unknown' then
                Assert.AreEqual('UnknownParameter', ReadText(Response, 'code'), 'Unknown keys must use the standard refusal.');
        end;
        Cleanup(RunCode);
    end;

    /// <summary>Seeds only a BIFTQ13- fixture, including synthetic receipt/ledger rows; does not invoke the operation under test.</summary>
    procedure SeedFixture(RunCode: Code[20]; var Inspection: Record "Qlty. Inspection Header")
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptHeader: Record "Purch. Rcpt. Header";
        ReceiptLine: Record "Purch. Rcpt. Line";
        Ledger: Record "Item Ledger Entry";
        ReturnReason: Record "Return Reason";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        InventoryPostingGroup: Record "Inventory Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnit: Record "Item Unit of Measure";
    begin
        if CopyStr(RunCode, 1, 8) <> 'BIFTQ13-' then
            Error('Only BIFTQ13- fixtures are permitted.');
        if Inspection.Get(RunCode, 0) then
            Error('Fixture already exists; inspect instead of replaying creation.');
        // Reuse only posting configuration, never existing vendor/item/receipt fixtures.
        // Seed synthetic rows directly so fixture creation cannot change number-series/setup or create contacts.
        GeneralPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GeneralPostingSetup.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        GeneralPostingSetup.FindFirst();
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.FindFirst();
        InventoryPostingGroup.FindFirst();
        VendorPostingGroup.FindFirst();
        UnitOfMeasure.FindFirst();
        Vendor."No." := RunCode;
        Vendor.Name := RunCode;
        Vendor."Gen. Bus. Posting Group" := GeneralPostingSetup."Gen. Bus. Posting Group";
        Vendor."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        Vendor."Vendor Posting Group" := VendorPostingGroup.Code;
        Vendor.Insert(false);
        Item."No." := RunCode;
        Item.Description := RunCode;
        Item."Base Unit of Measure" := UnitOfMeasure.Code;
        Item."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        Item."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        Item."Inventory Posting Group" := InventoryPostingGroup.Code;
        Item.Insert(false);
        ItemUnit."Item No." := RunCode;
        ItemUnit.Code := UnitOfMeasure.Code;
        ItemUnit."Qty. per Unit of Measure" := 1;
        ItemUnit.Insert(false);
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := RunCode;
        PurchaseHeader."Buy-from Vendor No." := RunCode;
        PurchaseHeader."Pay-to Vendor No." := RunCode;
        PurchaseHeader."Buy-from Vendor Name" := RunCode;
        PurchaseHeader."Posting Date" := WorkDate();
        PurchaseHeader."Document Date" := WorkDate();
        PurchaseHeader."Gen. Bus. Posting Group" := Vendor."Gen. Bus. Posting Group";
        PurchaseHeader."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        PurchaseHeader."Vendor Posting Group" := Vendor."Vendor Posting Group";
        PurchaseHeader.Insert(false);
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := RunCode;
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := Item."No.";
        PurchaseLine."Buy-from Vendor No." := Vendor."No.";
        PurchaseLine."Pay-to Vendor No." := Vendor."No.";
        PurchaseLine.Description := Item.Description;
        PurchaseLine."Unit of Measure Code" := UnitOfMeasure.Code;
        PurchaseLine."Qty. per Unit of Measure" := 1;
        PurchaseLine.Quantity := 10;
        PurchaseLine."Quantity (Base)" := 10;
        PurchaseLine."Qty. to Receive" := 10;
        PurchaseLine."Qty. to Receive (Base)" := 10;
        PurchaseLine."Qty. to Invoice" := 10;
        PurchaseLine."Qty. to Invoice (Base)" := 10;
        PurchaseLine."Outstanding Quantity" := 10;
        PurchaseLine."Outstanding Qty. (Base)" := 10;
        PurchaseLine."Gen. Bus. Posting Group" := Vendor."Gen. Bus. Posting Group";
        PurchaseLine."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        PurchaseLine."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        PurchaseLine."VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
        PurchaseLine."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
        PurchaseLine."VAT %" := VATPostingSetup."VAT %";
        PurchaseLine."VAT Identifier" := VATPostingSetup."VAT Identifier";
        PurchaseLine.Insert(false);
        ReceiptHeader.TransferFields(PurchaseHeader);
        ReceiptHeader."No." := RunCode;
        ReceiptHeader."Order No." := PurchaseHeader."No.";
        ReceiptHeader.Insert(false);
        ReceiptLine.TransferFields(PurchaseLine);
        ReceiptLine."Document No." := RunCode;
        ReceiptLine."Order No." := PurchaseHeader."No.";
        ReceiptLine."Order Line No." := PurchaseLine."Line No.";
        ReceiptLine.Insert(false);
        Ledger.LockTable();
        if Ledger.FindLast() then
            Ledger."Entry No." += 1
        else
            Ledger."Entry No." := 1;
        Ledger.Init();
        Ledger."Item No." := Item."No.";
        Ledger."Entry Type" := Ledger."Entry Type"::Purchase;
        Ledger."Document Type" := Ledger."Document Type"::"Purchase Receipt";
        Ledger."Document No." := RunCode;
        Ledger."Document Line No." := ReceiptLine."Line No.";
        Ledger.Quantity := 10;
        Ledger."Remaining Quantity" := 10;
        Ledger.Positive := true;
        Ledger.Open := true;
        Ledger.Insert(false);
        ReturnReason.Code := CopyStr(RunCode, 9, 10);
        if not ReturnReason.Get(ReturnReason.Code) then begin
            ReturnReason.Code := CopyStr(RunCode, 9, 10);
            ReturnReason.Insert(false);
        end;
        Inspection.Init();
        Inspection."No." := RunCode;
        Inspection."Source Table No." := Database::"Purchase Line";
        Inspection."Source Document No." := PurchaseHeader."No.";
        Inspection."Source Document Line No." := PurchaseLine."Line No.";
        Inspection."Source Item No." := Item."No.";
        Inspection."Source Quantity (Base)" := 10;
        Inspection."Fail Quantity" := 3;
        Inspection.Insert(false);
    end;

    /// <summary>Deletes only the inspection, synthetic receipt/ledger and documents/master data owned by this fixture.</summary>
    procedure Cleanup(RunCode: Code[20])
    var
        Inspection: Record "Qlty. Inspection Header";
        ReceiptHeader: Record "Purch. Rcpt. Header";
        ReceiptLine: Record "Purch. Rcpt. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Ledger: Record "Item Ledger Entry";
        Item: Record Item;
        ItemUnit: Record "Item Unit of Measure";
        Vendor: Record Vendor;
        ReturnReason: Record "Return Reason";
        ItemNo: Code[20];
        VendorNo: Code[20];
    begin
        if CopyStr(RunCode, 1, 8) <> 'BIFTQ13-' then
            Error('Only BIFTQ13- fixtures can be removed.');
        ReceiptLine.Get(RunCode, 10000);
        ItemNo := ReceiptLine."No.";
        VendorNo := ReceiptLine."Buy-from Vendor No.";
        PurchaseLine.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseLine.DeleteAll(false);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.DeleteAll(false);
        Ledger.SetRange("Document No.", RunCode);
        Ledger.SetRange("Item No.", ItemNo);
        Ledger.DeleteAll(false);
        ReceiptLine.SetRange("Document No.", RunCode);
        ReceiptLine.DeleteAll(false);
        ReceiptHeader.Get(RunCode);
        ReceiptHeader.Delete(false);
        Inspection.SetRange("No.", RunCode);
        Inspection.DeleteAll(false);
        ItemUnit.SetRange("Item No.", ItemNo);
        ItemUnit.DeleteAll(false);
        Item.Get(ItemNo);
        Item.Delete(false);
        Vendor.Get(VendorNo);
        Vendor.Delete(false);
        ReturnReason.Get(CopyStr(RunCode, 9, 10));
        ReturnReason.Delete(false);
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
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Quality.Disposition.CreatePurchaseReturn", Enum::"Message Version ori"::"1.0", '', 'quality13-tests', 'application/json', RequestContent, TaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
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

}
