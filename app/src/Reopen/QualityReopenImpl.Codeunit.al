namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;

/// <summary>Reopens a finished inspection through the standard ReopenInspection action.</summary>
codeunit 10035256 "Quality Reopen Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    trigger OnRun()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        InspectionId: Guid;
        Response: JsonObject;
        Result: JsonObject;
        Results: JsonArray;
    begin
        Request := Rec.GetRequestJson();
        Evaluate(InspectionId, Request.GetText('inspectionSystemId'));
        // The native action reads and writes status, quantities and workflow fields, so the full record is required.
        Inspection.GetBySystemId(InspectionId);
        Reopen(Inspection);
        Inspection.GetBySystemId(InspectionId);
        Result.Add('systemId', Format(Inspection.SystemId, 0, 4));
        Result.Add('inspectionNo', Inspection."No.");
        Result.Add('reinspectionNo', Inspection."Re-inspection No.");
        Results.Add(Result);
        Response.Add('status', 'Success');
        Response.Add('noOfRecords', 1);
        Response.Add('result', Results);
        Rec.SetResponseJson(Response);
        Rec."Content Type" := Rec.GetContentTypeJson();
    end;

    var
        PermissionErr: Label 'You need BIFROST QM Full ori to reopen an inspection.', Comment = 'is-IS=Þú þarft BIFROST QM Full ori til að enduropna skoðun.';
        MissingIdErr: Label 'inspectionSystemId is required and must identify an existing inspection.', Comment = 'is-IS=inspectionSystemId er áskilið og verður að auðkenna skoðun sem er til.';
        InvalidIdErr: Label 'inspectionSystemId must be a non-empty GUID.', Comment = 'is-IS=inspectionSystemId verður að vera GUID sem er ekki tómt.';
        UnknownKeyErr: Label 'Unknown parameter %1. Nothing was changed.', Comment = '%1 = request key, is-IS=Óþekkt viðfang %1. Engu var breytt.';
        FixIdTxt: Label 'Read the inspection SystemId with Data.Records.Get.', Comment = 'is-IS=Lestu SystemId skoðunarinnar með Data.Records.Get.';
        ExpectedIdTxt: Label 'an existing inspection SystemId', Comment = 'is-IS=SystemId skoðunar sem er til';
        PermissionNextTxt: Label 'Ask an administrator for the Bifrost Quality Full role. Microsoft also requires the Quality Admin & Supervisor role, or SUPER, before ReopenInspection runs.', Comment = 'is-IS=Biddu stjórnanda um hlutverkið Bifrost Quality Full. Microsoft krefst einnig hlutverksins Quality Admin & Supervisor, eða SUPER, áður en ReopenInspection keyrir.';

    /// <summary>Offers this action only to callers who can write the app permission marker.</summary>
    /// <returns>True when the caller has the app write grant.</returns>
    procedure IsEnabled(): Boolean
    var
        AccessMarker: Record "Quality Reopen Access ori";
    begin
        exit(AccessMarker.WritePermission());
    end;

    /// <summary>Identifies the inspection header this action changes.</summary>
    /// <returns>The inspection header table number.</returns>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Qlty. Inspection Header");
    end;

    /// <summary>Describes the native reopen action.</summary>
    /// <returns>A short description of the action.</returns>
    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Reopens a finished quality inspection through the standard ReopenInspection action so test values can be changed again.', Comment = 'is-IS=Enduropnar lokinni gæðaskoðun með staðlaðri ReopenInspection aðgerð svo prófunargildum megi breyta aftur.';
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides translated discovery terms.</summary>
    /// <returns>Comma-separated search terms.</returns>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'reopen, finished inspection, quality inspection, test values, open status', Comment = 'is-IS=enduropna, lokin skoðun, gæðaskoðun, prófunargildi, opin staða';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Explains when to select the action.</summary>
    /// <returns>The same text as the description.</returns>
    procedure GetSelectionDescription(): Text
    begin
        exit(GetDescription());
    end;

    /// <summary>Declares the inbound action direction.</summary>
    /// <returns>Inbound.</returns>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Checks the request, then runs the native reopen in its own transaction.</summary>
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
            Codeunit.Run(Codeunit::"Quality Reopen Impl ori", Argument)
        else
            if not Codeunit.Run(Codeunit::"Quality Reopen Impl ori", Argument) then
                Argument.RespondWithLastError();
    end;

    /// <summary>
    /// Calls the standard reopen path. Subscriber commits are rejected so a native refusal cannot leave a partial status change.
    /// </summary>
    /// <param name="Inspection">The inspection to reopen.</param>
    [CommitBehavior(CommitBehavior::Error)]
    local procedure Reopen(var Inspection: Record "Qlty. Inspection Header")
    begin
        Inspection.Get(Inspection."No.", Inspection."Re-inspection No.");
        Inspection.ReopenInspection();
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
    /// <param name="Envelope">Envelope chapter.</param>
    /// <returns>True when the chapter is written.</returns>
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

    /// <summary>Documents the inspection identity.</summary>
    /// <param name="Target">Target chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Target.Add(Contract.TargetEntry('data.inspectionSystemId', 'GUID', 'SystemId of the Qlty. Inspection Header to reopen.'));
        exit(true);
    end;

    /// <summary>Lists every accepted request key.</summary>
    /// <param name="Parameters">Parameter chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(Contract.Parameter('inspectionSystemId', 'string', true, 'Non-empty SystemId GUID of an existing quality inspection. Unknown keys are refused before execution.'));
        exit(true);
    end;

    /// <summary>Describes the success payload.</summary>
    /// <param name="Response">Response chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
    begin
        Fields.Add(Contract.ResponseField('status', 'string', 'Success'));
        Fields.Add(Contract.ResponseField('noOfRecords', 'integer', 'Always 1 on success.'));
        Fields.Add(Contract.ResponseField('result', 'array', 'One record with systemId, inspectionNo and reinspectionNo. Status and quantities are on the inspection, not copied around the standard action.'));
        Response.Add('contentType', 'application/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Documents validation, access and native refusals.</summary>
    /// <param name="Errors">Error chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, 'inspectionSystemId is missing.', 'Supply the inspection SystemId.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, 'inspectionSystemId is not a non-empty GUID.', 'Supply a GUID.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, 'An undeclared data key was supplied.', 'Remove undeclared keys.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, 'The inspection does not exist or is not visible.', 'Read the inspection with Data.Records.Get.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, 'The app action permission is missing.', 'Ask an administrator for BIFROST QM Full ori.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, 'Standard Quality Management refused the reopen: the user is not Quality Admin & Supervisor or SUPER, a later re-inspection exists, or another native check failed. The translated message is returned and no partial status or quantity change remains.', 'Correct the native business condition before retrying.'));
        exit(true);
    end;

    /// <summary>Documents the standard reopen path, including the absence of Commit.</summary>
    /// <param name="Effect">Effect chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
    begin
        Preconditions.Add('The caller has BIFROST QM Full ori.');
        Preconditions.Add('Microsoft ReopenInspection requires the Quality Admin & Supervisor role, or SUPER, assigned to the user. Included permission sets do not satisfy that check.');
        Preconditions.Add('No later re-inspection exists for the same inspection number.');
        Effect.Add('effect', 'write');
        Effect.Add('changes', 'Calls Qlty. Inspection Header.ReopenInspection. It does not write Status, Pass Quantity or Fail Quantity directly. The standard action checks the admin role, errors when a later re-inspection exists, and when the inspection is Finished and the non-interactive session proceeds (or the user confirms), validates Status to Open. On this Business Central version the procedure then Modify(true), and the persisted result is Status Open with the pass and fail quantities that were already stored. An already open inspection is left unchanged. There is no Commit on this path. Explicit subscriber commits are rejected. Normal task success commits; a business error rolls back.');
        Effect.Add('idempotent', true);
        Effect.Add('permissionSet', 'BIFROST QM Full ori');
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    /// <summary>No additional app metering.</summary>
    /// <param name="Metering">Unused metering chapter.</param>
    /// <returns>False. This type adds no metering chapter.</returns>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        Clear(Metering);
        exit(false);
    end;

    /// <summary>No related operation is required.</summary>
    /// <param name="Related">Unused related chapter.</param>
    /// <returns>False. This type adds no related chapter.</returns>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        Clear(Related);
        exit(false);
    end;

    /// <summary>No extra workflow chapter.</summary>
    /// <param name="Workflow">Unused workflow chapter.</param>
    /// <returns>False. This type adds no workflow chapter.</returns>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        Clear(Workflow);
        exit(false);
    end;

    /// <summary>Provides an executable request shape.</summary>
    /// <param name="Examples">Example chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Examples.Add(Contract.Example('Reopen a finished inspection', '{"type":"Quality.Inspection.Reopen","data":{"inspectionSystemId":"<inspection-systemId>"}}', '{"status":"Success","noOfRecords":1,"result":[{"systemId":"<inspection-systemId>","inspectionNo":"QI00001","reinspectionNo":0}]}'));
        exit(true);
    end;

    /// <summary>Provides the help overview.</summary>
    /// <param name="Overview">Overview text.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := GetDescription();
        exit(true);
    end;

    /// <summary>Explains effect, idempotency and transaction behaviour.</summary>
    /// <param name="Notes">Notes text.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetNotes(var Notes: Text): Boolean
    var
        NotesLbl: Label 'Effect: a finished inspection becomes open by the standard ReopenInspection action. Pass and fail quantities stay as that action leaves them. Idempotent: calling it again on the open inspection changes nothing. A later re-inspection is a refusal and changes nothing. There is no Commit on the standard path. A business refusal rolls back. In omit-commit mode the caller owns rollback.', Comment = 'is-IS=Áhrif: lokin skoðun verður opin með staðlaðri ReopenInspection aðgerð. Magn sem stóðst og féll helst eins og aðgerðin skilur við það. Ídempotent: annað kall á opna skoðun breytir engu. Síðari endurskoðun er höfnun og breytir engu. Ekkert Commit er á staðlaðri leið. Viðskiptahöfnun bakfærir. Í ham án staðfestingar ber kallandi ábyrgð á bakfærslu.';
    begin
        Notes := NotesLbl;
        exit(true);
    end;
}
