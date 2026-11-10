namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;

/// <summary>
/// Request reading, success writing and contract chapters for Quality.Inspection.Finish.
/// The answer uses status Success and recordStatus for the inspection, because Foundation
/// reserves status for the outcome of the message.
/// </summary>
codeunit 10035242 "Qlty Insp Finish Ctr ori"
{
    Access = Internal;

    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        OpenTok: Label 'Open', Locked = true;
        FinishedTok: Label 'Finished', Locked = true;
        SeveralProblemsErr: Label 'The request has more than one problem. Nothing was changed.', Comment = 'is-IS=Beiðnin hefur fleiri en eitt vandamál. Engu var breytt.';
        MissingParameterErr: Label 'Parameter %1 is required.', Comment = '%1 = parameter name, is-IS=Færibreyta %1 er nauðsynleg.';
        MissingNextStepTxt: Label 'Send no. Send reinspectionNo only for a reinspection.', Comment = 'is-IS=Sendu no. Sendu reinspectionNo aðeins fyrir endurskoðun.';
        UnknownParameterErr: Label 'Parameter %1 is not used by this message type.', Comment = '%1 = parameter name, is-IS=Færibreytan %1 er ekki notuð af þessari skilaboðategund.';
        UnknownNextStepTxt: Label 'Remove %1 from the request.', Comment = '%1 = parameter name, is-IS=Fjarlægðu %1 úr beiðninni.';
        TooLongErr: Label 'Parameter %1 is longer than %2 characters.', Comment = '%1 = parameter name, %2 = maximum length, is-IS=Færibreyta %1 er lengri en %2 stafir.';
        TooLongNextStepTxt: Label 'Send a code of at most 20 characters.', Comment = 'is-IS=Sendu kóða sem er í mesta lagi 20 stafir.';
        NotACodeErr: Label 'Parameter %1 must be text of at most 20 characters.', Comment = '%1 = parameter name, is-IS=Færibreyta %1 verður að vera texti sem er í mesta lagi 20 stafir.';
        NotAnIntegerErr: Label 'Parameter %1 must be a whole number from 0 upward.', Comment = '%1 = parameter name, is-IS=Færibreyta %1 verður að vera heiltala frá 0 og upp úr.';
        IntegerNextStepTxt: Label 'Send reinspectionNo as a whole number, or omit it for the original inspection.', Comment = 'is-IS=Sendu reinspectionNo sem heiltölu, eða slepptu henni fyrir upphaflegu skoðunina.';
        RecordNotFoundErr: Label 'Quality inspection %1 reinspection %2 was not found.', Comment = '%1 = inspection number, %2 = reinspection number, is-IS=Gæðaskoðun %1 endurskoðun %2 fannst ekki.';
        RecordNextStepTxt: Label 'Read the inspection with Data.Records.Get.', Comment = 'is-IS=Lestu skoðunina með Data.Records.Get.';
        PermissionDeniedErr: Label 'You do not have permission to finish this quality inspection.', Comment = 'is-IS=Þú hefur ekki heimild til að ljúka þessari gæðaskoðun.';
        PermissionExpectedTxt: Label 'read and write permission on the quality inspection header', Comment = 'is-IS=les- og skrifheimild á haus gæðaskoðunar';
        PermissionNextStepTxt: Label 'Ask for BIFROST QM Full ori and permission to change quality inspections, then send the same request again.', Comment = 'is-IS=Biddu um BIFROST QM Full ori og heimild til að breyta gæðaskoðunum og sendu sömu beiðni aftur.';
        NotFinishedErr: Label 'Inspection %1 reinspection %2 is still open. Nothing was changed.', Comment = '%1 = inspection number, %2 = reinspection number, is-IS=Skoðun %1 endurskoðun %2 er enn opin. Engu var breytt.';
        NotFinishedNextStepTxt: Label 'Accept the finish confirmation when a screen asks, or call this type from a service with no screen, then send the same request again.', Comment = 'is-IS=Samþykktu staðfestingu á að ljúka þegar skjár spyr, eða kallaðu þessa tegund úr þjónustu án skjás, og sendu sömu beiðni aftur.';
        CheckFailedNextStepTxt: Label 'Correct the result or the item tracking so finishing is allowed, then send the same request again.', Comment = 'is-IS=Lagfærðu niðurstöðuna eða vörurekjanleikann svo ljúka megi skoðuninni og sendu sömu beiðni aftur.';
        UnchangedMsg: Label 'Quality inspection %1 reinspection %2 is already finished. Nothing was changed.', Comment = '%1 = inspection number, %2 = reinspection number, is-IS=Gæðaskoðun %1 endurskoðun %2 er þegar lokið. Engu var breytt.';
        CodeExpectedTxt: Label 'text of at most 20 characters', Comment = 'is-IS=texti sem er í mesta lagi 20 stafir';
        IntegerExpectedTxt: Label 'a whole number from 0 upward', Comment = 'is-IS=heiltala frá 0 og upp úr';
        DeclaredParameterTxt: Label 'a parameter this message type declares', Comment = 'is-IS=færibreyta sem þessi skilaboðategund skilgreinir';
        ExistingInspectionTxt: Label 'an existing quality inspection', Comment = 'is-IS=gæðaskoðun sem er til';

        SubjectHelpTxt: Label 'The subject is not read. Send no under data.', Comment = 'is-IS=Subject er ekki lesið. Sendu no undir data.';
        InspectionNoTxt: Label 'inspection no.', Comment = 'is-IS=númer skoðunar';
        InspectionTargetTxt: Label 'The quality inspection header to finish.', Comment = 'is-IS=Haus gæðaskoðunarinnar sem á að ljúka.';
        ReinspectionNoTxt: Label 'reinspection no.', Comment = 'is-IS=númer endurskoðunar';
        ReinspectionHelpTxt: Label 'The reinspection number. Omit it, or send 0, for the original inspection.', Comment = 'is-IS=Númer endurskoðunar. Slepptu því, eða sendu 0, fyrir upphaflegu skoðunina.';
        InspectionNoHelpTxt: Label 'The quality inspection number.', Comment = 'is-IS=Númer gæðaskoðunarinnar.';
        SuccessHelpTxt: Label 'Success. Foundation reserves this key for the outcome of the message.', Comment = 'is-IS=Success. Foundation áskilur þennan lykil fyrir niðurstöðu skilaboðanna.';
        ReinspectionResponseTxt: Label 'The reinspection number. Zero is the original inspection.', Comment = 'is-IS=Númer endurskoðunar. Núll táknar upphaflegu skoðunina.';
        PreviousStatusHelpTxt: Label 'The status before the call: Open or Finished.', Comment = 'is-IS=Staða fyrir kallið: Open eða Finished.';
        RecordStatusHelpTxt: Label 'The status after the call. This is not the message outcome; that is status.', Comment = 'is-IS=Staða eftir kallið. Þetta er ekki niðurstaða skilaboðanna; hún er í status.';
        ChangedHelpTxt: Label 'False when the inspection was already finished and the item-tracking check passed. Nothing is written in that case.', Comment = 'is-IS=False þegar skoðuninni var þegar lokið og athugun vörurekjanleika tókst. Ekkert er skrifað í því tilviki.';
        MessageHelpTxt: Label 'Present only when changed is false.', Comment = 'is-IS=Aðeins til staðar þegar changed er false.';
        FinishedByHelpTxt: Label 'The user who finished the inspection, when Business Central recorded one.', Comment = 'is-IS=Notandinn sem lauk skoðuninni, þegar Business Central skráði hann.';
        FinishedDateHelpTxt: Label 'The finish timestamp in invariant format, when Business Central recorded one.', Comment = 'is-IS=Tímastimpill þegar skoðun lauk á stöðluðu sniði, þegar Business Central skráði hann.';
        MissingConditionTxt: Label 'no is missing or blank.', Comment = 'is-IS=no vantar eða er tómt.';
        FormatConditionTxt: Label 'no is not text of at most 20 characters, or reinspectionNo is not a whole number from 0 upward.', Comment = 'is-IS=no er ekki texti að hámarki 20 stafir, eða reinspectionNo er ekki heiltala sem er 0 eða hærri.';
        NotFoundConditionTxt: Label 'The inspection does not exist.', Comment = 'is-IS=Skoðunin er ekki til.';
        StillOpenConditionTxt: Label 'FinishInspection returned and the inspection is still open, for example because a screen confirmation was declined.', Comment = 'is-IS=FinishInspection skilaði og skoðunin er enn opin, til dæmis vegna þess að staðfestingu á skjá var hafnað.';
        UnknownConditionTxt: Label 'The request names a key other than no or reinspectionNo.', Comment = 'is-IS=Beiðnin nefnir annan lykil en no eða reinspectionNo.';
        RemoveUnknownTxt: Label 'Remove the unknown key.', Comment = 'is-IS=Fjarlægðu óþekkta lykilinn.';
        MultipleConditionTxt: Label 'Several of these problems were found in one call. errors lists each of them.', Comment = 'is-IS=Nokkur þessara vandamála fundust í einu kalli. errors telur þau öll upp.';
        CorrectAllTxt: Label 'Correct every listed problem and send the request again.', Comment = 'is-IS=Lagfærðu öll tilgreind vandamál og sendu beiðnina aftur.';
        BusinessConditionTxt: Label 'Business Central refused to finish the inspection. The record is unchanged.', Comment = 'is-IS=Business Central hafnaði því að ljúka skoðuninni. Færslan er óbreytt.';
        PermissionConditionTxt: Label 'The caller lacks the Full app role or cannot read and write the quality inspection header.', Comment = 'is-IS=Kallandinn hefur ekki fullt aðgangshlutverk appsins eða les- og skrifheimild á haus gæðaskoðunar.';
        RetryConditionTxt: Label 'The call can be sent again after the data it names is corrected.', Comment = 'is-IS=Hægt er að senda kallið aftur eftir að gögnin sem það nefnir hafa verið leiðrétt.';
        CorrectDataTxt: Label 'Correct the data and send the same request again.', Comment = 'is-IS=Lagfærðu gögnin og sendu sömu beiðni aftur.';
        ChangesHelpTxt: Label 'Calls FinishInspection on the quality inspection header. That procedure checks item tracking, then validates Status to Finished, which checks that the result allows finishing, records the finish user and timestamp, and modifies the header. It does not write Status on its own. FinishInspection does not call Commit. Unless the caller set Omit Commit, this message runs that call inside Codeunit.Run, which commits when finishing succeeds. A configured inspection-finished workflow can also commit inside Business Central. Finishing an inspection that is already finished does not write again when the item-tracking check passes.', Comment = 'is-IS=Kallar FinishInspection á haus gæðaskoðunar. Aðgerðin athugar vörurekjanleika og staðfestir síðan Status sem Finished, sem athugar hvort niðurstaðan leyfi að ljúka, skráir notanda og tímastimpil og breytir hausnum. Skilaboðin skrifa ekki Status sjálf. FinishInspection kallar ekki Commit. Nema kallandinn setji Omit Commit keyra skilaboðin kallið innan Codeunit.Run, sem staðfestir færsluna þegar skoðun lýkur. Uppsett verkflæði við lok skoðunar getur einnig staðfest færslu innan Business Central. Engin endurskrifun á sér stað þegar skoðuninni er þegar lokið og athugun vörurekjanleika tekst.';
        ExistsPreconditionTxt: Label 'The inspection already exists. This call does not create it.', Comment = 'is-IS=Skoðunin er þegar til. Þetta kall stofnar hana ekki.';
        DataPermissionPreconditionTxt: Label 'The caller can read and write the quality inspection header.', Comment = 'is-IS=Kallandinn getur lesið og skrifað haus gæðaskoðunar.';
        AppPermissionPreconditionTxt: Label 'The caller has the BIFROST QM Full ori permission set.', Comment = 'is-IS=Kallandinn hefur heimildasafnið BIFROST QM Full ori.';
        ResultPreconditionTxt: Label 'The result, when set, is configured to allow finishing, and required item tracking is present.', Comment = 'is-IS=Niðurstaðan, ef hún er stillt, er uppsett þannig að ljúka megi skoðuninni og nauðsynlegur vörurekjanleiki er til staðar.';
        ReadRelatedTxt: Label 'Read the inspection before and after the finish.', Comment = 'is-IS=Lestu skoðunina fyrir og eftir lok hennar.';
        WriteRelatedTxt: Label 'Cannot finish the inspection. Writing Status there skips the result and item-tracking checks.', Comment = 'is-IS=Getur ekki lokið skoðuninni. Að skrifa Status þar sleppir athugunum á niðurstöðu og vörurekjanleika.';
        ReadWorkflowTxt: Label 'Read the open inspection and its result.', Comment = 'is-IS=Lestu opnu skoðunina og niðurstöðu hennar.';
        FinishWorkflowTxt: Label 'Finish the inspection through FinishInspection.', Comment = 'is-IS=Ljúktu skoðuninni með FinishInspection.';
        ReadBackWorkflowTxt: Label 'Read the finished status back.', Comment = 'is-IS=Lestu lokastöðuna aftur.';
        WorkflowHelpTxt: Label 'Read the inspection, finish it, then read the status. The call is idempotent when the inspection is already finished and the item-tracking check passes.', Comment = 'is-IS=Lestu skoðunina, ljúktu henni og lestu svo stöðuna. Kallið er ítrekunaröruggt þegar skoðuninni er þegar lokið og athugun vörurekjanleika tekst.';
        FinishExampleTxt: Label 'Finish an inspection', Comment = 'is-IS=Ljúka skoðun';
        OverviewHelpTxt: Label 'Finishes one quality inspection by calling FinishInspection on the quality inspection header, after the standard result and item-tracking checks. Send no. Send reinspectionNo only for a reinspection; omit it for the original inspection. The effect is a write. The call is idempotent: finishing an inspection that is already finished does not write again when the item-tracking check passes.', Comment = 'is-IS=Lýkur einni gæðaskoðun með því að kalla FinishInspection á haus gæðaskoðunar eftir venjulegar athuganir á niðurstöðu og vörurekjanleika. Sendu no. Sendu reinspectionNo aðeins fyrir endurskoðun; slepptu því fyrir upphaflegu skoðunina. Áhrifin eru skrif. Kallið er ítrekunaröruggt: engin endurskrifun á sér stað þegar skoðuninni er þegar lokið og athugun vörurekjanleika tekst.';
        NotesHelpTxt: Label 'FinishInspection asks for confirmation when a user interface is available. A service call has no screen, so Business Central finishes without that question and still runs the checks. When a screen is present and the confirmation is declined, the inspection stays open and this message returns PreconditionFailed. A result configured to disallow finishing, or missing required item tracking, is returned as BusinessCentralError and leaves the inspection unchanged. FinishInspection does not call Commit. Unless Omit Commit is set, Codeunit.Run commits a successful finish. The answer uses status Success and recordStatus for the inspection, because Foundation reserves status for the outcome.', Comment = 'is-IS=FinishInspection biður um staðfestingu þegar notendaviðmót er tiltækt. Þjónustukall hefur engan skjá, svo Business Central lýkur án þessarar spurningar en keyrir samt athuganirnar. Þegar skjár er tiltækur og staðfestingu er hafnað er skoðunin áfram opin og skilaboðin skila PreconditionFailed. Niðurstaða sem bannar að ljúka, eða nauðsynlegur vörurekjanleiki sem vantar, skilar BusinessCentralError og skilur skoðunina eftir óbreytta. FinishInspection kallar ekki Commit. Nema Omit Commit sé stillt staðfestir Codeunit.Run færsluna þegar skoðun lýkur. Svarið notar status Success og recordStatus fyrir skoðunina því Foundation áskilur status fyrir niðurstöðu skilaboðanna.';

    /// <summary>Reads no and optional reinspectionNo. Collects every problem and returns false when any were collected.</summary>
    /// <param name="Argument">The message argument. Errors are collected on it.</param>
    /// <param name="InspectionNo">Receives the inspection number.</param>
    /// <param name="ReinspectionNo">Receives the reinspection number. Zero is the original inspection.</param>
    /// <returns>True when the request can be applied.</returns>
    internal procedure ReadFinishRequest(var Argument: Record "Message Argument ori"; var InspectionNo: Code[20]; var ReinspectionNo: Integer): Boolean
    var
        RequestJson: JsonObject;
        Token: JsonToken;
    begin
        RequestJson := Argument.GetRequestJson();
        CollectUnknownKeys(Argument, RequestJson);
        InspectionNo := '';
        ReinspectionNo := 0;

        if not RequestJson.Get('no', Token) then
            AddMissing(Argument, 'no')
        else
            ReadRequiredCode(Argument, Token, 'no', InspectionNo);

        if RequestJson.Get('reinspectionNo', Token) then
            ReadOptionalReinspection(Argument, Token, ReinspectionNo);

        exit(not Argument.HasCollectedErrors());
    end;

    /// <summary>Responds with validation errors collected before any write. One error keeps its own code.</summary>
    /// <param name="Argument">The message argument that holds the collected errors.</param>
    internal procedure RaiseCollected(var Argument: Record "Message Argument ori")
    begin
        Argument.RespondWithCollectedErrors("Bifrost Error Code ori"::MultipleErrors, SeveralProblemsErr);
    end;

    /// <summary>Preserves Foundation's platform error classification and adds the corrective next step.</summary>
    /// <param name="Argument">The message argument immediately after a failed Codeunit.Run.</param>
    internal procedure RespondWithPlatformError(var Argument: Record "Message Argument ori")
    var
        ResponseJson: JsonObject;
        CodeToken: JsonToken;
    begin
        Argument.RespondWithLastError();
        ResponseJson := Argument.GetResponseJson();
        if ResponseJson.Get('code', CodeToken) then
            if CodeToken.AsValue().AsText() = 'BusinessCentralError' then begin
                if ResponseJson.Contains('nextStep') then
                    ResponseJson.Replace('nextStep', CheckFailedNextStepTxt)
                else
                    ResponseJson.Add('nextStep', CheckFailedNextStepTxt);
                Argument.SetResponseJson(ResponseJson);
            end;
    end;

    /// <summary>Refuses the call without the app Full capability and native inspection read/write permissions.</summary>
    /// <param name="Argument">The message argument.</param>
    /// <param name="CanRead">True when the caller has the app Full capability and can read the table.</param>
    /// <param name="CanWrite">True when the caller can write the table.</param>
    /// <returns>True when the caller may continue.</returns>
    internal procedure HasTablePermission(var Argument: Record "Message Argument ori"; CanRead: Boolean; CanWrite: Boolean): Boolean
    begin
        if CanRead and CanWrite then
            exit(true);
        Argument.AddError("Bifrost Error Code ori"::PermissionDenied, PermissionDeniedErr, 'no', '', PermissionExpectedTxt, PermissionNextStepTxt);
        RaiseCollected(Argument);
        exit(false);
    end;

    /// <summary>Answers that the inspection does not exist.</summary>
    /// <param name="Argument">The message argument.</param>
    /// <param name="InspectionNo">The inspection number that was not found.</param>
    /// <param name="ReinspectionNo">The reinspection number that was not found.</param>
    internal procedure FailRecordNotFound(var Argument: Record "Message Argument ori"; InspectionNo: Code[20]; ReinspectionNo: Integer)
    begin
        Argument.AddError("Bifrost Error Code ori"::RecordNotFound, StrSubstNo(RecordNotFoundErr, InspectionNo, ReinspectionNo), 'no', InspectionNo, ExistingInspectionTxt, RecordNextStepTxt);
        RaiseCollected(Argument);
    end;

    /// <summary>Answers that FinishInspection returned and the inspection is still open.</summary>
    /// <param name="Argument">The message argument.</param>
    /// <param name="InspectionNo">The inspection number.</param>
    /// <param name="ReinspectionNo">The reinspection number.</param>
    internal procedure FailStillOpen(var Argument: Record "Message Argument ori"; InspectionNo: Code[20]; ReinspectionNo: Integer)
    begin
        Argument.AddError("Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(NotFinishedErr, InspectionNo, ReinspectionNo), 'no', InspectionNo, FinishedTok, NotFinishedNextStepTxt);
        RaiseCollected(Argument);
    end;

    /// <summary>Writes the success answer.</summary>
    /// <param name="Argument">The message argument.</param>
    /// <param name="Header">The inspection after the call.</param>
    /// <param name="PreviousToken">Open or Finished before the call.</param>
    /// <param name="Changed">False when the inspection was already finished.</param>
    internal procedure WriteSuccess(var Argument: Record "Message Argument ori"; var Header: Record "Qlty. Inspection Header"; PreviousToken: Text; Changed: Boolean)
    var
        ResponseJson: JsonObject;
        RecordToken: Text;
    begin
        RecordToken := StatusToken(Header.Status);
        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('no', Header."No.");
        ResponseJson.Add('reinspectionNo', Header."Re-inspection No.");
        ResponseJson.Add('previousStatus', PreviousToken);
        ResponseJson.Add('recordStatus', RecordToken);
        ResponseJson.Add('changed', Changed);
        if not Changed then
            ResponseJson.Add('message', StrSubstNo(UnchangedMsg, Header."No.", Header."Re-inspection No."));
        if Header."Finished By User ID" <> '' then
            ResponseJson.Add('finishedBy', Header."Finished By User ID");
        if Header."Finished Date" <> 0DT then
            ResponseJson.Add('finishedDate', Format(Header."Finished Date", 0, 9));
        Argument.SetResponseJson(ResponseJson);
    end;

    /// <summary>Stable token for an inspection status. Does not format the enum.</summary>
    /// <param name="Status">The status to name.</param>
    /// <returns>Open or Finished.</returns>
    internal procedure StatusToken(Status: Enum "Qlty. Inspection Status"): Text
    begin
        if Status = Status::Finished then
            exit(FinishedTok);
        exit(OpenTok);
    end;

    /// <summary>Builds the envelope. The subject is not read.</summary>
    /// <param name="EnvelopeChapter">Receives the chapter.</param>
    internal procedure Envelope(var EnvelopeChapter: JsonObject)
    var
        Subject: JsonObject;
    begin
        Subject.Add('use', 'notUsed');
        Subject.Add('description', SubjectHelpTxt);
        EnvelopeChapter.Add('subject', Subject);
        EnvelopeChapter.Add('dataRequired', true);
        EnvelopeChapter.Add('version', '1.0');
        EnvelopeChapter.Add('contentType', 'text/json');
    end;

    /// <summary>Builds the target chapter.</summary>
    /// <param name="TargetEntries">Receives the chapter.</param>
    internal procedure Target(var TargetEntries: JsonArray)
    begin
        TargetEntries.Add(ContractMgt.TargetEntry('data.no', InspectionNoTxt, InspectionTargetTxt));
        TargetEntries.Add(ContractMgt.TargetEntry('data.reinspectionNo', ReinspectionNoTxt, ReinspectionHelpTxt));
    end;

    /// <summary>Builds the parameters chapter.</summary>
    /// <param name="ParameterEntries">Receives the chapter.</param>
    internal procedure Parameters(var ParameterEntries: JsonArray)
    begin
        ParameterEntries.Add(ContractMgt.Parameter('no', 'string', true, InspectionNoHelpTxt));
        ParameterEntries.Add(ContractMgt.Parameter('reinspectionNo', 'integer', false, ReinspectionHelpTxt));
    end;

    /// <summary>Builds the response chapter.</summary>
    /// <param name="ResponseChapter">Receives the chapter.</param>
    internal procedure Response(var ResponseChapter: JsonObject)
    var
        Fields: JsonArray;
    begin
        Fields.Add(ContractMgt.ResponseField('status', 'string', SuccessHelpTxt));
        Fields.Add(ContractMgt.ResponseField('no', 'string', InspectionNoHelpTxt));
        Fields.Add(ContractMgt.ResponseField('reinspectionNo', 'integer', ReinspectionResponseTxt));
        Fields.Add(ContractMgt.ResponseField('previousStatus', 'string', PreviousStatusHelpTxt));
        Fields.Add(ContractMgt.ResponseField('recordStatus', 'string', RecordStatusHelpTxt));
        Fields.Add(ContractMgt.ResponseField('changed', 'boolean', ChangedHelpTxt));
        Fields.Add(ContractMgt.ResponseField('message', 'string', MessageHelpTxt));
        Fields.Add(ContractMgt.ResponseField('finishedBy', 'string', FinishedByHelpTxt));
        Fields.Add(ContractMgt.ResponseField('finishedDate', 'string', FinishedDateHelpTxt));
        ResponseChapter.Add('fields', Fields);
    end;

    /// <summary>Builds the errors chapter, including Retryable.</summary>
    /// <param name="ErrorEntries">Receives the chapter.</param>
    internal procedure Errors(var ErrorEntries: JsonArray)
    begin
        ErrorEntries.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter, MissingConditionTxt, MissingNextStepTxt));
        ErrorEntries.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, FormatConditionTxt, TooLongNextStepTxt));
        ErrorEntries.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, NotFoundConditionTxt, RecordNextStepTxt));
        ErrorEntries.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, StillOpenConditionTxt, NotFinishedNextStepTxt));
        ErrorEntries.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, UnknownConditionTxt, RemoveUnknownTxt));
        ErrorEntries.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MultipleErrors, MultipleConditionTxt, CorrectAllTxt));
        ErrorEntries.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, BusinessConditionTxt, CheckFailedNextStepTxt));
        ErrorEntries.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, PermissionConditionTxt, PermissionNextStepTxt));
        ErrorEntries.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::Retryable, RetryConditionTxt, CorrectDataTxt));
    end;

    /// <summary>Builds the effect chapter. The effect is write.</summary>
    /// <param name="EffectChapter">Receives the chapter.</param>
    internal procedure Effect(var EffectChapter: JsonObject)
    var
        Preconditions: JsonArray;
    begin
        EffectChapter.Add('effect', 'write');
        EffectChapter.Add('changes', ChangesHelpTxt);
        EffectChapter.Add('idempotent', true);
        EffectChapter.Add('permissionSet', 'BIFROST QM Full ori');
        Preconditions.Add(ExistsPreconditionTxt);
        Preconditions.Add(DataPermissionPreconditionTxt);
        Preconditions.Add(AppPermissionPreconditionTxt);
        Preconditions.Add(ResultPreconditionTxt);
        EffectChapter.Add('preconditions', Preconditions);
    end;

    /// <summary>Builds the related chapter. Only message types that exist today are named.</summary>
    /// <param name="RelatedEntries">Receives the chapter.</param>
    internal procedure Related(var RelatedEntries: JsonArray)
    begin
        RelatedEntries.Add(ContractMgt.RelatedEntry('Data.Records.Get', ReadRelatedTxt));
        RelatedEntries.Add(ContractMgt.RelatedEntry('Data.Records.Set', WriteRelatedTxt));
    end;

    /// <summary>Builds the workflow chapter.</summary>
    /// <param name="MessageType">The message type of this step.</param>
    /// <param name="WorkflowChapter">Receives the chapter.</param>
    internal procedure Workflow(MessageType: Text; var WorkflowChapter: JsonObject)
    var
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Data.Records.Get', ReadWorkflowTxt));
        Steps.Add(ContractMgt.WorkflowStep(MessageType, FinishWorkflowTxt));
        Steps.Add(ContractMgt.WorkflowStep('Data.Records.Get', ReadBackWorkflowTxt));
        WorkflowChapter.Add('steps', Steps);
        WorkflowChapter.Add('text', WorkflowHelpTxt);
    end;

    /// <summary>Builds one success example.</summary>
    /// <param name="ExampleEntries">Receives the chapter.</param>
    internal procedure Examples(var ExampleEntries: JsonArray)
    begin
        ExampleEntries.Add(ContractMgt.Example(FinishExampleTxt,
            '{"type":"Quality.Inspection.Finish","data":{"no":"QI00000001"}}',
            '{"status":"Success","no":"QI00000001","reinspectionNo":0,"previousStatus":"Open","recordStatus":"Finished","changed":true}'));
    end;

    /// <summary>Translated overview help chapter. States the effect and idempotency.</summary>
    /// <returns>The overview.</returns>
    internal procedure Overview(): Text
    begin
        exit(OverviewHelpTxt);
    end;

    /// <summary>Translated notes help chapter.</summary>
    /// <returns>The notes.</returns>
    internal procedure Notes(): Text
    begin
        exit(NotesHelpTxt);
    end;

    local procedure CollectUnknownKeys(var Argument: Record "Message Argument ori"; RequestJson: JsonObject)
    var
        Keys: List of [Text];
        ParameterKey: Text;
    begin
        Keys := RequestJson.Keys();
        foreach ParameterKey in Keys do
            if not (ParameterKey in ['no', 'reinspectionNo']) then
                Argument.AddError("Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownParameterErr, ParameterKey), ParameterKey, ParameterKey, DeclaredParameterTxt, StrSubstNo(UnknownNextStepTxt, ParameterKey));
    end;

    local procedure AddMissing(var Argument: Record "Message Argument ori"; ParameterName: Text)
    begin
        Argument.AddError("Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingParameterErr, ParameterName), ParameterName, '', ParameterName, MissingNextStepTxt);
    end;

    local procedure ReadRequiredCode(var Argument: Record "Message Argument ori"; Token: JsonToken; ParameterName: Text; var Value: Code[20])
    var
        Raw: Text;
    begin
        if not ReadTextToken(Token, Raw) then begin
            Argument.AddError("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(NotACodeErr, ParameterName), ParameterName, '', CodeExpectedTxt, TooLongNextStepTxt);
            exit;
        end;
        if Raw.Trim() = '' then begin
            AddMissing(Argument, ParameterName);
            exit;
        end;
        if StrLen(Raw) > MaxStrLen(Value) then begin
            Argument.AddError("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(TooLongErr, ParameterName, MaxStrLen(Value)), ParameterName, Raw, CodeExpectedTxt, TooLongNextStepTxt);
            exit;
        end;
        Value := CopyStr(Raw, 1, MaxStrLen(Value));
    end;

    local procedure ReadOptionalReinspection(var Argument: Record "Message Argument ori"; Token: JsonToken; var ReinspectionNo: Integer)
    var
        Raw: Text;
    begin
        if not ReadTextToken(Token, Raw) then begin
            Argument.AddError("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(NotAnIntegerErr, 'reinspectionNo'), 'reinspectionNo', '', IntegerExpectedTxt, IntegerNextStepTxt);
            exit;
        end;
        if Raw.Trim() = '' then begin
            Argument.AddError("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(NotAnIntegerErr, 'reinspectionNo'), 'reinspectionNo', Raw, IntegerExpectedTxt, IntegerNextStepTxt);
            exit;
        end;
        if not Evaluate(ReinspectionNo, Raw.Trim(), 9) then begin
            Argument.AddError("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(NotAnIntegerErr, 'reinspectionNo'), 'reinspectionNo', Raw.Trim(), IntegerExpectedTxt, IntegerNextStepTxt);
            exit;
        end;
        if ReinspectionNo < 0 then
            Argument.AddError("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(NotAnIntegerErr, 'reinspectionNo'), 'reinspectionNo', Raw.Trim(), IntegerExpectedTxt, IntegerNextStepTxt);
    end;

    local procedure ReadTextToken(Token: JsonToken; var Raw: Text): Boolean
    begin
        Raw := '';
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        Raw := Token.AsValue().AsText();
        exit(true);
    end;
}
