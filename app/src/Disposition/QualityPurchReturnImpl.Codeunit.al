namespace Origo.Bifrost.QualityManagement;

using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Dispositions.Purchase;
using Microsoft.QualityManagement.Document;
using Origo.Bifrost;

/// <summary>Creates a purchase return for the inspection failed quantity through Microsoft disposition logic.</summary>
codeunit 10035245 "Quality Purch Return Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        DescriptionLbl: Label 'Creates a purchase return order for the failed quantity of a purchase inspection.', MaxLength = 250, Comment = 'is-IS=Stofnar innkaupaskilapöntun fyrir fallið magn í innkaupaskoðun.';
        MissingKeyErr: Label 'The required parameter ''%1'' is missing or invalid.', Comment = '%1 = parameter name|is-IS=Nauðsynlega færibreytu ''%1'' vantar eða hún er ógild.';
        UnknownKeyErr: Label 'Unknown parameter ''%1''.', Comment = '%1 = parameter name|is-IS=Óþekkt færibreyta ''%1''.';
        TooLongErr: Label 'Parameter ''%1'' exceeds %2 characters.', Comment = '%1 = parameter name, %2 = limit|is-IS=Færibreytan ''%1'' er lengri en %2 stafir.';
        PermissionErr: Label 'The BIFROST QM Full ori permission set is required.', Comment = 'is-IS=Heimildasafnið BIFROST QM Full ori er nauðsynlegt.';
        NotFoundErr: Label 'The quality inspection was not found.', Comment = 'is-IS=Gæðaskoðunin fannst ekki.';
        SourceErr: Label 'The inspection must have a purchase line source.', Comment = 'is-IS=Uppruni skoðunar verður að vera innkaupalína.';
        NoReturnErr: Label 'Business Central did not create a purchase return order.', Comment = 'is-IS=Business Central stofnaði ekki innkaupaskilapöntun.';
        OverviewLbl: Label 'Creates an unposted purchase return order using Qlty. Disp. Purchase Return and the Failed Quantity behavior, with optional return reason and vendor credit memo number.', Comment = 'is-IS=Stofnar óbókaða innkaupaskilapöntun með Qlty. Disp. Purchase Return og föllnu magni ásamt valfrjálsri skilaástæðu og kreditreikningsnúmeri lánardrottins.';
        NotesLbl: Label 'inspectionSystemId selects exactly one inspection including its re-inspection. reasonCode (10 characters) and vendorCreditMemoNo (35 characters) are optional text. Missing, malformed and unknown inputs are refused before any business write. Only purchase line sources are accepted. Microsoft requires positive failed quantity, sufficient received quantity and valid purchase setup. No explicit Commit occurs on the standard disposition path; explicit subscriber commits are prohibited. Normal execution rolls back all writes on refusal. With Omit Commit the caller owns rollback. This operation is not idempotent: a retry can create another return. It creates an unposted return order; it does not post a vendor credit memo or call an external provider.', Comment = 'is-IS=inspectionSystemId velur nákvæmlega eina skoðun ásamt endurskoðun hennar. reasonCode (10 stafir) og vendorCreditMemoNo (35 stafir) eru valfrjálsir textar. Lyklum sem vantar og gölluðum eða óþekktum gildum er hafnað áður en viðskiptagögnum er breytt. Aðeins innkaupalínur eru leyfðar sem uppruni. Microsoft krefst jákvæðs fallins magns, nægs móttekins magns og gildrar innkaupauppsetningar. Staðlaða leiðin notar ekkert beint Commit; beinar staðfestingar frá áskrifendum eru bannaðar. Venjuleg keyrsla bakfærir allar breytingar við höfnun. Með Omit Commit ber kallandi ábyrgð á bakfærslu. Aðgerðin er ekki ítrekunarörugg: endurtekning getur stofnað aðra skilapöntun. Hún stofnar óbókaða skilapöntun, bókar ekki kreditreikning lánardrottins og kallar ekki á ytri þjónustu.';

    var
        InspectionDescriptionLbl: Label 'SystemId of the exact inspection and re-inspection.', Comment = 'is-IS=SystemId tiltekinnar skoðunar og endurskoðunar hennar.';
        ReasonDescriptionLbl: Label 'Return reason code, maximum 10 characters.', Comment = 'is-IS=Skilaástæðukóði, að hámarki 10 stafir.';
        CreditDescriptionLbl: Label 'Vendor credit memo number, maximum 35 characters.', Comment = 'is-IS=Kreditreikningsnúmer lánardrottins, að hámarki 35 stafir.';
        SuccessDescriptionLbl: Label 'Success.', Comment = 'is-IS=Tókst.';
        ReturnDescriptionLbl: Label 'Created unposted purchase return order number.', Comment = 'is-IS=Númer stofnaðrar óbókaðrar innkaupaskilapöntunar.';
        BusinessRefusalLbl: Label 'Business Central refusal', Comment = 'is-IS=Höfnun frá Business Central';
        ErrorWhenLbl: Label 'Invalid input, nonpurchase source, nonpositive failed quantity, unavailable receipt, setup or permission refusal.', Comment = 'is-IS=Ógilt inntak, uppruni er ekki innkaup, fallið magn er ekki jákvætt, móttöku vantar eða uppsetning eða heimildir hafna aðgerð.';
        ErrorFixLbl: Label 'Correct the request, inspection, purchase setup or permissions.', Comment = 'is-IS=Leiðréttu beiðni, skoðun, innkaupauppsetningu eða heimildir.';
        ChangesLbl: Label 'Creates an unposted purchase return header and lines through Microsoft disposition. Does not post a credit memo. No explicit Commit on the standard path; explicit subscriber commits prohibited.', Comment = 'is-IS=Stofnar óbókaðan innkaupaskilahaus og línur með stöðluðum aðgerðum Microsoft. Bókar ekki kreditreikning. Staðlaða leiðin inniheldur ekkert beint Commit; beinar staðfestingar frá áskrifendum eru bannaðar.';
        SourcePreconditionLbl: Label 'Inspection with Purchase Line source and positive failed quantity.', Comment = 'is-IS=Skoðun með innkaupalínu sem uppruna og jákvætt fallið magn.';
        SetupPreconditionLbl: Label 'Received quantity sufficient for the return and valid Microsoft purchase setup.', Comment = 'is-IS=Nægilegt móttekið magn fyrir skil og gild innkaupauppsetning Microsoft.';
        PermissionPreconditionLbl: Label 'Microsoft purchase and Quality Management permissions.', Comment = 'is-IS=Innkaupa- og gæðastjórnunarheimildir Microsoft.';
        ExpectedIdLbl: Label 'a non-empty SystemId GUID of an existing quality inspection', Comment = 'is-IS=SystemId GUID skoðunar sem er til og er ekki tómt';
        FindInspectionLbl: Label 'Read the inspection SystemId using Data.Records.Get and supply inspectionSystemId.', Comment = 'is-IS=Lestu SystemId skoðunar með Data.Records.Get og sendu inspectionSystemId.';
        TextExpectedLbl: Label 'a text value', Comment = 'is-IS=textagildi';
        FixParameterLbl: Label 'Correct the named request parameter and retry.', Comment = 'is-IS=Leiðréttu tilgreinda færibreytu beiðninnar og reyndu aftur.';
        MaximumTextLbl: Label 'text with at most %1 characters', Comment = '%1 = maximum length|is-IS=texti með að hámarki %1 stöfum';
        PermissionNextLbl: Label 'Ask an administrator for BIFROST QM Full ori and the native purchase permissions.', Comment = 'is-IS=Biddu stjórnanda um BIFROST QM Full ori og staðlaðar innkaupaheimildir.';
        PurchaseSourceLbl: Label 'an inspection with a Purchase Line source', Comment = 'is-IS=skoðun með innkaupalínu sem uppruna';
        ReturnExpectedLbl: Label 'a created purchase return order with an item line for this inspection', Comment = 'is-IS=stofnuð innkaupaskilapöntun með vörulínu fyrir þessa skoðun';
        ReturnNextLbl: Label 'Check the inspection, purchase setup and disposition subscribers before retrying; nothing was changed.', Comment = 'is-IS=Athugaðu skoðunina, innkaupauppsetningu og áskrifendur ráðstöfunar áður en þú reynir aftur; engu var breytt.';
        ExampleTitleLbl: Label 'Return the failed quantity', Comment = 'is-IS=Skila föllnu magni';

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
        if not Codeunit.Run(Codeunit::"Quality Purch Return Impl ori", Argument) then
            Argument.RespondWithLastError();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure PerformWrite(var Argument: Record "Message Argument ori")
    var
        WriteAccess: Record "Quality Return Access ori";
        Inspection: Record "Qlty. Inspection Header";
        ReturnLine: Record "Purchase Line";
        TempInstructions: Record "Qlty. Disposition Buffer" temporary;
        PurchaseReturn: Codeunit "Qlty. Disp. Purchase Return";
        Receipt: Codeunit "Quality Return Receipt ori";
        Request: JsonObject;
        Response: JsonObject;
        InspectionSystemId: Guid;
        ReturnOrderNo: Code[20];
        ParameterName: Text;
    begin
        if not WriteAccess.WritePermission() then
            Refuse(Argument, "Bifrost Error Code ori"::PermissionDenied, PermissionErr, 'permissionSet', '', 'BIFROST QM Full ori', PermissionNextLbl);
        Request := Argument.GetRequestJson();
        foreach ParameterName in Request.Keys() do
            if not (ParameterName in ['inspectionSystemId', 'reasonCode', 'vendorCreditMemoNo']) then
                Refuse(Argument, "Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, ParameterName), ParameterName, '', 'inspectionSystemId, reasonCode, vendorCreditMemoNo', FixParameterLbl);
        if not Evaluate(InspectionSystemId, ReadText(Argument, Request, 'inspectionSystemId', false)) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'inspectionSystemId'), 'inspectionSystemId', ReadText(Argument, Request, 'inspectionSystemId', false), ExpectedIdLbl, FindInspectionLbl);
        if IsNullGuid(InspectionSystemId) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, 'inspectionSystemId'), 'inspectionSystemId', ReadText(Argument, Request, 'inspectionSystemId', false), ExpectedIdLbl, FindInspectionLbl);
        TempInstructions."Disposition Action" := TempInstructions."Disposition Action"::"Create Purchase Return";
        TempInstructions."Quantity Behavior" := TempInstructions."Quantity Behavior"::"Failed Quantity";
        TempInstructions."Reason Code" := CopyStr(ReadOption(Argument, Request, 'reasonCode', 10), 1, 10);
        TempInstructions."External Document No." := CopyStr(ReadOption(Argument, Request, 'vendorCreditMemoNo', 35), 1, 35);
        // Microsoft reads the complete inspection while calculating quantities and copying the receipt.
        Inspection.ReadIsolation := IsolationLevel::UpdLock;
        if not Inspection.GetBySystemId(InspectionSystemId) then
            Refuse(Argument, "Bifrost Error Code ori"::RecordNotFound, NotFoundErr, 'inspectionSystemId', Format(InspectionSystemId, 0, 4), ExpectedIdLbl, FindInspectionLbl);
        if Inspection."Source Table No." <> Database::"Purchase Line" then
            Refuse(Argument, "Bifrost Error Code ori"::PreconditionFailed, SourceErr, 'inspectionSystemId', Format(InspectionSystemId, 0, 4), PurchaseSourceLbl, FindInspectionLbl);
        Receipt.Initialize(Inspection.SystemId);
        BindSubscription(Receipt);
        PurchaseReturn.PerformDisposition(Inspection, TempInstructions);
        UnbindSubscription(Receipt);
        ReturnOrderNo := Receipt.GetReturnOrderNo();
        if ReturnOrderNo = '' then
            Refuse(Argument, "Bifrost Error Code ori"::PreconditionFailed, NoReturnErr, 'inspectionSystemId', Format(InspectionSystemId, 0, 4), ReturnExpectedLbl, ReturnNextLbl);
        ReturnLine.ReadIsolation := IsolationLevel::ReadCommitted;
        ReturnLine.SetRange("Document Type", ReturnLine."Document Type"::"Return Order");
        ReturnLine.SetRange("Document No.", ReturnOrderNo);
        ReturnLine.SetRange(Type, ReturnLine.Type::Item);
        ReturnLine.SetRange("No.", Inspection."Source Item No.");
        if ReturnLine.IsEmpty() then
            Refuse(Argument, "Bifrost Error Code ori"::PreconditionFailed, NoReturnErr, 'inspectionSystemId', Format(InspectionSystemId, 0, 4), ReturnExpectedLbl, ReturnNextLbl);
        Response.Add('status', 'Success');
        Response.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Response.Add('returnOrderNo', ReturnOrderNo);
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure ReadOption(var Argument: Record "Message Argument ori"; Request: JsonObject; ParameterName: Text; MaximumLength: Integer): Text
    var
        Value: Text;
    begin
        if not Request.Contains(ParameterName) then
            exit('');
        Value := ReadText(Argument, Request, ParameterName, true);
        if StrLen(Value) > MaximumLength then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(TooLongErr, ParameterName, MaximumLength), ParameterName, Value, StrSubstNo(MaximumTextLbl, MaximumLength), FixParameterLbl);
        exit(Value);
    end;

    local procedure ReadText(var Argument: Record "Message Argument ori"; Request: JsonObject; ParameterName: Text; AllowEmpty: Boolean) Value: Text
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get(ParameterName, Token) then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, ParameterName), ParameterName, '', ExpectedIdLbl, FindInspectionLbl);
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(MissingKeyErr, ParameterName), ParameterName, Serialized, TextExpectedLbl, FixParameterLbl);
        Value := Token.AsValue().AsText();
        if (Value = '') and not AllowEmpty then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, ParameterName), ParameterName, '', ExpectedIdLbl, FindInspectionLbl);
    end;

    local procedure Refuse(var Argument: Record "Message Argument ori"; ErrorCode: Enum "Bifrost Error Code ori"; Message: Text; Parameter: Text; Received: Text; Expected: Text; NextStep: Text)
    begin
        // Foundation preserves this collection across Codeunit.Run rollback, including post-write refusals.
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
        KeywordsLbl: Label 'Quality.Disposition.CreatePurchaseReturn, quality, inspection, purchase, return, failed quantity', Comment = 'is-IS=Quality.Disposition.CreatePurchaseReturn, gæði, skoðun, innkaup, skil, fallið magn';
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
        Entry.Add('source', 'data.inspectionSystemId');
        Entry.Add('form', 'GUID');
        Entry.Add('description', InspectionDescriptionLbl);
        Target.Add(Entry);
        exit(true);
    end;

    /// <summary>Provides the parameters contract chapter.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Clear(Parameters);
        Parameters.Add(ContractMgt.Parameter('inspectionSystemId', 'string', true, InspectionDescriptionLbl));
        Parameters.Add(ContractMgt.Parameter('reasonCode', 'string', false, ReasonDescriptionLbl));
        Parameters.Add(ContractMgt.Parameter('vendorCreditMemoNo', 'string', false, CreditDescriptionLbl));
        exit(true);
    end;

    /// <summary>Provides the response contract chapter.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Fields: JsonArray;
    begin
        Clear(Response);
        AddResponseField(Fields, 'status', SuccessDescriptionLbl);
        AddResponseField(Fields, 'inspectionSystemId', InspectionDescriptionLbl);
        AddResponseField(Fields, 'returnOrderNo', ReturnDescriptionLbl);
        Response.Add('contentType', 'application/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    local procedure AddResponseField(var Fields: JsonArray; FieldName: Text; Description: Text)
    var
        FieldDefinition: JsonObject;
    begin
        FieldDefinition.Add('name', FieldName);
        FieldDefinition.Add('type', 'string');
        FieldDefinition.Add('description', Description);
        Fields.Add(FieldDefinition);
    end;

    /// <summary>Provides the errors contract chapter.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Clear(Errors);
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, 'inspectionSystemId'), FindInspectionLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, ErrorWhenLbl, FixParameterLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, '<parameter>'), FixParameterLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, NotFoundErr, FindInspectionLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, PermissionErr, PermissionNextLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, ErrorWhenLbl, ReturnNextLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, BusinessRefusalLbl, ErrorFixLbl));
        exit(true);
    end;

    /// <summary>Provides the effect contract chapter.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
    begin
        Clear(Effect);
        Preconditions.Add(SourcePreconditionLbl);
        Preconditions.Add(SetupPreconditionLbl);
        Preconditions.Add(PermissionPreconditionLbl);
        Effect.Add('effect', 'write');
        Effect.Add('changes', ChangesLbl);
        Effect.Add('idempotent', false);
        Effect.Add('permissionSet', 'BIFROST QM Full ori');
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    /// <summary>Provides the examples contract chapter.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        EntryToken: JsonToken;
        Entry: JsonObject;
    begin
        Examples.ReadFrom('[{"title":"Return the failed quantity","request":{"type":"Quality.Disposition.CreatePurchaseReturn","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001","reasonCode":"QUALITY","vendorCreditMemoNo":"VC-001"}},"response":{"status":"Success","inspectionSystemId":"00000000-0000-0000-0000-000000000001","returnOrderNo":"PRO00001"}}]');
        Examples.Get(0, EntryToken);
        Entry := EntryToken.AsObject();
        Entry.Replace('title', ExampleTitleLbl);
        Examples.Set(0, Entry);
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
