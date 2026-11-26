namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Origo.Bifrost;

/// <summary>Creates transfer orders for one inspection's stock through Microsoft's disposition interface in one rollback transaction.</summary>
codeunit 10035299 "Quality Transfer Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        DescriptionLbl: Label 'Creates transfer orders for the failed or passed stock of one quality inspection, for example to send it to quarantine. Nothing is shipped or posted.', MaxLength = 250, Comment = 'is-IS=Stofnar millilagerfærslur fyrir birgðir sem féllu eða stóðust eina gæðaskoðun, til dæmis til að senda þær í sóttkví. Ekkert er sent eða bókað.';
        MissingKeyErr: Label 'The required parameter %1 is missing or invalid.', Comment = '%1 = parameter name|is-IS=Nauðsynlega færibreytu %1 vantar eða hún er ógild.';
        UnknownKeyErr: Label 'Unknown parameter %1.', Comment = '%1 = parameter name|is-IS=Óþekkt færibreyta %1.';
        TooLongErr: Label 'Parameter %1 exceeds %2 characters.', Comment = '%1 = parameter name, %2 = limit|is-IS=Færibreytan %1 er lengri en %2 stafir.';
        FilterSyntaxErr: Label 'Parameter %1 must be one exact code; filter syntax is not accepted.', Comment = '%1 = parameter name|is-IS=Færibreytan %1 verður að vera einn nákvæmur kóði; síusetningafræði er ekki leyfð.';
        PermissionErr: Label 'The BIFROST QM Full ori permission set is required.', Comment = 'is-IS=Heimildasafnið BIFROST QM Full ori er nauðsynlegt.';
        NotFoundErr: Label 'The quality inspection was not found.', Comment = 'is-IS=Gæðaskoðunin fannst ekki.';
        ConfirmErr: Label 'Set confirm to true to authorize creating transfer orders.', Comment = 'is-IS=Stilltu confirm á true til að heimila stofnun millilagerfærslna.';
        QuantityErr: Label 'The quantity to transfer must be greater than zero.', Comment = 'is-IS=Magnið sem á að flytja verður að vera stærra en núll.';
        NothingCreatedErr: Label 'Business Central did not create a transfer order. Check the inspection quantity, the stock at the source and the locations.', Comment = 'is-IS=Business Central stofnaði ekki millilagerfærslu. Athugaðu magn skoðunar, birgðir á uppruna og staðsetningar.';
        ExpectedIdLbl: Label 'a non-empty SystemId GUID of an existing quality inspection', Comment = 'is-IS=SystemId GUID gæðaskoðunar sem er til og er ekki tómt';
        FindInspectionLbl: Label 'Read the inspection SystemId using Data.Records.Get and supply inspectionSystemId.', Comment = 'is-IS=Lestu SystemId skoðunar með Data.Records.Get og sendu inspectionSystemId.';
        TextExpectedLbl: Label 'a text value', Comment = 'is-IS=textagildi';
        MaximumTextLbl: Label 'a location or bin code with at most %1 characters', Comment = '%1 = maximum length|is-IS=staðsetningar- eða hólfskóði með að hámarki %1 stöfum';
        ExactCodeLbl: Label 'one exact code without filter operators', Comment = 'is-IS=einn nákvæmur kóði án síutákna';
        FixParameterLbl: Label 'Correct the named request parameter and retry.', Comment = 'is-IS=Leiðréttu tilgreinda færibreytu beiðninnar og reyndu aftur.';
        DestinationExpectedLbl: Label 'the code of an existing destination location', Comment = 'is-IS=kóði núverandi áfangastaðar';
        DestinationNextLbl: Label 'Supply destinationLocationCode, for example the quarantine location, and retry.', Comment = 'is-IS=Sendu destinationLocationCode, til dæmis sóttkvíarstaðsetningu, og reyndu aftur.';
        BasisExpectedLbl: Label 'failed or passed', Comment = 'is-IS=failed eða passed';
        QuantityExpectedLbl: Label 'a number greater than zero', Comment = 'is-IS=tala stærri en núll';
        QuantityNextLbl: Label 'Send a positive quantity in the base unit of measure, or omit quantity to use the inspection quantity.', Comment = 'is-IS=Sendu jákvætt magn í grunnmælieiningu eða slepptu quantity til að nota magn skoðunar.';
        InspectionQuantityNextLbl: Label 'Record a Fail or Pass Quantity on the inspection, or send an explicit quantity, and retry; nothing was changed.', Comment = 'is-IS=Skráðu fallið eða staðist magn á skoðunina, eða sendu quantity, og reyndu aftur; engu var breytt.';
        ConfirmExpectedLbl: Label 'true', Comment = 'is-IS=true';
        ConfirmNextLbl: Label 'Set confirm to true after reviewing the transfer, and retry.', Comment = 'is-IS=Stilltu confirm á true eftir að hafa farið yfir millilagerfærsluna og reyndu aftur.';
        PermissionNextLbl: Label 'Ask an administrator for BIFROST QM Full ori and the native transfer order permissions.', Comment = 'is-IS=Biddu stjórnanda um BIFROST QM Full ori og staðlaðar heimildir fyrir millilagerfærslur.';
        NothingCreatedExpectedLbl: Label 'a created transfer order for this inspection', Comment = 'is-IS=stofnuð millilagerfærsla fyrir þessa skoðun';
        NothingCreatedNextLbl: Label 'Check the inspection, the stock at the source location and the transfer setup before retrying; nothing was changed.', Comment = 'is-IS=Athugaðu skoðunina, birgðir á uppruna og uppsetningu millilagerfærslu áður en þú reynir aftur; engu var breytt.';

    trigger OnRun()
    begin
        PerformTransfer(Rec);
    end;

    /// <summary>Runs the disposition in an isolated transaction; standard business errors become refusals.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if Argument."Omit Commit" then begin
            PerformTransfer(Argument);
            exit;
        end;
        if not Codeunit.Run(Codeunit::"Quality Transfer Impl ori", Argument) then
            Argument.RespondWithLastError();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure PerformTransfer(var Argument: Record "Message Argument ori")
    var
        AccessCapability: Record "Quality Transfer Access ori";
        Inspection: Record "Qlty. Inspection Header";
        TempInstruction: Record "Qlty. Disposition Buffer" temporary;
        Capture: Codeunit "Quality Transfer Capture ori";
        Disposition: Interface "Qlty. Disposition";
        Request: JsonObject;
        Response: JsonObject;
        TransferOrderNos: JsonArray;
        OrderNo: Code[20];
        InspectionId: Guid;
        ParameterName: Text;
        Basis: Text;
        Quantity: Decimal;
        HasQuantity: Boolean;
    begin
        if not AccessCapability.WritePermission() then
            Refuse(Argument, "Bifrost Error Code ori"::PermissionDenied, PermissionErr, 'permissionSet', '', 'BIFROST QM Full ori', PermissionNextLbl);
        Request := Argument.GetRequestJson();
        foreach ParameterName in Request.Keys() do
            if not (ParameterName in ['inspectionSystemId', 'quantityBasis', 'quantity', 'sourceLocationCode', 'sourceBinCode', 'destinationLocationCode', 'destinationBinCode', 'inTransitLocationCode', 'confirm', 'expectedCount']) then
                Refuse(Argument, "Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, ParameterName), ParameterName, '', 'inspectionSystemId, quantityBasis, quantity, sourceLocationCode, sourceBinCode, destinationLocationCode, destinationBinCode, inTransitLocationCode, confirm, expectedCount', FixParameterLbl);
        InspectionId := ReadInspectionId(Request, Argument);
        if not IsConfirmed(Request, Argument) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, ConfirmErr, 'confirm', '', ConfirmExpectedLbl, ConfirmNextLbl);
        Basis := ReadCode(Request, 'quantityBasis', true, 10, false, Argument);
        case Basis of
            'failed':
                TempInstruction."Quantity Behavior" := TempInstruction."Quantity Behavior"::"Failed Quantity";
            'passed':
                TempInstruction."Quantity Behavior" := TempInstruction."Quantity Behavior"::"Passed Quantity";
            else
                Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'quantityBasis'), 'quantityBasis', Basis, BasisExpectedLbl, FixParameterLbl);
        end;
        HasQuantity := ReadQuantity(Request, Quantity, Argument);
        if HasQuantity then begin
            TempInstruction."Quantity Behavior" := TempInstruction."Quantity Behavior"::"Specific Quantity";
            TempInstruction."Qty. To Handle (Base)" := Quantity;
        end;
        TempInstruction."Location Filter" := CopyStr(ReadCode(Request, 'sourceLocationCode', false, 10, true, Argument), 1, MaxStrLen(TempInstruction."Location Filter"));
        TempInstruction."Bin Filter" := CopyStr(ReadCode(Request, 'sourceBinCode', false, 20, true, Argument), 1, MaxStrLen(TempInstruction."Bin Filter"));
        TempInstruction."New Location Code" := CopyStr(ReadCode(Request, 'destinationLocationCode', true, 10, true, Argument), 1, MaxStrLen(TempInstruction."New Location Code"));
        TempInstruction."New Bin Code" := CopyStr(ReadCode(Request, 'destinationBinCode', false, 20, true, Argument), 1, MaxStrLen(TempInstruction."New Bin Code"));
        TempInstruction."In-Transit Location Code" := CopyStr(ReadCode(Request, 'inTransitLocationCode', false, 10, true, Argument), 1, MaxStrLen(TempInstruction."In-Transit Location Code"));
        TempInstruction."Disposition Action" := TempInstruction."Disposition Action"::"Create Transfer Order";
        Inspection.ReadIsolation := IsolationLevel::UpdLock;
        if not Inspection.GetBySystemId(InspectionId) then
            Refuse(Argument, "Bifrost Error Code ori"::RecordNotFound, NotFoundErr, 'inspectionSystemId', Format(InspectionId, 0, 4), ExpectedIdLbl, FindInspectionLbl);
        if not HasQuantity then
            if ((Basis = 'failed') and (Inspection."Fail Quantity" <= 0)) or ((Basis = 'passed') and (Inspection."Pass Quantity" <= 0)) then
                Refuse(Argument, "Bifrost Error Code ori"::PreconditionFailed, QuantityErr, 'quantityBasis', Basis, QuantityExpectedLbl, InspectionQuantityNextLbl);
        Capture.Initialize(Inspection.SystemId);
        BindSubscription(Capture);
        Disposition := TempInstruction."Disposition Action";
        if not Disposition.PerformDisposition(Inspection, TempInstruction) then
            Refuse(Argument, "Bifrost Error Code ori"::PreconditionFailed, NothingCreatedErr, 'inspectionSystemId', Format(InspectionId, 0, 4), NothingCreatedExpectedLbl, NothingCreatedNextLbl);
        UnbindSubscription(Capture);
        foreach OrderNo in Capture.GetTransferOrderNos() do
            TransferOrderNos.Add(OrderNo);
        if TransferOrderNos.Count() = 0 then
            Refuse(Argument, "Bifrost Error Code ori"::PreconditionFailed, NothingCreatedErr, 'inspectionSystemId', Format(InspectionId, 0, 4), NothingCreatedExpectedLbl, NothingCreatedNextLbl);
        Response.Add('status', 'Success');
        Response.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Response.Add('inspectionNo', Inspection."No.");
        Response.Add('reinspectionNo', Inspection."Re-inspection No.");
        Response.Add('quantityBasis', Basis);
        Response.Add('transferOrderNos', TransferOrderNos);
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure ReadInspectionId(Request: JsonObject; var Argument: Record "Message Argument ori") InspectionId: Guid
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get('inspectionSystemId', Token) then
            RefuseInspectionId(Argument, '');
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            RefuseInspectionId(Argument, Serialized);
        if not Evaluate(InspectionId, Token.AsValue().AsText()) then
            RefuseInspectionId(Argument, Token.AsValue().AsText());
        if IsNullGuid(InspectionId) then
            RefuseInspectionId(Argument, Token.AsValue().AsText());
    end;

    local procedure RefuseInspectionId(var Argument: Record "Message Argument ori"; Received: Text)
    begin
        Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, 'inspectionSystemId'), 'inspectionSystemId', Received, ExpectedIdLbl, FindInspectionLbl);
    end;

    local procedure IsConfirmed(Request: JsonObject; var Argument: Record "Message Argument ori"): Boolean
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get('confirm', Token) then
            exit(false);
        Token.WriteTo(Serialized);
        if not (Serialized in ['true', 'false']) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'confirm'), 'confirm', Serialized, ConfirmExpectedLbl, ConfirmNextLbl);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure ReadQuantity(Request: JsonObject; var Quantity: Decimal; var Argument: Record "Message Argument ori"): Boolean
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get('quantity', Token) then
            exit(false);
        Token.WriteTo(Serialized);
        if not (CopyStr(Serialized, 1, 1) in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-']) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'quantity'), 'quantity', Serialized, QuantityExpectedLbl, QuantityNextLbl);
        if not Evaluate(Quantity, Serialized, 9) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'quantity'), 'quantity', Serialized, QuantityExpectedLbl, QuantityNextLbl);
        if Quantity <= 0 then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, QuantityErr, 'quantity', Serialized, QuantityExpectedLbl, QuantityNextLbl);
        exit(true);
    end;

    local procedure ReadCode(Request: JsonObject; ParameterName: Text; Required: Boolean; MaximumLength: Integer; ExactCode: Boolean; var Argument: Record "Message Argument ori") Value: Text
    var
        Token: JsonToken;
        Serialized: Text;
        Position: Integer;
    begin
        if not Request.Get(ParameterName, Token) then begin
            if Required then
                Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, ParameterName), ParameterName, '', ExpectedFor(ParameterName), NextStepFor(ParameterName));
            exit('');
        end;
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, ParameterName), ParameterName, Serialized, TextExpectedLbl, FixParameterLbl);
        Value := Token.AsValue().AsText();
        if Required and (Value = '') then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, ParameterName), ParameterName, '', ExpectedFor(ParameterName), NextStepFor(ParameterName));
        if StrLen(Value) > MaximumLength then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(TooLongErr, ParameterName, MaximumLength), ParameterName, Value, StrSubstNo(MaximumTextLbl, MaximumLength), FixParameterLbl);
        if ExactCode then begin
            // The standard buffer stores filters, but this API promises literal codes.
            for Position := 1 to StrLen(Value) do
                if StrPos('|&*?@<>=()''', CopyStr(Value, Position, 1)) > 0 then
                    Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(FilterSyntaxErr, ParameterName), ParameterName, Value, ExactCodeLbl, FixParameterLbl);
            if StrPos(Value, '..') > 0 then
                Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(FilterSyntaxErr, ParameterName), ParameterName, Value, ExactCodeLbl, FixParameterLbl);
        end;
    end;

    local procedure ExpectedFor(ParameterName: Text): Text
    begin
        case ParameterName of
            'destinationLocationCode':
                exit(DestinationExpectedLbl);
            'quantityBasis':
                exit(BasisExpectedLbl);
        end;
        exit(TextExpectedLbl);
    end;

    local procedure NextStepFor(ParameterName: Text): Text
    begin
        if ParameterName = 'destinationLocationCode' then
            exit(DestinationNextLbl);
        exit(FixParameterLbl);
    end;

    local procedure Refuse(var Argument: Record "Message Argument ori"; ErrorCode: Enum "Bifrost Error Code ori"; Message: Text; Parameter: Text; Received: Text; Expected: Text; NextStep: Text)
    begin
        // Foundation preserves this collection across Codeunit.Run rollback, including post-write refusals.
        Argument.AddError(ErrorCode, Message, Parameter, Received, Expected, NextStep);
        Argument.RaiseCollectedErrors(ErrorCode, Message);
    end;

    /// <summary>Returns whether the caller has the transfer order capability.</summary>
    procedure IsEnabled(): Boolean
    var
        AccessCapability: Record "Quality Transfer Access ori";
    begin
        exit(AccessCapability.WritePermission());
    end;

    /// <summary>Returns the standard inspection table.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Qlty. Inspection Header");
    end;

    /// <summary>Describes the transfer.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>The operation accepts inbound messages.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Returns translated search terms.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'quality, disposition, transfer order, quarantine, failed quantity, passed quantity, in-transit', Comment = 'is-IS=gæði, ráðstöfun, millilagerfærsla, sóttkví, fallið magn, staðist magn, á leiðinni';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Distinguishes this operation in discovery.</summary>
    procedure GetSelectionDescription(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Returns the envelope contract chapter.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    begin
        Envelope.ReadFrom('{"subject":{"use":"notUsed"},"dataRequired":true,"version":"1.0","contentType":"application/json"}');
        exit(true);
    end;

    /// <summary>Returns the target contract chapter.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        Target.ReadFrom('[{"source":"data.inspectionSystemId","form":"GUID","description":"SystemId of exactly one inspection, including its re-inspection."}]');
        exit(true);
    end;

    /// <summary>Returns the parameters contract chapter.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Parameter: JsonObject;
        AllowedValues: JsonArray;
    begin
        Clear(Parameters);
        Parameter := ContractMgt.Parameter('inspectionSystemId', 'string', true, 'SystemId of the exact inspection.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('quantityBasis', 'string', true, 'Use Microsoft inspection Fail Quantity or Pass Quantity; must be positive unless quantity is sent.');
        AllowedValues.ReadFrom('["failed","passed"]');
        Parameter.Add('allowed', AllowedValues);
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('quantity', 'number', false, 'Specific quantity in the base unit of measure; must be greater than zero. Omitted: the failed or passed quantity of the inspection.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('sourceLocationCode', 'string', false, 'Exact source location, up to 10 characters. No filter syntax. Omitted: Microsoft selects the stock of the inspection.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('sourceBinCode', 'string', false, 'Exact source bin, up to 20 characters. No filter syntax. Omitted: Microsoft selects available bins.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('destinationLocationCode', 'string', true, 'Transfer-to location, up to 10 characters, for example a quarantine location.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('destinationBinCode', 'string', false, 'Target bin, up to 20 characters. Passed to the standard instruction; Microsoft transfer orders carry no destination bin, so the bin is assigned when the transfer is received.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('inTransitLocationCode', 'string', false, 'In-transit location, up to 10 characters. Omitted: the transfer route in-transit location is used, otherwise the transfer is direct.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('confirm', 'boolean', true, 'Must be true to authorize creation of transfer orders.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('expectedCount', 'integer', false, 'expectedCount counts the one quality inspection named by inspectionSystemId (1 per call), not the transfer orders or lines the call creates. Omitting expectedCount reads that count and changes nothing only when Require Confirmation for Irreversible Messages is enabled in Bifrost Setup (on by default). When that setup is disabled, omitting expectedCount can create the transfer orders.');
        Parameters.Add(Parameter);
        exit(true);
    end;

    /// <summary>Returns the response contract chapter.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    begin
        Response.ReadFrom('{"contentType":"application/json","fields":[{"name":"status","type":"string","description":"Success."},{"name":"inspectionSystemId","type":"string","description":"Selected inspection SystemId."},{"name":"inspectionNo","type":"string","description":"Inspection number."},{"name":"reinspectionNo","type":"integer","description":"Re-inspection number."},{"name":"quantityBasis","type":"string","description":"failed or passed."},{"name":"transferOrderNos","type":"array","description":"Numbers of the created transfer orders. They are not shipped or posted."}]}');
        exit(true);
    end;

    /// <summary>Returns the errors contract chapter.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.ReadFrom('[{"code":"UnknownParameter","when":"An unknown data key is sent.","fix":"Use only declared parameters."},{"error":"Business Central refusal","when":"Setup, locations, bins, stock, permissions or the inspection quantity are invalid; standard validation fails.","fix":"Correct the request, setup or permissions and retry. No transfer order from the failed call remains."}]');
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, 'inspectionSystemId'), FindInspectionLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, 'destinationLocationCode'), DestinationNextLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, ConfirmErr, ConfirmNextLbl));
        exit(true);
    end;

    /// <summary>Returns the effect contract chapter.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        Effect.ReadFrom('{"effect":"irreversible","changes":"Creates one or more unposted transfer orders (header and line, with outbound item tracking reservations when the item is tracked) through the standard Qlty. Disposition implementation Create Transfer Order. Nothing is shipped, received or posted. A refusal or late failure rolls back everything the call did. Omit Commit leaves the transaction to the caller. The expectedCount unit is the one quality inspection named by inspectionSystemId (1 per call), not the transfer orders created. Foundation appends how to read it without a side effect. No delete or cancel message type exists; remove an unwanted transfer order in Business Central.","idempotent":false,"permissionSet":"BIFROST QM Full ori","preconditions":["confirm=true.","Caller has Microsoft transfer order permissions.","Positive inspection Pass Quantity or Fail Quantity, or an explicit quantity, and stock at the source.","The destination location exists; transfer routes or an in-transit location are set up when the transfer is not direct."]}');
        exit(true);
    end;

    /// <summary>Returns the examples contract chapter.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        Examples.ReadFrom('[{"title":"Send the failed quantity to quarantine","request":{"type":"Quality.Disposition.CreateTransferOrder","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001","quantityBasis":"failed","destinationLocationCode":"QUARANTINE","confirm":true,"expectedCount":1}},"response":{"status":"Success","inspectionSystemId":"00000000-0000-0000-0000-000000000001","inspectionNo":"QI00001","reinspectionNo":0,"quantityBasis":"failed","transferOrderNos":["TO00001"]}}]');
        exit(true);
    end;

    /// <summary>No additional metering chapter is declared.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional related chapter is declared.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional workflow chapter is declared.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>Returns the translated overview help chapter.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    var
        HelpLbl: Label 'Creates transfer orders for the failed or passed quantity of one quality inspection through standard Microsoft disposition, for example to send failed stock to a quarantine location. The transfer orders are left unposted and unshipped; the response lists transferOrderNos. confirm=true and destinationLocationCode are required. expectedCount counts the one quality inspection named by inspectionSystemId (1 per call), not the transfer orders or lines the call creates. Omitting expectedCount reads that count and changes nothing only when Require Confirmation for Irreversible Messages is enabled in Bifrost Setup (on by default). When that setup is disabled, omitting expectedCount can create the transfer orders.', Comment = 'is-IS=Stofnar millilagerfærslur fyrir fallið eða staðist magn einnar gæðaskoðunar með staðlaðri ráðstöfun Microsoft, til dæmis til að senda fallnar birgðir á sóttkvíarstaðsetningu. Millilagerfærslurnar eru skildar eftir óbókaðar og ósendar; svarið telur upp transferOrderNos. confirm=true og destinationLocationCode eru nauðsynleg. expectedCount telur eina gæðaskoðun sem inspectionSystemId nefnir (1 fyrir hvert kall), ekki millilagerfærslurnar eða línurnar sem kallið stofnar. Að sleppa expectedCount les þann fjölda og breytir engu aðeins þegar Krefjast staðfestingar fyrir óafturkræf skilaboð er virkt í Uppsetningu Bifröst (virkt sjálfgefið). Þegar sú uppsetning er óvirk getur það að sleppa expectedCount stofnað millilagerfærslurnar.';
    begin
        Overview := HelpLbl;
        exit(true);
    end;

    /// <summary>Returns the translated notes help chapter.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    var
        HelpLbl: Label 'Not idempotent: repeating a successful call can create another transfer order. Nothing is shipped or posted. A refusal or late failure rolls back every transfer order the call created. Normal success commits the isolated transaction; with Omit Commit the caller owns the transaction. No delete or cancel message type exists.', Comment = 'is-IS=Ekki ídempótent: endurtekið heppnað kall getur stofnað aðra millilagerfærslu. Ekkert er sent eða bókað. Höfnun eða seinbúin villa bakfærir allar millilagerfærslur sem kallið stofnaði. Venjuleg heppnuð keyrsla staðfestir einangraða færslu; með Omit Commit ber kallandi ábyrgð á færslunni. Engin skilaboðategund til að eyða eða hætta við er til.';
    begin
        Notes := HelpLbl;
        exit(true);
    end;
}
