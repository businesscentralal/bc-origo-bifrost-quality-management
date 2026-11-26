namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Configuration;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Setup;

/// <summary>Initializes test setup through Microsoft's public page and supplies missing test result defaults.</summary>
codeunit 97255 "Quality Setup Library ori"
{
    /// <summary>Preserves existing setup and results; opens the native setup page only when setup is absent.</summary>
    procedure Initialize()
    var
        QualitySetup: Record "Qlty. Management Setup";
        Configure: Codeunit "Qlty. Auto Configure";
        SetupPage: TestPage "Qlty. Management Setup";
    begin
        if not QualitySetup.Get() then begin
            SetupPage.OpenEdit();
            SetupPage.Close();
        end;
        EnsureResult(Configure.GetDefaultInProgressResult(), Configure.GetDefaultInProgressResultDescription(), 0, false);
        EnsureResult(Configure.GetDefaultFailResult(), Configure.GetDefaultFailResultDescription(), 1, true);
        EnsureResult(Configure.GetDefaultPassResult(), Configure.GetDefaultPassResultDescription(), 2, true);
    end;

    local procedure EnsureResult(ResultName: Text; ResultDescription: Text; EvaluationOrder: Integer; AllowFinish: Boolean)
    var
        InspectionResult: Record "Qlty. Inspection Result";
    begin
        if InspectionResult.Get(CopyStr(ResultName, 1, MaxStrLen(InspectionResult.Code))) then
            exit;
        InspectionResult.Code := CopyStr(ResultName, 1, MaxStrLen(InspectionResult.Code));
        InspectionResult.Description := CopyStr(ResultDescription, 1, MaxStrLen(InspectionResult.Description));
        InspectionResult."Evaluation Sequence" := EvaluationOrder;
        if AllowFinish then
            InspectionResult."Finish Allowed" := InspectionResult."Finish Allowed"::"Allow Finish"
        else
            InspectionResult."Finish Allowed" := InspectionResult."Finish Allowed"::"Do Not Allow Finish";
        InspectionResult.Insert(true);
    end;
}
