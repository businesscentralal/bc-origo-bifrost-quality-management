namespace Origo.Bifrost.QualityManagement.Verification;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;

/// <summary>Explicitly removes the self-seeded, unposted worker-7 Q12M-D7 fixture and restores its original setup.</summary>
codeunit 97299 "QM Fixture Cleanup D7 ori"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    /// <summary>Deletes only the known owned fixture after verifying no posted inventory exists.</summary>
    [Test]
    procedure CleanupOwnedUnpostedFixture()
    var
        Inspection: Record "Qlty. Inspection Header";
        Item: Record Item;
        Unit: Record "Unit of Measure";
        ItemUnit: Record "Item Unit of Measure";
        Location: Record Location;
        JournalTemplate: Record "Item Journal Template";
        JournalBatch: Record "Item Journal Batch";
        JournalLine: Record "Item Journal Line";
        Ledger: Record "Item Ledger Entry";
        Setup: Record "Qlty. Management Setup";
        FixtureCode: Code[10];
        DestinationCode: Code[10];
        CleanupErr: Label 'Owned fixture safety or cleanup assertion failed.', Locked = true;
    begin
        // Story #12 verification only | Time: none | Risk: exact worker-owned, unposted Q12M-D7 fixture only
        FixtureCode := 'Q12M-D7';
        DestinationCode := 'D12M-D7';
        if CompanyName() <> 'CRONUS International Ltd.' then
            Error(CleanupErr);
        Ledger.SetRange("Item No.", FixtureCode);
        if not Ledger.IsEmpty() then
            Error(CleanupErr);
        Ledger.Reset();
        Ledger.SetFilter("Location Code", '%1|%2', FixtureCode, DestinationCode);
        if not Ledger.IsEmpty() then
            Error(CleanupErr);
        Inspection.Get(FixtureCode, 0);
        Inspection.TestField("Source Item No.", FixtureCode);
        Setup.Get();
        Setup.TestField("Item Reclass. Batch Name", FixtureCode);
        JournalTemplate.Get(FixtureCode);
        JournalTemplate.TestField(Type, JournalTemplate.Type::Transfer);
        JournalLine.SetRange("Journal Template Name", FixtureCode);
        JournalLine.SetRange("Journal Batch Name", FixtureCode);
        if JournalLine.Count() <> 4 then
            Error(CleanupErr);
        JournalLine.FindSet();
        repeat
            JournalLine.TestField("Item No.", FixtureCode);
            JournalLine.TestField("Location Code", FixtureCode);
            JournalLine.TestField("New Location Code", DestinationCode);
        until JournalLine.Next() = 0;
        JournalLine.DeleteAll(false);
        Inspection.Delete(false);
        ItemUnit.SetRange("Item No.", FixtureCode);
        ItemUnit.DeleteAll(false);
        Item.Get(FixtureCode);
        Item.Delete(false);
        Unit.Get(FixtureCode);
        Unit.Delete(false);
        Location.Get(FixtureCode);
        Location.Delete(false);
        Location.Get(DestinationCode);
        Location.Delete(false);
        JournalBatch.SetRange("Journal Template Name", FixtureCode);
        JournalBatch.DeleteAll(false);
        JournalTemplate.Delete(false);
        // setup-before.json records the original batch name as empty on worker-7's w129-17 tenant.
        Setup.Validate("Item Reclass. Batch Name", '');
        Setup.Modify(true);
        if not JournalLine.IsEmpty() or Inspection.Get(FixtureCode, 0) or Item.Get(FixtureCode) or
           Unit.Get(FixtureCode) or Location.Get(FixtureCode) or Location.Get(DestinationCode) or
           not JournalBatch.IsEmpty() or JournalTemplate.Get(FixtureCode)
        then
            Error(CleanupErr);
        Commit();
    end;
}
