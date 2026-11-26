namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;

/// <summary>Creates and removes an isolated inspection and warehouse fixture, without external calls.</summary>
codeunit 97279 "Quality PutAway Fixture ori"
{
    var
        HadSetup: Boolean;

    /// <summary>Seeds demo stock in a native warehouse location created solely for this invocation.</summary>
    procedure Seed(var Inspection: Record "Qlty. Inspection Header"; var Location: Record Location; var SourceBin: Record Bin)
    var
        Unit: Record "Unit of Measure";
        Item: Record Item;
        ItemUnit: Record "Item Unit of Measure";
        BinContent: Record "Bin Content";
        Entry: Record "Warehouse Entry";
        Setup: Record "Qlty. Management Setup";
        Employee: Record "Warehouse Employee";
        Warehouse: Codeunit "Library - Warehouse";
        FixtureNo: Code[10];
        NextEntryNo: Integer;
    begin
        FixtureNo := CopyStr('Q16' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, 10);
        Unit.Code := FixtureNo;
        Unit.Insert(false);
        Item."No." := FixtureNo;
        Item.Description := 'Issue 16 owned demo fixture';
        Item."Base Unit of Measure" := FixtureNo;
        Item.Insert(false);
        ItemUnit."Item No." := FixtureNo;
        ItemUnit.Code := FixtureNo;
        ItemUnit."Qty. per Unit of Measure" := 1;
        ItemUnit.Insert(false);
        Warehouse.CreateFullWMSLocation(Location, 3);
        Warehouse.CreateWarehouseEmployee(Employee, Location.Code, false);
        Warehouse.FindBin(SourceBin, Location.Code, 'QC', 1);
        Warehouse.CreateBinContent(BinContent, Location.Code, SourceBin."Zone Code", SourceBin.Code, Item."No.", '', Unit.Code);
        Entry.SetLoadFields("Entry No.");
        if Entry.FindLast() then
            NextEntryNo := Entry."Entry No.";
        Entry.Init();
        Entry."Entry No." := NextEntryNo + 1;
        Entry."Location Code" := Location.Code;
        Entry."Zone Code" := SourceBin."Zone Code";
        Entry."Bin Code" := SourceBin.Code;
        Entry."Item No." := Item."No.";
        Entry."Unit of Measure Code" := Unit.Code;
        Entry."Qty. per Unit of Measure" := 1;
        Entry.Quantity := 10;
        Entry."Qty. (Base)" := 10;
        Entry.Insert(false);
        HadSetup := Setup.Get();
        if not HadSetup then
            Setup.Insert(false);
        Inspection."No." := FixtureNo;
        Inspection."Source Item No." := Item."No.";
        Inspection."Location Code" := Location.Code;
        Inspection."Source Quantity (Base)" := 5;
        Inspection."Fail Quantity" := 3;
        Inspection."Pass Quantity" := 2;
        Inspection.Insert(false);
    end;

    /// <summary>Removes only this invocation's warehouse, stock, inspection, item and dependent fixture records.</summary>
    procedure Cleanup(Inspection: Record "Qlty. Inspection Header"; Location: Record Location)
    var
        InternalHeader: Record "Whse. Internal Put-away Header";
        InternalLine: Record "Whse. Internal Put-away Line";
        Header: Record "Warehouse Activity Header";
        ActivityLine: Record "Warehouse Activity Line";
        PutAwayRequest: Record "Whse. Put-away Request";
        WhseRequest: Record "Warehouse Request";
        WorksheetLine: Record "Whse. Worksheet Line";
        Entry: Record "Warehouse Entry";
        BinContent: Record "Bin Content";
        Bin: Record Bin;
        Zone: Record Zone;
        Employee: Record "Warehouse Employee";
        PostingSetup: Record "Inventory Posting Setup";
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        Item: Record Item;
        ItemUnit: Record "Item Unit of Measure";
        Unit: Record "Unit of Measure";
        Setup: Record "Qlty. Management Setup";
    begin
        if (CopyStr(Inspection."No.", 1, 3) <> 'Q16') or (Inspection."Location Code" <> Location.Code) then
            Error('Only the supplied owned Q16 fixture may be removed.');
        InternalLine.SetRange("Location Code", Location.Code);
        InternalLine.DeleteAll(false);
        InternalHeader.SetRange("Location Code", Location.Code);
        InternalHeader.DeleteAll(false);
        ActivityLine.SetRange("Location Code", Location.Code);
        ActivityLine.DeleteAll(false);
        Header.SetRange("Location Code", Location.Code);
        Header.DeleteAll(false);
        PutAwayRequest.SetRange("Location Code", Location.Code);
        PutAwayRequest.DeleteAll(false);
        WhseRequest.SetRange("Location Code", Location.Code);
        WhseRequest.DeleteAll(false);
        WorksheetLine.SetRange("Location Code", Location.Code);
        WorksheetLine.DeleteAll(false);
        Entry.SetRange("Item No.", Inspection."Source Item No.");
        Entry.DeleteAll(false);
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.DeleteAll(false);
        Bin.SetRange("Location Code", Location.Code);
        Bin.DeleteAll(false);
        Zone.SetRange("Location Code", Location.Code);
        Zone.DeleteAll(false);
        Employee.SetRange("Location Code", Location.Code);
        Employee.DeleteAll(false);
        PostingSetup.SetRange("Location Code", Location.Code);
        PostingSetup.DeleteAll(false);
        PutAwayTemplateLine.SetRange("Put-away Template Code", Location."Put-away Template Code");
        PutAwayTemplateLine.DeleteAll(false);
        if PutAwayTemplateHeader.Get(Location."Put-away Template Code") then
            PutAwayTemplateHeader.Delete(false);
        Location.Delete(false);
        ItemUnit.SetRange("Item No.", Inspection."Source Item No.");
        ItemUnit.DeleteAll(false);
        Item.Get(Inspection."Source Item No.");
        Item.Delete(false);
        Unit.Get(Inspection."Source Item No.");
        Unit.Delete(false);
        Inspection.Delete(false);
        if not HadSetup then
            if Setup.Get() then
                Setup.Delete(false);
    end;
}
