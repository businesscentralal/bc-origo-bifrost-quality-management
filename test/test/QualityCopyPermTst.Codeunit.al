namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Configuration.Template;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Issue 18: only the app Full grant enables template copy.</summary>
codeunit 97285 "Quality Copy Perm Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>The read role cannot copy.</summary>
    [Test]
    procedure Scenario_AC05_ReadRole_ActionIsDisabled()
    begin
        // Story #18, AC05 | Time: no date-dependent inputs | Risk: permissions restored
        Assert.IsFalse(IsEnabledFor('BIFROST QM Read ori'), 'The read role must not authorize template copy.');
    end;

    /// <summary>The base role cannot copy.</summary>
    [Test]
    procedure Scenario_AC05_BaseRole_ActionIsDisabled()
    begin
        // Story #18, AC05 | Time: no date-dependent inputs | Risk: permissions restored
        Assert.IsFalse(IsEnabledFor('BIFROST Quality ori'), 'The base role must not authorize template copy.');
    end;

    /// <summary>The app full role enables the copy.</summary>
    [Test]
    procedure Scenario_AC05_FullRole_ActionIsEnabled()
    begin
        // Story #18, AC05 | Time: no date-dependent inputs | Risk: permissions restored
        Assert.IsTrue(IsEnabledFor('BIFROST QM Full ori'), 'The app full role must authorize template copy.');
    end;

    /// <summary>The Foundation full role includes the app copy grant.</summary>
    [Test]
    procedure Scenario_AC05_FoundationFull_ActionIsEnabled()
    begin
        // Story #18, AC05 | Time: no date-dependent inputs | Risk: permissions restored
        Assert.IsTrue(IsEnabledFor('BIFROST Full ori'), 'Foundation full must include the app copy grant.');
    end;

    /// <summary>A read caller is refused and no template is created.</summary>
    [Test]
    procedure Scenario_AC05_ReadCaller_ReceivesRefusal()
    var
        Setup: Record "Setup ori";
        InspTemplate: Record "Qlty. Inspection Template Hdr.";
        Dispatcher: Codeunit "Dispatcher ori";
        Request: BigText;
        Response: BigText;
        ResponseType: Text[100];
        ResponseText: Text;
        ResponseJson: JsonObject;
        BeforeCount: Integer;
    begin
        // Story #18, AC05 | Time: no date-dependent inputs | Risk: permissions restored
        LowerPermissions.SetOutsideO365Scope();
        Setup.InsertIfNotExists();
        BeforeCount := InspTemplate.Count();
        Commit();
        LowerPermissions.SetExactPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet('BIFROST QM Read ori');
        LowerPermissions.AddPermissionSet('QltyMgmt - Read');
        Request.AddText('{"sourceTemplateCode":"ANY","targetTemplateCode":"ANY2","expectedCount":1}');
        Dispatcher.Execute(Enum::"Message Type ori"::"Quality.Template.Copy", Enum::"Message Version ori"::"1.0", '', 'issue18-permissions', 'application/json', Request, Response, ResponseType, false);
        Response.GetSubText(ResponseText, 1);
        LowerPermissions.SetOutsideO365Scope();
        ResponseJson.ReadFrom(ResponseText);
        Assert.AreEqual('Error', ResponseJson.GetText('status'), ResponseText);
        Assert.AreEqual('PermissionDenied', ResponseJson.GetText('code'), ResponseText);
        Assert.AreEqual(BeforeCount, InspTemplate.Count(), 'A permission refusal must not create templates.');
    end;

    local procedure IsEnabledFor(PermissionSetId: Code[20]) Enabled: Boolean
    var
        Impl: Interface "Msg Interface ori";
    begin
        Impl := Enum::"Message Type ori"::"Quality.Template.Copy";
        LowerPermissions.SetExactPermissionSet(PermissionSetId);
        Enabled := Impl.IsEnabled();
        LowerPermissions.SetOutsideO365Scope();
    end;
}
