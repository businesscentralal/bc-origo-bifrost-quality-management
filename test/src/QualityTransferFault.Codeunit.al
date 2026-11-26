namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Inventory.Transfer;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Dispositions.Transfer;
using Microsoft.QualityManagement.Document;

/// <summary>Injects a late failure after the standard transfer line was created, to verify transaction rollback.</summary>
codeunit 97269 "Quality Transfer Fault ori"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Disp. Transfer", 'OnAfterCreateTransferLineWithOutboundTracking', '', false, false)]
    local procedure FailAfterCreate(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; var Created: Boolean)
    begin
        if CopyStr(QltyInspectionHeader."No.", 1, 4) = 'Q14-' then
            Error(ErrorInfo.Create('Q14 late failure after native transfer line creation.'));
    end;
}
