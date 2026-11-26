namespace Origo.Bifrost.QualityManagement;

using Microsoft.Inventory.Transfer;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Dispositions.Transfer;
using Microsoft.QualityManagement.Document;

/// <summary>Bound only during one transfer order disposition; collects the numbers Microsoft's disposition emits.</summary>
codeunit 10035301 "Quality Transfer Capture ori"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        InspectionSystemId: Guid;
        TransferOrderNos: List of [Code[20]];

    /// <summary>Limits the capture to the requested inspection.</summary>
    procedure Initialize(SystemId: Guid)
    begin
        InspectionSystemId := SystemId;
        Clear(TransferOrderNos);
    end;

    /// <summary>Returns the created transfer order numbers in creation order.</summary>
    procedure GetTransferOrderNos(): List of [Code[20]]
    begin
        exit(TransferOrderNos);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Disp. Transfer", 'OnAfterCreateTransferLineWithOutboundTracking', '', false, false)]
    local procedure CaptureTransfer(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; var Created: Boolean)
    begin
        if not Created then
            exit;
        if QltyInspectionHeader.SystemId <> InspectionSystemId then
            exit;
        if not TransferOrderNos.Contains(TransferHeader."No.") then
            TransferOrderNos.Add(TransferHeader."No.");
    end;
}
