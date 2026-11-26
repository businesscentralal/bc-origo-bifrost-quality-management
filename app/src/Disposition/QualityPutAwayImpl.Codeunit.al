namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Origo.Bifrost;

/// <summary>Creates standard put-away documents in one rollback transaction, without registering stock.</summary>
codeunit 10035308 "Quality PutAway Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        DescriptionLbl: Label 'Creates an internal or warehouse put-away for one quality inspection without registering it.', MaxLength = 250, Comment = 'is-IS=Stofnar innri frágang eða vöruhúsafrágang fyrir eina gæðaskoðun án skráningar.';
        InvalidErr: Label 'Parameter %1 is missing or invalid.', Comment = '%1 = parameter name|is-IS=Færibreytuna %1 vantar eða hún er ógild.';
        NextStepLbl: Label 'Correct the parameter and retry; use Data.Records.Get to find the inspection SystemId.', Comment = 'is-IS=Leiðréttu færibreytuna og reyndu aftur; notaðu Data.Records.Get til að finna SystemId skoðunar.';
        PermissionErr: Label 'The BIFROST QM Full ori permission set is required.', Comment = 'is-IS=Heimildasafnið BIFROST QM Full ori er nauðsynlegt.';
        NativeErr: Label 'Business Central did not create a put-away. Check warehouse location, bins, stock and inspection quantity.', Comment = 'is-IS=Business Central stofnaði ekki frágang. Athugaðu vöruhúsastaðsetningu, hólf, birgðir og magn skoðunar.';
        QuantityLbl: Label 'a positive quantity within the selected inspection quantity', Comment = 'is-IS=jákvætt magn innan valins magns skoðunar';
        ExactCodeLbl: Label 'an exact code without filter syntax', Comment = 'is-IS=nákvæmur kóði án síusetningar';
        IdLbl: Label 'the SystemId GUID of an existing quality inspection', Comment = 'is-IS=SystemId GUID gæðaskoðunar sem er til';
        KnownKeyLbl: Label 'a declared contract parameter', Comment = 'is-IS=skilgreind færibreyta samnings';
        CountLbl: Label 'one quality inspection', Comment = 'is-IS=ein gæðaskoðun';

    trigger OnRun()
    begin
        PerformPutAway(Rec);
    end;

    /// <summary>Isolates native document creation so a late refusal rolls back the complete operation.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if Argument."Omit Commit" then begin
            PerformPutAway(Argument);
            exit;
        end;
        if not Codeunit.Run(Codeunit::"Quality PutAway Impl ori", Argument) then
            Argument.RespondWithLastError();
    end;

    // Native release and put-away creation call Commit(); Ignore keeps the whole operation in one transaction, so any later refusal rolls back every document.
    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure PerformPutAway(var Argument: Record "Message Argument ori")
    var
        Capability: Record "Quality PutAway Access ori";
        Inspection: Record "Qlty. Inspection Header";
        TempInstruction: Record "Qlty. Disposition Buffer" temporary;
        Receipt: Codeunit "Quality PutAway Receipt ori";
        ConfirmGate: Codeunit "Confirm Gate ori";
        Disposition: Interface "Qlty. Disposition";
        Request: JsonObject;
        Response: JsonObject;
        Documents: JsonArray;
        Token: JsonToken;
        InspectionId: Guid;
        KeyName: Text;
        Kind: Text;
        QuantityBasis: Text;
        Serialized: Text;
        Quantity: Decimal;
        ReleaseImmediately: Boolean;
    begin
        if not Capability.WritePermission() then
            Error(ErrorInfo.Create(PermissionErr));
        Request := Argument.GetRequestJson();
        foreach KeyName in Request.Keys() do
            if not (KeyName in ['inspectionSystemId', 'kind', 'quantityBasis', 'quantity', 'sourceLocationCode', 'sourceBinCode', 'releaseImmediately', 'confirm', 'expectedCount']) then
                Refuse(Argument, KeyName, KnownKeyLbl);
        if not Evaluate(InspectionId, ReadText(Request, 'inspectionSystemId', true, 38, Argument)) then
            Refuse(Argument, 'inspectionSystemId', IdLbl);
        if IsNullGuid(InspectionId) then
            Refuse(Argument, 'inspectionSystemId', IdLbl);
        Kind := ReadText(Request, 'kind', true, 10, Argument);
        case Kind of
            'internal': TempInstruction."Disposition Action" := TempInstruction."Disposition Action"::"Create Internal Put-away";
            'warehouse': TempInstruction."Disposition Action" := TempInstruction."Disposition Action"::"Create Warehouse Put-away";
            else
                Refuse(Argument, 'kind', 'internal, warehouse');
        end;
        if (Kind = 'warehouse') and Request.Contains('releaseImmediately') then
            Refuse(Argument, 'releaseImmediately', 'kind=internal');
        ReleaseImmediately := ReadBoolean(Request, 'releaseImmediately', Argument);
        if not ReadBoolean(Request, 'confirm', Argument) then
            Refuse(Argument, 'confirm', 'true');
        QuantityBasis := ReadText(Request, 'quantityBasis', true, 10, Argument);
        case QuantityBasis of
            'failed': TempInstruction."Quantity Behavior" := TempInstruction."Quantity Behavior"::"Failed Quantity";
            'passed': TempInstruction."Quantity Behavior" := TempInstruction."Quantity Behavior"::"Passed Quantity";
            else
                Refuse(Argument, 'quantityBasis', 'failed, passed');
        end;
        TempInstruction."Location Filter" := CopyStr(ReadText(Request, 'sourceLocationCode', false, 10, Argument), 1, MaxStrLen(TempInstruction."Location Filter"));
        TempInstruction."Bin Filter" := CopyStr(ReadText(Request, 'sourceBinCode', false, 20, Argument), 1, MaxStrLen(TempInstruction."Bin Filter"));
        ValidateCode(TempInstruction."Location Filter", 'sourceLocationCode', Argument);
        ValidateCode(TempInstruction."Bin Filter", 'sourceBinCode', Argument);
        Inspection.ReadIsolation := IsolationLevel::UpdLock;
        if not Inspection.GetBySystemId(InspectionId) then
            Refuse(Argument, 'inspectionSystemId', IdLbl);
        if QuantityBasis = 'failed' then
            Quantity := Inspection."Fail Quantity"
        else
            Quantity := Inspection."Pass Quantity";
        if Quantity <= 0 then
            Refuse(Argument, 'quantityBasis', QuantityLbl);
        if Request.Get('quantity', Token) then begin
            Token.WriteTo(Serialized);
            if (CopyStr(Serialized, 1, 1) = '"') or not Evaluate(TempInstruction."Qty. To Handle (Base)", Serialized, 9) then
                Refuse(Argument, 'quantity', QuantityLbl);
            if (TempInstruction."Qty. To Handle (Base)" <= 0) or (TempInstruction."Qty. To Handle (Base)" > Quantity) then
                Refuse(Argument, 'quantity', QuantityLbl);
            TempInstruction."Quantity Behavior" := TempInstruction."Quantity Behavior"::"Specific Quantity";
        end;
        if not ConfirmGate.Confirm(Argument, 1, CountLbl) then
            exit;
        if ReleaseImmediately then
            TempInstruction."Entry Behavior" := TempInstruction."Entry Behavior"::Post;
        Disposition := TempInstruction."Disposition Action";
        BindSubscription(Receipt);
        if not Disposition.PerformDisposition(Inspection, TempInstruction) then
            Error(ErrorInfo.Create(NativeErr));
        UnbindSubscription(Receipt);
        Documents := Receipt.GetDocuments(Kind);
        if Documents.Count() = 0 then
            Error(ErrorInfo.Create(NativeErr));
        Response.Add('status', 'Success');
        Response.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Response.Add('kind', Kind);
        Response.Add('documentNumbers', Documents);
        Response.Add('released', ReleaseImmediately);
        Response.Add('registered', false);
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure Refuse(var Argument: Record "Message Argument ori"; ParameterName: Text; Expected: Text)
    var
        Message: Text;
    begin
        Message := StrSubstNo(InvalidErr, ParameterName);
        Argument.AddError("Bifrost Error Code ori"::InvalidParameter, Message, ParameterName, '', Expected, NextStepLbl);
        Argument.RaiseCollectedErrors("Bifrost Error Code ori"::InvalidParameter, Message);
    end;

    local procedure ReadText(Request: JsonObject; ParameterName: Text; Required: Boolean; MaximumLength: Integer; var Argument: Record "Message Argument ori") Value: Text
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get(ParameterName, Token) then begin
            if Required then
                Refuse(Argument, ParameterName, KnownKeyLbl);
            exit('');
        end;
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            Refuse(Argument, ParameterName, KnownKeyLbl);
        Value := Token.AsValue().AsText();
        if (Required and (Value = '')) or (StrLen(Value) > MaximumLength) then
            Refuse(Argument, ParameterName, ExactCodeLbl);
    end;

    local procedure ReadBoolean(Request: JsonObject; ParameterName: Text; var Argument: Record "Message Argument ori"): Boolean
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get(ParameterName, Token) then
            exit(false);
        Token.WriteTo(Serialized);
        if not (Serialized in ['true', 'false']) then
            Refuse(Argument, ParameterName, 'true, false');
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure ValidateCode(Value: Text; ParameterName: Text; var Argument: Record "Message Argument ori")
    var
        Position: Integer;
    begin
        for Position := 1 to StrLen(Value) do
            if StrPos('|&*?@<>=()''', CopyStr(Value, Position, 1)) > 0 then
                Refuse(Argument, ParameterName, ExactCodeLbl);
        if StrPos(Value, '..') > 0 then
            Refuse(Argument, ParameterName, ExactCodeLbl);
    end;
    /// <summary>Returns whether the caller has the inventory disposition capability.</summary>
    procedure IsEnabled(): Boolean
    var
        AccessCapability: Record "Quality PutAway Access ori";
    begin
        exit(AccessCapability.WritePermission());
    end;

    /// <summary>Returns the standard inspection table.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Qlty. Inspection Header");
    end;

    /// <summary>Describes the movement.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>The operation accepts inbound messages.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Returns translated search terms.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'quality, disposition, put-away, warehouse, failed quantity, passed quantity', Comment = 'is-IS=gæði, ráðstöfun, frágangur, vöruhús, fallið magn, staðist magn';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Distinguishes this operation in discovery.</summary>
    procedure GetSelectionDescription(): Text
    begin
        exit(DescriptionLbl);
    end;


    /// <summary>Returns the localized envelope contract chapter.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        ChapterLbl: Label '{"subject":{"use":"notUsed"},"dataRequired":true,"version":"1.0","contentType":"application/json"}', Comment = 'is-IS={"subject":{"use":"notUsed"},"dataRequired":true,"version":"1.0","contentType":"application/json"}';
    begin
        Envelope.ReadFrom(ChapterLbl);
        exit(true);
    end;

    /// <summary>Returns the localized target contract chapter.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    var
        ChapterLbl: Label '[{"source":"data.inspectionSystemId","form":"GUID","description":"One quality inspection."}]', Comment = 'is-IS=[{"source":"data.inspectionSystemId","form":"GUID","description":"Ein gæðaskoðun."}]';
    begin
        Target.ReadFrom(ChapterLbl);
        exit(true);
    end;

    /// <summary>Returns the localized parameters contract chapter.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ChapterLbl: Label '[{"name":"inspectionSystemId","type":"string","required":true,"description":"Existing inspection SystemId."},{"name":"kind","type":"string","required":true,"description":"internal or warehouse."},{"name":"quantityBasis","type":"string","required":true,"description":"failed or passed."},{"name":"quantity","type":"number","required":false,"description":"Positive base quantity, at most the selected inspection quantity. Omitted: selected inspection quantity."},{"name":"sourceLocationCode","type":"string","required":false,"description":"Exact source location, at most 10 characters; no filters."},{"name":"sourceBinCode","type":"string","required":false,"description":"Exact source bin, at most 20 characters; no filters."},{"name":"releaseImmediately","type":"boolean","required":false,"description":"Internal only; default false. Release the internal document without registering. Refused even when false for warehouse."},{"name":"confirm","type":"boolean","required":true,"description":"Must be true."},{"name":"expectedCount","type":"integer","required":false,"description":"Counts one inspection (1), not documents or lines. Omission previews with no changes when Require Confirmation for Irreversible Messages is enabled. Always checked when supplied."}]', Comment = 'is-IS=[{"name":"inspectionSystemId","type":"string","required":true,"description":"SystemId gæðaskoðunar sem er til."},{"name":"kind","type":"string","required":true,"description":"internal eða warehouse."},{"name":"quantityBasis","type":"string","required":true,"description":"failed eða passed."},{"name":"quantity","type":"number","required":false,"description":"Jákvætt grunnmagn, mest valið magn skoðunar. Sleppirðu því er valið magn skoðunar notað."},{"name":"sourceLocationCode","type":"string","required":false,"description":"Nákvæm upprunastaðsetning, mest 10 stafir; engar síur."},{"name":"sourceBinCode","type":"string","required":false,"description":"Nákvæmt upprunahólf, mest 20 stafir; engar síur."},{"name":"releaseImmediately","type":"boolean","required":false,"description":"Aðeins innri frágangur; sjálfgefið false. Losa innra skjal án skráningar. Hafnað jafnvel sem false fyrir warehouse."},{"name":"confirm","type":"boolean","required":true,"description":"Verður að vera true."},{"name":"expectedCount","type":"integer","required":false,"description":"Telur eina skoðun (1), ekki skjöl eða línur. Ef sleppt er forskoðað án breytinga þegar krafist er staðfestingar fyrir óafturkræf skilaboð. Alltaf athugað ef sent."}]';
    begin
        Parameters.ReadFrom(ChapterLbl);
        exit(true);
    end;

    /// <summary>Returns the localized response contract chapter.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        ChapterLbl: Label '{"contentType":"application/json","fields":[{"name":"status","type":"string","description":"Success."},{"name":"inspectionSystemId","type":"string","description":"Selected inspection."},{"name":"kind","type":"string","description":"Requested kind."},{"name":"documentNumbers","type":"array","description":"Final created document numbers."},{"name":"released","type":"boolean","description":"Internal release requested and completed."},{"name":"registered","type":"boolean","description":"Always false."}]}', Comment = 'is-IS={"contentType":"application/json","fields":[{"name":"status","type":"string","description":"Success."},{"name":"inspectionSystemId","type":"string","description":"Valin skoðun."},{"name":"kind","type":"string","description":"Umbeðin tegund."},{"name":"documentNumbers","type":"array","description":"Númer stofnaðra lokaskjala."},{"name":"released","type":"boolean","description":"Innri frágangur losaður samkvæmt beiðni."},{"name":"registered","type":"boolean","description":"Alltaf false."}]}';
    begin
        Response.ReadFrom(ChapterLbl);
        exit(true);
    end;

    /// <summary>Returns the localized errors contract chapter.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        ChapterLbl: Label '[{"code":"InvalidParameter","when":"Invalid input; no changes.","fix":"Use parameter, expected and nextStep to correct the request."},{"code":"Business Central refusal","when":"Native setup, permissions or stock are invalid; any late failure rolls back the entire call.","fix":"Correct warehouse setup, stock or native caller permissions."}]', Comment = 'is-IS=[{"code":"InvalidParameter","when":"Ógilt inntak; engar breytingar.","fix":"Notaðu parameter, expected og nextStep til að leiðrétta beiðnina."},{"code":"Business Central refusal","when":"Ógild uppsetning, heimildir eða birgðir; sein villa afturkallar allt kallið.","fix":"Leiðréttu uppsetningu vöruhúss, birgðir eða innbyggðar heimildir kallanda."}]';
    begin
        Errors.ReadFrom(ChapterLbl);
        exit(true);
    end;

    /// <summary>Returns the localized effect contract chapter.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        ChapterLbl: Label '{"effect":"irreversible","changes":"Creates internal or warehouse put-away documents through the standard disposition interface. Never registers or posts. expectedCount counts one inspection.","idempotent":false,"permissionSet":"BIFROST QM Full ori"}', Comment = 'is-IS={"effect":"irreversible","changes":"Stofnar innri frágang eða vöruhúsafrágang með stöðluðu ráðstöfunarviðmóti. Skráir aldrei eða bókar. expectedCount telur eina skoðun.","idempotent":false,"permissionSet":"BIFROST QM Full ori"}';
    begin
        Effect.ReadFrom(ChapterLbl);
        exit(true);
    end;

    /// <summary>Returns the localized examples contract chapter.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        ChapterLbl: Label '[{"title":"Create an open internal put-away","request":{"type":"Quality.Disposition.CreatePutAway","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001","kind":"internal","quantityBasis":"failed","confirm":true,"expectedCount":1}},"response":{"status":"Success","documentNumbers":["IP00001"],"registered":false}}]', Comment = 'is-IS=[{"title":"Stofna opinn innri frágang","request":{"type":"Quality.Disposition.CreatePutAway","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001","kind":"internal","quantityBasis":"failed","confirm":true,"expectedCount":1}},"response":{"status":"Success","documentNumbers":["IP00001"],"registered":false}}]';
    begin
        Examples.ReadFrom(ChapterLbl);
        exit(true);
    end;

    /// <summary>No additional metering chapter is declared.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional related chapter is declared.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional workflow chapter is declared.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>Returns localized overview help.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    var
        HelpLbl: Label 'Creates an internal or warehouse put-away for one inspection. confirm=true is required. Native warehouse permissions, directed put-away locations, bins and stock are required. expectedCount counts one inspection; omission previews without changes when confirmation is enabled.', Comment = 'is-IS=Stofnar innri frágang eða vöruhúsafrágang fyrir eina skoðun. confirm=true er nauðsynlegt. Innbyggðar vöruhúsaheimildir, stýrður frágangur, hólf og birgðir eru nauðsynleg. expectedCount telur eina skoðun; ef sleppt er forskoðað án breytinga þegar staðfesting er virk.';
    begin
        Overview := HelpLbl;
        exit(true);
    end;

    /// <summary>Returns localized notes help.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    var
        HelpLbl: Label 'Not idempotent: repeating a successful call can create another put-away. No registration or posting. releaseImmediately applies only to internal put-away. A failure rolls back every document created by the call.', Comment = 'is-IS=Ekki ídempótent: endurtekið heppnað kall getur stofnað annan frágang. Engin skráning eða bókun. releaseImmediately á aðeins við innri frágang. Villa afturkallar öll skjöl sem kallið stofnaði.';
    begin
        Notes := HelpLbl;
        exit(true);
    end;
}
