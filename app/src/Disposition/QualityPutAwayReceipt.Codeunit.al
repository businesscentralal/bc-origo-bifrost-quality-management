namespace Origo.Bifrost.QualityManagement;

using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.InternalDocument;

/// <summary>Collects document numbers inserted during one bound disposition invocation.</summary>
codeunit 10035309 "Quality PutAway Receipt ori"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        InternalDocuments: JsonArray;
        WarehouseDocuments: JsonArray;

    /// <summary>Returns only final documents of the requested kind.</summary>
    procedure GetDocuments(Kind: Text): JsonArray
    begin
        if Kind = 'internal' then
            exit(InternalDocuments);
        exit(WarehouseDocuments);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Internal Put-away Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure InternalInserted(var Rec: Record "Whse. Internal Put-away Header"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            InternalDocuments.Add(Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure WarehouseInserted(var Rec: Record "Warehouse Activity Header"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            if Rec.Type = Rec.Type::"Put-away" then
                WarehouseDocuments.Add(Rec."No.");
    end;
}
