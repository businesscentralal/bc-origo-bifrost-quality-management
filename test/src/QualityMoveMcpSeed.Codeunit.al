namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;

/// <summary>
/// Creates isolated Q12M-D7 inventory-disposition fixtures in the worker-owned development company.
/// Invoked explicitly by the verification harness; it never changes Foundation guards, licensing or consent.
/// All fixture data is removed when that owned ephemeral container is deleted after MCP/UI verification.
/// </summary>
codeunit 97253 "Quality Move MCP Seed ori"
{
    Access = Internal;

    trigger OnRun()
    var
        Item: Record Item;
        Unit: Record "Unit of Measure";
        ItemUnit: Record "Item Unit of Measure";
        Location: Record Location;
        JournalTemplate: Record "Item Journal Template";
        JournalBatch: Record "Item Journal Batch";
        Setup: Record "Qlty. Management Setup";
        Inspection: Record "Qlty. Inspection Header";
        FixtureCode: Code[10];
    begin
        FixtureCode := 'Q12M-D7';
        if Item.Get(FixtureCode) or Unit.Get(FixtureCode) or Inspection.Get(FixtureCode, 0) then
            Error('An owned Q12M-D7 fixture already exists. Inspect its state before recovery.');
        Unit.Code := FixtureCode;
        Unit.Insert(false);
        Item.Init();
        Item."No." := FixtureCode;
        Item.Description := 'Dainn issue 12 owned MCP inventory';
        Item."Base Unit of Measure" := FixtureCode;
        Item.Insert(false);
        ItemUnit."Item No." := FixtureCode;
        ItemUnit.Code := FixtureCode;
        ItemUnit."Qty. per Unit of Measure" := 1;
        ItemUnit.Insert(false);
        Location.Code := FixtureCode;
        Location.Insert(false);
        Location.Code := 'D12M-D7';
        Location.Insert(false);
        JournalTemplate.Name := FixtureCode;
        JournalTemplate.Type := JournalTemplate.Type::Transfer;
        JournalTemplate."Page ID" := Page::"Item Reclass. Journal";
        JournalTemplate.Insert(false);
        JournalBatch."Journal Template Name" := FixtureCode;
        JournalBatch.Name := FixtureCode;
        JournalBatch.Insert(false);
        Setup.Get();
        Setup."Item Reclass. Batch Name" := FixtureCode;
        Setup.Modify(false);
        Inspection.Init();
        Inspection."No." := FixtureCode;
        Inspection."Source Item No." := FixtureCode;
        Inspection."Location Code" := FixtureCode;
        Inspection."Source Quantity (Base)" := 5;
        Inspection."Fail Quantity" := 3;
        Inspection."Pass Quantity" := 2;
        Inspection.Insert(false);
    end;
}
