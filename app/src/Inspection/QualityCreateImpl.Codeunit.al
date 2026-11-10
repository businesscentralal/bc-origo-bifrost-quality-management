namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.API;
using Microsoft.QualityManagement.Document;
using Microsoft.Utilities;
using Origo.Bifrost;

/// <summary>Creates an inspection through the standard Microsoft API with atomic refusal handling.</summary>
codeunit 10035250 "Quality Create Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        DescriptionLbl: Label 'Creates or resolves a quality inspection for one source record through Microsoft generation rules.', MaxLength = 250, Comment = 'is-IS=Stofnar eða finnur gæðaskoðun fyrir eina upprunafærslu með stofnunarreglum Microsoft.';
        MissingKeyErr: Label 'The required parameter ''%1'' is missing or invalid.', Comment = '%1 = parameter name|is-IS=Nauðsynlega færibreytu ''%1'' vantar eða hún er ógild.';
        UnknownKeyErr: Label 'Unknown parameter ''%1''.', Comment = '%1 = parameter name|is-IS=Óþekkt færibreyta ''%1''.';
        TooLongErr: Label 'Parameter ''%1'' exceeds %2 characters.', Comment = '%1 = parameter name, %2 = limit|is-IS=Færibreytan ''%1'' er lengri en %2 stafir.';
        PermissionErr: Label 'The BIFROST QM Full ori permission set is required.', Comment = 'is-IS=Heimildasafnið BIFROST QM Full ori er nauðsynlegt.';
        NotFoundErr: Label 'The source record was not found.', Comment = 'is-IS=Upprunafærslan fannst ekki.';
        NotCreatedErr: Label 'Business Central could not create or resolve an inspection. Check Quality Management setup and generation rules.', Comment = 'is-IS=Business Central gat ekki stofnað eða fundið skoðun. Athugaðu uppsetningu gæðastjórnunar og stofnunarreglur.';
        OverviewLbl: Label 'Creates or resolves an inspection for one source record using the standard Microsoft Create Inspection API and creation codeunit. The optional template is passed through the native template-selection event.', Comment = 'is-IS=Stofnar eða finnur skoðun fyrir eina upprunafærslu með stöðluðu API og stofnunarkóðaeiningu Microsoft. Valfrjálst sniðmát er sent í gegnum staðlaðan atburð fyrir val á sniðmáti.';
        NotesLbl: Label 'sourceTableId and sourceSystemId identify one visible record in the current company. templateCode optionally selects a template; otherwise Microsoft generation rules select it. Native source mapping, template validation, permissions, numbering and workflow events run. Repeated requests may create another inspection or reuse one according to setup; this operation is not idempotent. The standard creation path has no explicit Commit. Explicit subscriber commits are prohibited. Normal execution uses an isolated transaction and rolls back on refusal. With Omit Commit the caller owns rollback. No source document is posted and no external provider is called.', Comment = 'is-IS=sourceTableId og sourceSystemId auðkenna eina sýnilega færslu í núverandi fyrirtæki. templateCode velur sniðmát ef það er gefið upp; annars velja stofnunarreglur Microsoft sniðmátið. Staðlaðar upprunavarpanir, sniðmátastaðfestingar, heimildir, númeraraðir og verkflæðisatburðir eru keyrð. Endurtekin köll geta stofnað aðra skoðun eða endurnýtt skoðun samkvæmt uppsetningu; aðgerðin er ekki endurtekningarörugg. Staðlaða stofnunarleiðin inniheldur ekkert beint Commit. Beinar staðfestingar frá áskrifendum eru bannaðar. Venjuleg keyrsla notar sérstaka færslu og bakfærir við höfnun. Með Omit Commit ber kallandi ábyrgð á bakfærslu. Ekkert upprunaskjal er bókað og engin ytri þjónusta er kölluð.';
        SourceTableLbl: Label 'Numeric table ID of the source record in the current company.', Comment = 'is-IS=Tölulegt töfluauðkenni upprunafærslunnar í núverandi fyrirtæki.';
        SourceIdLbl: Label 'SystemId of the source record, as a non-empty GUID string.', Comment = 'is-IS=SystemId upprunafærslunnar sem ótómur GUID-strengur.';
        TemplateLbl: Label 'Optional template code, at most 20 characters. Omit to use generation rules.', Comment = 'is-IS=Valfrjáls sniðmátskóði, mest 20 stafir. Slepptu til að nota stofnunarreglur.';

    trigger OnRun()
    begin
        PerformWrite(Rec);
    end;

    /// <summary>Validates the envelope and translates transaction failures into refusals.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if Argument."Omit Commit" then begin
            PerformWrite(Argument);
            exit;
        end;
        if not Codeunit.Run(Codeunit::"Quality Create Impl ori", Argument) then
            Argument.RespondWithLastError();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure PerformWrite(var Argument: Record "Message Argument ori")
    var
        WriteAccess: Record "Quality Write Access ori";
        Inspection: Record "Qlty. Inspection Header";
        ResultBuffer: Record "Name/Value Buffer";
        CreateContext: Codeunit "Quality Create Context ori";
        CreateInspection: Page "Qlty. Create Inspection API";
        SourceRecord: RecordRef;
        ActionContext: WebServiceActionContext;
        Request: JsonObject;
        Response: JsonObject;
        SourceSystemId: Guid;
        SourceTableId: Integer;
        RequestedTemplate: Text;
        ParameterName: Text;
    begin
        if not WriteAccess.WritePermission() then
            Error(ErrorInfo.Create(PermissionErr));
        Request := Argument.GetRequestJson();
        foreach ParameterName in Request.Keys() do
            if not (ParameterName in ['sourceTableId', 'sourceSystemId', 'templateCode']) then
                Error(ErrorInfo.Create(StrSubstNo(UnknownKeyErr, ParameterName)));
        SourceTableId := ReadTableId(Request);
        if not Evaluate(SourceSystemId, ReadText(Request, 'sourceSystemId', false)) then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, 'sourceSystemId')));
        if IsNullGuid(SourceSystemId) then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, 'sourceSystemId')));
        if Request.Contains('templateCode') then
            RequestedTemplate := ReadText(Request, 'templateCode', false);
        if Request.Contains('templateCode') and (DelChr(RequestedTemplate, '=', ' ') = '') then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, 'templateCode')));
        if StrLen(RequestedTemplate) > 20 then
            Error(ErrorInfo.Create(StrSubstNo(TooLongErr, 'templateCode', 20)));
        SourceRecord.Open(SourceTableId);
        SourceRecord.ReadIsolation := IsolationLevel::ReadCommitted;
        if not SourceRecord.GetBySystemId(SourceSystemId) then
            Error(ErrorInfo.Create(NotFoundErr));
        SourceRecord.SetRecFilter();
        CreateContext.Initialize(SourceRecord.RecordId(), CopyStr(RequestedTemplate, 1, 20));
        BindSubscription(CreateContext);
        // Derive the native table view from the resolved record; callers cannot supply a view.
        CreateInspection.CreateInspectionFromTableIDAndFilter(ActionContext, Format(SourceTableId, 0, 9), SourceRecord.GetView(false));
        UnbindSubscription(CreateContext);
        SourceRecord.Close();
        CreateInspection.GetRecord(ResultBuffer);
        Inspection.ReadIsolation := IsolationLevel::ReadCommitted;
        if IsNullGuid(ResultBuffer.SystemId) then
            Error(ErrorInfo.Create(NotCreatedErr));
        if not Inspection.GetBySystemId(ResultBuffer.SystemId) then
            Error(ErrorInfo.Create(NotCreatedErr));
        Response.Add('status', 'Success');
        Response.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Response.Add('inspectionNo', Inspection."No.");
        Response.Add('reinspectionNo', Inspection."Re-inspection No.");
        Response.Add('templateCode', Inspection."Template Code");
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure ReadTableId(Request: JsonObject): Integer
    var
        Token: JsonToken;
        Serialized: Text;
        TableId: Integer;
    begin
        if not Request.Get('sourceTableId', Token) then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, 'sourceTableId')));
        Token.WriteTo(Serialized);
        if not Evaluate(TableId, Serialized, 9) then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, 'sourceTableId')));
        if TableId <= 0 then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, 'sourceTableId')));
        exit(TableId);
    end;

    local procedure ReadText(Request: JsonObject; ParameterName: Text; AllowEmpty: Boolean) Value: Text
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get(ParameterName, Token) then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, ParameterName)));
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, ParameterName)));
        Value := Token.AsValue().AsText();
        if (Value = '') and not AllowEmpty then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, ParameterName)));
    end;

    /// <summary>Provides the IsEnabled discovery or contract chapter.</summary>
    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>Provides the GetFilterTableNo discovery or contract chapter.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>Provides the GetDescription discovery or contract chapter.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides the GetMessageDirection discovery or contract chapter.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Provides the GetKeywords discovery or contract chapter.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'Quality.Inspection.Create, quality, inspection, create, template, source', Comment = 'is-IS=Quality.Inspection.Create, gæði, skoðun, stofna, sniðmát, uppruni';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Provides the GetSelectionDescription discovery or contract chapter.</summary>
    procedure GetSelectionDescription(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides the GetOverview discovery or contract chapter.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := OverviewLbl;
        exit(true);
    end;

    /// <summary>Provides the GetNotes discovery or contract chapter.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := NotesLbl;
        exit(true);
    end;

    /// <summary>Provides the envelope contract chapter.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    begin
        Envelope.ReadFrom('{"subject":{"use":"notUsed"},"dataRequired":true,"version":"1.0","contentType":"application/json"}');
        exit(true);
    end;

    /// <summary>Provides the target contract chapter.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        Target.ReadFrom('[{"source":"data.sourceSystemId","form":"GUID","description":"SystemId in the table identified by sourceTableId."}]');
        exit(true);
    end;

    /// <summary>Provides the parameters contract chapter.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Clear(Parameters);
        Parameters.Add(ContractMgt.Parameter('sourceTableId', 'integer', true, SourceTableLbl));
        Parameters.Add(ContractMgt.Parameter('sourceSystemId', 'string', true, SourceIdLbl));
        Parameters.Add(ContractMgt.Parameter('templateCode', 'string', false, TemplateLbl));
        exit(true);
    end;

    /// <summary>Provides the response contract chapter.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    begin
        Response.ReadFrom('{"contentType":"application/json","fields":[{"name":"status","type":"string"},{"name":"inspectionSystemId","type":"string"},{"name":"inspectionNo","type":"string"},{"name":"reinspectionNo","type":"integer"},{"name":"templateCode","type":"string"}]}');
        exit(true);
    end;

    /// <summary>Provides the errors contract chapter.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    begin
        Errors.ReadFrom('[{"error":"Business Central refusal","when":"Invalid input, missing source or setup, invalid template, missing generation rule or insufficient permissions.","fix":"Correct the request, Quality Management configuration or permissions."}]');
        exit(true);
    end;

    /// <summary>Provides the effect contract chapter.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        Effect.ReadFrom('{"effect":"write","changes":"Creates or reuses an inspection, its lines and result conditions; applies numbering, source mappings and workflow events. No explicit Commit on the standard path; subscriber commits are prohibited.","idempotent":false,"permissionSet":"BIFROST QM Full ori","preconditions":["Visible source record in the current company.","Configured Microsoft Quality Management, source mappings, template, numbering and native permissions; generation rules when templateCode is omitted."]}');
        exit(true);
    end;

    /// <summary>Provides the examples contract chapter.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        Examples.ReadFrom('[{"title":"Create an inspection for a purchase line","request":{"type":"Quality.Inspection.Create","data":{"sourceTableId":39,"sourceSystemId":"00000000-0000-0000-0000-000000000001","templateCode":"RECEIPT"}}}]');
        exit(true);
    end;

    /// <summary>Declares no additional metering chapter.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        Clear(Metering);
        exit(false);
    end;

    /// <summary>Declares no additional related chapter.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        Clear(Related);
        exit(false);
    end;

    /// <summary>Declares no additional workflow chapter.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        Clear(Workflow);
        exit(false);
    end;
}
