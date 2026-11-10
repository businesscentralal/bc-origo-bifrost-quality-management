namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;
using System.Security.AccessControl;
using System.Security.User;

/// <summary>
/// Applies Quality.Inspection.Finish inside one transaction.
/// A failed check rolls back with the transaction. No write is performed inside a TryFunction.
/// FinishInspection is not load-field limited: it reads tracking, result and audit fields.
/// </summary>
codeunit 10035283 "Qlty Insp Finish Proc ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        Contract: Codeunit "Qlty Insp Finish Ctr ori";

    trigger OnRun()
    begin
        Apply(Rec);
    end;

    /// <summary>Reads the request and finishes the inspection through FinishInspection.</summary>
    /// <param name="Argument">The message argument.</param>
    internal procedure Apply(var Argument: Record "Message Argument ori")
    var
        AccessCapability: Record "Qlty Finish Access ori";
        Header: Record "Qlty. Inspection Header";
        InspectionNo: Code[20];
        ReinspectionNo: Integer;
        PreviousToken: Text;
        WasOpen: Boolean;
    begin
        if not Contract.ReadFinishRequest(Argument, InspectionNo, ReinspectionNo) then begin
            Contract.RaiseCollected(Argument);
            exit;
        end;

        if not Contract.HasTablePermission(Argument, AccessCapability.WritePermission() and Header.ReadPermission(), CanModifyInspection()) then
            exit;

        // FinishInspection reads tracking, result and audit fields, so this record is not load-field limited.
        if not Header.Get(InspectionNo, ReinspectionNo) then begin
            Contract.FailRecordNotFound(Argument, InspectionNo, ReinspectionNo);
            exit;
        end;

        PreviousToken := Contract.StatusToken(Header.Status);
        WasOpen := Header.Status = Header.Status::Open;
        Header.FinishInspection();
        Header.Get(InspectionNo, ReinspectionNo);

        if WasOpen and (Header.Status <> Header.Status::Finished) then begin
            Contract.FailStillOpen(Argument, InspectionNo, ReinspectionNo);
            exit;
        end;

        Contract.WriteSuccess(Argument, Header, PreviousToken, WasOpen and (Header.Status = Header.Status::Finished));
    end;
    local procedure CanModifyInspection(): Boolean
    var
        TempPermission: Record "Expanded Permission" temporary;
        UserPermissions: Codeunit "User Permissions";
    begin
        // Finishing needs Modify, not Delete. This matches the native FinishInspection permission check.
        TempPermission := UserPermissions.GetEffectivePermission(TempPermission."Object Type"::"Table Data", Database::"Qlty. Inspection Header");
        exit(TempPermission."Modify Permission" in [TempPermission."Modify Permission"::Yes, TempPermission."Modify Permission"::Indirect]);
    end;
}
