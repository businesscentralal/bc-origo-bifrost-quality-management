namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;

/// <summary>Creates and cleans owned synthetic purchase receipt and inspection data; never changes business values under test.</summary>
codeunit 97212 "Quality Return Fixture ori" implements "Msg Interface ori"
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
        exit('Test-only: create or cleanup a BIFTQ13- fixture using action and runCode on a CRONUS company.');
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
        Tests: Codeunit "Quality Return Tst ori";
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
        if (StrLen(RunCodeToken.AsValue().AsText()) > 20) or (CopyStr(RunCodeToken.AsValue().AsText(), 1, 8) <> 'BIFTQ13-') then
            Error('runCode must start with BIFTQ13- and contain at most 20 characters.');
        RunCode := CopyStr(RunCodeToken.AsValue().AsText(), 1, 20);
        ActionName := ActionToken.AsValue().AsText();
        case ActionName of
            'create': begin
                if Inspection.Get(RunCode, 0) then
                    Error('The fixture already exists; inspect it rather than replaying creation.');
                Tests.SeedFixture(RunCode, Inspection);
                Response.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
                Response.Add('inspectionNo', Inspection."No.");
            end;
            'cleanup': begin
                Inspection.Get(RunCode, 0);
                Tests.Cleanup(RunCode);
                Inspection.SetRange("No.", RunCode);
                if not Inspection.IsEmpty() then
                    Error('Fixture cleanup was incomplete.');
                Response.Add('remainingInspections', 0);
                Response.Add('remainingFixtures', 0);
            end;
            else
                Error('action must be create or cleanup.');
        end;
        Response.Add('status', 'Success');
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;
}
