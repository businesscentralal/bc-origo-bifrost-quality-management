namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;

/// <summary>Runs the native action in a transaction that rolls back on a business refusal.</summary>
codeunit 10035243 "Quality Reinspect Proc ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        CancelledErr: Label 'No re-inspection was created. The operation was cancelled.', Comment = 'is-IS=Engin endurskoðun var stofnuð. Hætt var við aðgerðina.';

    trigger OnRun()
    var
        Inspection: Record "Qlty. Inspection Header";
        Reinspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        InspectionId: Guid;
        Response: JsonObject;
        Result: JsonObject;
        Results: JsonArray;
    begin
        Request := Rec.GetRequestJson();
        Evaluate(InspectionId, Request.GetText('inspectionSystemId'));
        Inspection.GetBySystemId(InspectionId);
        CreateReinspection(Inspection, Reinspection);
        if IsNullGuid(Reinspection.SystemId) then
            Error(ErrorInfo.Create(CancelledErr));
        Result.Add('systemId', Format(Reinspection.SystemId, 0, 4));
        Result.Add('inspectionNo', Reinspection."No.");
        Result.Add('reinspectionNo', Reinspection."Re-inspection No.");
        Result.Add('sourceSystemId', Request.GetText('inspectionSystemId'));
        Results.Add(Result);
        Response.Add('status', 'Success');
        Response.Add('noOfRecords', 1);
        Response.Add('result', Results);
        Rec.SetResponseJson(Response);
        Rec."Content Type" := Rec.GetContentTypeJson();
    end;

    // The page's Commit follows this table method. Reject subscriber commits too,
    // so a native validation failure cannot leave a finished source or partial revision.
    [CommitBehavior(CommitBehavior::Error)]
    local procedure CreateReinspection(var Inspection: Record "Qlty. Inspection Header"; var Reinspection: Record "Qlty. Inspection Header")
    begin
        Inspection.CreateReinspection(Reinspection);
    end;
}
