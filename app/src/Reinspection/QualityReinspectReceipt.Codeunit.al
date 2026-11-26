namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Document;

/// <summary>Captures the native reinspection created during one manually bound action.</summary>
codeunit 10035324 "Quality Reinspect Receipt ori"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        CreatedInspection: Record "Qlty. Inspection Header";
        SourceNo: Code[20];

    /// <summary>Limits the receipt to the requested inspection number.</summary>
    internal procedure SetSource(InspectionNo: Code[20])
    begin
        SourceNo := InspectionNo;
        Clear(CreatedInspection);
    end;

    /// <summary>Returns the record supplied by Microsoft's creation event, or an empty record on cancellation.</summary>
    internal procedure GetCreated(var Inspection: Record "Qlty. Inspection Header")
    begin
        Inspection := CreatedInspection;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Inspection - Create", 'OnAfterCreateReinspection', '', false, false)]
    local procedure CaptureCreated(var FromThisQltyInspectionHeader: Record "Qlty. Inspection Header"; var CreatedReQltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
        if FromThisQltyInspectionHeader."No." = SourceNo then
            CreatedInspection := CreatedReQltyInspectionHeader;
    end;
}
