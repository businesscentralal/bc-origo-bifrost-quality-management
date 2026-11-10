namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;

/// <summary>
/// Implements Quality.Inspection.Finish.
/// Calls FinishInspection on the quality inspection header so Business Central runs the
/// result and item-tracking checks. The write runs in Qlty Insp Finish Proc ori unless the
/// caller set Omit Commit, in which case the same apply runs in the caller's transaction.
/// </summary>
codeunit 10035282 "Qlty Insp Finish Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        Contract: Codeunit "Qlty Insp Finish Ctr ori";
        DescriptionLbl: Label 'Finishes one quality inspection so its result is locked, with the standard Business Central checks.', MaxLength = 250, Comment = 'is-IS=Lýkur einni gæðaskoðun svo niðurstaðan læsist, með venjulegum athugunum Business Central.';

    /// <summary>The type is always available. It does not read a setup table of this app.</summary>
    /// <returns>True.</returns>
    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>The filter table is the quality inspection header.</summary>
    /// <returns>The table id of Qlty. Inspection Header.</returns>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Qlty. Inspection Header");
    end;

    /// <summary>Catalogue description.</summary>
    /// <returns>The description, in the caller's language.</returns>
    procedure GetDescription(): Text[250]
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Search keywords. The Icelandic list is not shorter than the English one.</summary>
    /// <returns>Comma-separated keywords.</returns>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'inspection, finish inspection, quality inspection, lock result, inspection status, finished inspection, complete inspection, quality result', Comment = 'is-IS=skoðun, ljúka skoðun, gæðaskoðun, læsa niðurstöðu, staða skoðunar, lokin skoðun, ljúka gæðaskoðun, niðurstaða gæða';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Longer selection text for discovery.</summary>
    /// <returns>When to choose this message type.</returns>
    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Finish one open quality inspection so Business Central locks the result. Send no. Send reinspectionNo only when the inspection is not the original. A finished inspection is left unchanged when the item-tracking check passes.', Comment = 'is-IS=Ljúktu einni opinni gæðaskoðun svo Business Central læsi niðurstöðunni. Sendu no. Sendu reinspectionNo aðeins þegar skoðunin er ekki sú upphaflega. Lokið skoðun er óbreytt þegar athugun rekjanleika tekst.';
    begin
        exit(SelectionLbl);
    end;

    /// <summary>The message is inbound.</summary>
    /// <returns>Inbound.</returns>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Envelope chapter. The subject is not read.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    begin
        Contract.Envelope(Envelope);
        exit(true);
    end;

    /// <summary>Target chapter.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        Contract.Target(Target);
        exit(true);
    end;

    /// <summary>Parameters chapter.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    begin
        Contract.Parameters(Parameters);
        exit(true);
    end;

    /// <summary>Response chapter.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    begin
        Contract.Response(Response);
        exit(true);
    end;

    /// <summary>Errors chapter, including Retryable.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    begin
        Contract.Errors(Errors);
        exit(true);
    end;

    /// <summary>Effect chapter. The effect is write. A finished inspection is not written again when tracking passes.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        Contract.Effect(Effect);
        exit(true);
    end;

    /// <summary>Metering is filled by Foundation.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>Related chapter.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        Contract.Related(Related);
        exit(true);
    end;

    /// <summary>Workflow chapter.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        Contract.Workflow(MessageTypeName(), Workflow);
        exit(true);
    end;

    /// <summary>Examples chapter.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        Contract.Examples(Examples);
        exit(true);
    end;

    /// <summary>Translated overview chapter. States the effect and idempotency.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := Contract.Overview();
        exit(true);
    end;

    /// <summary>Translated notes chapter. States confirmation and commit behaviour.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := Contract.Notes();
        exit(true);
    end;

    trigger OnRun()
    var
        Proc: Codeunit "Qlty Insp Finish Proc ori";
    begin
        Proc.Apply(Rec);
    end;

    /// <summary>Runs the finish. Omit Commit keeps the caller's transaction.</summary>
    /// <param name="Argument">The message argument.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Proc: Codeunit "Qlty Insp Finish Proc ori";
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if Argument."Omit Commit" then begin
            Proc.Apply(Argument);
            exit;
        end;
        if not Codeunit.Run(Codeunit::"Qlty Insp Finish Proc ori", Argument) then
            Contract.RespondWithPlatformError(Argument);
    end;

    local procedure MessageTypeName(): Text
    begin
        exit('Quality.Inspection.Finish');
    end;
}
