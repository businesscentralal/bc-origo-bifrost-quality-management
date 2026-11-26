namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Reports;
using Origo.Bifrost;
using System.Utilities;

/// <summary>
/// Renders one inspection report as a PDF and stages it through the Foundation staging façade.
/// The caller restores the session language and handles errors; nothing but the staging row is written.
/// </summary>
codeunit 10035332 "Quality Report Proc ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        TooLargeErr: Label 'The rendered report is %1 bytes, which is over the limit of %2 bytes. Nothing was staged.', Comment = '%1 = rendered size, %2 = limit, is-IS=Skýrslan er %1 bæti sem er yfir mörkunum %2 bæti. Engu var komið fyrir í biðsvæði.';
        TooLargeExpectedTxt: Label 'a rendered report of at most 10485760 bytes', Comment = 'is-IS=skýrsla sem er í mesta lagi 10485760 bæti';
        TooLargeNextTxt: Label 'Print a smaller inspection, or read the data with Data.Records.Get.', Comment = 'is-IS=Prentaðu minni skoðun eða lestu gögnin með Data.Records.Get.';
        SourceTxt: Label 'Quality.Report.Print', Locked = true;
        FileNameLbl: Label '%1-%2-%3.pdf', Locked = true;

    trigger OnRun()
    begin
        Apply(Rec);
    end;

    /// <summary>Largest PDF that is staged, in bytes.</summary>
    /// <returns>The size limit.</returns>
    internal procedure MaxSizeBytes() Limit: Integer
    begin
        Limit := 10485760;
        OnGetMaxSizeBytes(Limit);
    end;

    /// <summary>Lets the test app lower the size limit to exercise the refusal.</summary>
    /// <param name="Limit">The limit in bytes.</param>
    [InternalEvent(false)]
    local procedure OnGetMaxSizeBytes(var Limit: Integer)
    begin
    end;

    /// <summary>Maps the request value to the Microsoft report object (its default layout is rendered).</summary>
    /// <param name="Kind">certificateOfAnalysis, nonConformance or general.</param>
    /// <returns>The report id to render.</returns>
    internal procedure ResolveReportId(Kind: Text): Integer
    begin
        case Kind of
            'certificateOfAnalysis':
                exit(Report::"Qlty. Certificate of Analysis");
            'nonConformance':
                exit(Report::"Qlty. Non-Conformance");
            else
                exit(Report::"Qlty. General Purpose Inspect.");
        end;
    end;

    local procedure Apply(var Argument: Record "Message Argument ori")
    var
        Inspection: Record "Qlty. Inspection Header";
        BlobStaging: Codeunit "Blob Staging ori";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        Request: JsonObject;
        Response: JsonObject;
        Result: JsonObject;
        Results: JsonArray;
        OutStr: OutStream;
        InStr: InStream;
        InspectionId: Guid;
        Kind: Text;
        FileName: Text;
        StagingId: Guid;
        Size: BigInteger;
    begin
        Request := Argument.GetRequestJson();
        Evaluate(InspectionId, Request.GetText('inspectionSystemId'));
        Kind := Request.GetText('report');
        Inspection.GetBySystemId(InspectionId);
        Inspection.SetRecFilter();
        RecRef.GetTable(Inspection);
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(ResolveReportId(Kind), '', ReportFormat::Pdf, OutStr, RecRef);
        Size := TempBlob.Length();
        if Size > MaxSizeBytes() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::LimitExceeded, StrSubstNo(TooLargeErr, Size, MaxSizeBytes()), 'report', Format(Size), TooLargeExpectedTxt, TooLargeNextTxt);
            exit;
        end;
        FileName := BuildFileName(Inspection, Kind);
        TempBlob.CreateInStream(InStr);
        StagingId := BlobStaging.Create(InStr, FileName, 'application/pdf', SourceTxt);

        Result.Add('stagingId', Format(StagingId, 0, 4));
        Result.Add('fileName', FileName);
        Result.Add('contentType', 'application/pdf');
        Result.Add('sizeBytes', Size);
        Result.Add('inspectionSystemId', Format(InspectionId, 0, 4));
        Result.Add('report', Kind);
        Results.Add(Result);
        Response.Add('status', 'Success');
        Response.Add('noOfRecords', 1);
        Response.Add('result', Results);
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure BuildFileName(Inspection: Record "Qlty. Inspection Header"; Kind: Text): Text
    var
        Safe: Text;
    begin
        Safe := ConvertStr(Inspection."No.", '\/:*?"<>| ', '__________');
        exit(StrSubstNo(FileNameLbl, Safe, Inspection."Re-inspection No.", Kind));
    end;
}
