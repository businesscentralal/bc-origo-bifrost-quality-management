namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;

/// <summary>Reads matching inspections through the public Microsoft source-matching method.</summary>
codeunit 10035291 "Quality Find Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        DescriptionLbl: Label 'Finds quality inspections for one source record using Microsoft matching rules.', MaxLength = 250, Comment = 'is-IS=Finnur gæðaskoðanir fyrir eina upprunafærslu með samsvörunarreglum Microsoft.';
        OverviewLbl: Label 'Returns up to 100 matching inspections, newest first by creation time, then inspection number and re-inspection number descending. No inspection is created or changed.', Comment = 'is-IS=Skilar allt að 100 samsvarandi skoðunum, nýjustu fyrst eftir stofnunartíma, síðan skoðunarnúmeri og endurskoðunarnúmeri í lækkandi röð. Engin skoðun er stofnuð eða henni breytt.';
        NotesLbl: Label 'tableId and systemId identify a visible source record. matchOn selects item, tracking and/or document matching using Microsoft source configuration. latestOnly defaults to true and selects the most recent re-inspection of each inspection. result is the native result code; status is the English enum name in both languages. truncated is true when more than 100 visible rows match. Missing source mappings or unavailable selected source values are InvalidParameter on matchOn. Native read permissions remain required.', Comment = 'is-IS=tableId og systemId auðkenna sýnilega upprunafærslu. matchOn velur samsvörun eftir vöru, rakningu og/eða skjali með upprunauppsetningu Microsoft. latestOnly er sjálfgefið true og velur nýjustu endurskoðun hverrar skoðunar. result er staðlaður niðurstöðukóði; status er enskt heiti talningargildis á báðum tungumálum. truncated er true þegar fleiri en 100 sýnilegar línur passa. Ef upprunavörpun eða valin upprunagildi vantar er skilað InvalidParameter fyrir matchOn. Staðlaðar lesheimildir eru nauðsynlegar.';
        MissingKeyErr: Label 'The required parameter ''%1'' is missing or invalid.', Comment = '%1 = parameter name|is-IS=Nauðsynlega færibreytu ''%1'' vantar eða hún er ógild.';
        UnknownKeyErr: Label 'Unknown parameter ''%1''.', Comment = '%1 = parameter name|is-IS=Óþekkt færibreyta ''%1''.';
        PermissionErr: Label 'Read permission on the source record and quality inspection header is required.', Comment = 'is-IS=Lesheimild á upprunafærslu og gæðaskoðunarhaus er nauðsynleg.';
        NotFoundErr: Label 'The source record was not found.', Comment = 'is-IS=Upprunafærslan fannst ekki.';
        SourceTableLbl: Label 'Numeric table ID of the source record in the current company.', Comment = 'is-IS=Tölulegt töfluauðkenni upprunafærslunnar í núverandi fyrirtæki.';
        TargetLbl: Label 'SystemId in the table identified by tableId.', Comment = 'is-IS=SystemId í töflunni sem tableId auðkennir.';
        SourceIdLbl: Label 'SystemId of the source record as a non-empty GUID string.', Comment = 'is-IS=SystemId upprunafærslunnar sem ótómur GUID-strengur.';
        ExpectedTableLbl: Label 'a positive integer ID of an existing readable table', Comment = 'is-IS=jákvætt heiltöluauðkenni töflu sem er til og má lesa';
        ExpectedGuidLbl: Label 'a non-empty SystemId GUID of an existing source record', Comment = 'is-IS=SystemId GUID upprunafærslu sem er til og er ekki tómt';
        ExpectedTextLbl: Label 'a text value', Comment = 'is-IS=textagildi';
        ExpectedMatchLbl: Label 'a non-empty array of item, tracking and/or document with configured source values', Comment = 'is-IS=ótómt fylki með item, tracking og/eða document og uppsettum upprunagildum';
        ExpectedBoolLbl: Label 'a JSON boolean: true or false', Comment = 'is-IS=JSON-rökgildi: true eða false';
        FixParameterLbl: Label 'Correct the named request parameter and retry.', Comment = 'is-IS=Leiðréttu tilgreinda færibreytu beiðninnar og reyndu aftur.';
        FindSourceLbl: Label 'Read the source SystemId with Data.Records.Get and supply tableId and systemId.', Comment = 'is-IS=Lestu SystemId upprunafærslunnar með Data.Records.Get og sendu tableId og systemId.';
        PermissionNextLbl: Label 'Ask an administrator for native read permissions and BIFROST QM Read ori.', Comment = 'is-IS=Biddu stjórnanda um staðlaðar lesheimildir og BIFROST QM Read ori.';
        MatchLbl: Label 'Required non-empty array: item, tracking and/or document. The selected Microsoft filters are combined.', Comment = 'is-IS=Nauðsynlegt ótómt fylki: item, tracking og/eða document. Valdar síur Microsoft eru sameinaðar.';
        LatestLbl: Label 'Defaults to true: only the most recent re-inspection of each inspection. false also returns superseded revisions.', Comment = 'is-IS=Sjálfgefið true: aðeins nýjasta endurskoðun hverrar skoðunar. false skilar einnig eldri útgáfum.';

    /// <summary>Validates and reads without starting a write transaction or committing.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if not ReadInspections(Argument) then
            Argument.RespondWithLastError();
    end;

    [TryFunction]
    [CommitBehavior(CommitBehavior::Error)]
    local procedure ReadInspections(var Argument: Record "Message Argument ori")
    var
        Inspection: Record "Qlty. Inspection Header";
        SourceRecord: RecordRef;
        Request: JsonObject;
        Response: JsonObject;
        Rows: JsonArray;
        Dates: List of [DateTime];
        Numbers: List of [Text];
        Revisions: List of [Integer];
        SourceId: Guid;
        TableId: Integer;
        MatchCount: Integer;
        KeyName: Text;
        LatestOnly: Boolean;
        UseItem: Boolean;
        UseTracking: Boolean;
        UseDocument: Boolean;
    begin
        Request := Argument.GetRequestJson();
        foreach KeyName in Request.Keys() do
            if not (KeyName in ['tableId', 'systemId', 'matchOn', 'latestOnly']) then
                Refuse(Argument, "Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, KeyName), KeyName, '', 'tableId, systemId, matchOn, latestOnly', FixParameterLbl);
        TableId := ReadTableId(Request, Argument);
        KeyName := ReadText(Request, 'systemId', Argument);
        if not Evaluate(SourceId, KeyName) or IsNullGuid(SourceId) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'systemId'), 'systemId', KeyName, ExpectedGuidLbl, FixParameterLbl);
        ReadMatchOn(Request, Argument, UseItem, UseTracking, UseDocument);
        LatestOnly := ReadLatestOnly(Request, Argument);
        if not TryOpenSource(SourceRecord, TableId) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'tableId'), 'tableId', Format(TableId, 0, 9), ExpectedTableLbl, FixParameterLbl);
        if not SourceRecord.ReadPermission() then
            Refuse(Argument, "Bifrost Error Code ori"::PermissionDenied, PermissionErr, 'tableId', Format(TableId, 0, 9), ExpectedTableLbl, PermissionNextLbl);
        SourceRecord.ReadIsolation := IsolationLevel::ReadCommitted;
        if not SourceRecord.GetBySystemId(SourceId) then
            Refuse(Argument, "Bifrost Error Code ori"::RecordNotFound, NotFoundErr, 'systemId', Format(SourceId, 0, 4), ExpectedGuidLbl, FindSourceLbl);
        if not Inspection.ReadPermission() then
            Refuse(Argument, "Bifrost Error Code ori"::PermissionDenied, PermissionErr, 'permissionSet', '', 'BIFROST QM Read ori + native read', PermissionNextLbl);
        if not TrySetNativeFilters(Inspection, SourceRecord, UseItem, UseTracking, UseDocument) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'matchOn'), 'matchOn', '', ExpectedMatchLbl, FixParameterLbl);
        SourceRecord.Close();
        if LatestOnly then
            Inspection.SetRange("Most Recent Re-inspection", true);
        Inspection.ReadIsolation := IsolationLevel::ReadCommitted;
        Inspection.SetLoadFields(SystemId, SystemCreatedAt, "No.", "Re-inspection No.", Status, "Result Code");
        if Inspection.FindSet() then
            repeat
                MatchCount += 1;
                AddNewest(Inspection, Rows, Dates, Numbers, Revisions);
            until Inspection.Next() = 0;
        Response.Add('status', 'Success');
        Response.Add('inspections', Rows);
        Response.Add('truncated', MatchCount > 100);
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure AddNewest(Inspection: Record "Qlty. Inspection Header"; var Rows: JsonArray; var Dates: List of [DateTime]; var Numbers: List of [Text]; var Revisions: List of [Integer])
    var
        Row: JsonObject;
        Position: Integer;
    begin
        // Keep only the newest 100 in memory, independent of document numbering or SQL key order.
        Position := 1;
        while Position <= Dates.Count() do begin
            if (Inspection.SystemCreatedAt > Dates.Get(Position)) or
               ((Inspection.SystemCreatedAt = Dates.Get(Position)) and (Inspection."No." > Numbers.Get(Position))) or
               ((Inspection.SystemCreatedAt = Dates.Get(Position)) and (Inspection."No." = Numbers.Get(Position)) and (Inspection."Re-inspection No." > Revisions.Get(Position))) then
                break;
            Position += 1;
        end;
        if Position > 100 then
            exit;
        Row.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Row.Add('no', Inspection."No.");
        Row.Add('reinspectionNo', Inspection."Re-inspection No.");
        Row.Add('status', Inspection.Status.Names().Get(Inspection.Status.Ordinals().IndexOf(Inspection.Status.AsInteger())));
        Row.Add('result', Inspection."Result Code");
        Rows.Insert(Position - 1, Row);
        Dates.Insert(Position, Inspection.SystemCreatedAt);
        Numbers.Insert(Position, Inspection."No.");
        Revisions.Insert(Position, Inspection."Re-inspection No.");
        if Rows.Count() > 100 then begin
            Rows.RemoveAt(100);
            Dates.RemoveAt(101);
            Numbers.RemoveAt(101);
            Revisions.RemoveAt(101);
        end;
    end;

    [TryFunction]
    local procedure TryOpenSource(var SourceRecord: RecordRef; TableId: Integer)
    begin
        SourceRecord.Open(TableId);
    end;

    [TryFunction]
    local procedure TrySetNativeFilters(var Inspection: Record "Qlty. Inspection Header"; SourceRecord: RecordRef; UseItem: Boolean; UseTracking: Boolean; UseDocument: Boolean)
    begin
        Inspection.SetRecordFiltersToFindInspectionFor(true, SourceRecord, UseItem, UseTracking, UseDocument);
    end;

    local procedure ReadTableId(Request: JsonObject; var Argument: Record "Message Argument ori"): Integer
    var
        Token: JsonToken;
        Serialized: Text;
        TableId: Integer;
    begin
        if not Request.Get('tableId', Token) then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, 'tableId'), 'tableId', '', ExpectedTableLbl, FixParameterLbl);
        Token.WriteTo(Serialized);
        if not Evaluate(TableId, Serialized, 9) or (TableId <= 0) or (StrPos(Serialized, '.') > 0) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'tableId'), 'tableId', Serialized, ExpectedTableLbl, FixParameterLbl);
        exit(TableId);
    end;

    local procedure ReadText(Request: JsonObject; ParameterName: Text; var Argument: Record "Message Argument ori"): Text
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get(ParameterName, Token) then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, ParameterName), ParameterName, '', ExpectedTextLbl, FixParameterLbl);
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, ParameterName), ParameterName, Serialized, ExpectedTextLbl, FixParameterLbl);
        exit(Token.AsValue().AsText());
    end;

    local procedure ReadMatchOn(Request: JsonObject; var Argument: Record "Message Argument ori"; var UseItem: Boolean; var UseTracking: Boolean; var UseDocument: Boolean)
    var
        Token: JsonToken;
        Member: JsonToken;
        Name: Text;
        Values: JsonArray;
        Serialized: Text;
    begin
        if not Request.Get('matchOn', Token) then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, 'matchOn'), 'matchOn', '', ExpectedMatchLbl, FixParameterLbl);
        if not Token.IsArray() then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'matchOn'), 'matchOn', '', ExpectedMatchLbl, FixParameterLbl);
        Values := Token.AsArray();
        if Values.Count() = 0 then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'matchOn'), 'matchOn', '[]', ExpectedMatchLbl, FixParameterLbl);
        foreach Member in Values do begin
            Member.WriteTo(Serialized);
            if CopyStr(Serialized, 1, 1) <> '"' then
                Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'matchOn'), 'matchOn', Serialized, ExpectedMatchLbl, FixParameterLbl);
            Name := Member.AsValue().AsText();
            case Name of
                'item': UseItem := true;
                'tracking': UseTracking := true;
                'document': UseDocument := true;
                else
                    Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'matchOn'), 'matchOn', Name, ExpectedMatchLbl, FixParameterLbl);
            end;
        end;
    end;

    local procedure ReadLatestOnly(Request: JsonObject; var Argument: Record "Message Argument ori"): Boolean
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get('latestOnly', Token) then
            exit(true);
        Token.WriteTo(Serialized);
        if not (Serialized in ['true', 'false']) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'latestOnly'), 'latestOnly', Serialized, ExpectedBoolLbl, FixParameterLbl);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure Refuse(var Argument: Record "Message Argument ori"; ErrorCode: Enum "Bifrost Error Code ori"; Message: Text; Parameter: Text; Received: Text; Expected: Text; NextStep: Text)
    begin
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
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    /// <summary>Provides the GetKeywords discovery or contract chapter.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'Quality.Inspection.FindForRecord, quality, inspection, find, item, tracking, document', Comment = 'is-IS=Quality.Inspection.FindForRecord, gæði, skoðun, finna, vara, rakning, skjal';
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
    var
        Entry: JsonObject;
    begin
        Clear(Target);
        Entry.Add('source', 'data.systemId');
        Entry.Add('form', 'GUID');
        Entry.Add('description', TargetLbl);
        Target.Add(Entry);
        exit(true);
    end;

    /// <summary>Provides the parameters contract chapter.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Clear(Parameters);
        Parameters.Add(ContractMgt.Parameter('tableId', 'integer', true, SourceTableLbl));
        Parameters.Add(ContractMgt.Parameter('systemId', 'string', true, SourceIdLbl));
        Parameters.Add(ContractMgt.Parameter('matchOn', 'array', true, MatchLbl));
        Parameters.Add(ContractMgt.Parameter('latestOnly', 'boolean', false, LatestLbl));
        exit(true);
    end;

    /// <summary>Provides the response contract chapter.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    begin
        Response.ReadFrom('{"contentType":"application/json","fields":[{"name":"status","type":"string"},{"name":"inspections","type":"array","fields":[{"name":"inspectionSystemId","type":"string"},{"name":"no","type":"string"},{"name":"reinspectionNo","type":"integer"},{"name":"status","type":"string"},{"name":"result","type":"string"}]},{"name":"truncated","type":"boolean"}]}');
        exit(true);
    end;

    /// <summary>Provides the errors contract chapter.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Clear(Errors);
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, 'tableId'), FixParameterLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'matchOn'), FixParameterLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, '<parameter>'), FixParameterLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, NotFoundErr, FindSourceLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, PermissionErr, PermissionNextLbl));
        exit(true);
    end;

    /// <summary>Provides the effect contract chapter.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        Effect.ReadFrom('{"effect":"read","idempotent":true,"permissionSet":"BIFROST QM Read ori"}');
        exit(true);
    end;

    /// <summary>Provides the examples contract chapter.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        Examples.ReadFrom('[{"request":{"type":"Quality.Inspection.FindForRecord","data":{"tableId":39,"systemId":"00000000-0000-0000-0000-000000000001","matchOn":["document"],"latestOnly":true}}}]');
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
