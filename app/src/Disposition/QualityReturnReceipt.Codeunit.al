namespace Origo.Bifrost.QualityManagement;

using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Dispositions.Purchase;
using Microsoft.QualityManagement.Document;

/// <summary>Captures the standard disposition result for one bound invocation without changing business data.</summary>
codeunit 10035247 "Quality Return Receipt ori"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        InspectionSystemId: Guid;
        ReturnOrderNo: Code[20];

    /// <summary>Limits the receipt to the requested inspection.</summary>
    procedure Initialize(SystemId: Guid)
    begin
        InspectionSystemId := SystemId;
        Clear(ReturnOrderNo);
    end;

    /// <summary>Returns the number emitted by Microsoft's disposition event.</summary>
    procedure GetReturnOrderNo(): Code[20]
    begin
        exit(ReturnOrderNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Disp. Purchase Return", 'OnAfterProcessDisposition', '', false, false)]
    local procedure CaptureReturn(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var CreatedReturnOrderPurchaseHeader: Record "Purchase Header"; var DidSomething: Boolean)
    begin
        if QltyInspectionHeader.SystemId = InspectionSystemId then
            if CreatedReturnOrderPurchaseHeader."Document Type" = CreatedReturnOrderPurchaseHeader."Document Type"::"Return Order" then
                ReturnOrderNo := CreatedReturnOrderPurchaseHeader."No.";
    end;
}
