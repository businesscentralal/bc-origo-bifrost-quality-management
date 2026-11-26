namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.GenerationRule.JobQueue;
using Microsoft.QualityManagement.Setup;
using Origo.Bifrost;
using System.Threading;

/// <summary>Creates a standard job queue entry without invoking the inspection report.</summary>
codeunit 10035329 "Quality Schedule Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    trigger OnRun()
    begin
        CreateSchedule(Rec);
    end;

    var
        Contract: Codeunit "Quality Schedule Contract ori";
        JsonObjectExpectedTxt: Label 'a JSON object', Comment = 'is-IS=JSON-hlutur';
        InvalidErr: Label 'Invalid parameter %1. Nothing was changed.', Comment = '%1 = parameter name, is-IS=Ógilt viðfang %1. Engu var breytt.';
        CorrectTxt: Label 'Correct this parameter and send the request again.', Comment = 'is-IS=Leiðréttu þetta viðfang og sendu beiðnina aftur.';
        UnknownErr: Label 'Unknown parameter %1. Nothing was changed.', Comment = '%1 = parameter name, is-IS=Óþekkt viðfang %1. Engu var breytt.';
        PermissionErr: Label 'Scheduling requires BIFROST QM Full ori and native job queue permissions.', Comment = 'is-IS=Tímaáætlun krefst BIFROST QM Full ori og staðlaðra heimilda að verkbiðröð.';
        PermissionNextTxt: Label 'Ask an administrator for BIFROST QM Full ori and job queue permissions.', Comment = 'is-IS=Biddu stjórnanda um BIFROST QM Full ori og heimildir að verkbiðröð.';
        GroupExpectedTxt: Label 'a non-empty schedule group of at most 20 characters', Comment = 'is-IS=tímaáætlunarflokkur sem er ekki tómur og hefur mest 20 stafi';
        TimeExpectedTxt: Label 'a time string HH:mm:ss from 00:00:00 to 23:59:59', Comment = 'is-IS=tímastrengur HH:mm:ss frá 00:00:00 til 23:59:59';
        DaysExpectedTxt: Label 'a non-empty array of unique integers 1 (Monday) to 7 (Sunday)', Comment = 'is-IS=fylki sem er ekki tómt með einkvæmum heiltölum 1 (mánudagur) til 7 (sunnudagur)';
        MinutesExpectedTxt: Label 'an integer from 1 to 2147483647 minutes', Comment = 'is-IS=heiltala frá 1 til 2147483647 mínútna';
        BooleanExpectedTxt: Label 'a JSON Boolean, true or false', Comment = 'is-IS=JSON-rökgildi, true eða false';
        NoRulesErr: Label 'No generation rule exists in schedule group %1.', Comment = '%1 = schedule group, is-IS=Engin stofnunarregla er til í tímaáætlunarflokki %1.';
        FilterErr: Label 'Every generation rule in schedule group %1 must have at least one filter.', Comment = '%1 = schedule group, is-IS=Sérhver stofnunarregla í tímaáætlunarflokki %1 verður að hafa að minnsta kosti eina síu.';
        RuleExpectedTxt: Label 'at least one generation rule, with a condition, item or item attribute filter on every rule', Comment = 'is-IS=að minnsta kosti ein stofnunarregla með skilyrðis-, vöru- eða vörueiginleikasíu á hverri reglu';
        RuleNextTxt: Label 'Review the Quality Inspection Generation Rules page and set a filter on every rule in this group.', Comment = 'is-IS=Farðu yfir síðuna með stofnunarreglum gæðaskoðana og stilltu síu á hverja reglu í þessum flokki.';
        DuplicateErr: Label 'A scheduled-inspection job already covers group %1.', Comment = '%1 = schedule group, is-IS=Verk fyrir áætlaðar skoðanir nær þegar yfir flokk %1.';
        DuplicateExpectedTxt: Label 'no existing job queue entry for this schedule group', Comment = 'is-IS=engin fyrirliggjandi verkbiðraðarfærsla fyrir þennan tímaáætlunarflokk';
        DuplicateNextTxt: Label 'Review the existing job on the Job Queue Entries page. This message never replaces it.', Comment = 'is-IS=Farðu yfir fyrirliggjandi verk á síðunni Verkbiðraðarfærslur. Þessi skilaboð koma aldrei í stað þess.';
        SetupErr: Label 'Quality Management Setup is missing.', Comment = 'is-IS=Uppsetningu gæðastjórnunar vantar.';
        SetupExpectedTxt: Label 'existing Quality Management Setup', Comment = 'is-IS=fyrirliggjandi uppsetning gæðastjórnunar';
        SetupNextTxt: Label 'Complete Quality Management Setup before scheduling inspections.', Comment = 'is-IS=Ljúktu uppsetningu gæðastjórnunar áður en skoðanir eru settar á tímaáætlun.';
        CountTxt: Label 'one job queue entry, not the inspections generated later', Comment = 'is-IS=ein verkbiðraðarfærsla, ekki skoðanirnar sem verða stofnaðar síðar';
        DescriptionTxt: Label 'Schedule inspection: %1', Comment = '%1 = schedule group, is-IS=Áætluð skoðun: %1';
        WarningTxt: Label 'The current Inspection Creation Option creates inspections on every run even when inspections already exist. Review this setting before activating the job.', Comment = 'is-IS=Núverandi valkostur fyrir stofnun skoðana stofnar skoðanir við hverja keyrslu þótt skoðanir séu þegar til. Farðu yfir þessa stillingu áður en verkið er virkjað.';

    /// <summary>Requires both the dedicated app capability and native job queue write access.</summary>
    /// <returns>Whether the caller can create schedules.</returns>
    procedure IsEnabled(): Boolean
    var
        Capability: Record "Quality Schedule Access ori";
        Job: Record "Job Queue Entry";
    begin
        exit(Capability.WritePermission() and Job.WritePermission());
    end;

    /// <summary>Identifies the created table.</summary>
    /// <returns>The Job Queue Entry table number.</returns>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Job Queue Entry");
    end;

    /// <summary>Describes the admin scheduling action.</summary>
    /// <returns>The localized description.</returns>
    procedure GetDescription(): Text[250]
    begin
        exit(Contract.Description());
    end;

    /// <summary>Declares the inbound write direction.</summary>
    /// <returns>Inbound.</returns>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Returns translated discovery terms.</summary>
    /// <returns>Comma-separated keywords.</returns>
    procedure GetKeywords(): Text
    var
        KeywordsTxt: Label 'quality, generation rule, schedule, job queue, inspection', Comment = 'is-IS=gæði, stofnunarregla, tímaáætlun, verkbiðröð, skoðun';
    begin
        exit(KeywordsTxt);
    end;

    /// <summary>Explains when to select this type.</summary>
    /// <returns>The localized description.</returns>
    procedure GetSelectionDescription(): Text
    begin
        exit(GetDescription());
    end;

    /// <summary>Runs validation and creation in one transaction; native failures roll back.</summary>
    /// <param name="Argument">Request and response carrier.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if Argument."Omit Commit" then
            CreateSchedule(Argument)
        else
            if not Codeunit.Run(Codeunit::"Quality Schedule Impl ori", Argument) then
                Argument.RespondWithLastError();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure CreateSchedule(var Argument: Record "Message Argument ori")
    var
        Job: Record "Job Queue Entry";
        Rule: Record "Qlty. Inspection Gen. Rule";
        Setup: Record "Qlty. Management Setup";
        ConfirmGate: Codeunit "Confirm Gate ori";
        RequestJson: JsonObject;
        Response: JsonObject;
        ScheduleGroup: Code[20];
        StartTime: Time;
        Days: List of [Integer];
        RepeatMinutes: Integer;
        Activate: Boolean;
    begin
        if not IsEnabled() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PermissionDenied, PermissionErr, 'permissions', '', 'BIFROST QM Full ori', PermissionNextTxt);
            exit;
        end;
        if not TryReadRequest(Argument, RequestJson) then begin
            Invalid(Argument, 'data', JsonObjectExpectedTxt);
            exit;
        end;
        if not ReadRequest(Argument, RequestJson, ScheduleGroup, StartTime, Days, RepeatMinutes, Activate) then
            exit;
        // Existing rules provide a shared lock for concurrent requests for the same group.
        Rule.LockTable();
        Rule.SetRange("Schedule Group", ScheduleGroup);
        Rule.SetLoadFields("Schedule Group", "Condition Filter", "Item Filter", "Item Attribute Filter");
        if not Rule.FindSet() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(NoRulesErr, ScheduleGroup), 'scheduleGroup', ScheduleGroup, RuleExpectedTxt, RuleNextTxt);
            exit;
        end;
        repeat
            if (Rule."Condition Filter" = '') and (Rule."Item Filter" = '') and (Rule."Item Attribute Filter" = '') then begin
                Argument.RespondWithError("Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(FilterErr, ScheduleGroup), 'scheduleGroup', ScheduleGroup, RuleExpectedTxt, RuleNextTxt);
                exit;
            end;
        until Rule.Next() = 0;
        Job.LockTable();
        if HasExistingJob(ScheduleGroup) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(DuplicateErr, ScheduleGroup), 'scheduleGroup', ScheduleGroup, DuplicateExpectedTxt, DuplicateNextTxt);
            exit;
        end;
        Setup.SetLoadFields("Inspection Creation Option");
        if not Setup.Get() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PreconditionFailed, SetupErr, 'scheduleGroup', ScheduleGroup, SetupExpectedTxt, SetupNextTxt);
            exit;
        end;
        if not ConfirmGate.Confirm(Argument, 1, CountTxt) then
            exit;
        Job.Init();
        Job.Insert(true);
        Job.Validate("Object Type to Run", Job."Object Type to Run"::Report);
        Job.Validate("Object ID to Run", Report::"Qlty. Schedule Inspection");
        Job.Status := Job.Status::"On Hold";
        Job."Recurring Job" := true;
        Job.Validate("Run on Mondays", Days.Contains(1));
        Job.Validate("Run on Tuesdays", Days.Contains(2));
        Job.Validate("Run on Wednesdays", Days.Contains(3));
        Job.Validate("Run on Thursdays", Days.Contains(4));
        Job.Validate("Run on Fridays", Days.Contains(5));
        Job.Validate("Run on Saturdays", Days.Contains(6));
        Job.Validate("Run on Sundays", Days.Contains(7));
        Job.Validate("No. of Minutes between Runs", RepeatMinutes);
        Job.Validate("Starting Time", StartTime);
        Job.SetReportParameters(ReportParameters(ScheduleGroup));
        Job."Report Request Page Options" := true;
        Job.Description := CopyStr(StrSubstNo(DescriptionTxt, ScheduleGroup), 1, MaxStrLen(Job.Description));
        Job.Modify(true);
        if Activate then
            Job.SetStatus(Job.Status::Ready);
        Response.Add('status', 'Success');
        Response.Add('noOfRecords', 1);
        Response.Add('jobQueueEntryId', Format(Job.ID, 0, 4));
        if Job.Status = Job.Status::Ready then
            Response.Add('jobStatus', 'Ready')
        else
            Response.Add('jobStatus', 'On Hold');
        Response.Add('scheduleGroup', ScheduleGroup);
        Response.Add('inspectionCreationOption', Setup."Inspection Creation Option".Names().Get(Setup."Inspection Creation Option".Ordinals().IndexOf(Setup."Inspection Creation Option".AsInteger())));
        if Setup."Inspection Creation Option" in [Setup."Inspection Creation Option"::"Always create new inspection", Setup."Inspection Creation Option"::"Always create re-inspection"] then
            Response.Add('warning', WarningTxt);
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    [TryFunction]
    local procedure TryReadRequest(var Argument: Record "Message Argument ori"; var RequestJson: JsonObject)
    begin
        RequestJson := Argument.GetRequestJson();
    end;

    local procedure ReadRequest(var Argument: Record "Message Argument ori"; RequestJson: JsonObject; var ScheduleGroup: Code[20]; var StartTime: Time; var Days: List of [Integer]; var RepeatMinutes: Integer; var Activate: Boolean): Boolean
    var
        Token: JsonToken;
        DayToken: JsonToken;
        KeyName: Text;
        InputText: Text;
        DayNumber: Integer;
        ExpectedCount: Integer;
    begin
        foreach KeyName in RequestJson.Keys() do
            if not (KeyName in ['scheduleGroup', 'startTime', 'daysOfWeek', 'repeatEveryMinutes', 'activate', 'expectedCount']) then begin
                Argument.RespondWithError("Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownErr, KeyName), KeyName, '', 'scheduleGroup, startTime, daysOfWeek, repeatEveryMinutes, activate, expectedCount', CorrectTxt);
                exit(false);
            end;
        if RequestJson.Get('expectedCount', Token) then
            if not ReadInteger(Token, ExpectedCount) then begin
                Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(InvalidErr, 'expectedCount'), 'expectedCount', '', '1', CorrectTxt);
                exit(false);
            end;
        ScheduleGroup := 'QM';
        if RequestJson.Get('scheduleGroup', Token) then begin
            if not ReadText(Token, InputText) then
                exit(Invalid(Argument, 'scheduleGroup', GroupExpectedTxt));
            if (StrLen(InputText) > 20) or (InputText.Trim() = '') then
                exit(Invalid(Argument, 'scheduleGroup', GroupExpectedTxt));
            ScheduleGroup := CopyStr(InputText, 1, MaxStrLen(ScheduleGroup));
        end;
        if not RequestJson.Get('startTime', Token) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, StrSubstNo(InvalidErr, 'startTime'), 'startTime', '', TimeExpectedTxt, CorrectTxt);
            exit(false);
        end;
        if not ReadText(Token, InputText) then
            exit(Invalid(Argument, 'startTime', TimeExpectedTxt));
        if StrLen(InputText) <> 8 then
            exit(Invalid(Argument, 'startTime', TimeExpectedTxt));
        if (CopyStr(InputText, 3, 1) <> ':') or (CopyStr(InputText, 6, 1) <> ':') or (DelChr(DelChr(InputText, '=', ':'), '=', '0123456789') <> '') then
            exit(Invalid(Argument, 'startTime', TimeExpectedTxt));
        if (CopyStr(InputText, 1, 2) > '23') or (CopyStr(InputText, 4, 2) > '59') or (CopyStr(InputText, 7, 2) > '59') then
            exit(Invalid(Argument, 'startTime', TimeExpectedTxt));
        if not Evaluate(StartTime, InputText, 9) then
            exit(Invalid(Argument, 'startTime', TimeExpectedTxt));
        if RequestJson.Get('daysOfWeek', Token) then begin
            if not Token.IsArray() then
                exit(Invalid(Argument, 'daysOfWeek', DaysExpectedTxt));
            if Token.AsArray().Count() = 0 then
                exit(Invalid(Argument, 'daysOfWeek', DaysExpectedTxt));
            foreach DayToken in Token.AsArray() do begin
                if not ReadInteger(DayToken, DayNumber) then
                    exit(Invalid(Argument, 'daysOfWeek', DaysExpectedTxt));
                if (DayNumber < 1) or (DayNumber > 7) or Days.Contains(DayNumber) then
                    exit(Invalid(Argument, 'daysOfWeek', DaysExpectedTxt));
                Days.Add(DayNumber);
            end;
        end else
            for DayNumber := 1 to 7 do
                Days.Add(DayNumber);
        RepeatMinutes := 1440;
        if RequestJson.Get('repeatEveryMinutes', Token) then begin
            if not ReadInteger(Token, RepeatMinutes) then
                exit(Invalid(Argument, 'repeatEveryMinutes', MinutesExpectedTxt));
            if RepeatMinutes < 1 then
                exit(Invalid(Argument, 'repeatEveryMinutes', MinutesExpectedTxt));
        end;
        if RequestJson.Get('activate', Token) then begin
            Token.WriteTo(InputText);
            if not (InputText in ['true', 'false']) then
                exit(Invalid(Argument, 'activate', BooleanExpectedTxt));
            Activate := InputText = 'true';
        end;
        exit(true);
    end;

    local procedure ReadText(Token: JsonToken; var InputText: Text): Boolean
    var
        Serialized: Text;
    begin
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            exit(false);
        InputText := Token.AsValue().AsText();
        exit(true);
    end;

    local procedure ReadInteger(Token: JsonToken; var Number: Integer): Boolean
    var
        Serialized: Text;
    begin
        Token.WriteTo(Serialized);
        if (Serialized = '') or (DelChr(Serialized, '=', '0123456789') <> '') then
            exit(false);
        exit(Evaluate(Number, Serialized, 9));
    end;

    local procedure Invalid(var Argument: Record "Message Argument ori"; ParameterName: Text; Expected: Text): Boolean
    begin
        Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidErr, ParameterName), ParameterName, '', Expected, CorrectTxt);
        exit(false);
    end;

    local procedure ReportParameters(ScheduleGroup: Code[20]) Parameters: Text
    var
        Rule: Record "Qlty. Inspection Gen. Rule";
        Document: XmlDocument;
        RootElement: XmlElement;
        DataItems: XmlElement;
        DataItem: XmlElement;
    begin
        Rule.SetRange("Schedule Group", ScheduleGroup);
        Document := XmlDocument.Create();
        DataItem := XmlElement.Create('DataItem');
        DataItem.SetAttribute('name', 'CurrentInspectionGenerationRule');
        DataItem.Add(XmlText.Create(Rule.GetView(false)));
        DataItems := XmlElement.Create('DataItems');
        DataItems.Add(DataItem);
        RootElement := XmlElement.Create('ReportParameters');
        RootElement.Add(DataItems);
        Document.Add(RootElement);
        Document.WriteTo(Parameters);
    end;

    local procedure HasExistingJob(ScheduleGroup: Code[20]): Boolean
    var
        Job: Record "Job Queue Entry";
        Document: XmlDocument;
        DataItem: XmlNode;
        Covers: Boolean;
    begin
        Job.SetRange("Object Type to Run", Job."Object Type to Run"::Report);
        Job.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection");
        // GetReportParameters reads a BLOB, so use full records here.
        if Job.FindSet() then
            repeat
                if not XmlDocument.ReadFrom(Job.GetReportParameters(), Document) then
                    exit(true);
                if not Document.SelectSingleNode('/ReportParameters/DataItems/DataItem[@name="CurrentInspectionGenerationRule"]', DataItem) then
                    exit(true);
                if not TryCoversGroup(DataItem.AsXmlElement().InnerText(), ScheduleGroup, Covers) then
                    exit(true);
                if Covers then
                    exit(true);
            until Job.Next() = 0;
    end;

    [TryFunction]
    local procedure TryCoversGroup(ViewText: Text; ScheduleGroup: Code[20]; var Covers: Boolean)
    var
        Rule: Record "Qlty. Inspection Gen. Rule";
        TempValidation: Record "Message Argument ori" temporary;
        RuleRef: RecordRef;
        ViewRequest: JsonObject;
        GroupFilter: Text;
    begin
        // Validate persisted native XML too: a misspelled field must never widen the selection.
        ViewRequest.Add('tableView', ViewText);
        RuleRef.Open(Database::"Qlty. Inspection Gen. Rule");
        if not TempValidation.ApplyTableView(ViewRequest, RuleRef) then begin
            RuleRef.Close();
            Covers := true;
            exit;
        end;
        RuleRef.SetTable(Rule);
        RuleRef.Close();
        // Other report filters must not allow a second job for the same schedule group.
        GroupFilter := Rule.GetFilter("Schedule Group");
        Rule.Reset();
        Rule.SetFilter("Schedule Group", GroupFilter);
        Rule.FilterGroup(10);
        Rule.SetRange("Schedule Group", ScheduleGroup);
        Covers := not Rule.IsEmpty();
    end;

    /// <summary>Declares the JSON envelope; subject is unused.</summary>
    /// <param name="Envelope">Receives the envelope chapter.</param>
    /// <returns>True.</returns>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
    begin
        Subject.Add('use', 'notUsed');
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', true);
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'application/json');
        exit(true);
    end;

    /// <summary>Provides the localized target contract chapter.</summary>
    /// <param name="Target">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        exit(Contract.GetTarget(Target));
    end;

    /// <summary>Provides the localized parameters contract chapter.</summary>
    /// <param name="Parameters">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    begin
        exit(Contract.GetParameters(Parameters));
    end;

    /// <summary>Provides the localized response contract chapter.</summary>
    /// <param name="Response">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetResponse(var Response: JsonObject): Boolean
    begin
        exit(Contract.GetResponse(Response));
    end;

    /// <summary>Provides the localized errors contract chapter.</summary>
    /// <param name="Errors">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetErrors(var Errors: JsonArray): Boolean
    begin
        exit(Contract.GetErrors(Errors));
    end;

    /// <summary>Provides the localized effect contract chapter.</summary>
    /// <param name="Effect">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        exit(Contract.GetEffect(Effect));
    end;

    /// <summary>Provides the localized metering contract chapter.</summary>
    /// <param name="Metering">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(Contract.GetMetering(Metering));
    end;

    /// <summary>Provides the localized related contract chapter.</summary>
    /// <param name="Related">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        exit(Contract.GetRelated(Related));
    end;

    /// <summary>Provides the localized workflow contract chapter.</summary>
    /// <param name="Workflow">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(Contract.GetWorkflow(Workflow));
    end;

    /// <summary>Provides the localized examples contract chapter.</summary>
    /// <param name="Examples">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        exit(Contract.GetExamples(Examples));
    end;

    /// <summary>Provides the localized overview contract chapter.</summary>
    /// <param name="Overview">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        exit(Contract.GetOverview(Overview));
    end;

    /// <summary>Provides the localized notes contract chapter.</summary>
    /// <param name="Notes">Receives the chapter.</param>
    /// <returns>Whether the chapter is available.</returns>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        exit(Contract.GetNotes(Notes));
    end;
}
