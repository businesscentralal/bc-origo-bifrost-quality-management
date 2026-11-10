namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Document;

/// <summary>Supplies an optional template through Microsoft's standard creation event for this invocation only.</summary>
codeunit 10035251 "Quality Create Context ori"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        SourceRecordId: RecordId;
        TemplateCode: Code[20];

    /// <summary>Scopes the template override to the source selected by this request.</summary>
    procedure Initialize(SourceId: RecordId; RequestedTemplate: Code[20])
    begin
        SourceRecordId := SourceId;
        TemplateCode := RequestedTemplate;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Inspection - Create", OnBeforeCreateInspection, '', false, false)]
    local procedure SelectTemplate(var TargetRecordRef: RecordRef; var IsManualCreation: Boolean; var OptionalSpecificTemplate: Code[20]; var IsHandled: Boolean; var OptionalRec2Variant: Variant; var OptionalRec3Variant: Variant)
    begin
        if (TargetRecordRef.RecordId() = SourceRecordId) and (TemplateCode <> '') then
            OptionalSpecificTemplate := TemplateCode;
    end;
}
