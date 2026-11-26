namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Document;

/// <summary>Injects a late native write failure to prove media and staging share the rollback boundary.</summary>
codeunit 97266 "Quality Picture Fault ori"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. Inspection Header", 'OnBeforeModifyEvent', '', false, false)]
    local procedure RefusePicture(var Rec: Record "Qlty. Inspection Header"; var xRec: Record "Qlty. Inspection Header"; RunTrigger: Boolean)
    begin
        if (CopyStr(Rec."No.", 1, 8) = 'BIFTQ6-P') and Rec."Most Recent Picture".HasValue() then
            Error('Injected picture write refusal after media import.');
    end;
}
