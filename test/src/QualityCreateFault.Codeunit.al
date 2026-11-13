namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Document;

/// <summary>Injects an error after the native header insert to prove transaction rollback.</summary>
codeunit 97213 "Quality Create Fault ori"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. Inspection Header", OnAfterInsertEvent, '', false, false)]
    local procedure FailAfterInsert(var Rec: Record "Qlty. Inspection Header"; RunTrigger: Boolean)
    begin
        if (not Rec.IsTemporary()) and (CopyStr(Rec."Template Code", 1, 3) = 'XQ3') then
            Error('Injected late native creation failure.');
    end;
}
