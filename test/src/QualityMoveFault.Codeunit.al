namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;

/// <summary>Injects a late failure after standard movement line creation to verify transaction rollback.</summary>
codeunit 97221 "Quality Move Fault ori"
{
    EventSubscriberInstance = Manual;

    var
        PostingFault: Boolean;

    /// <summary>Moves the fault to after successful standard posting.</summary>
    procedure SetPostingFault()
    begin
        PostingFault := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Item Journal Management", OnAfterGenericCreateItemJournalLine, '', false, false)]
    local procedure FailAfterCreate(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    begin
        if PostingFault then
            exit;
        if CopyStr(QltyInspectionHeader."No.", 1, 4) = 'Q12-' then
            Error(ErrorInfo.Create('Q12 late failure after native journal creation.'));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Item Journal Management", OnAfterPostItemJournal, '', false, false)]
    local procedure FailAfterPost(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var ItemJournalLine: Record "Item Journal Line"; var AllLinesPosted: Boolean)
    begin
        if PostingFault and AllLinesPosted and (CopyStr(QltyInspectionHeader."No.", 1, 4) = 'Q12-') then
            Error(ErrorInfo.Create('Q12 late posting failure after native ledger creation.'));
    end;
}
