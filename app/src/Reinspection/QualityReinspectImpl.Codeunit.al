namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;

/// <summary>Creates a re-inspection through the standard inspection header action.</summary>
codeunit 10035242 "Quality Reinspect Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;

    var
        PermissionErr: Label 'You need BIFROST QM Full ori to create a re-inspection.', Comment = 'is-IS=Þú þarft BIFROST QM Full ori til að stofna endurskoðun.';
        MissingIdErr: Label 'inspectionSystemId is required and must identify an existing inspection.', Comment = 'is-IS=inspectionSystemId er áskilið og verður að auðkenna skoðun sem er til.';
        InvalidIdErr: Label 'inspectionSystemId must be a non-empty GUID.', Comment = 'is-IS=inspectionSystemId verður að vera GUID sem er ekki tómt.';
        UnknownKeyErr: Label 'Unknown parameter %1. Nothing was changed.', Comment = '%1 = request key, is-IS=Óþekkt viðfang %1. Engu var breytt.';
        FixIdTxt: Label 'Read the source inspection SystemId using Data.Records.Get.', Comment = 'is-IS=Lestu SystemId upprunalegrar skoðunar með Data.Records.Get.';
        ExpectedIdTxt: Label 'an existing inspection SystemId', Comment = 'is-IS=SystemId skoðunar sem er til';
        PermissionNextTxt: Label 'Ask an administrator for the Bifrost Quality Full role and the standard Quality Inspector permissions.', Comment = 'is-IS=Biddu stjórnanda um hlutverkið Bifrost Quality Full og staðlaðar heimildir gæðaskoðunarmanns.';

    /// <summary>Offers this action only to callers with the app action permission.</summary>
    procedure IsEnabled(): Boolean
    var
        AccessMarker: Record "Quality Action Access ori";
    begin
        exit(AccessMarker.WritePermission());
    end;

    /// <summary>Identifies the underlying inspection table.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Qlty. Inspection Header");
    end;

    /// <summary>Describes the native action.</summary>
    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Creates the next re-inspection from an existing quality inspection using standard Business Central validation.', Comment = 'is-IS=Stofnar næstu endurskoðun úr gæðaskoðun með stöðluðum sannprófunum Business Central.';
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides translated discovery terms.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'reinspection, re-inspection, inspect again, failed quality inspection, retest', Comment = 'is-IS=endurskoðun, endurtaka skoðun, fallin gæðaskoðun, endurprófun, skoða aftur';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Explains when to select the action.</summary>
    procedure GetSelectionDescription(): Text
    begin
        exit(GetDescription());
    end;

    /// <summary>Declares the inbound action direction.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Checks all input before dispatching the native transaction.</summary>
    /// <param name="Argument">Foundation request and response.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        InspectionId: Guid;
    begin
        Argument.AssertIsLicensed();
        Argument.AssertVersion1();
        if not IsEnabled() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PermissionDenied, PermissionErr, '', '', 'BIFROST QM Full ori', PermissionNextTxt);
            exit;
        end;
        Request := Argument.GetRequestJson();
        if not ReadInspectionId(Argument, Request, InspectionId) then
            exit;
        if not Inspection.GetBySystemId(InspectionId) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::RecordNotFound, MissingIdErr, 'inspectionSystemId', Format(InspectionId, 0, 4), ExpectedIdTxt, FixIdTxt);
            exit;
        end;
        if Argument."Omit Commit" then
            Codeunit.Run(Codeunit::"Quality Reinspect Proc ori", Argument)
        else
            if not Codeunit.Run(Codeunit::"Quality Reinspect Proc ori", Argument) then
                Argument.RespondWithLastError();
    end;

    local procedure ReadInspectionId(var Argument: Record "Message Argument ori"; Request: JsonObject; var InspectionId: Guid): Boolean
    var
        ValueToken: JsonToken;
        KeyName: Text;
    begin
        foreach KeyName in Request.Keys() do
            if KeyName <> 'inspectionSystemId' then begin
                Argument.RespondWithError("Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, KeyName), KeyName, '', 'inspectionSystemId', FixIdTxt);
                exit(false);
            end;
        if not Request.Get('inspectionSystemId', ValueToken) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, MissingIdErr, 'inspectionSystemId', '', ExpectedIdTxt, FixIdTxt);
            exit(false);
        end;
        if ValueToken.IsValue() then
            if not ValueToken.AsValue().IsNull() then
                if not ValueToken.AsValue().IsUndefined() then
                    if Evaluate(InspectionId, ValueToken.AsValue().AsText()) then
                        if not IsNullGuid(InspectionId) then
                            exit(true);
        Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameter, InvalidIdErr, 'inspectionSystemId', '', ExpectedIdTxt, FixIdTxt);
        exit(false);
    end;

    /// <summary>Declares the request envelope.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
    begin
        Subject.Add('use', 'notUsed');
        Subject.Add('description', 'Use data.inspectionSystemId.');
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
        Target.Add(Contract.TargetEntry('data.inspectionSystemId', 'GUID', 'SystemId of the source Qlty. Inspection Header.'));
        exit(true);
    end;

    /// <summary>Lists every accepted request key.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(Contract.Parameter('inspectionSystemId', 'string', true, 'Non-empty SystemId GUID of an existing quality inspection. Unknown keys are refused before execution.'));
        exit(true);
    end;

    /// <summary>Describes the created revision identity.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
    begin
        Fields.Add(Contract.ResponseField('status', 'string', 'Success'));
        Fields.Add(Contract.ResponseField('noOfRecords', 'integer', 'Always 1 on success.'));
        Fields.Add(Contract.ResponseField('result', 'array', 'One created record with systemId, inspectionNo, reinspectionNo and sourceSystemId.'));
        Response.Add('contentType', 'application/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Documents validation, access and native refusals.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, 'inspectionSystemId is missing.', 'Supply the source SystemId.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, 'inspectionSystemId is not a non-empty GUID.', 'Supply a GUID.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, 'An undeclared data key was supplied.', 'Remove undeclared keys.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, 'The inspection does not exist or is not visible.', 'Read the inspection with Data.Records.Get.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, 'The app action permission is missing.', 'Ask an administrator for the documented roles.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, 'Standard Quality Management setup, permissions, tracking, result or template validation refused the action; the native translated message is returned and no partial changes remain.', 'Correct the native business condition before retrying.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::Retryable, 'A transient native lock prevented the action.', 'Retry only after checking whether an earlier call succeeded.'));
        exit(true);
    end;

    /// <summary>Documents native finishing, revision selection and commit behavior.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
    begin
        Preconditions.Add('Quality Management setup exists and native validation allows the action.');
        Preconditions.Add('The caller has BIFROST QM Full ori plus standard Quality Inspector data permissions.');
        Effect.Add('effect', 'write');
        Effect.Add('changes', 'Calls Qlty. Inspection Header.CreateReinspection(var header). An open source is finished first. The latest revision with the same inspection number supplies the next revision, even when an older source SystemId is sent. Copies the header, clears completion/result values and generates lines from the template. The preceding revision loses its most-recent flag. No explicit Commit occurs on this native path; the page-only Commit is not called. Explicit subscriber commits are rejected; normal task success commits, business errors roll back.');
        Effect.Add('idempotent', false);
        Effect.Add('permissionSet', 'BIFROST QM Full ori');
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    /// <summary>No additional app metering.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        Clear(Metering);
        exit(false);
    end;

    /// <summary>No related operation is needed to execute this action.</summary>
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
        Examples.Add(Contract.Example('Create a re-inspection', '{"type":"Quality.Inspection.CreateReinspection","data":{"inspectionSystemId":"<source-systemId>"}}', '{"status":"Success","noOfRecords":1,"result":[{"systemId":"<created-systemId>","inspectionNo":"QI00001","reinspectionNo":1,"sourceSystemId":"<source-systemId>"}]}'));
        exit(true);
    end;

    /// <summary>Provides the help overview.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := GetDescription();
        exit(true);
    end;

    /// <summary>Explains retry and transaction semantics.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    var
        NotesLbl: Label 'Not idempotent: each successful retry creates another revision. Read the result before retrying. Native refusals leave no partial inspection or source-status change. In omit-commit mode native errors propagate to the enclosing task transaction for rollback.', Comment = 'is-IS=Ekki ídempotent: hver endurtekning sem tekst stofnar nýja útgáfu. Lestu niðurstöðuna áður en þú reynir aftur. Höfnun staðlaðrar aðgerðar skilur hvorki eftir hluta skoðunar né breytta stöðu upprunalegrar skoðunar. Í ham án staðfestingar berast villur til umlykjandi færslu til afturköllunar.';
    begin
        Notes := NotesLbl;
        exit(true);
    end;
}
