namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Dispositions.Purchase;
using Microsoft.QualityManagement.Document;

/// <summary>Injects a late error after the native return header and lines have been created.</summary>
codeunit 97211 "Quality Return Fault ori"
{
    EventSubscriberInstance = Manual;

    var
        Mode: Text;

    /// <summary>Selects a no-op, late refusal, or forbidden commit for the bound scenario.</summary>
    procedure SetMode(Scenario: Text)
    begin
        Mode := Scenario;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Disp. Purchase Return", 'OnBeforeProcessDisposition', '', false, false)]
    local procedure NoOp(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var DidSomething: Boolean; var IsHandled: Boolean)
    begin
        if Mode = 'noop' then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Disp. Purchase Return", 'OnAfterProcessDisposition', '', false, false)]
    local procedure Refuse(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var CreatedReturnOrderPurchaseHeader: Record "Purchase Header"; var DidSomething: Boolean)
    begin
        if CreatedReturnOrderPurchaseHeader."No." = '' then
            exit;
        if Mode = 'commit' then
            Commit();
        if Mode = 'late' then
            Error('Injected late purchase return refusal.');
    end;
}
