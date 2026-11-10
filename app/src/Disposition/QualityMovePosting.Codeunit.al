namespace Origo.Bifrost.QualityManagement;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Posting;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.Warehouse.Journal;

/// <summary>
/// Bound only during a disposition. Uses the same standard posting codeunits with suppressed commits,
/// avoiding Quality Management's per-line Commit and Boolean Run which otherwise leave partial results.
/// Errors propagate to the outer rollback transaction. No business validation is replaced.
/// </summary>
codeunit 10035272 "Quality Move Posting ori"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        ConflictingSubscriberErr: Label 'Another extension has replaced quality posting. Inventory movement was cancelled.', Comment = 'is-IS=Önnur viðbót hefur tekið yfir gæðabókun. Hætt var við birgðaflutning.';
        MissingFilterErr: Label 'Quality posting did not identify a journal line. Inventory movement was cancelled.', Comment = 'is-IS=Gæðabókun tilgreindi ekki færslubókarlínu. Hætt var við birgðaflutning.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Item Journal Management", OnBeforePostItemJournal, '', false, false)]
    local procedure PostItemJournal(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var ItemJournalLine: Record "Item Journal Line"; var AllLinesPosted: Boolean; var IsHandled: Boolean)
    var
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        if IsHandled then
            Error(ErrorInfo.Create(ConflictingSubscriberErr));
        if ItemJournalLine."Line No." = 0 then
            Error(ErrorInfo.Create(MissingFilterErr));
        ItemJournalLine.SetRecFilter();
        ItemJnlPostBatch.SetSuppressCommit(true);
        ItemJnlPostBatch.Run(ItemJournalLine);
        AllLinesPosted := true;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Item Journal Management", OnBeforePostWarehouseJournal, '', false, false)]
    local procedure PostWarehouseJournal(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WarehouseJournalLine: Record "Warehouse Journal Line"; var AllLinesPosted: Boolean; var IsHandled: Boolean)
    var
        WhseJnlRegisterBatch: Codeunit "Whse. Jnl.-Register Batch";
    begin
        if IsHandled then
            Error(ErrorInfo.Create(ConflictingSubscriberErr));
        if WarehouseJournalLine."Line No." = 0 then
            Error(ErrorInfo.Create(MissingFilterErr));
        WarehouseJournalLine.SetRecFilter();
        WhseJnlRegisterBatch.SetSuppressCommit(true);
        WhseJnlRegisterBatch.Run(WarehouseJournalLine);
        AllLinesPosted := true;
        IsHandled := true;
    end;
}
