namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Issue 5: the app permission set is required before the native reopen action runs.</summary>
codeunit 97221 "Quality Reopen Perm Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>The read role cannot execute the reopen action.</summary>
    [Test]
    procedure Scenario_AC05_ReadRole_ActionIsDisabled()
    var
        Impl: Interface "Msg Interface ori";
        Enabled: Boolean;
    begin
        // Story #5, AC05 | Time: no date-dependent inputs | Risk: permissions restored
        Impl := Enum::"Message Type ori"::"Quality.Inspection.Reopen";
        LowerPermissions.SetExactPermissionSet('BIFROST QM Read ori');
        Enabled := Impl.IsEnabled();
        LowerPermissions.SetOutsideO365Scope();
        Assert.IsFalse(Enabled, 'The read role must not authorize reopen.');
    end;

    /// <summary>A read caller is refused and no inspection row changes.</summary>
    [Test]
    procedure Scenario_AC08_ReadCaller_ReceivesRefusal()
    var
        Setup: Record "Setup ori";
        Inspection: Record "Qlty. Inspection Header";
        Dispatcher: Codeunit "Dispatcher ori";
        Request: BigText;
        Response: BigText;
        ResponseType: Text[100];
        ResponseText: Text;
        ResponseJson: JsonObject;
        BeforeCount: Integer;
    begin
        // Story #5, AC05/AC08 | Time: no date-dependent inputs | Risk: permissions restored
        LowerPermissions.SetOutsideO365Scope();
        Setup.InsertIfNotExists();
        BeforeCount := Inspection.Count();
        Commit();
        LowerPermissions.SetExactPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet('BIFROST QM Read ori');
        LowerPermissions.AddPermissionSet('QltyMgmt - Read');
        Request.AddText('{}');
        Dispatcher.Execute(Enum::"Message Type ori"::"Quality.Inspection.Reopen", Enum::"Message Version ori"::"1.0", '', 'issue5-permissions', 'application/json', Request, Response, ResponseType, false);
        Response.GetSubText(ResponseText, 1);
        LowerPermissions.SetOutsideO365Scope();
        ResponseJson.ReadFrom(ResponseText);
        Assert.AreEqual('Error', ResponseJson.GetText('status'), ResponseText);
        Assert.AreEqual('PermissionDenied', ResponseJson.GetText('code'), ResponseText);
        Assert.AreEqual(BeforeCount, Inspection.Count(), 'A permission refusal must not change inspections.');
    end;

    /// <summary>The Foundation full role includes the app action.</summary>
    [Test]
    procedure Scenario_AC05_FoundationFull_ActionIsEnabled()
    var
        Impl: Interface "Msg Interface ori";
        Enabled: Boolean;
    begin
        // Story #5, AC05 | Time: no date-dependent inputs | Risk: permissions restored
        Impl := Enum::"Message Type ori"::"Quality.Inspection.Reopen";
        LowerPermissions.SetExactPermissionSet('BIFROST Full ori');
        Enabled := Impl.IsEnabled();
        LowerPermissions.SetOutsideO365Scope();
        Assert.IsTrue(Enabled, 'Foundation full must include the app reopen grant.');
    end;
}
