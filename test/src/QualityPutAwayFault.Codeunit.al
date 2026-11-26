namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Warehouse.InternalDocument;

/// <summary>Injects a failure after native put-away line creation to prove transaction rollback.</summary>
codeunit 97277 "Quality PutAway Fault ori"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Internal Put-away Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure FailAfterInsert(var Rec: Record "Whse. Internal Put-away Line"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            Error('Q16 injected late failure');
    end;
}
