namespace Origo.Bifrost.QualityManagement;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Origo.Bifrost;

/// <summary>Writes off inspection stock with a negative adjustment through Microsoft's disposition interface in one rollback transaction.</summary>
codeunit 10035303 "Quality Neg Adj Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        DescriptionLbl: Label 'Writes off the failed or passed quantity of one quality inspection with a negative inventory adjustment, left in the journal or posted now.', MaxLength = 250, Comment = 'is-IS=Afskrifar fallið eða staðist magn einnar gæðaskoðunar með neikvæðri birgðaleiðréttingu sem er skilin eftir í færslubók eða bókuð strax.';
        InvalidKeyErr: Label 'The required parameter %1 is missing or invalid.', Comment = '%1 = parameter name|is-IS=Nauðsynlega færibreytu %1 vantar eða hún er ógild.';
        UnknownKeyErr: Label 'Unknown parameter %1.', Comment = '%1 = parameter name|is-IS=Óþekkt færibreyta %1.';
        TooLongErr: Label 'Parameter %1 exceeds %2 characters.', Comment = '%1 = parameter name, %2 = limit|is-IS=Færibreytan %1 er lengri en %2 stafir.';
        PermissionErr: Label 'The BIFROST QM Full ori permission set is required.', Comment = 'is-IS=Heimildasafnið BIFROST QM Full ori er nauðsynlegt.';
        NotFoundErr: Label 'The quality inspection was not found.', Comment = 'is-IS=Gæðaskoðunin fannst ekki.';
        ConfirmErr: Label 'Set confirm to true to authorize this negative inventory adjustment.', Comment = 'is-IS=Stilltu confirm á true til að heimila þessa neikvæðu birgðaleiðréttingu.';
        NothingAdjustedErr: Label 'Business Central did not create or post a negative adjustment. Check the inspection quantity, stock and the adjustment batch in Quality Management Setup.', Comment = 'is-IS=Business Central stofnaði ekki eða bókaði neikvæða leiðréttingu. Athugaðu magn skoðunar, birgðir og leiðréttingarbunka í uppsetningu gæðastjórnunar.';
        ExpectedIdLbl: Label 'a non-empty quality inspection SystemId GUID', Comment = 'is-IS=SystemId GUID gæðaskoðunar sem er ekki tómt';
        FindInspectionLbl: Label 'Read the inspection SystemId using Data.Records.Get and supply inspectionSystemId.', Comment = 'is-IS=Lestu SystemId skoðunar með Data.Records.Get og sendu inspectionSystemId.';
        ExpectedBasisLbl: Label 'failed or passed', Comment = 'is-IS=failed eða passed';
        BasisNextStepLbl: Label 'Send quantityBasis as failed or passed.', Comment = 'is-IS=Sendu quantityBasis sem failed eða passed.';
        ExpectedQuantityLbl: Label 'a JSON number greater than zero (base quantity)', Comment = 'is-IS=JSON tala hærri en núll (grunneining)';
        QuantityNextStepLbl: Label 'Send quantity as a positive number, or omit it to use the inspection quantity.', Comment = 'is-IS=Sendu quantity sem jákvæða tölu eða slepptu því til að nota magn skoðunar.';
        ExpectedCodeLbl: Label 'an exact code without filter syntax', Comment = 'is-IS=nákvæmur kóði án síunarsetningafræði';
        CodeNextStepLbl: Label 'Send the exact location or bin code; filter syntax is not accepted.', Comment = 'is-IS=Sendu nákvæman staðar- eða hólfskóða; síunarsetningafræði er ekki studd.';
        ExpectedLengthLbl: Label 'a value within the stated maximum length', Comment = 'is-IS=gildi innan tilgreindrar hámarkslengdar';
        LengthNextStepLbl: Label 'Shorten the value.', Comment = 'is-IS=Styttu gildið.';
        ExpectedBooleanLbl: Label 'true or false', Comment = 'is-IS=true eða false';
        BooleanNextStepLbl: Label 'Send a JSON boolean.', Comment = 'is-IS=Sendu JSON boolean gildi.';
        ConfirmNextStepLbl: Label 'Send confirm=true after the user has approved the write-off.', Comment = 'is-IS=Sendu confirm=true þegar notandinn hefur samþykkt afskriftina.';
        KeysNextStepLbl: Label 'Remove the parameter; only the declared parameters are accepted.', Comment = 'is-IS=Fjarlægðu færibreytuna; aðeins tilgreindar færibreytur eru samþykktar.';
        PermissionNextStepLbl: Label 'Assign the BIFROST QM Full ori permission set.', Comment = 'is-IS=Úthlutaðu heimildasafninu BIFROST QM Full ori.';
        ExistingInspectionLbl: Label 'the SystemId of an existing inspection', Comment = 'is-IS=SystemId núverandi skoðunar';

    trigger OnRun()
    begin
        PerformAdjustment(Rec);
    end;

    /// <summary>Runs the disposition in an isolated transaction; standard business errors become refusals.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if Argument."Omit Commit" then begin
            PerformAdjustment(Argument);
            exit;
        end;
        if not Codeunit.Run(Codeunit::"Quality Neg Adj Impl ori", Argument) then
            Argument.RespondWithLastError();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure PerformAdjustment(var Argument: Record "Message Argument ori")
    var
        AccessCapability: Record "Quality Neg Adj Access ori";
        Inspection: Record "Qlty. Inspection Header";
        Setup: Record "Qlty. Management Setup";
        TempInstruction: Record "Qlty. Disposition Buffer" temporary;
        JournalLine: Record "Item Journal Line";
        Ledger: Record "Item Ledger Entry";
        Disposition: Interface "Qlty. Disposition";
        Request: JsonObject;
        Response: JsonObject;
        Lines: JsonArray;
        Entries: JsonArray;
        Line: JsonObject;
        InspectionId: Guid;
        ParameterName: Text;
        Basis: Text;
        Reason: Text;
        Quantity: Decimal;
        PostImmediately: Boolean;
        TemplateName: Code[10];
        LastLineNo: Integer;
        LastEntryNo: Integer;
    begin
        if not AccessCapability.WritePermission() then
            Refuse(Argument, "Bifrost Error Code ori"::PermissionDenied, PermissionErr, 'permissionSet', '', 'BIFROST QM Full ori', PermissionNextStepLbl);
        Request := Argument.GetRequestJson();
        foreach ParameterName in Request.Keys() do
            if not (ParameterName in ['inspectionSystemId', 'quantityBasis', 'quantity', 'sourceLocationCode', 'sourceBinCode', 'reasonCode', 'postImmediately', 'confirm', 'expectedCount']) then
                Refuse(Argument, "Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, ParameterName), ParameterName, '', 'only declared parameters', KeysNextStepLbl);
        InspectionId := ReadInspectionId(Request, Argument);
        if not ReadBoolean(Request, 'confirm', Argument) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, ConfirmErr, 'confirm', 'false', 'true', ConfirmNextStepLbl);
        PostImmediately := ReadBoolean(Request, 'postImmediately', Argument);
        Basis := ReadText(Request, 'quantityBasis', true, 10, Argument);
        case Basis of
            'failed':
                TempInstruction."Quantity Behavior" := TempInstruction."Quantity Behavior"::"Failed Quantity";
            'passed':
                TempInstruction."Quantity Behavior" := TempInstruction."Quantity Behavior"::"Passed Quantity";
            else
                Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, 'quantityBasis'), 'quantityBasis', Basis, ExpectedBasisLbl, BasisNextStepLbl);
        end;
        if Request.Contains('quantity') then begin
            Quantity := ReadQuantity(Request, Argument);
            TempInstruction."Quantity Behavior" := TempInstruction."Quantity Behavior"::"Specific Quantity";
            TempInstruction."Qty. To Handle (Base)" := Quantity;
        end;
        TempInstruction."Location Filter" := CopyStr(ReadCode(Request, 'sourceLocationCode', 10, Argument), 1, MaxStrLen(TempInstruction."Location Filter"));
        TempInstruction."Bin Filter" := CopyStr(ReadCode(Request, 'sourceBinCode', 20, Argument), 1, MaxStrLen(TempInstruction."Bin Filter"));
        Reason := ReadText(Request, 'reasonCode', false, 10, Argument);
        TempInstruction."Reason Code" := CopyStr(Reason, 1, MaxStrLen(TempInstruction."Reason Code"));
        if PostImmediately then
            TempInstruction."Entry Behavior" := TempInstruction."Entry Behavior"::Post;
        Inspection.ReadIsolation := IsolationLevel::UpdLock;
        if not Inspection.GetBySystemId(InspectionId) then
            Refuse(Argument, "Bifrost Error Code ori"::RecordNotFound, NotFoundErr, 'inspectionSystemId', Format(InspectionId, 0, 4), ExistingInspectionLbl, FindInspectionLbl);
        // Remember where the journal and ledger ended so the response lists only what this call created.
        Setup.Get();
        TemplateName := Setup.GetInventoryAdjustmentJournalTemplate();
        JournalLine.SetRange("Journal Template Name", TemplateName);
        JournalLine.SetRange("Journal Batch Name", Setup."Item Journal Batch Name");
        if JournalLine.FindLast() then
            LastLineNo := JournalLine."Line No.";
        if Ledger.FindLast() then
            LastEntryNo := Ledger."Entry No.";
        TempInstruction."Disposition Action" := TempInstruction."Disposition Action"::"Dispose with Negative Inventory Adjustment";
        Disposition := TempInstruction."Disposition Action";
        if not Disposition.PerformDisposition(Inspection, TempInstruction) then
            Error(ErrorInfo.Create(NothingAdjustedErr));
        JournalLine.SetFilter("Line No.", '>%1', LastLineNo);
        JournalLine.SetFilter("Item No.", '<>%1', '');
        if JournalLine.FindSet() then
            repeat
                Clear(Line);
                Line.Add('journalTemplateName', JournalLine."Journal Template Name");
                Line.Add('journalBatchName', JournalLine."Journal Batch Name");
                Line.Add('lineNo', JournalLine."Line No.");
                Line.Add('itemNo', JournalLine."Item No.");
                Line.Add('locationCode', JournalLine."Location Code");
                Line.Add('binCode', JournalLine."Bin Code");
                Line.Add('quantity', JournalLine.Quantity);
                Lines.Add(Line);
            until JournalLine.Next() = 0;
        Ledger.SetFilter("Entry No.", '>%1', LastEntryNo);
        Ledger.SetRange("Item No.", Inspection."Source Item No.");
        Ledger.SetRange("Entry Type", Ledger."Entry Type"::"Negative Adjmt.");
        if Ledger.FindSet() then
            repeat
                Clear(Line);
                Line.Add('entryNo', Ledger."Entry No.");
                Line.Add('itemNo', Ledger."Item No.");
                Line.Add('locationCode', Ledger."Location Code");
                Line.Add('quantity', Ledger.Quantity);
                Entries.Add(Line);
            until Ledger.Next() = 0;
        Response.Add('status', 'Success');
        Response.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Response.Add('inspectionNo', Inspection."No.");
        Response.Add('reinspectionNo', Inspection."Re-inspection No.");
        Response.Add('quantityBasis', Basis);
        Response.Add('posted', PostImmediately);
        Response.Add('journalLines', Lines);
        Response.Add('ledgerEntries', Entries);
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure ReadInspectionId(Request: JsonObject; var Argument: Record "Message Argument ori") InspectionId: Guid
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get('inspectionSystemId', Token) then
            RefuseInspectionId(Argument);
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            RefuseInspectionId(Argument);
        if not Evaluate(InspectionId, Token.AsValue().AsText()) then
            RefuseInspectionId(Argument);
        if IsNullGuid(InspectionId) then
            RefuseInspectionId(Argument);
    end;

    local procedure RefuseInspectionId(var Argument: Record "Message Argument ori")
    begin
        Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(InvalidKeyErr, 'inspectionSystemId'), 'inspectionSystemId', '', ExpectedIdLbl, FindInspectionLbl);
    end;

    local procedure Refuse(var Argument: Record "Message Argument ori"; ErrorCode: Enum "Bifrost Error Code ori"; Message: Text; Parameter: Text; Received: Text; Expected: Text; NextStep: Text)
    begin
        // Foundation preserves this collection across the Codeunit.Run rollback.
        Argument.AddError(ErrorCode, Message, Parameter, Received, Expected, NextStep);
        Argument.RaiseCollectedErrors(ErrorCode, Message);
    end;

    local procedure ReadCode(Request: JsonObject; ParameterName: Text; MaximumLength: Integer; var Argument: Record "Message Argument ori") Value: Text
    var
        Position: Integer;
    begin
        Value := ReadText(Request, ParameterName, false, MaximumLength, Argument);
        // The standard buffer stores filters, but this API promises literal codes.
        for Position := 1 to StrLen(Value) do
            if StrPos('|&*?@<>=()''', CopyStr(Value, Position, 1)) > 0 then
                Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, ParameterName), ParameterName, Value, ExpectedCodeLbl, CodeNextStepLbl);
        if StrPos(Value, '..') > 0 then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, ParameterName), ParameterName, Value, ExpectedCodeLbl, CodeNextStepLbl);
    end;

    local procedure ReadText(Request: JsonObject; ParameterName: Text; Required: Boolean; MaximumLength: Integer; var Argument: Record "Message Argument ori") Value: Text
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get(ParameterName, Token) then begin
            if Required then
                Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(InvalidKeyErr, ParameterName), ParameterName, '', ParameterName, FindInspectionLbl);
            exit('');
        end;
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, ParameterName), ParameterName, Serialized, 'a JSON string', FindInspectionLbl);
        Value := Token.AsValue().AsText();
        if Required and (Value = '') then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(InvalidKeyErr, ParameterName), ParameterName, '', ParameterName, FindInspectionLbl);
        if StrLen(Value) > MaximumLength then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(TooLongErr, ParameterName, MaximumLength), ParameterName, Value, ExpectedLengthLbl, LengthNextStepLbl);
    end;

    local procedure ReadBoolean(Request: JsonObject; ParameterName: Text; var Argument: Record "Message Argument ori"): Boolean
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get(ParameterName, Token) then
            exit(false);
        Token.WriteTo(Serialized);
        if not (Serialized in ['true', 'false']) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, ParameterName), ParameterName, Serialized, ExpectedBooleanLbl, BooleanNextStepLbl);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure ReadQuantity(Request: JsonObject; var Argument: Record "Message Argument ori") Quantity: Decimal
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        Request.Get('quantity', Token);
        Token.WriteTo(Serialized);
        if (Serialized = '') or (CopyStr(Serialized, 1, 1) in ['"', 't', 'f', 'n', '{', '[']) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, 'quantity'), 'quantity', Serialized, ExpectedQuantityLbl, QuantityNextStepLbl);
        Quantity := Token.AsValue().AsDecimal();
        if Quantity <= 0 then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidKeyErr, 'quantity'), 'quantity', Serialized, ExpectedQuantityLbl, QuantityNextStepLbl);
    end;

    /// <summary>Returns whether the caller has the negative adjustment capability.</summary>
    procedure IsEnabled(): Boolean
    var
        AccessCapability: Record "Quality Neg Adj Access ori";
    begin
        exit(AccessCapability.WritePermission());
    end;

    /// <summary>Returns the standard inspection table.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Qlty. Inspection Header");
    end;

    /// <summary>Describes the write-off.</summary>
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
        KeywordsLbl: Label 'quality, disposition, write off, scrap, dispose, negative adjustment, inventory adjustment, failed quantity', Comment = 'is-IS=gæði, ráðstöfun, afskrifa, förgun, farga, neikvæð leiðrétting, birgðaleiðrétting, fallið magn';
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
        Parameter := ContractMgt.Parameter('quantityBasis', 'string', true, 'Use Microsoft inspection Fail Quantity or Pass Quantity; must be positive.');
        AllowedValues.ReadFrom('["failed","passed"]');
        Parameter.Add('allowed', AllowedValues);
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('quantity', 'number', false, 'Optional base quantity to write off instead of the whole basis quantity. Must be greater than zero.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('sourceLocationCode', 'string', false, 'Exact source location, up to 10 characters. No filter syntax. Omitted: Microsoft selects available inventory.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('sourceBinCode', 'string', false, 'Exact source bin, up to 20 characters. No filter syntax. Omitted: Microsoft selects available bins.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('reasonCode', 'string', false, 'Reason code for the adjustment lines, up to 10 characters.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('postImmediately', 'boolean', false, 'true posts the negative adjustment now and reduces stock; false (default) leaves the lines in the journal batch named in Quality Management Setup.');
        Parameter.Add('default', false);
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('confirm', 'boolean', true, 'Must be true to authorize creation or posting of the negative adjustment.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('expectedCount', 'integer', false, 'expectedCount counts the one quality inspection named by inspectionSystemId (1 per call), not the journal lines or inventory entries the call creates. Omitting expectedCount reads that count and changes nothing only when Require Confirmation for Irreversible Messages is enabled in Bifrost Setup (on by default). When that setup is disabled, omitting expectedCount can execute the write-off.');
        Parameters.Add(Parameter);
        exit(true);
    end;

    /// <summary>Returns the response contract chapter.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    begin
        Response.ReadFrom('{"contentType":"application/json","fields":[{"name":"status","type":"string","description":"Success."},{"name":"inspectionSystemId","type":"string","description":"Selected inspection SystemId."},{"name":"inspectionNo","type":"string","description":"Inspection number."},{"name":"reinspectionNo","type":"integer","description":"Re-inspection number."},{"name":"quantityBasis","type":"string","description":"failed or passed."},{"name":"posted","type":"boolean","description":"True only when postImmediately was requested and posting completed; false means the lines wait in the journal."},{"name":"journalLines","type":"array","description":"Item journal lines this call created and left in the journal (empty after posting)."},{"name":"ledgerEntries","type":"array","description":"Negative adjustment item ledger entries this call wrote (empty unless posted)."}]}');
        exit(true);
    end;

    /// <summary>Returns the errors contract chapter.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.ReadFrom('[{"code":"UnknownParameter","when":"An unknown data key is sent.","fix":"Use only declared parameters."},{"code":"InvalidParameter","when":"confirm is not true, or a value is malformed, too long, a filter or not positive.","fix":"Correct the parameter named in the error."},{"code":"RecordNotFound","when":"The inspection does not exist.","fix":"Read the inspection SystemId with Data.Records.Get."},{"error":"Business Central refusal","when":"The adjustment batch is missing, the template forces a posting report, stock is insufficient or standard validation fails.","fix":"Correct the setup, stock or request and retry. No line or entry from the failed call remains."}]');
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, StrSubstNo(InvalidKeyErr, 'inspectionSystemId'), FindInspectionLbl));
        exit(true);
    end;

    /// <summary>Returns the effect contract chapter.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        Effect.ReadFrom('{"effect":"irreversible","changes":"Creates negative item adjustment journal lines through the standard Qlty. Disp. Neg. Adjust Inv. implementation in the adjustment batch named in Quality Management Setup. With postImmediately=true the lines are posted and item ledger entries reduce stock; posted entries cannot be undone by this type and a repeated call can write off more stock. Standard posting suppresses commits and explicit commits are prohibited, so a late refusal rolls back lines and posting together. Success commits once through the isolated wrapper. Omit Commit leaves the transaction to the caller. The expectedCount unit is the one quality inspection named by inspectionSystemId (1 per call), not the journal lines or inventory entries the call creates.","idempotent":false,"permissionSet":"BIFROST QM Full ori","preconditions":["confirm=true.","Caller has Microsoft item journal and inventory posting permissions.","Positive inspection Pass Quantity or Fail Quantity (or a positive quantity) and sufficient visible inventory.","Quality Management Setup names an item journal batch whose template does not force a posting report."]}');
        exit(true);
    end;

    /// <summary>Returns the examples contract chapter.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        Examples.ReadFrom('[{"title":"Leave a failed-quantity write-off in the journal","request":{"type":"Quality.Disposition.CreateNegativeAdjustment","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001","quantityBasis":"failed","reasonCode":"SCRAP","confirm":true,"expectedCount":1}},"response":{"status":"Success","inspectionSystemId":"00000000-0000-0000-0000-000000000001","inspectionNo":"QI00001","reinspectionNo":0,"quantityBasis":"failed","posted":false,"journalLines":[{"journalTemplateName":"ITEM","journalBatchName":"QUALITY","lineNo":10000,"itemNo":"1000","locationCode":"","binCode":"","quantity":-3}],"ledgerEntries":[]}}]');
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
        HelpLbl: Label 'Writes off the failed or passed quantity of one quality inspection with a negative inventory adjustment through standard Microsoft disposition. With postImmediately=false (default) the lines stay in the journal batch named in Quality Management Setup; with postImmediately=true they are posted and stock is reduced. confirm=true is required. expectedCount counts the one quality inspection named by inspectionSystemId (1 per call), not the journal lines or inventory entries the call creates. Omitting expectedCount reads that count and changes nothing only when Require Confirmation for Irreversible Messages is enabled in Bifrost Setup (on by default). When that setup is disabled, omitting expectedCount can execute the write-off.', Comment = 'is-IS=Afskrifar fallið eða staðist magn einnar gæðaskoðunar með neikvæðri birgðaleiðréttingu í gegnum staðlaða ráðstöfun Microsoft. Með postImmediately=false (sjálfgefið) eru línurnar skildar eftir í færslubókarbunkanum sem uppsetning gæðastjórnunar tilgreinir; með postImmediately=true eru þær bókaðar og birgðir lækka. confirm=true er nauðsynlegt. expectedCount telur eina gæðaskoðun sem inspectionSystemId nefnir (1 fyrir hvert kall), ekki færslubókarlínurnar eða birgðafærslurnar sem kallið stofnar. Að sleppa expectedCount les þann fjölda og breytir engu aðeins þegar Krefjast staðfestingar fyrir óafturkræf skilaboð er virkt í Uppsetningu Bifröst (virkt sjálfgefið). Þegar sú uppsetning er óvirk getur það að sleppa expectedCount keyrt afskriftina.';
    begin
        Overview := HelpLbl;
        exit(true);
    end;

    /// <summary>Returns the translated notes help chapter.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    var
        HelpLbl: Label 'Not idempotent: posted entries change inventory and a repeated call can write off more stock. There is no delete type and no reverse type. Posting is atomic; a refusal rolls back journal creation and posting. Locations with directed put-away and pick use the warehouse journal of Microsoft setup; only preparing is supported there. Normal success commits the isolated transaction; with Omit Commit the caller owns the transaction.', Comment = 'is-IS=Ekki ídempótent: bókaðar færslur breyta birgðum og endurtekið kall getur afskrifað meira magn. Engin eyðingar- eða bakfærslugerð er til. Bókun er ein heild; höfnun bakfærir stofnun færslubókar og bókun. Staðsetningar með stýrða vörslu og tínslu nota vöruhúsafærslubók úr uppsetningu Microsoft; þar er aðeins stutt að undirbúa. Venjuleg heppnuð keyrsla staðfestir einangraða færslu; með Omit Commit ber kallandi ábyrgð á færslunni.';
    begin
        Notes := HelpLbl;
        exit(true);
    end;
}
