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
            Error(ErrorInfo.Create(PermissionErr));
        Request := Argument.GetRequestJson();
        foreach ParameterName in Request.Keys() do
            if not (ParameterName in ['inspectionSystemId', 'testCode', 'value']) then
                Error(ErrorInfo.Create(StrSubstNo(UnknownKeyErr, ParameterName)));
        if not Evaluate(InspectionSystemId, ReadText(Request, 'inspectionSystemId', false)) then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, 'inspectionSystemId')));
        if IsNullGuid(InspectionSystemId) then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, 'inspectionSystemId')));
        TestCode := ReadText(Request, 'testCode', false);
        TestValue := ReadText(Request, 'value', true);
        if StrLen(TestCode) > MaxStrLen(InspectionLine."Test Code") then
            Error(ErrorInfo.Create(StrSubstNo(TooLongErr, 'testCode', MaxStrLen(InspectionLine."Test Code"))));
        if StrLen(TestValue) > MaxStrLen(InspectionLine."Test Value") then
            Error(ErrorInfo.Create(StrSubstNo(TooLongErr, 'value', MaxStrLen(InspectionLine."Test Value"))));
        // Load the complete mutable record: Microsoft validation reads and changes other fields.
        Inspection.ReadIsolation := IsolationLevel::UpdLock;
        if not Inspection.GetBySystemId(InspectionSystemId) then
            Error(ErrorInfo.Create(NotFoundErr));
        Inspection.TestField(Status, Inspection.Status::Open);
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
    begin
        Errors.ReadFrom('[{"error":"Business Central refusal","when":"Missing, malformed or unknown input; missing or finished inspection; missing or ambiguous test line; invalid test value or insufficient permissions.","fix":"Correct the request, inspection setup, status or permissions and retry."}]');
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
