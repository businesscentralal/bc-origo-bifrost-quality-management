namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;

/// <summary>Public dispatcher, discovery and bilingual contract for inspection picture replacement.</summary>
codeunit 10035295 "Quality Picture Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;

    /// <summary>Validates the envelope and runs the rollback boundary.</summary>
    /// <param name="Argument">Public dispatcher argument.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Processor: Codeunit "Quality Picture Proc ori";
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if Argument."Omit Commit" then
            Processor.Apply(Argument)
        else
            if not Codeunit.Run(Codeunit::"Quality Picture Proc ori", Argument) then
                Argument.RespondWithLastError();
    end;

    /// <summary>Always discoverable; execution checks the dedicated Full capability.</summary>
    /// <returns>True.</returns>
    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>Names the inspection header target.</summary>
    /// <returns>The inspection header table id.</returns>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Qlty. Inspection Header");
    end;

    /// <summary>Declares a write direction.</summary>
    /// <returns>Inbound.</returns>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Describes the picture operation in the caller language.</summary>
    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Replaces the most recent picture of one open quality inspection with JPEG, PNG or BMP bytes from base64 or an owned staged upload.', MaxLength = 250, Comment = 'is-IS=Skiptir út nýjustu mynd einnar opinnar gæðaskoðunar fyrir JPEG-, PNG- eða BMP-bæti úr base64 eða eigin sviðssettri upphleðslu.';
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Lists translated discovery search terms.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'quality, inspection, picture, photo, image, upload, evidence, staging', Comment = 'is-IS=gæði, skoðun, mynd, ljósmynd, myndskrá, upphleðsla, sönnun, sviðsetning';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Explains when to select the operation.</summary>
    procedure GetSelectionDescription(): Text
    begin
        exit(GetDescription());
    end;

    /// <summary>Provides the translated overview.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := GetDescription();
        exit(true);
    end;

    /// <summary>Provides the envelope contract chapter.</summary>
    /// <param name="Envelope">Contract chapter.</param>
    /// <returns>True when populated.</returns>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
    begin
        Subject.Add('use', 'notUsed');
        Subject.Add('description', TargetLbl);
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', true);
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'application/json');
        exit(true);
    end;

    /// <summary>Provides the target contract chapter.</summary>
    /// <param name="Target">Contract chapter.</param>
    /// <returns>True when populated.</returns>
    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Target.Add(Contract.TargetEntry('data.inspectionSystemId', 'GUID', IdentityLbl));
        exit(true);
    end;

    /// <summary>Provides the parameters contract chapter.</summary>
    /// <param name="Parameters">Contract chapter.</param>
    /// <returns>True when populated.</returns>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(Contract.Parameter('inspectionSystemId', 'string', true, IdentityLbl));
        Parameters.Add(Contract.Parameter('base64', 'string', false, Base64Lbl));
        Parameters.Add(Contract.Parameter('stagingId', 'string', false, StagingLbl));
        Parameters.Add(Contract.Parameter('fileName', 'string', false, FileLbl));
        Parameters.Add(Contract.Parameter('expectedCount', 'integer', false, CountLbl));
        exit(true);
    end;

    /// <summary>Provides the response contract chapter.</summary>
    /// <param name="Response">Contract chapter.</param>
    /// <returns>True when populated.</returns>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
    begin
        Fields.Add(Contract.ResponseField('status', 'string', 'Success'));
        Fields.Add(Contract.ResponseField('inspectionSystemId', 'string', IdentityLbl));
        Fields.Add(Contract.ResponseField('additionalHandlingApplied', 'boolean', HandlingLbl));
        Response.Add('contentType', 'application/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Provides the errors contract chapter.</summary>
    /// <param name="Errors">Contract chapter.</param>
    /// <returns>True when populated.</returns>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, ErrorsLbl, FixLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, ErrorsLbl, FixLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, ErrorsLbl, FixLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, ErrorsLbl, FixLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, ErrorsLbl, FixLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, ErrorsLbl, FixLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, ErrorsLbl, FixLbl));
        exit(true);
    end;

    /// <summary>Provides the effect contract chapter.</summary>
    /// <param name="Effect">Contract chapter.</param>
    /// <returns>True when populated.</returns>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
    begin
        Effect.Add('effect', 'write');
        Effect.Add('changes', ChangesLbl);
        Effect.Add('idempotent', false);
        Effect.Add('permissionSet', 'BIFROST QM Full ori');
        Preconditions.Add(PreconditionsLbl);
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    /// <summary>No additional metering chapter.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        Clear(Metering);
        exit(false);
    end;

    /// <summary>No additional related chapter.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        Clear(Related);
        exit(false);
    end;

    /// <summary>No additional workflow chapter.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        Clear(Workflow);
        exit(false);
    end;

    /// <summary>Provides the examples contract chapter.</summary>
    /// <param name="Examples">Contract chapter.</param>
    /// <returns>True when populated.</returns>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Examples.Add(Contract.Example(ExampleLbl, '{"type":"Quality.Inspection.AddPicture","data":{"inspectionSystemId":"<inspection-systemId>","stagingId":"<staging-systemId>","expectedCount":1}}', '{"status":"Success","inspectionSystemId":"<inspection-systemId>","additionalHandlingApplied":false}'));
        exit(true);
    end;

    /// <summary>Provides the notes contract chapter.</summary>
    /// <param name="Notes">Contract chapter.</param>
    /// <returns>True when populated.</returns>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := NotesLbl;
        exit(true);
    end;

    var
        TargetLbl: Label 'Use data.inspectionSystemId.', Comment = 'is-IS=Notaðu data.inspectionSystemId.';
        IdentityLbl: Label 'SystemId of an open quality inspection.', Comment = 'is-IS=SystemId opinnar gæðaskoðunar.';
        Base64Lbl: Label 'Exactly one of base64 and stagingId. JPEG, PNG or BMP bytes; maximum 1048576 decoded bytes (1 MiB). Format is detected from bytes, never the file name.', Comment = 'is-IS=Nákvæmlega annað af base64 og stagingId. JPEG-, PNG- eða BMP-bæti; að hámarki 1048576 afkóðuð bæti (1 MiB). Snið er greint úr bætum, aldrei skráarheiti.';
        StagingLbl: Label 'SystemId of an upload owned by this user in this company. Consumed on success; retained after every failure.', Comment = 'is-IS=SystemId upphleðslu í eigu þessa notanda í þessu fyrirtæki. Fjarlægð við árangur; varðveitt eftir sérhverja bilun.';
        FileLbl: Label 'Optional image name, 1 to 250 characters without path separators. A byte-detected image extension is appended. Default: inspection-picture.', Comment = 'is-IS=Valfrjálst myndheiti, 1 til 250 stafir án slóðaskilja. Viðskeyti greint úr bætum er bætt við. Sjálfgefið: inspection-picture.';
        CountLbl: Label 'Must equal 1 when supplied. Counts the one inspection, not its existing pictures.', Comment = 'is-IS=Verður að vera 1 ef sent. Telur eina skoðun, ekki myndir sem fyrir eru.';
        HandlingLbl: Label 'Always false. Native extra attachment and OneDrive handling is local/internal and is not called.', Comment = 'is-IS=Alltaf false. Staðlað viðbótarferli fyrir viðhengi og OneDrive er staðbundið/innra og er ekki kallað.';
        ErrorsLbl: Label 'Missing, invalid or unknown input; finished or unknown inspection; unavailable staged upload; missing Full or native modify permission. Refusals carry parameter, expected and nextStep.', Comment = 'is-IS=Inntak vantar, er ógilt eða óþekkt; lokin eða óþekkt skoðun; sviðssett upphleðsla ekki tiltæk; Full eða staðlaðar breytingaheimildir vantar. Höfnun inniheldur parameter, expected og nextStep.';
        FixLbl: Label 'Correct the parameter or permission and retry. Failed calls preserve the old picture and staged upload.', Comment = 'is-IS=Leiðréttu færibreytu eða heimild og reyndu aftur. Misheppnuð köll varðveita fyrri mynd og sviðsetta upphleðslu.';
        ChangesLbl: Label 'Replaces Most Recent Picture using Media.ImportStream. Earlier pictures are not retained. No camera, file dialog, attachment or OneDrive handling. No external call.', Comment = 'is-IS=Skiptir út Most Recent Picture með Media.ImportStream. Fyrri myndir eru ekki varðveittar. Engin myndavél, skráargluggi, viðhengi eða OneDrive-vinnsla. Engin ytri köll.';
        PreconditionsLbl: Label 'Open inspection, BIFROST QM Full ori and native inspection modify permission.', Comment = 'is-IS=Opin skoðun, BIFROST QM Full ori og staðlaðar breytingaheimildir á skoðun.';
        ExampleLbl: Label 'Attach an inspection picture', Comment = 'is-IS=Bæta mynd við skoðun';
        NotesLbl: Label 'The maximum image size is 1 MiB (1048576 bytes). Exactly one of base64 and stagingId is required. The public staging Take API consumes in the same transaction; all failures raise and roll back staging and media changes. In omit-commit mode the caller owns rollback and commit. Repeating a base64 call creates replacement media, so it is not idempotent. A staged upload can succeed only once. Unknown or foreign staging identifiers have the same refusal. Additional handling is unavailable through public Quality Management APIs; additionalHandlingApplied is false.', Comment = 'is-IS=Hámarksstærð myndar er 1 MiB (1048576 bæti). Nákvæmlega annað af base64 og stagingId er áskilið. Opinbera Take-viðmótið fjarlægir sviðsetningu í sömu færslu; allar bilanir valda villu og bakfæra sviðsetningu og myndbreytingar. Í ham án staðfestingar ber kallandi ábyrgð á bakfærslu og staðfestingu. Endurtekið base64-kall býr til nýja mynd og er því ekki ídempotent. Sviðssett upphleðsla getur aðeins tekist einu sinni. Óþekkt auðkenni sviðsetningar og auðkenni í eigu annarra fá sömu höfnun. Viðbótarferli er ekki tiltækt í opinberum gæðastjórnunarviðmótum; additionalHandlingApplied er false.';
}
