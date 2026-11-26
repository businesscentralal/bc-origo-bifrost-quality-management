namespace Origo.Bifrost.QualityManagement;

using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Origo.Bifrost;

/// <summary>
/// Copies one inspection template with all its lines to a new template code through Microsoft's
/// Qlty. Inspection Copy Template report (single-copy path). The target must not exist.
/// </summary>
codeunit 10035315 "Quality Copy Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    trigger OnRun()
    begin
        PerformCopy(Rec);
    end;

    var
        SourceKeyTok: Label 'sourceTemplateCode', Locked = true;
        TargetKeyTok: Label 'targetTemplateCode', Locked = true;
        DescriptionKeyTok: Label 'targetDescription', Locked = true;
        ExpectedCountKeyTok: Label 'expectedCount', Locked = true;
        DescriptionLbl: Label 'Copies one quality inspection template with all its lines and result conditions to a new template code through the standard Copy Template report.', MaxLength = 250, Comment = 'is-IS=Afritar eitt gæðaskoðunarsniðmát með öllum línum þess og niðurstöðuskilyrðum í nýjan sniðmátskóða með staðlaðri skýrslunni Afrita sniðmát.';
        KeywordsLbl: Label 'copy template, inspection template, duplicate template, quality template, template lines', Comment = 'is-IS=afrita sniðmát, skoðunarsniðmát, tvöfalda sniðmát, gæðasniðmát, sniðmátslínur';
        PermissionErr: Label 'You need BIFROST QM Full ori to copy an inspection template.', Comment = 'is-IS=Þú þarft BIFROST QM Full ori til að afrita skoðunarsniðmát.';
        PermissionNextTxt: Label 'Ask an administrator for the Bifrost Quality Full role.', Comment = 'is-IS=Biddu stjórnanda um hlutverkið Bifrost Quality Full.';
        NativePermissionErr: Label 'You need permission to insert quality inspection templates, template lines and result conditions.', Comment = 'is-IS=Þú þarft heimild til að stofna gæðaskoðunarsniðmát, sniðmátslínur og niðurstöðuskilyrði.';
        NativePermissionNextTxt: Label 'Ask an administrator for the QltyMgmt - Admin permission set.', Comment = 'is-IS=Biddu stjórnanda um heimildasafnið QltyMgmt - Admin.';
        MissingErr: Label 'The parameter %1 is required.', Comment = '%1 = parameter name, is-IS=Færibreytan %1 er áskilin.';
        InvalidTextErr: Label 'The parameter %1 must be a text value.', Comment = '%1 = parameter name, is-IS=Færibreytan %1 verður að vera textagildi.';
        TooLongErr: Label 'The parameter %1 is longer than %2 characters. Nothing was changed.', Comment = '%1 = parameter name, %2 = maximum length, is-IS=Færibreytan %1 er lengri en %2 stafir. Engu var breytt.';
        UnknownKeyErr: Label 'Unknown parameter %1. Nothing was changed.', Comment = '%1 = parameter name, is-IS=Óþekkt færibreyta %1. Engu var breytt.';
        SameCodeErr: Label 'targetTemplateCode must differ from sourceTemplateCode. Nothing was changed.', Comment = 'is-IS=targetTemplateCode verður að vera annar en sourceTemplateCode. Engu var breytt.';
        SourceNotFoundErr: Label 'The inspection template %1 does not exist. Nothing was changed.', Comment = '%1 = template code, is-IS=Skoðunarsniðmátið %1 er ekki til. Engu var breytt.';
        TargetExistsErr: Label 'The inspection template %1 already exists. This type only creates a new template; nothing was changed.', Comment = '%1 = template code, is-IS=Skoðunarsniðmátið %1 er þegar til. Þessi tegund stofnar aðeins nýtt sniðmát; engu var breytt.';
        DescriptionRequiredErr: Label 'The source template has no description, so targetDescription is required. Nothing was changed.', Comment = 'is-IS=Upprunasniðmátið hefur enga lýsingu og því er targetDescription áskilið. Engu var breytt.';
        NotCopiedErr: Label 'Business Central did not create the template %1. Nothing was changed.', Comment = '%1 = template code, is-IS=Business Central stofnaði ekki sniðmátið %1. Engu var breytt.';
        CodeExpectedTxt: Label 'a template code of at most 20 characters', Comment = 'is-IS=sniðmátskóði sem er í mesta lagi 20 stafir';
        DescriptionExpectedTxt: Label 'a description of at most 100 characters', Comment = 'is-IS=lýsing sem er í mesta lagi 100 stafir';
        NewCodeExpectedTxt: Label 'a template code that does not exist yet', Comment = 'is-IS=sniðmátskóði sem er ekki til enn';
        AllowedKeysTxt: Label 'sourceTemplateCode, targetTemplateCode, targetDescription, expectedCount', Comment = 'is-IS=sourceTemplateCode, targetTemplateCode, targetDescription, expectedCount';
        FindTemplateTxt: Label 'Read the template codes with Data.Records.Get on Qlty. Inspection Template Hdr.', Comment = 'is-IS=Lestu sniðmátskóðana með Data.Records.Get á Qlty. Inspection Template Hdr.';
        FixParameterTxt: Label 'Correct the parameter and send the request again.', Comment = 'is-IS=Leiðréttu færibreytuna og sendu beiðnina aftur.';
        ChooseNewCodeTxt: Label 'Choose a target code that does not exist. To change an existing template, use Data.Records.Set or the Quality Inspection Template page.', Comment = 'is-IS=Veldu markkóða sem er ekki til. Til að breyta sniðmáti sem er til skaltu nota Data.Records.Set eða síðuna Gæðaskoðunarsniðmát.';
        AddDescriptionTxt: Label 'Send targetDescription.', Comment = 'is-IS=Sendu targetDescription.';
        CheckTemplateTxt: Label 'Check the source template and try again.', Comment = 'is-IS=Athugaðu upprunasniðmátið og reyndu aftur.';
        ConfirmSummaryTxt: Label 'one new inspection template %1 with %2 lines copied from %3', Comment = '%1 = target code, %2 = line count, %3 = source code, is-IS=eitt nýtt skoðunarsniðmát %1 með %2 línum afritað úr %3';
        OverviewLbl: Label 'Copies one quality inspection template with all its lines and result conditions to a new template code in one call. It runs the standard Copy Template report on its single-copy path, so every line keeps its test and conditions and both header and lines show the source in Copied From Template Code. It creates a new template only: an existing target code is refused, and no template or line is changed or removed.', Comment = 'is-IS=Afritar eitt gæðaskoðunarsniðmát með öllum línum þess og niðurstöðuskilyrðum í nýjan sniðmátskóða í einu kalli. Það keyrir staðlaðu skýrsluna Afrita sniðmát á leið stakrar afritunar, svo hver lína heldur prófun sinni og skilyrðum og bæði haus og línur sýna upprunann í Afritað úr sniðmátskóða. Það stofnar aðeins nýtt sniðmát: markkóða sem er til er hafnað og engu sniðmáti eða línu er breytt eða þeim eytt.';
        NotesLbl: Label 'Effect: inserts one template header, its lines and their result conditions. Not idempotent: a second call with the same target is refused because the target then exists, and nothing changes. All input checks run before any change. expectedCount counts the one new template (always 1). With Require Confirmation for Irreversible Messages enabled, a call without expectedCount returns the count and changes nothing. There is no Commit on the standard path: a refusal or error rolls back the whole copy. In omit-commit mode the caller owns rollback. Copying from items (bulk copy) and merging into an existing template are not supported.', Comment = 'is-IS=Áhrif: stofnar einn sniðmátshaus, línur hans og niðurstöðuskilyrði þeirra. Ekki ídempotent: öðru kalli með sama mark er hafnað því markið er þá til, og engu er breytt. Allar inntaksathuganir keyra áður en nokkru er breytt. expectedCount telur eina nýja sniðmátið (alltaf 1). Þegar Krefjast staðfestingar fyrir óafturkræf skilaboð er virkt skilar kall án expectedCount fjöldanum og breytir engu. Ekkert Commit er á staðlaðri leið: höfnun eða villa bakfærir alla afritunina. Í ham án staðfestingar ber kallandi ábyrgð á bakfærslu. Afritun úr vörum (fjöldaafritun) og sameining við sniðmát sem er til eru ekki studdar.';
        ChangesLbl: Label 'Runs report Qlty. Inspection Copy Template (20402) with Create from Item Nos. off. It inserts the target template header with the source settings, every source line with the same Line No., Test Code and values, and the result conditions of every line. Header and lines get Copied From Template Code = the source code. The source template is not changed.', Comment = 'is-IS=Keyrir skýrsluna Qlty. Inspection Copy Template (20402) með Stofna úr vörunúmerum óvirkt. Hún stofnar markhaus sniðmátsins með stillingum upprunans, hverja upprunalínu með sama línunúmeri, prófunarkóða og gildum, og niðurstöðuskilyrði hverrar línu. Haus og línur fá Afritað úr sniðmátskóða = upprunakóðann. Upprunasniðmátinu er ekki breytt.';
        SourcePreconditionLbl: Label 'The source template exists.', Comment = 'is-IS=Upprunasniðmátið er til.';
        TargetPreconditionLbl: Label 'The target template code does not exist.', Comment = 'is-IS=Marksniðmátskóðinn er ekki til.';
        PermissionPreconditionLbl: Label 'The caller has BIFROST QM Full ori and native insert permission on the template header, line and result condition tables.', Comment = 'is-IS=Kallandi hefur BIFROST QM Full ori og innbyggða heimild til að stofna í töflum sniðmátshauss, sniðmátslína og niðurstöðuskilyrða.';
        NativeRefusalTxt: Label 'Standard Quality Management refused the copy. The translated message is returned and no header or line remains.', Comment = 'is-IS=Stöðluð gæðastjórnun hafnaði afrituninni. Þýdd skilaboð eru send til baka og enginn haus eða lína situr eftir.';

    /// <summary>Offers this action only to callers who can write the app permission marker.</summary>
    /// <returns>True when the caller has the app write grant.</returns>
    procedure IsEnabled(): Boolean
    var
        AccessMarker: Record "Quality Copy Access ori";
    begin
        exit(AccessMarker.WritePermission());
    end;

    /// <summary>Identifies the template header table this action creates rows in.</summary>
    /// <returns>The inspection template header table number.</returns>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Qlty. Inspection Template Hdr.");
    end;

    /// <summary>Describes the copy action.</summary>
    /// <returns>A short description of the action.</returns>
    procedure GetDescription(): Text[250]
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides translated discovery terms.</summary>
    /// <returns>Comma-separated search terms.</returns>
    procedure GetKeywords(): Text
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Explains when to select the action.</summary>
    /// <returns>The same text as the description.</returns>
    procedure GetSelectionDescription(): Text
    begin
        exit(GetDescription());
    end;

    /// <summary>Declares the inbound action direction.</summary>
    /// <returns>Inbound.</returns>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Validates the whole request and the count confirmation, then copies in its own transaction.</summary>
    /// <param name="Argument">Foundation request and response.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        SourceLine: Record "Qlty. Inspection Template Line";
        ConfirmGate: Codeunit "Confirm Gate ori";
        SourceCode: Code[20];
        TargetCode: Code[20];
        TargetDescription: Text[100];
    begin
        Argument.AssertIsLicensed();
        Argument.AssertVersion1();
        if not IsEnabled() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PermissionDenied, PermissionErr, '', '', 'BIFROST QM Full ori', PermissionNextTxt);
            exit;
        end;
        if not ReadRequest(Argument, SourceCode, TargetCode, TargetDescription) then
            exit;
        if not CheckTemplates(Argument, SourceCode, TargetCode, TargetDescription) then
            exit;
        if not HasNativePermissions() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PermissionDenied, NativePermissionErr, '', '', 'QltyMgmt - Admin', NativePermissionNextTxt);
            exit;
        end;
        SourceLine.SetRange("Template Code", SourceCode);
        if not ConfirmGate.Confirm(Argument, 1, StrSubstNo(ConfirmSummaryTxt, TargetCode, SourceLine.Count(), SourceCode)) then
            exit;
        if Argument."Omit Commit" then
            Codeunit.Run(Codeunit::"Quality Copy Impl ori", Argument)
        else
            if not Codeunit.Run(Codeunit::"Quality Copy Impl ori", Argument) then
                Argument.RespondWithLastError();
    end;

    /// <summary>Runs the standard report and writes the response. Subscriber commits are rejected so a failure leaves no partial template.</summary>
    /// <param name="Argument">Foundation request and response.</param>
    [CommitBehavior(CommitBehavior::Error)]
    local procedure PerformCopy(var Argument: Record "Message Argument ori")
    var
        TargetTemplate: Record "Qlty. Inspection Template Hdr.";
        TargetLine: Record "Qlty. Inspection Template Line";
        Response: JsonObject;
        Result: JsonObject;
        Results: JsonArray;
        SourceCode: Code[20];
        TargetCode: Code[20];
        TargetDescription: Text[100];
    begin
        // The request was validated before this transaction; a refusal here already wrote its typed response.
        if not ReadRequest(Argument, SourceCode, TargetCode, TargetDescription) then
            exit;
        TargetTemplate.ReadIsolation := IsolationLevel::UpdLock;
        TargetTemplate.SetRange(Code, TargetCode);
        if not TargetTemplate.IsEmpty() then
            Error(ErrorInfo.Create(StrSubstNo(TargetExistsErr, TargetCode)));
        if TargetDescription = '' then
            TargetDescription := SourceDescription(SourceCode);
        Report.Execute(Report::"Qlty. Inspection Copy Template", BuildRequestParameters(SourceCode, TargetCode, TargetDescription));
        TargetTemplate.Reset();
        TargetTemplate.ReadIsolation := IsolationLevel::Default;
        TargetTemplate.SetLoadFields(Code, Description, "Copied From Template Code");
        if not TargetTemplate.Get(TargetCode) then
            Error(ErrorInfo.Create(StrSubstNo(NotCopiedErr, TargetCode)));
        TargetLine.SetRange("Template Code", TargetCode);
        Result.Add('templateCode', TargetTemplate.Code);
        Result.Add('description', TargetTemplate.Description);
        Result.Add('copiedFromTemplateCode', TargetTemplate."Copied From Template Code");
        Result.Add('linesCopied', TargetLine.Count());
        Results.Add(Result);
        Response.Add('status', 'Success');
        Response.Add('noOfRecords', 1);
        Response.Add('result', Results);
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure ReadRequest(var Argument: Record "Message Argument ori"; var SourceCode: Code[20]; var TargetCode: Code[20]; var TargetDescription: Text[100]): Boolean
    var
        Request: JsonObject;
        KeyName: Text;
        Value: Text;
    begin
        Request := Argument.GetRequestJson();
        foreach KeyName in Request.Keys() do
            if not (KeyName in [SourceKeyTok, TargetKeyTok, DescriptionKeyTok, ExpectedCountKeyTok]) then begin
                Argument.RespondWithError("Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, KeyName), KeyName, '', AllowedKeysTxt, FixParameterTxt);
                exit(false);
            end;
        if not ReadText(Argument, Request, SourceKeyTok, true, MaxStrLen(SourceCode), CodeExpectedTxt, Value) then
            exit(false);
        SourceCode := CopyStr(Value, 1, MaxStrLen(SourceCode));
        if not ReadText(Argument, Request, TargetKeyTok, true, MaxStrLen(TargetCode), CodeExpectedTxt, Value) then
            exit(false);
        TargetCode := CopyStr(Value, 1, MaxStrLen(TargetCode));
        if not ReadText(Argument, Request, DescriptionKeyTok, false, MaxStrLen(TargetDescription), DescriptionExpectedTxt, Value) then
            exit(false);
        TargetDescription := CopyStr(Value, 1, MaxStrLen(TargetDescription));
        if SourceCode = TargetCode then begin
            Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameter, SameCodeErr, TargetKeyTok, TargetCode, NewCodeExpectedTxt, ChooseNewCodeTxt);
            exit(false);
        end;
        exit(true);
    end;

    local procedure ReadText(var Argument: Record "Message Argument ori"; Request: JsonObject; KeyName: Text; Required: Boolean; MaxLength: Integer; ExpectedTxt: Text; var Value: Text): Boolean
    var
        Token: JsonToken;
    begin
        Value := '';
        if Request.Get(KeyName, Token) then
            if Token.IsValue() then
                if Token.AsValue().IsNull() or Token.AsValue().IsUndefined() then
                    Clear(Token);
        if Token.IsValue() then begin
            if not IsJsonString(Token) then begin
                Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidTextErr, KeyName), KeyName, '', ExpectedTxt, FixParameterTxt);
                exit(false);
            end;
            Value := Token.AsValue().AsText().Trim();
        end else
            if Request.Contains(KeyName) and not IsNullToken(Request, KeyName) then begin
                Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidTextErr, KeyName), KeyName, '', ExpectedTxt, FixParameterTxt);
                exit(false);
            end;
        if StrLen(Value) > MaxLength then begin
            Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(TooLongErr, KeyName, MaxLength), KeyName, CopyStr(Value, 1, 250), ExpectedTxt, FixParameterTxt);
            exit(false);
        end;
        if Required and (Value = '') then begin
            Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingErr, KeyName), KeyName, '', ExpectedTxt, FindTemplateTxt);
            exit(false);
        end;
        exit(true);
    end;

    local procedure IsJsonString(Token: JsonToken): Boolean
    var
        Serialized: Text;
    begin
        Token.WriteTo(Serialized);
        exit(CopyStr(Serialized, 1, 1) = '"');
    end;

    local procedure IsNullToken(Request: JsonObject; KeyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        Request.Get(KeyName, Token);
        if Token.IsValue() then
            exit(Token.AsValue().IsNull() or Token.AsValue().IsUndefined());
        exit(false);
    end;

    local procedure CheckTemplates(var Argument: Record "Message Argument ori"; SourceCode: Code[20]; TargetCode: Code[20]; TargetDescription: Text[100]): Boolean
    var
        InspTemplate: Record "Qlty. Inspection Template Hdr.";
    begin
        if not InspTemplate.ReadPermission() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PermissionDenied, NativePermissionErr, '', '', 'QltyMgmt - Admin', NativePermissionNextTxt);
            exit(false);
        end;
        InspTemplate.SetRange(Code, SourceCode);
        if InspTemplate.IsEmpty() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::RecordNotFound, StrSubstNo(SourceNotFoundErr, SourceCode), SourceKeyTok, SourceCode, CodeExpectedTxt, FindTemplateTxt);
            exit(false);
        end;
        InspTemplate.SetRange(Code, TargetCode);
        if not InspTemplate.IsEmpty() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(TargetExistsErr, TargetCode), TargetKeyTok, TargetCode, NewCodeExpectedTxt, ChooseNewCodeTxt);
            exit(false);
        end;
        if (TargetDescription = '') and (SourceDescription(SourceCode) = '') then begin
            Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, DescriptionRequiredErr, DescriptionKeyTok, '', DescriptionExpectedTxt, AddDescriptionTxt);
            exit(false);
        end;
        exit(true);
    end;

    local procedure SourceDescription(SourceCode: Code[20]): Text[100]
    var
        InspTemplate: Record "Qlty. Inspection Template Hdr.";
    begin
        InspTemplate.SetLoadFields(Description);
        if InspTemplate.Get(SourceCode) then
            exit(InspTemplate.Description);
        exit('');
    end;

    local procedure HasNativePermissions(): Boolean
    var
        InspTemplate: Record "Qlty. Inspection Template Hdr.";
        InspTemplateLine: Record "Qlty. Inspection Template Line";
        Condition: Record "Qlty. I. Result Condit. Conf.";
    begin
        exit(InspTemplate.WritePermission() and InspTemplateLine.WritePermission() and Condition.WritePermission());
    end;

    /// <summary>Builds the request page parameters of report 20402 for the single-copy path.</summary>
    /// <param name="SourceCode">The template to copy from.</param>
    /// <param name="TargetCode">The new template code.</param>
    /// <param name="TargetDescription">The new template description.</param>
    /// <returns>The report parameter XML.</returns>
    local procedure BuildRequestParameters(SourceCode: Code[20]; TargetCode: Code[20]; TargetDescription: Text[100]): Text
    var
        SourceTemplate: Record "Qlty. Inspection Template Hdr.";
        NoItem: Record Item;
        Document: XmlDocument;
        Root: XmlElement;
        Options: XmlElement;
        DataItems: XmlElement;
        Result: Text;
    begin
        SourceTemplate.SetRange(Code, SourceCode);
        // The item data item only matters for bulk copy. An empty item number never exists, so the report reads no items.
        NoItem.SetRange("No.", '');
        Document := XmlDocument.Create();
        Document.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
        Root := XmlElement.Create('ReportParameters');
        Root.SetAttribute('name', 'Qlty. Inspection Copy Template');
        Root.SetAttribute('id', Format(Report::"Qlty. Inspection Copy Template", 0, 9));
        Options := XmlElement.Create('Options');
        Options.Add(OptionField('CreateFromItems', 'false'));
        Options.Add(OptionField('TargetDestinationName', TargetCode));
        Options.Add(OptionField('Description', TargetDescription));
        Root.Add(Options);
        DataItems := XmlElement.Create('DataItems');
        DataItems.Add(DataItemView('CurrentTemplate', SourceTemplate.GetView(false)));
        DataItems.Add(DataItemView('CurrentItem', NoItem.GetView(false)));
        Root.Add(DataItems);
        Document.Add(Root);
        Document.WriteTo(Result);
        exit(Result);
    end;

    local procedure OptionField(FieldName: Text; FieldValue: Text): XmlElement
    var
        Field: XmlElement;
    begin
        Field := XmlElement.Create('Field');
        Field.SetAttribute('name', FieldName);
        Field.Add(XmlText.Create(FieldValue));
        exit(Field);
    end;

    local procedure DataItemView(DataItemName: Text; View: Text): XmlElement
    var
        DataItem: XmlElement;
    begin
        DataItem := XmlElement.Create('DataItem');
        DataItem.SetAttribute('name', DataItemName);
        DataItem.Add(XmlText.Create(View));
        exit(DataItem);
    end;

    /// <summary>Declares the request envelope.</summary>
    /// <param name="Envelope">Envelope chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
    begin
        Subject.Add('use', 'notUsed');
        Subject.Add('description', 'Use data.sourceTemplateCode and data.targetTemplateCode.');
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', true);
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'application/json');
        exit(true);
    end;

    /// <summary>Documents the template identities.</summary>
    /// <param name="Target">Target chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Target.Add(Contract.TargetEntry('data.sourceTemplateCode', 'Code[20]', 'Code of the Qlty. Inspection Template Hdr. to copy from.'));
        Target.Add(Contract.TargetEntry('data.targetTemplateCode', 'Code[20]', 'Code of the new Qlty. Inspection Template Hdr. It must not exist.'));
        exit(true);
    end;

    /// <summary>Lists every accepted request key.</summary>
    /// <param name="Parameters">Parameter chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(Contract.Parameter('sourceTemplateCode', 'string', true, 'Code of an existing inspection template, at most 20 characters.'));
        Parameters.Add(Contract.Parameter('targetTemplateCode', 'string', true, 'New template code, at most 20 characters. It must not exist and must differ from sourceTemplateCode.'));
        Parameters.Add(Contract.Parameter('targetDescription', 'string', false, 'Description of the new template, at most 100 characters. Defaults to the source description; required when the source has none.'));
        Parameters.Add(Contract.Parameter('expectedCount', 'integer', false, 'Counts the one new template, so 1. Any other value is refused before any change. With Require Confirmation for Irreversible Messages enabled, omit it to preview the count without a change. Unknown keys are refused before execution.'));
        exit(true);
    end;

    /// <summary>Describes the success payload.</summary>
    /// <param name="Response">Response chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
    begin
        Fields.Add(Contract.ResponseField('status', 'string', 'Success'));
        Fields.Add(Contract.ResponseField('noOfRecords', 'integer', 'Always 1 on success: the one new template.'));
        Fields.Add(Contract.ResponseField('result', 'array', 'One record with templateCode, description, copiedFromTemplateCode and linesCopied (the number of lines of the new template).'));
        Response.Add('contentType', 'application/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Documents validation, access, confirmation and native refusals.</summary>
    /// <param name="Errors">Error chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingErr, '<parameter>'), FindTemplateTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, DescriptionRequiredErr, AddDescriptionTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(TooLongErr, '<parameter>', '<limit>'), FixParameterTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, SameCodeErr, ChooseNewCodeTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, '<parameter>'), FixParameterTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, StrSubstNo(SourceNotFoundErr, '<sourceTemplateCode>'), FindTemplateTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(TargetExistsErr, '<targetTemplateCode>'), ChooseNewCodeTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, PermissionErr, PermissionNextTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, NativePermissionErr, NativePermissionNextTxt));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, NativeRefusalTxt, CheckTemplateTxt));
        exit(true);
    end;

    /// <summary>Documents the standard copy path, including the absence of Commit.</summary>
    /// <param name="Effect">Effect chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
    begin
        Preconditions.Add(SourcePreconditionLbl);
        Preconditions.Add(TargetPreconditionLbl);
        Preconditions.Add(PermissionPreconditionLbl);
        Effect.Add('effect', 'write');
        Effect.Add('changes', ChangesLbl);
        Effect.Add('idempotent', false);
        Effect.Add('permissionSet', 'BIFROST QM Full ori');
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    /// <summary>No additional app metering.</summary>
    /// <param name="Metering">Unused metering chapter.</param>
    /// <returns>False. This type adds no metering chapter.</returns>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        Clear(Metering);
        exit(false);
    end;

    /// <summary>No related operation is required.</summary>
    /// <param name="Related">Unused related chapter.</param>
    /// <returns>False. This type adds no related chapter.</returns>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        Clear(Related);
        exit(false);
    end;

    /// <summary>No extra workflow chapter.</summary>
    /// <param name="Workflow">Unused workflow chapter.</param>
    /// <returns>False. This type adds no workflow chapter.</returns>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        Clear(Workflow);
        exit(false);
    end;

    /// <summary>Provides an executable request shape.</summary>
    /// <param name="Examples">Example chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Examples.Add(Contract.Example('Copy a template to a new code', '{"type":"Quality.Template.Copy","data":{"sourceTemplateCode":"INCOMING","targetTemplateCode":"INCOMING-V2","targetDescription":"Incoming goods, version 2","expectedCount":1}}', '{"status":"Success","noOfRecords":1,"result":[{"templateCode":"INCOMING-V2","description":"Incoming goods, version 2","copiedFromTemplateCode":"INCOMING","linesCopied":4}]}'));
        exit(true);
    end;

    /// <summary>Provides the help overview.</summary>
    /// <param name="Overview">Overview text.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := OverviewLbl;
        exit(true);
    end;

    /// <summary>Explains effect, idempotency, confirmation and transaction behaviour.</summary>
    /// <param name="Notes">Notes text.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := NotesLbl;
        exit(true);
    end;
}
