namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;

/// <summary>Runs Microsoft's test-value validation and inspection-result recalculation atomically.</summary>
codeunit 10035242 "Quality Set Value Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        DescriptionLbl: Label 'Sets a test value on an open quality inspection and recalculates its result.', MaxLength = 250, Comment = 'is-IS=Skráir prófunargildi í opinni gæðaskoðun og endurreiknar niðurstöðu hennar.';
        MissingKeyErr: Label 'The required parameter ''%1'' is missing or invalid.', Comment = '%1 = parameter name|is-IS=Nauðsynlega færibreytu ''%1'' vantar eða hún er ógild.';
        UnknownKeyErr: Label 'Unknown parameter ''%1''.', Comment = '%1 = parameter name|is-IS=Óþekkt færibreyta ''%1''.';
        TooLongErr: Label 'Parameter ''%1'' exceeds %2 characters.', Comment = '%1 = parameter name, %2 = limit|is-IS=Færibreytan ''%1'' er lengri en %2 stafir.';
        PermissionErr: Label 'The BIFROST QM Full ori permission set is required.', Comment = 'is-IS=Heimildasafnið BIFROST QM Full ori er nauðsynlegt.';
        NotFoundErr: Label 'The quality inspection was not found.', Comment = 'is-IS=Gæðaskoðunin fannst ekki.';
        ExpectedIdLbl: Label 'a non-empty SystemId GUID of an existing quality inspection', Comment = 'is-IS=SystemId GUID skoðunar sem er til og er ekki tómt';
        FindInspectionLbl: Label 'Read the inspection SystemId using Data.Records.Get and supply inspectionSystemId.', Comment = 'is-IS=Lestu SystemId skoðunar með Data.Records.Get og sendu inspectionSystemId.';
        InvalidWhenLbl: Label 'inspectionSystemId is not a valid GUID, or testCode or value is not text or is longer than its field allows.', Comment = 'is-IS=inspectionSystemId er ekki gilt GUID, eða testCode eða value er ekki texti eða er lengra en reiturinn leyfir.';
        TextExpectedLbl: Label 'a text value', Comment = 'is-IS=textagildi';
        NonEmptyTextLbl: Label 'a non-empty text value', Comment = 'is-IS=textagildi sem er ekki tómt';
        FixParameterLbl: Label 'Correct the named request parameter and retry.', Comment = 'is-IS=Leiðréttu tilgreinda færibreytu beiðninnar og reyndu aftur.';
        MaximumTextLbl: Label 'text with at most %1 characters', Comment = '%1 = maximum length|is-IS=texti með að hámarki %1 stöfum';
        PermissionNextLbl: Label 'Ask an administrator for BIFROST QM Full ori and the native Quality Management permissions.', Comment = 'is-IS=Biddu stjórnanda um BIFROST QM Full ori og staðlaðar gæðastjórnunarheimildir.';
        StatusErr: Label 'The quality inspection Status must be Open.', Comment = 'is-IS=Staða gæðaskoðunar verður að vera Opin.';
        OpenExpectedLbl: Label 'an open quality inspection', Comment = 'is-IS=opin gæðaskoðun';
        OpenNextLbl: Label 'Select an open inspection before setting a test value; nothing was changed.', Comment = 'is-IS=Veldu opna skoðun áður en prófunargildi er skráð; engu var breytt.';
        NativeRefusalLbl: Label 'Microsoft validation refused the test value, test selection or setup.', Comment = 'is-IS=Staðfesting Microsoft hafnaði prófunargildi, vali á prófun eða uppsetningu.';
        NativeNextLbl: Label 'Correct the inspection test, value or setup and retry.', Comment = 'is-IS=Leiðréttu skoðunarprófun, gildi eða uppsetningu og reyndu aftur.';
        OverviewLbl: Label 'Validates the value of exactly one inspection test through Microsoft SetTestValue, then recalculates and saves the header result through UpdateResultFromLines.', Comment = 'is-IS=Staðfestir gildi nákvæmlega einnar prófunar í skoðun með SetTestValue frá Microsoft og endurreiknar og vistar niðurstöðu hauss með UpdateResultFromLines.';
        NotesLbl: Label 'Identify the exact inspection, including its re-inspection, by inspectionSystemId. testCode is the test code, not its caption. value is text (maximum 250 characters); an empty string clears it if Microsoft permits. Unknown keys, missing keys, non-text values and overlong values are refused. The inspection must be open and have exactly one matching test line. Microsoft validation and result rules apply. The standard path has no explicit Commit; explicit commits from subscribers are prohibited. Normal execution uses a separate transaction, so a business refusal rolls back all writes. With Omit Commit, the caller owns rollback. Repeating the same value is not guaranteed idempotent because Microsoft validation can update related expressions and invoke subscribers. No external provider is called.', Comment = 'is-IS=Auðkenndu tiltekna skoðun, ásamt endurskoðun hennar, með inspectionSystemId. testCode er prófunarkóði, ekki heiti. value er texti (hámark 250 stafir); tómur strengur hreinsar gildið ef Microsoft leyfir. Óþekktum lyklum, lyklum sem vantar, öðrum gildum en texta og of löngum gildum er hafnað. Skoðunin verður að vera opin og hafa nákvæmlega eina samsvarandi prófunarlínu. Staðfestingar og niðurstöðureglur Microsoft gilda. Staðlaða leiðin inniheldur ekkert beint Commit; beinar staðfestingar frá áskrifendum eru bannaðar. Venjuleg keyrsla notar sérstaka færslu svo höfnun bakfærir allar breytingar. Með Omit Commit ber kallandi ábyrgð á bakfærslu. Endurtekning sama gildis tryggir ekki óbreytt ástand því staðfesting Microsoft getur uppfært tengdar segðir og kallað á áskrifendur. Engin ytri þjónusta er kölluð.';

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
        if not Codeunit.Run(Codeunit::"Quality Set Value Impl ori", Argument) then
            Argument.RespondWithLastError();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure PerformWrite(var Argument: Record "Message Argument ori")
    var
        WriteAccess: Record "Quality Write Access ori";
        Inspection: Record "Qlty. Inspection Header";
        InspectionLine: Record "Qlty. Inspection Line";
        Request: JsonObject;
        Response: JsonObject;
        InspectionSystemId: Guid;
        TestCode: Text;
        TestValue: Text;
        ParameterName: Text;
    begin
        if not WriteAccess.WritePermission() then
            Refuse(Argument, "Bifrost Error Code ori"::PermissionDenied, PermissionErr, 'permissionSet', '', 'BIFROST QM Full ori', PermissionNextLbl);
        Request := Argument.GetRequestJson();
        foreach ParameterName in Request.Keys() do
            if not (ParameterName in ['inspectionSystemId', 'testCode', 'value']) then
                Refuse(Argument, "Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, ParameterName), ParameterName, '', 'inspectionSystemId, testCode, value', FixParameterLbl);
        if not Evaluate(InspectionSystemId, ReadText(Request, 'inspectionSystemId', false, Argument)) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'inspectionSystemId'), 'inspectionSystemId', ReadText(Request, 'inspectionSystemId', false, Argument), ExpectedIdLbl, FindInspectionLbl);
        if IsNullGuid(InspectionSystemId) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'inspectionSystemId'), 'inspectionSystemId', ReadText(Request, 'inspectionSystemId', false, Argument), ExpectedIdLbl, FindInspectionLbl);
        TestCode := ReadText(Request, 'testCode', false, Argument);
        TestValue := ReadText(Request, 'value', true, Argument);
        if StrLen(TestCode) > MaxStrLen(InspectionLine."Test Code") then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(TooLongErr, 'testCode', MaxStrLen(InspectionLine."Test Code")), 'testCode', TestCode, StrSubstNo(MaximumTextLbl, MaxStrLen(InspectionLine."Test Code")), FixParameterLbl);
        if StrLen(TestValue) > MaxStrLen(InspectionLine."Test Value") then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(TooLongErr, 'value', MaxStrLen(InspectionLine."Test Value")), 'value', TestValue, StrSubstNo(MaximumTextLbl, MaxStrLen(InspectionLine."Test Value")), FixParameterLbl);
        // Load the complete mutable record: Microsoft validation reads and changes other fields.
        Inspection.ReadIsolation := IsolationLevel::UpdLock;
        if not Inspection.GetBySystemId(InspectionSystemId) then
            Refuse(Argument, "Bifrost Error Code ori"::RecordNotFound, NotFoundErr, 'inspectionSystemId', Format(InspectionSystemId, 0, 4), ExpectedIdLbl, FindInspectionLbl);
        if Inspection.Status <> Inspection.Status::Open then
            Refuse(Argument, "Bifrost Error Code ori"::PreconditionFailed, StatusErr, 'inspectionSystemId', Format(InspectionSystemId, 0, 4), OpenExpectedLbl, OpenNextLbl);
        Inspection.SetTestValue(TestCode, TestValue);
        Inspection.GetBySystemId(InspectionSystemId);
        Inspection.UpdateResultFromLines();
        Inspection.Modify(true);
        Response.Add('status', 'Success');
        Response.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Response.Add('inspectionNo', Inspection."No.");
        Response.Add('reinspectionNo', Inspection."Re-inspection No.");
        Response.Add('testCode', TestCode);
        Response.Add('resultCode', Inspection."Result Code");
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure ReadText(Request: JsonObject; ParameterName: Text; AllowEmpty: Boolean; var Argument: Record "Message Argument ori") Value: Text
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get(ParameterName, Token) then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, ParameterName), ParameterName, '', ExpectedInput(ParameterName, AllowEmpty), RecoveryStep(ParameterName));
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, ParameterName), ParameterName, Serialized, TextExpectedLbl, FixParameterLbl);
        Value := Token.AsValue().AsText();
        if (Value = '') and not AllowEmpty then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, ParameterName), ParameterName, '', ExpectedInput(ParameterName, AllowEmpty), RecoveryStep(ParameterName));
    end;

    local procedure ExpectedInput(ParameterName: Text; AllowEmpty: Boolean): Text
    begin
        if ParameterName = 'inspectionSystemId' then
            exit(ExpectedIdLbl);
        if AllowEmpty then
            exit(TextExpectedLbl);
        exit(NonEmptyTextLbl);
    end;

    local procedure RecoveryStep(ParameterName: Text): Text
    begin
        if ParameterName = 'inspectionSystemId' then
            exit(FindInspectionLbl);
        exit(FixParameterLbl);
    end;

    local procedure Refuse(var Argument: Record "Message Argument ori"; ErrorCode: Enum "Bifrost Error Code ori"; Message: Text; Parameter: Text; Received: Text; Expected: Text; NextStep: Text)
    begin
        // Foundation carries the structured collection across the transaction rollback.
        Argument.AddError(ErrorCode, Message, Parameter, Received, Expected, NextStep);
        Argument.RaiseCollectedErrors(ErrorCode, Message);
    end;

    /// <summary>Provides the IsEnabled discovery or contract chapter.</summary>
    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>Provides the GetFilterTableNo discovery or contract chapter.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Qlty. Inspection Header");
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
        KeywordsLbl: Label 'Quality.Inspection.SetTestValue, quality, inspection, test value, measurement, result', Comment = 'is-IS=Quality.Inspection.SetTestValue, gæði, skoðun, prófunargildi, mæling, niðurstaða';
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
        Target.ReadFrom('[{"source":"data.inspectionSystemId","form":"GUID","description":"SystemId of the exact inspection and re-inspection."}]');
        exit(true);
    end;

    /// <summary>Provides the parameters contract chapter.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Clear(Parameters);
        Parameters.Add(ContractMgt.Parameter('inspectionSystemId', 'string', true, 'SystemId of the exact inspection and re-inspection.'));
        Parameters.Add(ContractMgt.Parameter('testCode', 'string', true, 'Exact test code, maximum 20 characters. Must identify exactly one line.'));
        Parameters.Add(ContractMgt.Parameter('value', 'string', true, 'Test value as text, maximum 250 characters; may be empty.'));
        exit(true);
    end;

    /// <summary>Provides the response contract chapter.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    begin
        Response.ReadFrom('{"contentType":"application/json","fields":[{"name":"status","type":"string","description":"Success."},{"name":"inspectionSystemId","type":"string","description":"Inspection SystemId."},{"name":"inspectionNo","type":"string","description":"Inspection number."},{"name":"reinspectionNo","type":"integer","description":"Re-inspection number."},{"name":"testCode","type":"string","description":"Selected test code."},{"name":"resultCode","type":"string","description":"Recalculated overall result code."}]}');
        exit(true);
    end;

    /// <summary>Provides the errors contract chapter.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Clear(Errors);
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, 'inspectionSystemId / testCode / value'), FixParameterLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, InvalidWhenLbl, FixParameterLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, 'data'), FixParameterLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, PermissionErr, PermissionNextLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, NotFoundErr, FindInspectionLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, StatusErr, OpenNextLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, NativeRefusalLbl, NativeNextLbl));
        exit(true);
    end;

    /// <summary>Provides the effect contract chapter.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        Effect.ReadFrom('{"effect":"write","changes":"Validates the selected inspection line test value, recalculates related expressions and header result; Microsoft triggers and subscribers run. No explicit Commit on the standard path; subscriber commits are prohibited.","idempotent":false,"permissionSet":"BIFROST QM Full ori","preconditions":["Open inspection with exactly one matching test line.","Microsoft Quality Management setup and read/write permissions."]}');
        exit(true);
    end;

    /// <summary>Provides the examples contract chapter.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        Examples.ReadFrom('[{"title":"Set a measurement","request":{"type":"Quality.Inspection.SetTestValue","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001","testCode":"TEMP","value":"20"}},"response":{"status":"Success","inspectionSystemId":"00000000-0000-0000-0000-000000000001","inspectionNo":"QI00001","reinspectionNo":0,"testCode":"TEMP","resultCode":"PASS"}}]');
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
