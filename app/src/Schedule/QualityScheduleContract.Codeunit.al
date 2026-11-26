namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Bilingual scheduling contract, including the count unit and explicit activation.</summary>
codeunit 10035331 "Quality Schedule Contract ori"
{
    Access = Internal;
    var
        Contract: Codeunit "Msg Contract Mgt ori";
        DescriptionTxt: Label 'Creates one scheduled-inspection job for a generation-rule group, on hold by default. Activation must be explicit.', Comment = 'is-IS=Stofnar eitt verk fyrir áætlaðar skoðanir í stofnunarregluflokki, sjálfgefið í bið. Virkjun verður að vera skýr.';
        GroupTxt: Label 'Schedule group, default QM. Code of 1 to 20 characters. Every rule must have at least one filter.', Comment = 'is-IS=Tímaáætlunarflokkur, sjálfgefið QM. Kóði með 1 til 20 stöfum. Hver regla verður að hafa að minnsta kosti eina síu.';
        TimeTxt: Label 'Required HH:mm:ss time, 00:00:00 through 23:59:59, mapped to Job Queue Entry Starting Time in the scheduling user time zone.', Comment = 'is-IS=Áskilinn tími HH:mm:ss, 00:00:00 til 23:59:59, varpað á upphafstíma verkbiðraðarfærslu í tímabelti notandans sem áætlar verkið.';
        DaysTxt: Label 'Unique integer weekdays 1=Monday through 7=Sunday. Omit for all seven days. An empty array is refused.', Comment = 'is-IS=Einkvæmir heiltöluvikudagar 1=mánudagur til 7=sunnudagur. Slepptu fyrir alla sjö dagana. Tómu fylki er hafnað.';
        MinutesTxt: Label 'Whole minutes between runs, 1 to 2147483647. Default 1440 (daily). Maps to No. of Minutes between Runs.', Comment = 'is-IS=Heilar mínútur milli keyrslna, 1 til 2147483647. Sjálfgefið 1440 (daglega). Varpað á fjölda mínútna milli keyrslna.';
        ActivateTxt: Label 'False by default: create On Hold. True makes the entry Ready through standard scheduling; the report is never run synchronously.', Comment = 'is-IS=Sjálfgefið false: stofna í bið. True gerir færsluna tilbúna með staðlaðri tímaáætlun; skýrslan er aldrei keyrð samstillt.';
        CountTxt: Label 'Counts one job queue entry, not future inspections. Must equal 1 when sent. If Require Confirmation for Irreversible Messages is enabled, omission returns expected 1 without writing; otherwise omission permits creation.', Comment = 'is-IS=Telur eina verkbiðraðarfærslu, ekki framtíðarskoðanir. Verður að vera 1 við sendingu. Ef Krefjast staðfestingar fyrir óafturkræf skilaboð er virkt skilar vöntun expected 1 án skrifa; annars leyfir vöntun stofnun.';
        IdTxt: Label 'ID of the new Job Queue Entry, as a GUID.', Comment = 'is-IS=Auðkenni nýrrar verkbiðraðarfærslu sem GUID.';
        StatusTxt: Label 'On Hold or Ready. The outer status describes message success.', Comment = 'is-IS=On Hold eða Ready. Ytra status lýsir árangri skilaboðanna.';
        OptionTxt: Label 'Invariant name of the current Inspection Creation Option from Quality Management Setup.', Comment = 'is-IS=Óstaðfært heiti núverandi valkosts fyrir stofnun skoðana úr uppsetningu gæðastjórnunar.';
        WarningTxt: Label 'Present only for Always create new inspection or Always create re-inspection. Review the setup before activating.', Comment = 'is-IS=Aðeins til staðar fyrir Always create new inspection eða Always create re-inspection. Farðu yfir uppsetningu fyrir virkjun.';
        OneTxt: Label 'Exactly one job queue entry.', Comment = 'is-IS=Nákvæmlega ein verkbiðraðarfærsla.';
        InputErrTxt: Label 'Missing or malformed input, including null, wrong JSON types, invalid time or weekdays, group length or unknown keys.', Comment = 'is-IS=Viðfang vantar eða er ógilt, þar á meðal null, röng JSON-gagnagerð, ógildur tími eða vikudagar, lengd flokks eða óþekktir lyklar.';
        InputNextTxt: Label 'Use only the documented keys and formats.', Comment = 'is-IS=Notaðu aðeins skjalfesta lykla og snið.';
        PreconditionTxt: Label 'No rule in the group, a rule without filters, missing setup, or an existing scheduled-inspection job covering the group.', Comment = 'is-IS=Engin regla í flokknum, regla án síu, uppsetningu vantar eða fyrirliggjandi verk fyrir áætlaðar skoðanir nær yfir flokkinn.';
        PreconditionNextTxt: Label 'Review generation rules, Quality Management Setup and Job Queue Entries. Existing jobs are never replaced.', Comment = 'is-IS=Farðu yfir stofnunarreglur, uppsetningu gæðastjórnunar og verkbiðraðarfærslur. Aldrei er skipt út fyrirliggjandi verkum.';
        PermissionTxt: Label 'BIFROST QM Full ori and native job queue permissions are required. Read and base roles are refused.', Comment = 'is-IS=BIFROST QM Full ori og staðlaðar heimildir að verkbiðröð eru nauðsynlegar. Les- og grunnhlutverkum er hafnað.';
        PermissionNextTxt: Label 'Ask an administrator for the required roles.', Comment = 'is-IS=Biddu stjórnanda um nauðsynleg hlutverk.';
        ConfirmTxt: Label 'The count is missing while confirmation is enabled, or does not equal one. Nothing is changed.', Comment = 'is-IS=Fjöldann vantar á meðan staðfesting er virk, eða hann er ekki einn. Engu er breytt.';
        ConfirmNextTxt: Label 'Read expected and resend the same request with expectedCount 1.', Comment = 'is-IS=Lestu expected og sendu sömu beiðni aftur með expectedCount 1.';
        NativeTxt: Label 'Business Central rejected job creation or activation; the entire write is rolled back.', Comment = 'is-IS=Business Central hafnaði stofnun eða virkjun verks; öll skrif eru afturkölluð.';
        EffectTxt: Label 'Creates a recurring Job Queue Entry for Qlty. Schedule Inspection with standard report parameters. The expectedCount unit is one job queue entry. The entry is On Hold unless activate=true schedules it as Ready. No inspection is created by this call. Success commits once; failure rolls back; Omit Commit leaves the transaction with the caller.', Comment = 'is-IS=Stofnar endurtekna verkbiðraðarfærslu fyrir Qlty. Schedule Inspection með stöðluðum skýrsluviðföngum. Eining expectedCount er ein verkbiðraðarfærsla. Færslan er í bið nema activate=true áætli hana tilbúna. Engin skoðun er stofnuð af þessu kalli. Árangur staðfestir einu sinni; bilun afturkallar; Omit Commit skilur færsluna eftir hjá kallanda.';
        NotesTxt: Label 'Duplicate requests are refused; edit existing jobs on Job Queue Entries. No rules or setup are changed. Always-create options can generate inspections on every future run. No delete, run-now or pause operation is provided. Midnight is accepted as the standard 0T starting-time value.', Comment = 'is-IS=Tvíteknum beiðnum er hafnað; breyttu fyrirliggjandi verkum á Verkbiðraðarfærslum. Engum reglum eða uppsetningu er breytt. Valkostir sem stofna alltaf geta myndað skoðanir við hverja framtíðarkeyrslu. Engin eyðing, tafarlaus keyrsla eða biðaðgerð er í boði. Miðnætti er samþykkt sem staðlað 0T upphafstímagildi.';
        ExampleTxt: Label 'Prepare a weekday schedule on hold', Comment = 'is-IS=Undirbúa tímaáætlun virka daga í bið';

    /// <summary>Provides the localized scheduling description.</summary>
    /// <returns>A short description.</returns>
    procedure Description(): Text[250]
    begin
        exit(DescriptionTxt);
    end;

    /// <summary>Provides the localized target chapter.</summary>
    /// <param name="Target">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        Target.Add(Contract.TargetEntry('data.scheduleGroup', 'Code[20]', GroupTxt));
        exit(true);
    end;

    /// <summary>Provides the localized parameters chapter.</summary>
    /// <param name="Parameters">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    begin
        Parameters.Add(Contract.Parameter('scheduleGroup', 'string', false, GroupTxt));
        Parameters.Add(Contract.Parameter('startTime', 'string', true, TimeTxt));
        Parameters.Add(Contract.Parameter('daysOfWeek', 'array', false, DaysTxt));
        Parameters.Add(Contract.Parameter('repeatEveryMinutes', 'integer', false, MinutesTxt));
        Parameters.Add(Contract.Parameter('activate', 'boolean', false, ActivateTxt));
        Parameters.Add(Contract.Parameter('expectedCount', 'integer', false, CountTxt));
        exit(true);
    end;

    /// <summary>Provides the localized response chapter.</summary>
    /// <param name="Response">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Fields: JsonArray;
    begin
        Response.Add('contentType', 'application/json');
        Fields.Add(Contract.ResponseField('status', 'string', 'Success'));
        Fields.Add(Contract.ResponseField('noOfRecords', 'integer', OneTxt));
        Fields.Add(Contract.ResponseField('jobQueueEntryId', 'string', IdTxt));
        Fields.Add(Contract.ResponseField('jobStatus', 'string', StatusTxt));
        Fields.Add(Contract.ResponseField('scheduleGroup', 'string', GroupTxt));
        Fields.Add(Contract.ResponseField('inspectionCreationOption', 'string', OptionTxt));
        Fields.Add(Contract.ResponseField('warning', 'string', WarningTxt));
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Provides the localized errors chapter.</summary>
    /// <param name="Errors">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetErrors(var Errors: JsonArray): Boolean
    begin
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, InputErrTxt, InputNextTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, InputErrTxt, InputNextTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, InputErrTxt, InputNextTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, InputErrTxt, InputNextTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, PreconditionTxt, PreconditionNextTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, PermissionTxt, PermissionNextTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::ConfirmationRequired, ConfirmTxt, ConfirmNextTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::ConfirmationMismatch, ConfirmTxt, ConfirmNextTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, NativeTxt, PreconditionNextTxt));
        exit(true);
    end;

    /// <summary>Provides the localized effect chapter.</summary>
    /// <param name="Effect">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
    begin
        Effect.Add('effect', 'write');
        Effect.Add('changes', EffectTxt);
        Effect.Add('idempotent', false);
        Effect.Add('permissionSet', 'BIFROST QM Full ori');
        Preconditions.Add(PermissionTxt);
        Preconditions.Add(GroupTxt);
        Preconditions.Add(CountTxt);
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    /// <summary>Provides the localized metering chapter.</summary>
    /// <param name="Metering">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        Clear(Metering);
        exit(false);
    end;

    /// <summary>Provides the localized related chapter.</summary>
    /// <param name="Related">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        Clear(Related);
        exit(false);
    end;

    /// <summary>Provides the localized workflow chapter.</summary>
    /// <param name="Workflow">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        Clear(Workflow);
        exit(false);
    end;

    /// <summary>Provides the localized examples chapter.</summary>
    /// <param name="Examples">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        Examples.Add(Contract.Example(ExampleTxt, '{"type":"Quality.GenerationRule.Schedule","data":{"scheduleGroup":"QM","startTime":"08:00:00","daysOfWeek":[1,2,3,4,5],"repeatEveryMinutes":60,"activate":false,"expectedCount":1}}', '{"status":"Success","noOfRecords":1,"jobQueueEntryId":"<guid>","jobStatus":"On Hold","scheduleGroup":"QM","inspectionCreationOption":"Use existing open inspection if available"}'));
        exit(true);
    end;

    /// <summary>Provides the localized overview chapter.</summary>
    /// <param name="Overview">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := DescriptionTxt;
        exit(true);
    end;

    /// <summary>Provides the localized notes chapter.</summary>
    /// <param name="Notes">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := NotesTxt;
        exit(true);
    end;
}
