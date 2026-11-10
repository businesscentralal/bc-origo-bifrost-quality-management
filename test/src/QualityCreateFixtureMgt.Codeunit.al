namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Document;
using Origo.Bifrost;

/// <summary>Creates and cleans owned synthetic inspection data; never changes business values under test.</summary>
codeunit 97212 "Quality Create Fixture Mgt ori" implements "Msg Interface ori"
{
    /// <summary>Exposes fixtures only on CRONUS demonstration companies.</summary>
    procedure IsEnabled(): Boolean
    begin
        exit(CopyStr(CompanyName(), 1, 6) = 'CRONUS');
    end;

    /// <summary>Names the fixture header table.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Qlty. Inspection Header");
    end;

    /// <summary>Describes this test-only lifecycle.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit('Test-only: create or cleanup a XQ3 fixture using action and runCode on a CRONUS company.');
    end;

    /// <summary>Declares fixture writes.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Controls owned fixture creation and cleanup; no test operation is executed here.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Inspection: Record "Qlty. Inspection Header";
        Item: Record Item;
        SavedSetup: Record "Quality Create Fixture ori";
        Tests: Codeunit "Quality Create Tst ori";
        Request: JsonObject;
        Response: JsonObject;
        ActionToken: JsonToken;
        RunCodeToken: JsonToken;
        RunCode: Code[20];
        ActionName: Text;
    begin
        if not IsEnabled() then
            Error('Fixtures require a CRONUS company.');
        Argument.AssertVersion1();
        Request := Argument.GetRequestJson();
        if not Request.Get('action', ActionToken) or not Request.Get('runCode', RunCodeToken) then
            Error('action and runCode are required.');
        if (StrLen(RunCodeToken.AsValue().AsText()) > 20) or (CopyStr(RunCodeToken.AsValue().AsText(), 1, 3) <> 'XQ3') then
            Error('runCode must start with XQ3 and contain at most 20 characters.');
        RunCode := CopyStr(RunCodeToken.AsValue().AsText(), 1, 20);
        ActionName := ActionToken.AsValue().AsText();
        case ActionName of
            'create': begin
                if SavedSetup.Get(RunCode) then
                    Error('The fixture already exists; inspect it instead of replaying creation.');
                Tests.SeedFixture(RunCode, Item);
                Response.Add('sourceSystemId', Format(Item.SystemId, 0, 4));
                Response.Add('sourceTableId', Database::Item);
                Response.Add('templateCode', RunCode);
            end;
            'cleanup': begin
                Tests.CleanupFixture(RunCode);
                Inspection.SetRange("Template Code", RunCode);
                Item.SetRange("No.", RunCode);
                SavedSetup.SetRange(Code, RunCode);
                if not Inspection.IsEmpty() or not Item.IsEmpty() or not SavedSetup.IsEmpty() then
                    Error('Fixture cleanup was incomplete.');
                Response.Add('remainingInspections', 0);
                Response.Add('remainingSources', 0);
                Response.Add('remainingFixtureState', 0);
            end;
            else
                Error('action must be create or cleanup.');
        end;
        Response.Add('status', 'Success');
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;
}
