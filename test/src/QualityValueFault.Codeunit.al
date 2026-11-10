namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Document;

/// <summary>Injects a late business refusal to verify transaction rollback after line changes.</summary>
codeunit 97203 "Quality Value Fault ori"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. Inspection Header", OnAfterFindLineUpdateResultFromLines, '', false, false)]
    local procedure RefuseAfterLineWrite(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var QltyInspectionLine: Record "Qlty. Inspection Line")
    var
        RefusalErr: Label 'Injected late quality validation refusal.', Locked = true;
    begin
        Error(ErrorInfo.Create(RefusalErr));
    end;
}
