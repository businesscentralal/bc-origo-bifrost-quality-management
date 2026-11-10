namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;
using Origo.Bifrost.QualityManagement;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Issue 7: real app-role authorization with restrictive permission mocking.</summary>
codeunit 97208 "Quality Action Perm Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>The read role cannot execute a write action.</summary>
    [Test]
    procedure Scenario_AC05_ReadRole_ActionIsDisabled()
    var
        Impl: Codeunit "Quality Reinspect Impl ori";
        Enabled: Boolean;
    begin
        // Story #7, AC05 | Time: No date dependency | Risk: Permissions restored
        LowerPermissions.SetExactPermissionSet('BIFROST QM Read ori');
        Enabled := Impl.IsEnabled();
        LowerPermissions.SetOutsideO365Scope();
        Assert.IsFalse(Enabled, 'Read role must not authorize re-inspection.');
    end;

    /// <summary>A caller with API and read roles gets a refusal through the real dispatcher.</summary>
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
        // Story #7, AC08 | Time: No date dependency | Risk: Permissions restored
        Setup.InsertIfNotExists();
        BeforeCount := Inspection.Count();
        Commit();
        LowerPermissions.SetExactPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet('BIFROST QM Read ori');
        LowerPermissions.AddPermissionSet('QltyMgmt - Read');
        Request.AddText('{}');
        Dispatcher.Execute(Enum::"Message Type ori"::"Quality.Inspection.CreateReinspection", Enum::"Message Version ori"::"1.0", '', 'issue7-permissions', 'application/json', Request, Response, ResponseType, false);
        Response.GetSubText(ResponseText, 1);
        LowerPermissions.SetOutsideO365Scope();
        ResponseJson.ReadFrom(ResponseText);
        Assert.AreEqual('Error', ResponseJson.GetText('status'), ResponseText);
        Assert.AreEqual(BeforeCount, Inspection.Count(), 'A permission refusal must not change inspections.');
    end;

    /// <summary>The Foundation full role includes the app action capability.</summary>
    [Test]
    procedure Scenario_AC05_FoundationFull_ActionIsEnabled()
    var
        Impl: Codeunit "Quality Reinspect Impl ori";
        Enabled: Boolean;
    begin
        // Story #7, AC05 | Time: No date dependency | Risk: Permissions restored
        LowerPermissions.SetExactPermissionSet('BIFROST Full ori');
        Enabled := Impl.IsEnabled();
        LowerPermissions.SetOutsideO365Scope();
        Assert.IsTrue(Enabled, 'Foundation full role must include the app action.');
    end;
}
