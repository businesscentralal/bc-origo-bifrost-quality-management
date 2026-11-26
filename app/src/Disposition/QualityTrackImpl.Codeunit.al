namespace Origo.Bifrost.QualityManagement;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Origo.Bifrost;

/// <summary>Changes lot, serial, package number or expiration date of inspection stock through Microsoft's disposition interface in one rollback transaction.</summary>
codeunit 10035311 "Quality Track Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        DescriptionLbl: Label 'Changes the lot, serial or package number or the expiration date of one quality inspection''s stock with a reclassification journal, left prepared or posted now.', MaxLength = 250, Comment = 'is-IS=Breytir lotu-, rað- eða pakkanúmeri eða fyrningardagsetningu birgða einnar gæðaskoðunar með endurflokkunarbók, undirbúið eða bókað strax.';
        InvalidKeyErr: Label 'The required parameter %1 is missing or invalid.', Comment = '%1 = parameter name|is-IS=Nauðsynlega færibreytu %1 vantar eða hún er ógild.';
        UnknownKeyErr: Label 'Unknown parameter %1.', Comment = '%1 = parameter name|is-IS=Óþekkt færibreyta %1.';
        TooLongErr: Label 'Parameter %1 exceeds %2 characters.', Comment = '%1 = parameter name, %2 = limit|is-IS=Færibreytan %1 er lengri en %2 stafir.';
        PermissionErr: Label 'The BIFROST QM Full ori permission set is required.', Comment = 'is-IS=Heimildasafnið BIFROST QM Full ori er nauðsynlegt.';
        NotFoundErr: Label 'The quality inspection was not found.', Comment = 'is-IS=Gæðaskoðunin fannst ekki.';
        ConfirmErr: Label 'Set confirm to true to authorize this item tracking change.', Comment = 'is-IS=Stilltu confirm á true til að heimila þessa breytingu á rakningu.';
        NoChangeErr: Label 'Specify at least one of newLotNo, newSerialNo, newPackageNo or newExpirationDate.', Comment = 'is-IS=Tilgreindu að minnsta kosti eitt af newLotNo, newSerialNo, newPackageNo eða newExpirationDate.';
        NotTrackedErr: Label 'The inspection has no lot, serial or package number, so its stock has no item tracking to change.', Comment = 'is-IS=Skoðunin hefur ekkert lotu-, rað- eða pakkanúmer og því er engin rakning á birgðum hennar til að breyta.';
        NothingChangedErr: Label 'Business Central did not create or post an item tracking change. Check the inspection quantity, stock and the reclassification batches in Quality Management Setup.', Comment = 'is-IS=Business Central stofnaði ekki eða bókaði breytingu á rakningu. Athugaðu magn skoðunar, birgðir og endurflokkunarbunka í uppsetningu gæðastjórnunar.';
        ExpectedIdLbl: Label 'a non-empty quality inspection SystemId GUID', Comment = 'is-IS=SystemId GUID gæðaskoðunar sem er ekki tómt';
        FindInspectionLbl: Label 'Read the inspection SystemId using Data.Records.Get and supply inspectionSystemId.', Comment = 'is-IS=Lestu SystemId skoðunar með Data.Records.Get og sendu inspectionSystemId.';
        ExistingInspectionLbl: Label 'the SystemId of an existing inspection', Comment = 'is-IS=SystemId núverandi skoðunar';
        ExpectedBasisLbl: Label 'failed or passed', Comment = 'is-IS=failed eða passed';
        BasisNextStepLbl: Label 'Send quantityBasis as failed or passed.', Comment = 'is-IS=Sendu quantityBasis sem failed eða passed.';
        ExpectedQuantityLbl: Label 'a JSON number greater than zero (base quantity)', Comment = 'is-IS=JSON tala hærri en núll (grunneining)';
        QuantityNextStepLbl: Label 'Send quantity as a positive number, or omit it to use the inspection quantity.', Comment = 'is-IS=Sendu quantity sem jákvæða tölu eða slepptu því til að nota magn skoðunar.';
        ExpectedCodeLbl: Label 'an exact code without filter syntax', Comment = 'is-IS=nákvæmur kóði án síunarsetningafræði';
        CodeNextStepLbl: Label 'Send the exact location or bin code; filter syntax is not accepted.', Comment = 'is-IS=Sendu nákvæman staðar- eða hólfskóða; síunarsetningafræði er ekki studd.';
        ExpectedLengthLbl: Label 'a value within the stated maximum length', Comment = 'is-IS=gildi innan tilgreindrar hámarkslengdar';
        LengthNextStepLbl: Label 'Shorten the value.', Comment = 'is-IS=Styttu gildið.';
        ExpectedTextLbl: Label 'a JSON string', Comment = 'is-IS=JSON strengur';
        TextNextStepLbl: Label 'Send the value as a JSON string.', Comment = 'is-IS=Sendu gildið sem JSON streng.';
        ExpectedDateLbl: Label 'a date in the form YYYY-MM-DD', Comment = 'is-IS=dagsetning á forminu YYYY-MM-DD';
        DateNextStepLbl: Label 'Send newExpirationDate as a JSON string such as 2027-06-30.', Comment = 'is-IS=Sendu newExpirationDate sem JSON streng, t.d. 2027-06-30.';
        ExpectedChangeLbl: Label 'at least one new tracking value', Comment = 'is-IS=að minnsta kosti eitt nýtt rakningargildi';
        ChangeNextStepLbl: Label 'Send newLotNo, newSerialNo, newPackageNo or newExpirationDate.', Comment = 'is-IS=Sendu newLotNo, newSerialNo, newPackageNo eða newExpirationDate.';
        ExpectedTrackedLbl: Label 'an inspection of lot, serial or package tracked stock', Comment = 'is-IS=skoðun á birgðum með lotu-, rað- eða pakkarakningu';
        TrackedNextStepLbl: Label 'Choose an inspection of tracked stock; this type does not add tracking to untracked stock.', Comment = 'is-IS=Veldu skoðun á rakningarbirgðum; þessi tegund bætir ekki rakningu við birgðir án rakningar.';
        ExpectedBooleanLbl: Label 'true or false', Comment = 'is-IS=true eða false';
        BooleanNextStepLbl: Label 'Send a JSON boolean.', Comment = 'is-IS=Sendu JSON boolean gildi.';
        ConfirmNextStepLbl: Label 'Send confirm=true after the user has approved the item tracking change.', Comment = 'is-IS=Sendu confirm=true þegar notandinn hefur samþykkt breytinguna á rakningu.';
        ExpectedKeysLbl: Label 'only the declared parameters', Comment = 'is-IS=aðeins tilgreindar færibreytur';
        KeysNextStepLbl: Label 'Remove the parameter; only the declared parameters are accepted.', Comment = 'is-IS=Fjarlægðu færibreytuna; aðeins tilgreindar færibreytur eru samþykktar.';
        PermissionNextStepLbl: Label 'Assign the BIFROST QM Full ori permission set.', Comment = 'is-IS=Úthlutaðu heimildasafninu BIFROST QM Full ori.';

    trigger OnRun()
    begin
        PerformChange(Rec);
    end;

    /// <summary>Runs the disposition in an isolated transaction; standard business errors become refusals.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if Argument."Omit Commit" then begin
            PerformChange(Argument);
            exit;
        end;
        if not Codeunit.Run(Codeunit::"Quality Track Impl ori", Argument) then
            Argument.RespondWithLastError();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure PerformChange(var Argument: Record "Message Argument ori")
    var
        AccessCapability: Record "Quality Track Access ori";
        Inspection: Record "Qlty. Inspection Header";
        Setup: Record "Qlty. Management Setup";
        TempInstruction: Record "Qlty. Disposition Buffer" temporary;
        JournalLine: Record "Item Journal Line";
        Ledger: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        AtomicPosting: Codeunit "Quality Move Posting ori";
        Disposition: Interface "Qlty. Disposition";
        Request: JsonObject;
        Response: JsonObject;
        InspectionId: Guid;
        ParameterName: Text;
        Basis: Text;
        PostImmediately: Boolean;
        TemplateName: Code[10];
        WarehouseTemplateName: Code[10];
        LastLineNo: Integer;
        LastEntryNo: Integer;
        LastWarehouseEntryNo: Integer;
        StartedAt: DateTime;
    begin
        if not AccessCapability.WritePermission() then
            Refuse(Argument, "Bifrost Error Code ori"::PermissionDenied, PermissionErr, 'permissionSet', '', 'BIFROST QM Full ori', PermissionNextStepLbl);
        Request := Argument.GetRequestJson();
        foreach ParameterName in Request.Keys() do
            if not (ParameterName in ['inspectionSystemId', 'newLotNo', 'newSerialNo', 'newPackageNo', 'newExpirationDate', 'quantityBasis', 'quantity', 'sourceLocationCode', 'sourceBinCode', 'postImmediately', 'confirm', 'expectedCount']) then
                Refuse(Argument, "Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, ParameterName), ParameterName, '', ExpectedKeysLbl, KeysNextStepLbl);
        InspectionId := ReadInspectionId(Request, Argument);
        if not ReadBoolean(Request, 'confirm', Argument) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, ConfirmErr, 'confirm', 'false', 'true', ConfirmNextStepLbl);
        PostImmediately := ReadBoolean(Request, 'postImmediately', Argument);
        TempInstruction."New Lot No." := CopyStr(ReadText(Request, 'newLotNo', false, MaxStrLen(TempInstruction."New Lot No."), Argument), 1, MaxStrLen(TempInstruction."New Lot No."));
        TempInstruction."New Serial No." := CopyStr(ReadText(Request, 'newSerialNo', false, MaxStrLen(TempInstruction."New Serial No."), Argument), 1, MaxStrLen(TempInstruction."New Serial No."));
        TempInstruction."New Package No." := CopyStr(ReadText(Request, 'newPackageNo', false, MaxStrLen(TempInstruction."New Package No."), Argument), 1, MaxStrLen(TempInstruction."New Package No."));
        TempInstruction."New Expiration Date" := ReadDate(Request, 'newExpirationDate', Argument);
        if (TempInstruction."New Lot No." = '') and (TempInstruction."New Serial No." = '') and (TempInstruction."New Package No." = '') and (TempInstruction."New Expiration Date" = 0D) then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, NoChangeErr, 'newLotNo', '', ExpectedChangeLbl, ChangeNextStepLbl);
        Basis := ReadText(Request, 'quantityBasis', true, 10, Argument);
        case Basis of
            'failed':
                TempInstruction."Quantity Behavior" := TempInstruction."Quantity Behavior"::"Failed Quantity";
            'passed':
                TempInstruction."Quantity Behavior" := TempInstruction."Quantity Behavior"::"Passed Quantity";
            else
                Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, 'quantityBasis'), 'quantityBasis', Basis, ExpectedBasisLbl, BasisNextStepLbl);
        end;
        if Request.Contains('quantity') then begin
            TempInstruction."Qty. To Handle (Base)" := ReadQuantity(Request, Argument);
            TempInstruction."Quantity Behavior" := TempInstruction."Quantity Behavior"::"Specific Quantity";
        end;
        TempInstruction."Location Filter" := CopyStr(ReadCode(Request, 'sourceLocationCode', 10, Argument), 1, MaxStrLen(TempInstruction."Location Filter"));
        TempInstruction."Bin Filter" := CopyStr(ReadCode(Request, 'sourceBinCode', 20, Argument), 1, MaxStrLen(TempInstruction."Bin Filter"));
        if PostImmediately then
            TempInstruction."Entry Behavior" := TempInstruction."Entry Behavior"::Post;
        Inspection.ReadIsolation := IsolationLevel::UpdLock;
        if not Inspection.GetBySystemId(InspectionId) then
            Refuse(Argument, "Bifrost Error Code ori"::RecordNotFound, NotFoundErr, 'inspectionSystemId', Format(InspectionId, 0, 4), ExistingInspectionLbl, FindInspectionLbl);
        if (Inspection."Source Lot No." = '') and (Inspection."Source Serial No." = '') and (Inspection."Source Package No." = '') then
            Refuse(Argument, "Bifrost Error Code ori"::PreconditionFailed, NotTrackedErr, 'inspectionSystemId', Inspection."No.", ExpectedTrackedLbl, TrackedNextStepLbl);
        // Remember where the journals and ledgers ended so the response lists only what this call created.
        StartedAt := CurrentDateTime();
        Setup.Get();
        if Setup."Item Reclass. Batch Name" <> '' then begin
            TemplateName := Setup.GetItemReclassJournalTemplate();
            JournalLine.SetRange("Journal Template Name", TemplateName);
            JournalLine.SetRange("Journal Batch Name", Setup."Item Reclass. Batch Name");
            if JournalLine.FindLast() then
                LastLineNo := JournalLine."Line No.";
        end;
        if Setup."Whse. Reclass. Batch Name" <> '' then
            WarehouseTemplateName := Setup.GetWarehouseReclassificationJournalTemplate();
        if Ledger.FindLast() then
            LastEntryNo := Ledger."Entry No.";
        if WarehouseEntry.FindLast() then
            LastWarehouseEntryNo := WarehouseEntry."Entry No.";
        TempInstruction."Disposition Action" := TempInstruction."Disposition Action"::"Change Item Tracking";
        Disposition := TempInstruction."Disposition Action";
        // Bind standard posting with suppressed commits so a late refusal rolls back lines and entries together.
        BindSubscription(AtomicPosting);
        if not Disposition.PerformDisposition(Inspection, TempInstruction) then
            Error(ErrorInfo.Create(NothingChangedErr));
        UnbindSubscription(AtomicPosting);
        Response.Add('status', 'Success');
        Response.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Response.Add('inspectionNo', Inspection."No.");
        Response.Add('reinspectionNo', Inspection."Re-inspection No.");
        Response.Add('quantityBasis', Basis);
        Response.Add('posted', PostImmediately);
        Response.Add('journalLines', ListJournalLines(TemplateName, Setup."Item Reclass. Batch Name", LastLineNo));
        Response.Add('warehouseJournalLines', ListWarehouseLines(WarehouseTemplateName, Setup."Whse. Reclass. Batch Name", Inspection."Source Item No.", StartedAt));
        Response.Add('ledgerEntries', ListLedgerEntries(Inspection."Source Item No.", LastEntryNo));
        Response.Add('warehouseEntries', ListWarehouseEntries(Inspection."Source Item No.", LastWarehouseEntryNo));
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure ListJournalLines(TemplateName: Code[10]; BatchName: Code[10]; LastLineNo: Integer) Lines: JsonArray
    var
        JournalLine: Record "Item Journal Line";
        Reservation: Record "Reservation Entry";
        Line: JsonObject;
    begin
        if (TemplateName = '') or (BatchName = '') then
            exit;
        JournalLine.SetRange("Journal Template Name", TemplateName);
        JournalLine.SetRange("Journal Batch Name", BatchName);
        JournalLine.SetFilter("Line No.", '>%1', LastLineNo);
        JournalLine.SetFilter("Item No.", '<>%1', '');
        if not JournalLine.FindSet() then
            exit;
        repeat
            Clear(Line);
            Line.Add('journalTemplateName', JournalLine."Journal Template Name");
            Line.Add('journalBatchName', JournalLine."Journal Batch Name");
            Line.Add('lineNo', JournalLine."Line No.");
            Line.Add('itemNo', JournalLine."Item No.");
            Line.Add('locationCode', JournalLine."Location Code");
            Line.Add('binCode', JournalLine."Bin Code");
            Line.Add('quantity', JournalLine.Quantity);
            // Without item tracking on lines, Microsoft keeps the new values on the line's reservation entry.
            Reservation.SetRange("Source Type", Database::"Item Journal Line");
            Reservation.SetRange("Source ID", JournalLine."Journal Template Name");
            Reservation.SetRange("Source Batch Name", JournalLine."Journal Batch Name");
            Reservation.SetRange("Source Ref. No.", JournalLine."Line No.");
            if Reservation.FindFirst() then begin
                Line.Add('lotNo', Reservation."Lot No.");
                Line.Add('serialNo', Reservation."Serial No.");
                Line.Add('packageNo', Reservation."Package No.");
                Line.Add('newLotNo', Reservation."New Lot No.");
                Line.Add('newSerialNo', Reservation."New Serial No.");
                Line.Add('newPackageNo', Reservation."New Package No.");
                Line.Add('newExpirationDate', FormatDate(Reservation."New Expiration Date"));
            end else begin
                Line.Add('lotNo', JournalLine."Lot No.");
                Line.Add('serialNo', JournalLine."Serial No.");
                Line.Add('packageNo', JournalLine."Package No.");
                Line.Add('newLotNo', JournalLine."New Lot No.");
                Line.Add('newSerialNo', JournalLine."New Serial No.");
                Line.Add('newPackageNo', JournalLine."New Package No.");
                Line.Add('newExpirationDate', FormatDate(JournalLine."New Item Expiration Date"));
            end;
            Lines.Add(Line);
        until JournalLine.Next() = 0;
    end;

    local procedure ListWarehouseLines(TemplateName: Code[10]; BatchName: Code[10]; ItemNo: Code[20]; StartedAt: DateTime) Lines: JsonArray
    var
        WarehouseLine: Record "Warehouse Journal Line";
        Line: JsonObject;
    begin
        if (TemplateName = '') or (BatchName = '') then
            exit;
        WarehouseLine.SetRange("Journal Template Name", TemplateName);
        WarehouseLine.SetRange("Journal Batch Name", BatchName);
        WarehouseLine.SetRange("Item No.", ItemNo);
        WarehouseLine.SetFilter(SystemCreatedAt, '>=%1', StartedAt);
        if not WarehouseLine.FindSet() then
            exit;
        repeat
            Clear(Line);
            Line.Add('journalTemplateName', WarehouseLine."Journal Template Name");
            Line.Add('journalBatchName', WarehouseLine."Journal Batch Name");
            Line.Add('locationCode', WarehouseLine."Location Code");
            Line.Add('lineNo', WarehouseLine."Line No.");
            Line.Add('itemNo', WarehouseLine."Item No.");
            Line.Add('binCode', WarehouseLine."From Bin Code");
            Line.Add('quantity', WarehouseLine."Qty. (Base)");
            Lines.Add(Line);
        until WarehouseLine.Next() = 0;
    end;

    local procedure ListLedgerEntries(ItemNo: Code[20]; LastEntryNo: Integer) Entries: JsonArray
    var
        Ledger: Record "Item Ledger Entry";
        Entry: JsonObject;
    begin
        Ledger.SetFilter("Entry No.", '>%1', LastEntryNo);
        Ledger.SetRange("Item No.", ItemNo);
        Ledger.SetRange("Entry Type", Ledger."Entry Type"::Transfer);
        if not Ledger.FindSet() then
            exit;
        repeat
            Clear(Entry);
            Entry.Add('entryNo', Ledger."Entry No.");
            Entry.Add('itemNo', Ledger."Item No.");
            Entry.Add('locationCode', Ledger."Location Code");
            Entry.Add('lotNo', Ledger."Lot No.");
            Entry.Add('serialNo', Ledger."Serial No.");
            Entry.Add('packageNo', Ledger."Package No.");
            Entry.Add('expirationDate', FormatDate(Ledger."Expiration Date"));
            Entry.Add('quantity', Ledger.Quantity);
            Entries.Add(Entry);
        until Ledger.Next() = 0;
    end;

    local procedure ListWarehouseEntries(ItemNo: Code[20]; LastEntryNo: Integer) Entries: JsonArray
    var
        WarehouseEntry: Record "Warehouse Entry";
        Entry: JsonObject;
    begin
        WarehouseEntry.SetFilter("Entry No.", '>%1', LastEntryNo);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        if not WarehouseEntry.FindSet() then
            exit;
        repeat
            Clear(Entry);
            Entry.Add('entryNo', WarehouseEntry."Entry No.");
            Entry.Add('itemNo', WarehouseEntry."Item No.");
            Entry.Add('locationCode', WarehouseEntry."Location Code");
            Entry.Add('binCode', WarehouseEntry."Bin Code");
            Entry.Add('lotNo', WarehouseEntry."Lot No.");
            Entry.Add('serialNo', WarehouseEntry."Serial No.");
            Entry.Add('packageNo', WarehouseEntry."Package No.");
            Entry.Add('expirationDate', FormatDate(WarehouseEntry."Expiration Date"));
            Entry.Add('quantity', WarehouseEntry."Qty. (Base)");
            Entries.Add(Entry);
        until WarehouseEntry.Next() = 0;
    end;

    local procedure FormatDate(Value: Date): Text
    begin
        if Value = 0D then
            exit('');
        exit(Format(Value, 0, 9));
    end;

    local procedure ReadInspectionId(Request: JsonObject; var Argument: Record "Message Argument ori") InspectionId: Guid
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get('inspectionSystemId', Token) then
            RefuseInspectionId(Argument);
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            RefuseInspectionId(Argument);
        if not Evaluate(InspectionId, Token.AsValue().AsText()) then
            RefuseInspectionId(Argument);
        if IsNullGuid(InspectionId) then
            RefuseInspectionId(Argument);
    end;

    local procedure RefuseInspectionId(var Argument: Record "Message Argument ori")
    begin
        Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(InvalidKeyErr, 'inspectionSystemId'), 'inspectionSystemId', '', ExpectedIdLbl, FindInspectionLbl);
    end;

    local procedure Refuse(var Argument: Record "Message Argument ori"; ErrorCode: Enum "Bifrost Error Code ori"; Message: Text; Parameter: Text; Received: Text; Expected: Text; NextStep: Text)
    begin
        // Foundation preserves this collection across the Codeunit.Run rollback.
        Argument.AddError(ErrorCode, Message, Parameter, Received, Expected, NextStep);
        Argument.RaiseCollectedErrors(ErrorCode, Message);
    end;

    local procedure ReadCode(Request: JsonObject; ParameterName: Text; MaximumLength: Integer; var Argument: Record "Message Argument ori") Value: Text
    var
        Position: Integer;
    begin
        Value := ReadText(Request, ParameterName, false, MaximumLength, Argument);
        // The standard buffer stores filters, but this API promises literal codes.
        for Position := 1 to StrLen(Value) do
            if StrPos('|&*?@<>=()''', CopyStr(Value, Position, 1)) > 0 then
                Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, ParameterName), ParameterName, Value, ExpectedCodeLbl, CodeNextStepLbl);
        if StrPos(Value, '..') > 0 then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, ParameterName), ParameterName, Value, ExpectedCodeLbl, CodeNextStepLbl);
    end;

    local procedure ReadText(Request: JsonObject; ParameterName: Text; Required: Boolean; MaximumLength: Integer; var Argument: Record "Message Argument ori") Value: Text
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get(ParameterName, Token) then begin
            if Required then
                Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(InvalidKeyErr, ParameterName), ParameterName, '', ParameterName, KeysNextStepLbl);
            exit('');
        end;
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, ParameterName), ParameterName, Serialized, ExpectedTextLbl, TextNextStepLbl);
        Value := Token.AsValue().AsText();
        if Required and (Value = '') then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(InvalidKeyErr, ParameterName), ParameterName, '', ParameterName, KeysNextStepLbl);
        if StrLen(Value) > MaximumLength then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(TooLongErr, ParameterName, MaximumLength), ParameterName, Value, ExpectedLengthLbl, LengthNextStepLbl);
    end;

    local procedure ReadDate(Request: JsonObject; ParameterName: Text; var Argument: Record "Message Argument ori") Value: Date
    var
        Received: Text;
    begin
        if not Request.Contains(ParameterName) then
            exit(0D);
        Received := ReadText(Request, ParameterName, true, 10, Argument);
        // Only the ISO calendar form is accepted, so a locale-dependent date never reaches the journal.
        if (StrLen(Received) <> 10) or (CopyStr(Received, 5, 1) <> '-') or (CopyStr(Received, 8, 1) <> '-') then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, ParameterName), ParameterName, Received, ExpectedDateLbl, DateNextStepLbl);
        if not Evaluate(Value, Received, 9) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, ParameterName), ParameterName, Received, ExpectedDateLbl, DateNextStepLbl);
        if Value = 0D then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, ParameterName), ParameterName, Received, ExpectedDateLbl, DateNextStepLbl);
    end;

    local procedure ReadBoolean(Request: JsonObject; ParameterName: Text; var Argument: Record "Message Argument ori"): Boolean
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get(ParameterName, Token) then
            exit(false);
        Token.WriteTo(Serialized);
        if not (Serialized in ['true', 'false']) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, ParameterName), ParameterName, Serialized, ExpectedBooleanLbl, BooleanNextStepLbl);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure ReadQuantity(Request: JsonObject; var Argument: Record "Message Argument ori") Quantity: Decimal
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        Request.Get('quantity', Token);
        Token.WriteTo(Serialized);
        if (Serialized = '') or (CopyStr(Serialized, 1, 1) in ['"', 't', 'f', 'n', '{', '[']) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, 'quantity'), 'quantity', Serialized, ExpectedQuantityLbl, QuantityNextStepLbl);
        Quantity := Token.AsValue().AsDecimal();
        if Quantity <= 0 then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, 'quantity'), 'quantity', Serialized, ExpectedQuantityLbl, QuantityNextStepLbl);
    end;

    /// <summary>Returns whether the caller has the item tracking change capability.</summary>
    procedure IsEnabled(): Boolean
    var
        AccessCapability: Record "Quality Track Access ori";
    begin
        exit(AccessCapability.WritePermission());
    end;

    /// <summary>Returns the standard inspection table.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Qlty. Inspection Header");
    end;

    /// <summary>Describes the item tracking change.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>The operation accepts inbound messages.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Returns translated search terms.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'quality, disposition, item tracking, lot number, serial number, package number, expiration date, reclassification', Comment = 'is-IS=gæði, ráðstöfun, vörurakning, lotunúmer, raðnúmer, pakkanúmer, fyrningardagsetning, endurflokkun';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Distinguishes this operation in discovery.</summary>
    procedure GetSelectionDescription(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Returns the envelope contract chapter.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    begin
        Envelope.ReadFrom('{"subject":{"use":"notUsed"},"dataRequired":true,"version":"1.0","contentType":"application/json"}');
        exit(true);
    end;

    /// <summary>Returns the target contract chapter.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        Target.ReadFrom('[{"source":"data.inspectionSystemId","form":"GUID","description":"SystemId of exactly one inspection of lot, serial or package tracked stock, including its re-inspection."}]');
        exit(true);
    end;

    /// <summary>Returns the parameters contract chapter.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Parameter: JsonObject;
        AllowedValues: JsonArray;
    begin
        Clear(Parameters);
        Parameter := ContractMgt.Parameter('inspectionSystemId', 'string', true, 'SystemId of the exact inspection. The inspection must name a lot, serial or package number.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('newLotNo', 'string', false, 'New lot number, up to 50 characters. Send at least one of newLotNo, newSerialNo, newPackageNo or newExpirationDate.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('newSerialNo', 'string', false, 'New serial number, up to 50 characters.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('newPackageNo', 'string', false, 'New package number, up to 50 characters.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('newExpirationDate', 'string', false, 'New expiration date as YYYY-MM-DD.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('quantityBasis', 'string', true, 'Use Microsoft inspection Fail Quantity or Pass Quantity; must be positive.');
        AllowedValues.ReadFrom('["failed","passed"]');
        Parameter.Add('allowed', AllowedValues);
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('quantity', 'number', false, 'Optional base quantity to change instead of the whole basis quantity. Must be greater than zero.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('sourceLocationCode', 'string', false, 'Exact source location, up to 10 characters. No filter syntax. Omitted: Microsoft selects available inventory.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('sourceBinCode', 'string', false, 'Exact source bin, up to 20 characters. No filter syntax. Omitted: Microsoft selects available bins.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('postImmediately', 'boolean', false, 'true posts the reclassification now and changes the tracking of the stock; false (default) leaves the lines in the reclassification batch named in Quality Management Setup.');
        Parameter.Add('default', false);
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('confirm', 'boolean', true, 'Must be true to authorize creation or posting of the item tracking change.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('expectedCount', 'integer', false, 'expectedCount counts the one quality inspection named by inspectionSystemId (1 per call), not the journal lines or entries the call creates. Omitting expectedCount reads that count and changes nothing only when Require Confirmation for Irreversible Messages is enabled in Bifrost Setup (on by default). When that setup is disabled, omitting expectedCount can execute the change.');
        Parameters.Add(Parameter);
        exit(true);
    end;

    /// <summary>Returns the response contract chapter.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    begin
        Response.ReadFrom('{"contentType":"application/json","fields":[{"name":"status","type":"string","description":"Success."},{"name":"inspectionSystemId","type":"string","description":"Selected inspection SystemId."},{"name":"inspectionNo","type":"string","description":"Inspection number."},{"name":"reinspectionNo","type":"integer","description":"Re-inspection number."},{"name":"quantityBasis","type":"string","description":"failed or passed."},{"name":"posted","type":"boolean","description":"True when the reclassification was posted; false when the lines were only prepared."},{"name":"journalLines","type":"array","description":"Item reclassification lines this call left in the journal, with their current and new lot, serial, package number and new expiration date. Empty after posting."},{"name":"warehouseJournalLines","type":"array","description":"Warehouse reclassification lines this call left in the journal (locations with directed put-away and pick)."},{"name":"ledgerEntries","type":"array","description":"Item ledger transfer entries posted by this call, with lot, serial, package number and expiration date."},{"name":"warehouseEntries","type":"array","description":"Warehouse entries registered by this call."}]}');
        exit(true);
    end;

    /// <summary>Returns the errors contract chapter.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.ReadFrom('[{"code":"UnknownParameter","when":"An unknown data key is sent.","fix":"Use only declared parameters."},{"code":"InvalidParameter","when":"confirm is not true, or a value is malformed, too long, a filter, not a YYYY-MM-DD date or not positive.","fix":"Correct the parameter named in the error."},{"code":"RecordNotFound","when":"The inspection does not exist.","fix":"Read the inspection SystemId with Data.Records.Get."},{"code":"PreconditionFailed","when":"The inspection names no lot, serial or package number.","fix":"Choose an inspection of tracked stock."},{"code":"PermissionDenied","when":"The caller lacks BIFROST QM Full ori.","fix":"Assign the BIFROST QM Full ori permission set."},{"error":"Business Central refusal","when":"Microsoft refuses: missing reclassification batch, item not tracked, insufficient stock, or posting fails.","fix":"Correct the setup, stock or permissions and retry. No lines or entries from the failed call remain."}]');
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, NoChangeErr, ChangeNextStepLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, StrSubstNo(InvalidKeyErr, 'inspectionSystemId'), FindInspectionLbl));
        exit(true);
    end;

    /// <summary>Returns the effect contract chapter.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        Effect.ReadFrom('{"effect":"irreversible","changes":"Creates item reclassification lines (or warehouse reclassification lines at locations with directed put-away and pick) through the standard Qlty. Disp. Change Tracking implementation in the batch named in Quality Management Setup, carrying the new lot, serial, package number or expiration date. With postImmediately=true the lines are posted and the stock identity changes; posted entries cannot be undone by this type and a repeated call changes stock again. Standard posting is bound with SetSuppressCommit(true) and explicit commits are prohibited, so a refusal rolls back lines and entries together. Success commits once through the isolated wrapper; Omit Commit leaves the transaction to the caller. The expectedCount unit is the one quality inspection named by inspectionSystemId (1 per call), not the journal lines or entries the call creates. Foundation appends how to read it without a side effect.","idempotent":false,"permissionSet":"BIFROST QM Full ori","preconditions":["confirm=true.","At least one new tracking value.","The inspection names a lot, serial or package number of tracked stock.","Caller has Microsoft item journal, item tracking and posting permissions.","Positive inspection Pass Quantity or Fail Quantity and sufficient stock.","The reclassification batch (or warehouse reclassification batch) is set in Quality Management Setup."]}');
        exit(true);
    end;

    /// <summary>Returns the examples contract chapter.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        Examples.ReadFrom('[{"title":"Prepare a new lot number for the failed quantity","request":{"type":"Quality.Disposition.ChangeItemTracking","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001","quantityBasis":"failed","newLotNo":"LOT-QA-01","confirm":true,"expectedCount":1}},"response":{"status":"Success","inspectionSystemId":"00000000-0000-0000-0000-000000000001","inspectionNo":"QI00001","reinspectionNo":0,"quantityBasis":"failed","posted":false,"journalLines":[{"journalTemplateName":"RECLASS","journalBatchName":"QUALITY","lineNo":10000,"itemNo":"1000","locationCode":"MAIN","binCode":"","quantity":3,"lotNo":"LOT01","serialNo":"","packageNo":"","newLotNo":"LOT-QA-01","newSerialNo":"","newPackageNo":"","newExpirationDate":""}],"warehouseJournalLines":[],"ledgerEntries":[],"warehouseEntries":[]}}]');
        exit(true);
    end;

    /// <summary>No additional metering chapter is declared.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional related chapter is declared.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional workflow chapter is declared.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>Returns the translated overview help chapter.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    var
        HelpLbl: Label 'Changes the lot, serial or package number or the expiration date of the failed or passed quantity of one quality inspection through standard Microsoft disposition, using an item or warehouse reclassification journal. With postImmediately=false (default) the lines stay in the reclassification batch named in Quality Management Setup; with postImmediately=true they are posted. confirm=true and at least one new value are required. expectedCount counts the one quality inspection named by inspectionSystemId (1 per call), not the journal lines or entries the call creates. Omitting expectedCount reads that count and changes nothing only when Require Confirmation for Irreversible Messages is enabled in Bifrost Setup (on by default). When that setup is disabled, omitting expectedCount can execute the change.', Comment = 'is-IS=Breytir lotu-, rað- eða pakkanúmeri eða fyrningardagsetningu fallins eða staðins magns einnar gæðaskoðunar með staðlaðri ráðstöfun Microsoft, með endurflokkunarbók vöru eða vöruhúss. Með postImmediately=false (sjálfgefið) eru línurnar áfram í endurflokkunarbunkanum sem er tilgreindur í uppsetningu gæðastjórnunar; með postImmediately=true eru þær bókaðar. confirm=true og að minnsta kosti eitt nýtt gildi eru nauðsynleg. expectedCount telur eina gæðaskoðun sem inspectionSystemId nefnir (1 fyrir hvert kall), ekki færslubókarlínurnar eða færslurnar sem kallið stofnar. Að sleppa expectedCount les þann fjölda og breytir engu aðeins þegar Krefjast staðfestingar fyrir óafturkræf skilaboð er virkt í Uppsetningu Bifröst (virkt sjálfgefið). Þegar sú uppsetning er óvirk getur það að sleppa expectedCount keyrt breytinguna.';
    begin
        Overview := HelpLbl;
        exit(true);
    end;

    /// <summary>Returns the translated notes help chapter.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    var
        HelpLbl: Label 'Not idempotent: posted entries change the identity of stock and cannot be undone by repeating the call; a repeated call creates another change. There is no delete type and no undo type. Tracking is not added to untracked stock. Microsoft changes the expiration date of a lot only for its whole remaining quantity. Posting is atomic; a refusal rolls back journal creation and posting. Normal success commits the isolated transaction; with Omit Commit the caller owns the transaction.', Comment = 'is-IS=Ekki ídempótent: bókaðar færslur breyta auðkenni birgða og endurtekið kall afturkallar þær ekki; endurtekið kall stofnar aðra breytingu. Engin eyðingartegund og engin afturköllunartegund er til. Rakningu er ekki bætt við birgðir án rakningar. Microsoft breytir fyrningardagsetningu lotu aðeins fyrir allt eftirstandandi magn hennar. Bókun er ein heild; höfnun bakfærir stofnun færslubókar og bókun. Venjuleg heppnuð keyrsla staðfestir einangraða færslu; með Omit Commit ber kallandi ábyrgð á færslunni.';
    begin
        Notes := HelpLbl;
        exit(true);
    end;
}
