namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;
using System.Text;
using System.Utilities;

/// <summary>Generates tiny synthetic images and owned CRONUS fixtures for dispatcher and MCP tests.</summary>
codeunit 97265 "Quality Picture Fixture ori" implements "Msg Interface ori"
{
    /// <summary>Only exposes test fixtures in demo companies.</summary>
    procedure IsEnabled(): Boolean
    begin
        exit(CopyStr(CompanyName(), 1, 6) = 'CRONUS');
    end;

    /// <summary>Names the fixture target.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Qlty. Inspection Header");
    end;

    /// <summary>Describes this test-only message.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit('Test-only: seed, stage or inspect an owned BIFTQ6-P picture fixture.');
    end;

    /// <summary>Declares test fixture writes.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Runs the explicitly requested fixture lifecycle; never executes AddPicture itself.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Inspection: Record "Qlty. Inspection Header";
        Blob: Codeunit "Temp Blob";
        Staging: Codeunit "Blob Staging ori";
        Request: JsonObject;
        Response: JsonObject;
        RunCode: Code[20];
        Action: Text;
        FormatName: Text;
        StageId: Guid;
        Input: InStream;
    begin
        if not IsEnabled() then
            Error('Fixtures require a CRONUS company.');
        Request := Argument.GetRequestJson();
        if (CopyStr(Request.GetText('runCode'), 1, 8) <> 'BIFTQ6-P') or (StrLen(Request.GetText('runCode')) > 20) then
            Error('runCode must start with BIFTQ6-P and have at most 20 characters.');
        RunCode := CopyStr(Request.GetText('runCode'), 1, 20);
        Action := Request.GetText('action');
        case Action of
            'seed':
                begin
                    Seed(RunCode, Inspection);
                    Response.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
                end;
            'stage':
                begin
                    FormatName := Request.GetText('format');
                    MakeImage(FormatName, Blob);
                    Blob.CreateInStream(Input);
                    StageId := Staging.Create(Input, 'fixture.' + FormatName, '', 'quality11-test');
                    Response.Add('stagingId', Format(StageId, 0, 4));
                    Response.Add('base64', Encoded(Blob));
                    Response.Add('size', Blob.Length());
                end;
            'inspect':
                begin
                    Inspection.Get(RunCode, 0);
                    Response.Add('hasPicture', Inspection."Most Recent Picture".HasValue());
                    Response.Add('mediaId', Format(Inspection."Most Recent Picture".MediaId(), 0, 4));
                    if Request.Contains('stagingId') then begin
                        Evaluate(StageId, Request.GetText('stagingId'));
                        Response.Add('stagingExists', Staging.Exists(StageId));
                    end;
                end;
            'finish':
                begin
                    Inspection.Get(RunCode, 0);
                    Inspection.Status := Inspection.Status::Finished;
                    Inspection.Modify();
                end;
            else
                Error('Unknown fixture action.');
        end;
        Response.Add('status', 'Success');
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    /// <summary>Inserts one synthetic open inspection with a unique owned key.</summary>
    procedure Seed(RunCode: Code[20]; var Inspection: Record "Qlty. Inspection Header")
    var
        Setup: Record "Setup ori";
    begin
        Setup.InsertIfNotExists();
        Inspection.Init();
        Inspection."No." := RunCode;
        Inspection.Status := Inspection.Status::Open;
        Inspection.Insert();
    end;

    /// <summary>Removes only the exact synthetic fixture inspection.</summary>
    procedure Cleanup(RunCode: Code[20])
    var
        Inspection: Record "Qlty. Inspection Header";
    begin
        if CopyStr(RunCode, 1, 8) <> 'BIFTQ6-P' then
            Error('Only owned fixtures can be removed.');
        if Inspection.Get(RunCode, 0) then
            Inspection.Delete(true);
    end;

    /// <summary>Builds a one-pixel BMP in memory and encodes variants with the public Image API.</summary>
    procedure MakeImage(FormatName: Text; var Blob: Codeunit "Temp Blob")
    var
        Convert: Codeunit "Base64 Convert";
        Picture: Codeunit Image;
        SeedBlob: Codeunit "Temp Blob";
        Input: InStream;
        Output: OutStream;
        SeedOutput: OutStream;
        Value: Byte;
        Index: Integer;
        TargetSize: Integer;
    begin
        Clear(Blob);
        if FormatName = 'invalid' then begin
            Blob.CreateOutStream(Output);
            Output.WriteText('not an image');
            exit;
        end;
        // Generated BMP file header, BITMAPINFOHEADER and one red pixel; no external file or provider.
        SeedBlob.CreateOutStream(SeedOutput);
        Convert.FromBase64('Qk06AAAAAAAAADYAAAAoAAAAAQAAAAEAAAABABgAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAD/AA==', SeedOutput);
        SeedBlob.CreateInStream(Input);
        if FormatName in ['png', 'jpg', 'gif'] then begin
            Picture.FromStream(Input);
            case FormatName of
                'png':
                    Picture.SetFormat(Enum::"Image Format"::Png);
                'gif':
                    Picture.SetFormat(Enum::"Image Format"::Gif);
                else
                    Picture.SetFormat(Enum::"Image Format"::Jpeg);
            end;
            Blob.CreateOutStream(Output);
            Picture.Save(Output);
            exit;
        end;
        // One writer owns the entire output cursor. Do not reuse the Base64 Convert writer for appending.
        Blob.CreateOutStream(Output);
        while not Input.EOS() do begin
            Input.Read(Value);
            Output.Write(Value);
        end;
        if FormatName in ['limit', 'oversize'] then begin
            TargetSize := 1048576;
            if FormatName = 'oversize' then
                TargetSize += 1;
            Value := 0;
            for Index := SeedBlob.Length() + 1 to TargetSize do
                Output.Write(Value);
            if Blob.Length() <> TargetSize then
                Error('Generated fixture has %1 bytes; expected %2.', Blob.Length(), TargetSize);
        end;
    end;

    /// <summary>Encodes generated bytes for a base64 dispatcher request.</summary>
    procedure Encoded(var Blob: Codeunit "Temp Blob"): Text
    var
        Convert: Codeunit "Base64 Convert";
        Input: InStream;
    begin
        Blob.CreateInStream(Input);
        exit(Convert.ToBase64(Input));
    end;
}
