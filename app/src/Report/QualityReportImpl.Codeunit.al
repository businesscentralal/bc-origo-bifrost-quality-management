namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;
using System.Security.AccessControl;
using System.Security.User;

/// <summary>Renders an inspection report to PDF and returns it through Foundation staging.</summary>
codeunit 10035319 "Quality Report Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;

    var
        PermissionErr: Label 'You need read access to the quality inspection and permission to run the report.', Comment = 'is-IS=Þú þarft lesaðgang að gæðaskoðuninni og heimild til að keyra skýrsluna.';
        PermissionNextTxt: Label 'Ask an administrator for the Bifrost Quality Read role and the Microsoft Quality Management read permissions.', Comment = 'is-IS=Biddu stjórnanda um hlutverkið Bifrost Quality Read og lesheimildir Microsoft Quality Management.';
        MissingIdErr: Label 'inspectionSystemId is required and must identify an existing inspection.', Comment = 'is-IS=inspectionSystemId er áskilið og verður að auðkenna skoðun sem er til.';
        InvalidIdErr: Label 'inspectionSystemId must be a non-empty GUID.', Comment = 'is-IS=inspectionSystemId verður að vera GUID sem er ekki tómt.';
        MissingReportErr: Label 'report is required: certificateOfAnalysis, nonConformance or general.', Comment = 'is-IS=report er áskilið: certificateOfAnalysis, nonConformance eða general.';
        InvalidReportErr: Label 'report must be certificateOfAnalysis, nonConformance or general.', Comment = 'is-IS=report verður að vera certificateOfAnalysis, nonConformance eða general.';
        InvalidLanguageErr: Label 'languageCode must be en-US or is-IS.', Comment = 'is-IS=languageCode verður að vera en-US eða is-IS.';
        UnknownKeyErr: Label 'Unknown parameter %1. Nothing was rendered.', Comment = '%1 = request key, is-IS=Óþekkt viðfang %1. Engin skýrsla var búin til.';
        FixIdTxt: Label 'Read the inspection SystemId using Data.Records.Get.', Comment = 'is-IS=Lestu SystemId skoðunar með Data.Records.Get.';
        FixReportTxt: Label 'Use certificateOfAnalysis, nonConformance or general.', Comment = 'is-IS=Notaðu certificateOfAnalysis, nonConformance eða general.';
        FixLanguageTxt: Label 'Use en-US or is-IS, or omit languageCode.', Comment = 'is-IS=Notaðu en-US eða is-IS, eða slepptu languageCode.';
        ExpectedIdTxt: Label 'an existing inspection SystemId', Comment = 'is-IS=SystemId skoðunar sem er til';
        ExpectedReportTxt: Label 'certificateOfAnalysis, nonConformance or general', Comment = 'is-IS=certificateOfAnalysis, nonConformance eða general';
        ExpectedLanguageTxt: Label 'en-US or is-IS', Comment = 'is-IS=en-US eða is-IS';

    /// <summary>The type is offered to every caller; native read access is checked when it runs.</summary>
    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>Identifies the underlying inspection table.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Qlty. Inspection Header");
    end;

    /// <summary>Describes the message type.</summary>
    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Renders the Certificate of Analysis, Non-Conformance or general inspection report for one quality inspection as a PDF and returns it through Foundation staging. Changes no business data.', Comment = 'is-IS=Býr til greiningarvottorð, frávikaskýrslu eða almenna skoðunarskýrslu fyrir eina gæðaskoðun sem PDF og skilar henni í gegnum biðsvæði Foundation. Breytir engum viðskiptagögnum.';
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides translated discovery terms.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'quality report, certificate of analysis, non-conformance report, inspection report, pdf, print', Comment = 'is-IS=gæðaskýrsla, greiningarvottorð, frávikaskýrsla, skoðunarskýrsla, pdf, prenta';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Explains when to select the type.</summary>
    procedure GetSelectionDescription(): Text
    begin
        exit(GetDescription());
    end;

    /// <summary>Declares the outbound read direction.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    /// <summary>Validates the request, checks permissions, renders the PDF and stages it.</summary>
    /// <param name="Argument">Foundation request and response.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Inspection: Record "Qlty. Inspection Header";
        Proc: Codeunit "Quality Report Proc ori";
        Request: JsonObject;
        InspectionId: Guid;
        Kind: Text;
        Lcid: Integer;
        PreviousLanguage: Integer;
        Succeeded: Boolean;
    begin
        Argument.AssertIsLicensed();
        Argument.AssertVersion1();
        Request := Argument.GetRequestJson();
        if not ReadRequest(Argument, Request, InspectionId, Kind, Lcid) then
            exit;
        if not HasPermission(Proc.ResolveReportId(Kind)) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PermissionDenied, PermissionErr, '', '', 'QltyMgmt - Read', PermissionNextTxt);
            exit;
        end;
        if not Inspection.GetBySystemId(InspectionId) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::RecordNotFound, MissingIdErr, 'inspectionSystemId', Format(InspectionId, 0, 4), ExpectedIdTxt, FixIdTxt);
            exit;
        end;
        PreviousLanguage := GlobalLanguage();
        if Lcid <> 0 then
            GlobalLanguage(Lcid);
        Succeeded := Codeunit.Run(Codeunit::"Quality Report Proc ori", Argument);
        GlobalLanguage(PreviousLanguage);
        if not Succeeded then
            Argument.RespondWithLastError();
    end;

    local procedure HasPermission(ReportId: Integer): Boolean
    var
        Header: Record "Qlty. Inspection Header";
        TempPermission: Record "Expanded Permission" temporary;
        UserPermissions: Codeunit "User Permissions";
    begin
        if not Header.ReadPermission() then
            exit(false);
        TempPermission := UserPermissions.GetEffectivePermission(TempPermission."Object Type"::Report, ReportId);
        exit(TempPermission."Execute Permission" in [TempPermission."Execute Permission"::Yes, TempPermission."Execute Permission"::Indirect]);
    end;

    local procedure ReadRequest(var Argument: Record "Message Argument ori"; Request: JsonObject; var InspectionId: Guid; var Kind: Text; var Lcid: Integer): Boolean
    var
        ValueToken: JsonToken;
        KeyName: Text;
        LanguageCode: Text;
    begin
        foreach KeyName in Request.Keys() do
            if not (KeyName in ['inspectionSystemId', 'report', 'languageCode']) then begin
                Argument.RespondWithError("Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, KeyName), KeyName, '', 'inspectionSystemId, report, languageCode', FixIdTxt);
                exit(false);
            end;
        if not Request.Get('inspectionSystemId', ValueToken) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, MissingIdErr, 'inspectionSystemId', '', ExpectedIdTxt, FixIdTxt);
            exit(false);
        end;
        if not ScalarText(ValueToken, LanguageCode) or not Evaluate(InspectionId, LanguageCode) or IsNullGuid(InspectionId) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameter, InvalidIdErr, 'inspectionSystemId', '', ExpectedIdTxt, FixIdTxt);
            exit(false);
        end;
        if not Request.Get('report', ValueToken) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, MissingReportErr, 'report', '', ExpectedReportTxt, FixReportTxt);
            exit(false);
        end;
        if not ScalarText(ValueToken, Kind) or not (Kind in ['certificateOfAnalysis', 'nonConformance', 'general']) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameter, InvalidReportErr, 'report', '', ExpectedReportTxt, FixReportTxt);
            exit(false);
        end;
        Lcid := 0;
        if Request.Get('languageCode', ValueToken) then begin
            if not ScalarText(ValueToken, LanguageCode) then
                LanguageCode := '?';
            case LanguageCode of
                'en-US':
                    Lcid := 1033;
                'is-IS':
                    Lcid := 1039;
                else begin
                    Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameter, InvalidLanguageErr, 'languageCode', '', ExpectedLanguageTxt, FixLanguageTxt);
                    exit(false);
                end;
            end;
        end;
        exit(true);
    end;

    local procedure ScalarText(Token: JsonToken; var Value: Text): Boolean
    begin
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() or Token.AsValue().IsUndefined() then
            exit(false);
        Value := Token.AsValue().AsText();
        exit(Value <> '');
    end;

    /// <summary>Declares the request envelope.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
    begin
        Subject.Add('use', 'notUsed');
        Subject.Add('description', 'Use data.inspectionSystemId and data.report.');
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', true);
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'application/json');
        exit(true);
    end;

    /// <summary>Documents the source identity.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Target.Add(Contract.TargetEntry('data.inspectionSystemId', 'GUID', 'SystemId of the Qlty. Inspection Header to print.'));
        exit(true);
    end;

    /// <summary>Lists every accepted request key.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(Contract.Parameter('inspectionSystemId', 'string', true, 'Non-empty SystemId GUID of an existing quality inspection.'));
        Parameters.Add(Contract.Parameter('report', 'string', true, 'certificateOfAnalysis (Certificate of Analysis), nonConformance (Non-Conformance report) or general (general purpose inspection report).'));
        Parameters.Add(Contract.Parameter('languageCode', 'string', false, 'en-US or is-IS. Renders the report in that language; the session language is restored afterwards. Default: the session language.'));
        exit(true);
    end;

    /// <summary>Describes the staged result.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
    begin
        Fields.Add(Contract.ResponseField('status', 'string', 'Success'));
        Fields.Add(Contract.ResponseField('noOfRecords', 'integer', 'Always 1 on success.'));
        Fields.Add(Contract.ResponseField('result', 'array', 'One entry with stagingId (Foundation Blob Staging row of the caller), fileName, contentType (application/pdf), sizeBytes, inspectionSystemId and report.'));
        Response.Add('contentType', 'application/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Documents validation, access and size refusals.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, 'inspectionSystemId or report is missing.', 'Supply both keys.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, 'inspectionSystemId is not a non-empty GUID, report is not one of the three values, or languageCode is not en-US or is-IS.', 'Correct the value.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, 'An undeclared data key was supplied.', 'Remove undeclared keys.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, 'The inspection does not exist or is not visible.', 'Read the inspection with Data.Records.Get.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, 'The caller lacks read access to the inspection or execute permission for the report.', 'Ask an administrator for the Quality Management read roles.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::LimitExceeded, 'The rendered PDF is over 10485760 bytes. It is refused, not truncated, and no staging row is left.', 'Print a smaller inspection.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, 'The report itself refused, for example for an inspection state it does not support. The translated message is returned.', 'Correct the native condition before retrying.'));
        exit(true);
    end;

    /// <summary>Documents the read effect.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
    begin
        Preconditions.Add('The caller can read the inspection and run the Microsoft report.');
        Effect.Add('effect', 'read');
        Effect.Add('changes', 'Changes no inspection, line, setup or journal data. Renders the Microsoft report for the one inspection with Report.SaveAs (PDF) and stores the PDF as one Foundation Blob Staging row owned by the caller; that scratch row is the only write. Read it with the staging types using stagingId. The Microsoft report object is rendered with its default layout; a custom Report Selections entry is not used, because Report Selections is not readable under the Read role. Results over 10485760 bytes are refused.');
        Effect.Add('idempotent', false);
        Effect.Add('permissionSet', 'BIFROST QM Read ori');
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    /// <summary>No additional app metering.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        Clear(Metering);
        exit(false);
    end;

    /// <summary>No related operation.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        Clear(Related);
        exit(false);
    end;

    /// <summary>No extra workflow chapter.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        Clear(Workflow);
        exit(false);
    end;

    /// <summary>Provides an executable request shape.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Examples.Add(Contract.Example('Certificate of Analysis as PDF', '{"type":"Quality.Report.Print","data":{"inspectionSystemId":"<inspection-systemId>","report":"certificateOfAnalysis","languageCode":"en-US"}}', '{"status":"Success","noOfRecords":1,"result":[{"stagingId":"<id>","fileName":"QI00001-0-certificateOfAnalysis.pdf","contentType":"application/pdf","sizeBytes":12345,"inspectionSystemId":"<inspection-systemId>","report":"certificateOfAnalysis"}]}'));
        exit(true);
    end;

    /// <summary>Provides the help overview.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := GetDescription();
        exit(true);
    end;

    /// <summary>Explains staging, size limit and retries.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    var
        NotesLbl: Label 'Each call stages a new PDF; retrying creates another staging row. Results over 10485760 bytes are refused. The caller reads the staged PDF with the existing staging types. The session language is restored after rendering, also after a refusal.', Comment = 'is-IS=Hvert kall býr til nýtt PDF í biðsvæði; endurtekning býr til aðra biðsvæðisfærslu. Niðurstöður yfir 10485760 bætum er hafnað. Kallandi les PDF úr biðsvæðinu með biðsvæðistegundum. Tungumál lotunnar er endurheimt eftir myndun, einnig eftir höfnun.';
    begin
        Notes := NotesLbl;
        exit(true);
    end;
}
