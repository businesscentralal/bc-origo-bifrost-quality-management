namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Origo.Bifrost;

/// <summary>Moves inspection inventory through Microsoft's disposition interface in one rollback transaction.</summary>
codeunit 10035270 "Quality Move Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        DescriptionLbl: Label 'Moves failed or passed inspection inventory using standard quality disposition and optional posting.', MaxLength = 250, Comment = 'is-IS=Flytur birgðir sem standast eða falla í gæðaskoðun með staðlaðri ráðstöfun og valfrjálsri bókun.';
        MissingKeyErr: Label 'The required parameter %1 is missing or invalid.', Comment = '%1 = parameter name|is-IS=Nauðsynlega færibreytu %1 vantar eða hún er ógild.';
        UnknownKeyErr: Label 'Unknown parameter %1.', Comment = '%1 = parameter name|is-IS=Óþekkt færibreyta %1.';
        TooLongErr: Label 'Parameter %1 exceeds %2 characters.', Comment = '%1 = parameter name, %2 = limit|is-IS=Færibreytan %1 er lengri en %2 stafir.';
        PermissionErr: Label 'The BIFROST QM Full ori permission set is required.', Comment = 'is-IS=Heimildasafnið BIFROST QM Full ori er nauðsynlegt.';
        NotFoundErr: Label 'The quality inspection was not found.', Comment = 'is-IS=Gæðaskoðunin fannst ekki.';
        ConfirmErr: Label 'Set confirm to true to authorize this inventory movement.', Comment = 'is-IS=Stilltu confirm á true til að heimila þennan birgðaflutning.';
        NothingMovedErr: Label 'Business Central did not create or post an inventory movement. Check the inspection quantity and movement setup.', Comment = 'is-IS=Business Central stofnaði ekki eða bókaði birgðaflutning. Athugaðu magn skoðunar og uppsetningu flutnings.';
        DestinationErr: Label 'Specify destinationLocationCode or destinationBinCode.', Comment = 'is-IS=Tilgreindu destinationLocationCode eða destinationBinCode.';
        WorksheetPostErr: Label 'The movement worksheet and internal movement methods prepare movements; they cannot post immediately.', Comment = 'is-IS=Vinnublað flutnings og innri flutningur undirbúa flutninga; ekki er hægt að bóka þá strax.';

    trigger OnRun()
    begin
        PerformMove(Rec);
    end;

    /// <summary>Runs the disposition in an isolated transaction; standard business errors become refusals.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if Argument."Omit Commit" then begin
            PerformMove(Argument);
            exit;
        end;
        if not Codeunit.Run(Codeunit::"Quality Move Impl ori", Argument) then
            Argument.RespondWithLastError();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure PerformMove(var Argument: Record "Message Argument ori")
    var
        AccessCapability: Record "Quality Move Access ori";
        Inspection: Record "Qlty. Inspection Header";
        TempInstruction: Record "Qlty. Disposition Buffer" temporary;
        AtomicPosting: Codeunit "Quality Move Posting ori";
        Disposition: Interface "Qlty. Disposition";
        Request: JsonObject;
        Response: JsonObject;
        InspectionId: Guid;
        ParameterName: Text;
        Method: Text;
        PostImmediately: Boolean;
    begin
        if not AccessCapability.WritePermission() then
            Error(ErrorInfo.Create(PermissionErr));
        Request := Argument.GetRequestJson();
        foreach ParameterName in Request.Keys() do
            if not (ParameterName in ['inspectionSystemId', 'quantityBasis', 'method', 'sourceLocationCode', 'sourceBinCode', 'destinationLocationCode', 'destinationBinCode', 'postImmediately', 'confirm', 'expectedCount']) then
                Error(ErrorInfo.Create(StrSubstNo(UnknownKeyErr, ParameterName)));
        if not Evaluate(InspectionId, ReadText(Request, 'inspectionSystemId', true, 50)) then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, 'inspectionSystemId')));
        if IsNullGuid(InspectionId) then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, 'inspectionSystemId')));
        if not ReadBoolean(Request, 'confirm') then
            Error(ErrorInfo.Create(ConfirmErr));
        PostImmediately := ReadBoolean(Request, 'postImmediately');
        Method := ReadText(Request, 'method', true, 30);
        case Method of
            'automatic': TempInstruction."Disposition Action" := TempInstruction."Disposition Action"::"Move with automatic choice";
            'itemReclassification': TempInstruction."Disposition Action" := TempInstruction."Disposition Action"::"Move with Item Reclassification";
            'warehouseReclassification': TempInstruction."Disposition Action" := TempInstruction."Disposition Action"::"Move with Warehouse Reclassification";
            'movementWorksheet': TempInstruction."Disposition Action" := TempInstruction."Disposition Action"::"Move with Movement Worksheet";
            'internalMovement': TempInstruction."Disposition Action" := TempInstruction."Disposition Action"::"Move with Internal Movement";
            else
                Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, 'method')));
        end;
        if PostImmediately and (Method in ['movementWorksheet', 'internalMovement']) then
            Error(ErrorInfo.Create(WorksheetPostErr));
        case ReadText(Request, 'quantityBasis', true, 10) of
            'failed': TempInstruction."Quantity Behavior" := TempInstruction."Quantity Behavior"::"Failed Quantity";
            'passed': TempInstruction."Quantity Behavior" := TempInstruction."Quantity Behavior"::"Passed Quantity";
            else
                Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, 'quantityBasis')));
        end;
        TempInstruction."Location Filter" := CopyStr(ReadText(Request, 'sourceLocationCode', false, 10), 1, MaxStrLen(TempInstruction."Location Filter"));
        TempInstruction."Bin Filter" := CopyStr(ReadText(Request, 'sourceBinCode', false, 20), 1, MaxStrLen(TempInstruction."Bin Filter"));
        ValidateSourceCode(TempInstruction."Location Filter", 'sourceLocationCode');
        ValidateSourceCode(TempInstruction."Bin Filter", 'sourceBinCode');
        TempInstruction."New Location Code" := CopyStr(ReadText(Request, 'destinationLocationCode', false, 10), 1, MaxStrLen(TempInstruction."New Location Code"));
        TempInstruction."New Bin Code" := CopyStr(ReadText(Request, 'destinationBinCode', false, 20), 1, MaxStrLen(TempInstruction."New Bin Code"));
        if (TempInstruction."New Location Code" = '') and (TempInstruction."New Bin Code" = '') then
            Error(ErrorInfo.Create(DestinationErr));
        if PostImmediately then
            TempInstruction."Entry Behavior" := TempInstruction."Entry Behavior"::Post;
        Inspection.ReadIsolation := IsolationLevel::UpdLock;
        if not Inspection.GetBySystemId(InspectionId) then
            Error(ErrorInfo.Create(NotFoundErr));
        Disposition := TempInstruction."Disposition Action";
        BindSubscription(AtomicPosting);
        if not Disposition.PerformDisposition(Inspection, TempInstruction) then
            Error(ErrorInfo.Create(NothingMovedErr));
        UnbindSubscription(AtomicPosting);
        Response.Add('status', 'Success');
        Response.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        Response.Add('inspectionNo', Inspection."No.");
        Response.Add('reinspectionNo', Inspection."Re-inspection No.");
        Response.Add('method', Method);
        Response.Add('quantityBasis', ReadText(Request, 'quantityBasis', true, 10));
        Response.Add('posted', PostImmediately);
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure ValidateSourceCode(Value: Text; ParameterName: Text)
    var
        Position: Integer;
    begin
        // The standard buffer stores filters, but this API promises literal codes.
        for Position := 1 to StrLen(Value) do
            if StrPos('|&*?@<>=()''', CopyStr(Value, Position, 1)) > 0 then
                Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, ParameterName)));
        if StrPos(Value, '..') > 0 then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, ParameterName)));
    end;

    local procedure ReadText(Request: JsonObject; ParameterName: Text; Required: Boolean; MaximumLength: Integer) Value: Text
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get(ParameterName, Token) then begin
            if Required then
                Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, ParameterName)));
            exit('');
        end;
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, ParameterName)));
        Value := Token.AsValue().AsText();
        if Required and (Value = '') then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, ParameterName)));
        if StrLen(Value) > MaximumLength then
            Error(ErrorInfo.Create(StrSubstNo(TooLongErr, ParameterName, MaximumLength)));
    end;

    local procedure ReadBoolean(Request: JsonObject; ParameterName: Text): Boolean
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get(ParameterName, Token) then
            exit(false);
        Token.WriteTo(Serialized);
        if not (Serialized in ['true', 'false']) then
            Error(ErrorInfo.Create(StrSubstNo(MissingKeyErr, ParameterName)));
        exit(Token.AsValue().AsBoolean());
    end;

    /// <summary>Returns whether the caller has the inventory disposition capability.</summary>
    procedure IsEnabled(): Boolean
    var
        AccessCapability: Record "Quality Move Access ori";
    begin
        exit(AccessCapability.WritePermission());
    end;

    /// <summary>Returns the standard inspection table.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Qlty. Inspection Header");
    end;

    /// <summary>Describes the movement.</summary>
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
        KeywordsLbl: Label 'quality, disposition, move inventory, quarantine, failed quantity, passed quantity, reclassification', Comment = 'is-IS=gæði, ráðstöfun, flytja birgðir, sóttkví, fallið magn, staðist magn, endurflokkun';
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
        Parameter := ContractMgt.Parameter('method', 'string', true, 'Standard Microsoft disposition. automatic chooses item or warehouse reclassification.');
        AllowedValues.ReadFrom('["automatic","itemReclassification","warehouseReclassification","movementWorksheet","internalMovement"]');
        Parameter.Add('allowed', AllowedValues);
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('sourceLocationCode', 'string', false, 'Exact source location, up to 10 characters. No filter syntax. Omitted: Microsoft selects available inventory.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('sourceBinCode', 'string', false, 'Exact source bin, up to 20 characters. No filter syntax. Omitted: Microsoft selects available bins.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('destinationLocationCode', 'string', false, 'Target location, up to 10 characters. Supply at least this or destinationBinCode.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('destinationBinCode', 'string', false, 'Target bin, up to 20 characters. Standard location/bin validation applies.');
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('postImmediately', 'boolean', false, 'Post item or warehouse reclassification in the same atomic transaction. Worksheet and internal movement only prepare movements.');
        Parameter.Add('default', false);
        Parameters.Add(Parameter);
        Parameter := ContractMgt.Parameter('confirm', 'boolean', true, 'Must be true to authorize creation or posting of inventory movements.');
        Parameters.Add(Parameter);
        exit(true);
    end;

    /// <summary>Returns the response contract chapter.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    begin
        Response.ReadFrom('{"contentType":"application/json","fields":[{"name":"status","type":"string","description":"Success."},{"name":"inspectionSystemId","type":"string","description":"Selected inspection SystemId."},{"name":"inspectionNo","type":"string","description":"Inspection number."},{"name":"reinspectionNo","type":"integer","description":"Re-inspection number."},{"name":"method","type":"string","description":"Requested standard movement method."},{"name":"quantityBasis","type":"string","description":"failed or passed."},{"name":"posted","type":"boolean","description":"True only when immediate posting was requested and completed."}]}');
        exit(true);
    end;

    /// <summary>Returns the errors contract chapter.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    begin
        Errors.ReadFrom('[{"code":"UnknownParameter","when":"An unknown data key is sent.","fix":"Use only declared parameters."},{"error":"Business Central refusal","when":"Input, confirmation, permissions, stock, bin, inspection quantity or movement setup are invalid; standard validation or posting fails.","fix":"Correct the request, setup or permissions and retry. No movement from the failed call remains."}]');
        exit(true);
    end;

    /// <summary>Returns the effect contract chapter.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        Effect.ReadFrom('{"effect":"irreversible","changes":"Creates item reclassification lines, warehouse reclassification lines, internal movement documents or movement worksheet lines through the standard Qlty. Disposition implementation. Optional immediate posting creates inventory or warehouse entries. Standard Quality Management posting normally commits before each line; this wrapper binds standard posting with SetSuppressCommit(true), runs without a Boolean return and prohibits explicit commits for atomic rollback. Success commits once through the isolated wrapper. Omit Commit leaves the transaction to the caller.","idempotent":false,"permissionSet":"BIFROST QM Full ori","preconditions":["confirm=true.","Caller has Microsoft movement and inventory posting permissions.","Positive inspection Pass Quantity or Fail Quantity and sufficient visible inventory.","Microsoft movement journal batches, locations and bins are configured."]}');
        exit(true);
    end;

    /// <summary>Returns the examples contract chapter.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        Examples.ReadFrom('[{"title":"Prepare a failed-quantity item reclassification","request":{"type":"Quality.Disposition.MoveInventory","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001","quantityBasis":"failed","method":"itemReclassification","destinationLocationCode":"QUARANTINE","confirm":true,"expectedCount":1}},"response":{"status":"Success","inspectionSystemId":"00000000-0000-0000-0000-000000000001","inspectionNo":"QI00001","reinspectionNo":0,"method":"itemReclassification","quantityBasis":"failed","posted":false}}]');
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
        HelpLbl: Label 'Moves the failed or passed quantity of one quality inspection through standard Microsoft disposition. Choose item or warehouse reclassification, movement worksheet, internal movement or automatic reclassification. confirm=true is required.', Comment = 'is-IS=Flytur fallið eða staðist magn einnar gæðaskoðunar með staðlaðri ráðstöfun Microsoft. Veldu endurflokkun vöru eða vöruhúss, vinnublað flutnings, innri flutning eða sjálfvirka endurflokkun. confirm=true er nauðsynlegt.';
    begin
        Overview := HelpLbl;
        exit(true);
    end;

    /// <summary>Returns the translated notes help chapter.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    var
        HelpLbl: Label 'Not idempotent: repeating a successful call can create another movement. No direct business-field writes bypass Microsoft validation. Immediate posting is atomic across all selected lines; a refusal rolls back journal creation and posting. Internal movement and worksheet prepare only. Normal success commits the isolated transaction; with Omit Commit the caller owns the transaction.', Comment = 'is-IS=Ekki ídempótent: endurtekið heppnað kall getur stofnað annan flutning. Engin bein skrif í viðskiptareiti fara fram hjá staðfestingu Microsoft. Tafarlaus bókun er ein heild yfir allar valdar línur; höfnun bakfærir stofnun færslubókar og bókun. Innri flutningur og vinnublað undirbúa eingöngu. Venjuleg heppnuð keyrsla staðfestir einangraða færslu; með Omit Commit ber kallandi ábyrgð á færslunni.';
    begin
        Notes := HelpLbl;
        exit(true);
    end;
}
