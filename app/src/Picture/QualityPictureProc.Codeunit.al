namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;
using System.Text;
using System.Utilities;
using System.Security.AccessControl;
using System.Security.User;

/// <summary>Validates and writes an inspection picture in one rollback boundary, including staging consumption.</summary>
codeunit 10035297 "Quality Picture Proc ori"
{
    Access = Internal;

    var
        InvalidLbl: Label 'Parameter %1 is invalid.', Comment = '%1 = parameter name|is-IS=Færibreytan %1 er ógild.';
        MissingLbl: Label 'Parameter %1 is required.', Comment = '%1 = parameter name|is-IS=Færibreytan %1 er áskilin.';
        NextLbl: Label 'Correct the named parameter and retry; nothing was changed.', Comment = 'is-IS=Leiðréttu tilgreinda færibreytu og reyndu aftur; engu var breytt.';
        OpenLbl: Label 'The inspection must be open.', Comment = 'is-IS=Skoðunin verður að vera opin.';
        MissingInspectionLbl: Label 'The inspection was not found.', Comment = 'is-IS=Skoðunin fannst ekki.';
        StagingLbl: Label 'The staged upload is unavailable.', Comment = 'is-IS=Sviðssetta upphleðslan er ekki tiltæk.';
        PermissionExpectedLbl: Label 'BIFROST QM Full ori and native inspection modify permission', Comment = 'is-IS=BIFROST QM Full ori og staðlaðar breytingaheimildir á skoðun';
        PermissionLbl: Label 'BIFROST QM Full ori and native inspection modify permission are required.', Comment = 'is-IS=BIFROST QM Full ori og staðlaðar breytingaheimildir á skoðun eru nauðsynlegar.';
        ImageLbl: Label 'JPEG, PNG or BMP bytes, at most 1048576 bytes', Comment = 'is-IS=JPEG-, PNG- eða BMP-bæti, að hámarki 1048576 bæti';
        GuidLbl: Label 'a non-empty SystemId GUID', Comment = 'is-IS=SystemId GUID sem er ekki tómt';
        SourceLbl: Label 'exactly one of base64 and stagingId', Comment = 'is-IS=nákvæmlega annað af base64 og stagingId';
        StageExpectedLbl: Label 'an upload owned by the current user in the current company', Comment = 'is-IS=upphleðsla í eigu núverandi notanda í núverandi fyrirtæki';
        OpenExpectedLbl: Label 'an open inspection', Comment = 'is-IS=opin skoðun';
        TextExpectedLbl: Label 'a non-empty text value', Comment = 'is-IS=textagildi sem er ekki tómt';
        FileExpectedLbl: Label 'a file name of 1 to 250 characters without path separators', Comment = 'is-IS=skráarheiti með 1 til 250 stöfum án slóðaskilja';

    [CommitBehavior(CommitBehavior::Error)]
    /// <summary>All failures raise inside this transaction; Take and media changes therefore roll back together.</summary>
    /// <param name="Argument">Public dispatcher argument.</param>
    internal procedure Apply(var Argument: Record "Message Argument ori")
    var
        AccessMarker: Record "Quality Picture Access ori";
        Inspection: Record "Qlty. Inspection Header";
        Blob: Codeunit "Temp Blob";
        Staging: Codeunit "Blob Staging ori";
        Request: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
        InspectionId: Guid;
        StagingId: Guid;
        KeyName: Text;
        Encoded: Text;
        FileName: Text;
        Mime: Text;
        Extension: Text;
        Input: InStream;
        Output: OutStream;
        CountText: Text;
    begin
        if not AccessMarker.WritePermission() or not CanModifyInspection() then
            Refuse(Argument, "Bifrost Error Code ori"::PermissionDenied, PermissionLbl, 'permissionSet', PermissionExpectedLbl);
        Request := Argument.GetRequestJson();
        foreach KeyName in Request.Keys() do
            if not (KeyName in ['inspectionSystemId', 'base64', 'stagingId', 'fileName', 'expectedCount']) then
                Refuse(Argument, "Bifrost Error Code ori"::UnknownParameter, StrSubstNo(InvalidLbl, KeyName), KeyName, 'inspectionSystemId, base64, stagingId, fileName, expectedCount');
        InspectionId := ReadGuid(Request, 'inspectionSystemId', Argument);
        if Request.Contains('expectedCount') then begin
            Request.Get('expectedCount', Token);
            Token.WriteTo(CountText);
            if CountText <> '1' then
                Refuse(Argument, "Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(InvalidLbl, 'expectedCount'), 'expectedCount', '1');
        end;
        if Request.Contains('base64') and Request.Contains('stagingId') then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidLbl, 'base64/stagingId'), 'base64', SourceLbl);
        if not Request.Contains('base64') and not Request.Contains('stagingId') then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingLbl, 'base64/stagingId'), 'base64', SourceLbl);
        FileName := 'inspection-picture';
        if Request.Contains('fileName') then begin
            FileName := ReadText(Request, 'fileName', Argument);
            if (StrLen(FileName) > 250) or FileName.Contains('/') or FileName.Contains('\') then
                Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidLbl, 'fileName'), 'fileName', FileExpectedLbl);
        end;
        // Mutable full record: no SetLoadFields before Modify. Lock the exact inspection before staging or media writes.
        Inspection.ReadIsolation := IsolationLevel::UpdLock;
        if not Inspection.GetBySystemId(InspectionId) then
            Refuse(Argument, "Bifrost Error Code ori"::RecordNotFound, MissingInspectionLbl, 'inspectionSystemId', GuidLbl);
        if Inspection.Status <> Inspection.Status::Open then
            Refuse(Argument, "Bifrost Error Code ori"::PreconditionFailed, OpenLbl, 'inspectionSystemId', OpenExpectedLbl);
        if Request.Contains('stagingId') then begin
            StagingId := ReadGuid(Request, 'stagingId', Argument);
            if not Staging.Take(StagingId, Blob) then
                Refuse(Argument, "Bifrost Error Code ori"::RecordNotFound, StagingLbl, 'stagingId', StageExpectedLbl);
        end else begin
            Encoded := ReadText(Request, 'base64', Argument);
            // Bound decoding allocation as well as decoded bytes. 4 * ceil(1048576 / 3).
            if StrLen(Encoded) > 1398104 then
                Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidLbl, 'base64'), 'base64', ImageLbl);
            Blob.CreateOutStream(Output);
            if not Decode(Encoded, Output) then
                Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidLbl, 'base64'), 'base64', ImageLbl);
        end;
        if (Blob.Length() = 0) or (Blob.Length() > 1048576) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidLbl, 'base64/stagingId'), SourceParameter(Request), ImageLbl);
        Blob.CreateInStream(Input);
        Mime := ImageMime(Input, Extension);
        if Mime = '' then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidLbl, 'base64/stagingId'), SourceParameter(Request), ImageLbl);
        Blob.CreateInStream(Input);
        Clear(Inspection."Most Recent Picture");
        Inspection."Most Recent Picture".ImportStream(Input, CopyStr(FileName, 1, 250 - StrLen(Extension)) + Extension, Mime);
        Inspection.Modify();
        Response.Add('status', 'Success');
        Response.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Response.Add('additionalHandlingApplied', false);
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure CanModifyInspection(): Boolean
    var
        TempPermission: Record "Expanded Permission" temporary;
        UserPermissions: Codeunit "User Permissions";
    begin
        TempPermission := UserPermissions.GetEffectivePermission(TempPermission."Object Type"::"Table Data", Database::"Qlty. Inspection Header");
        // This codeunit grants no elevated inspection permission; native Modify still enforces the caller grant.
        exit(TempPermission."Modify Permission" = TempPermission."Modify Permission"::Yes);
    end;

    local procedure SourceParameter(Request: JsonObject): Text
    begin
        if Request.Contains('stagingId') then
            exit('stagingId');
        exit('base64');
    end;

    local procedure ReadText(
        Request: JsonObject;
        Name: Text;
        var Argument: Record "Message Argument ori") Value: Text
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get(Name, Token) then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingLbl, Name), Name, GuidLbl);
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidLbl, Name), Name, TextExpectedLbl);
        Value := Token.AsValue().AsText();
        if Value = '' then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidLbl, Name), Name, TextExpectedLbl);
    end;

    local procedure ReadGuid(
        Request: JsonObject;
        Name: Text;
        var Argument: Record "Message Argument ori") Value: Guid
    begin
        if not Evaluate(Value, ReadText(Request, Name, Argument)) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidLbl, Name), Name, GuidLbl);
        if IsNullGuid(Value) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidLbl, Name), Name, GuidLbl);
    end;

    [TryFunction]
    local procedure Decode(Encoded: Text; var Output: OutStream)
    var
        Convert: Codeunit "Base64 Convert";
    begin
        // Only a temporary blob is written in this TryFunction. Persistent writes stay outside it.
        Convert.FromBase64(Encoded, Output);
    end;

    local procedure ImageMime(var Input: InStream; var Extension: Text): Text
    var
        Picture: Codeunit Image;
    begin
        if not ReadImage(Picture, Input) then
            exit('');
        case Picture.GetFormat() of
            Enum::"Image Format"::Png:
                begin
                    Extension := '.png';
                    exit('image/png');
                end;
            Enum::"Image Format"::Jpeg:
                begin
                    Extension := '.jpg';
                    exit('image/jpeg');
                end;
            Enum::"Image Format"::Bmp:
                begin
                    Extension := '.bmp';
                    exit('image/bmp');
                end;
        end;
        exit('');
    end;

    [TryFunction]
    local procedure ReadImage(var Picture: Codeunit Image; var Input: InStream)
    begin
        // Decoder validates actual image bytes; this creates no persistent media.
        Picture.FromStream(Input);
    end;

    local procedure Refuse(
        var Argument: Record "Message Argument ori";
        Code: Enum "Bifrost Error Code ori";
        Message: Text;
        Parameter: Text;
        Expected: Text)
    begin
        Argument.AddError(Code, Message, Parameter, '', Expected, NextLbl);
        Argument.RaiseCollectedErrors(Code, Message);
    end;
}
