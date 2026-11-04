namespace Origo.Bifrost.QualityManagement.Test;

using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>
/// Asserts that Bifrost Quality Management makes itself known to Bifrost Foundation's
/// application registry. Foundation shows the setup notifications for the whole family on its
/// own Bifrost Setup page, and it can only report on an application that answers
/// <c>OnRegisterApps</c> - so losing the subscriber would silently drop this app off that page.
/// </summary>
codeunit 97200 "Quality Scaffold Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        PermissionsMock: Codeunit "Permissions Mock";
        AppUnderTestId: Guid;
        AppNameTok: Label 'Bifrost Quality Management', Locked = true;
        AppIdNotFoundErr: Label 'The test app must depend on %1 for this test to resolve its app id.', Comment = '%1 = the app name', Locked = true;

    /// <summary>Checks the installed app registration through Foundation discovery.</summary>
    [Test]
    procedure Scenario_AC01_AppIsRegistered()
    var
        TempApps: Record "Registered App ori" temporary;
        AppRegistry: Codeunit "App Registry ori";
    begin
        // [GIVEN] The module id of the app under test
        Initialize();

        // [WHEN] Foundation builds the registry of installed Bifrost applications
        AppRegistry.GetApps(TempApps);

        // [THEN] Bifrost Quality Management is in it, under its own module id and name
        Assert.IsTrue(TempApps.Get(AppUnderTestId), 'Bifrost Quality Management should register itself with the Bifrost application registry.');
        Assert.AreEqual(AppNameTok, TempApps."App Name", 'The registry should carry the app display name.');
        Assert.AreEqual(0, TempApps."Setup Page Id", 'This app has no setup page of its own.');
    end;

    /// <summary>Rebuilding the registry retains exactly one entry for this app.</summary>
    [Test]
    procedure Scenario_AC01_RebuildHasNoDuplicates()
    var
        TempApps: Record "Registered App ori" temporary;
        AppRegistry: Codeunit "App Registry ori";
    begin
        // [GIVEN] A populated registry with this app installed.
        Initialize();
        AppRegistry.GetApps(TempApps);

        // [WHEN] Discovery is refreshed for the same installed apps.
        AppRegistry.GetApps(TempApps);

        // [THEN] There is exactly one row for this app, without a fictitious setup page.
        TempApps.SetRange("App Id", AppUnderTestId);
        Assert.AreEqual(1, TempApps.Count(), 'Repeated discovery must not duplicate the application.');
        TempApps.FindFirst();
        Assert.AreEqual(0, TempApps."Setup Page Id", 'The scaffold has no setup page.');
    end;

    /// <summary>Exercises licence-administrator setup access in English.</summary>
    [Test]
    procedure Scenario_AC05_LicenceAdmin_OpensReadOnlySetupEnglish()
    begin
        // [SCENARIO] Issue #1: registration preserves the licence-administrator boundary.
        VerifySetupAccess(1033);
    end;

    /// <summary>Exercises licence-administrator setup access in Icelandic.</summary>
    [Test]
    procedure Scenario_AC05_LicenceAdmin_OpensReadOnlySetupIcelandic()
    begin
        // [SCENARIO] Issue #1: registration preserves the licence-administrator boundary.
        VerifySetupAccess(1039);
    end;

    local procedure VerifySetupAccess(LanguageId: Integer)
    var
        BifrostSetup: Record "Setup ori";
        TempApps: Record "Registered App ori" temporary;
        AppRegistry: Codeunit "App Registry ori";
        SetupPage: TestPage "Setup ori";
        TestAppInfo: ModuleInfo;
        Dependency: ModuleDependencyInfo;
        AppId: Guid;
        PreviousLanguage: Integer;
        IsEditable: Boolean;
        CanWriteSetup: Boolean;
        IsRegistered: Boolean;
    begin
        // [GIVEN] An installed app and an initialized setup, with permission mocking active.
        Assert.IsTrue(PermissionsMock.IsStarted(), 'The test runner must enable permission mocking.');
        NavApp.GetCurrentModuleInfo(TestAppInfo);
        foreach Dependency in TestAppInfo.Dependencies() do
            if Dependency.Name() = 'Bifrost Quality Management' then
                AppId := Dependency.Id();
        Assert.IsFalse(IsNullGuid(AppId), 'The test app must depend on Quality Management.');
        BifrostSetup.InsertIfNotExists();
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        LowerPermissions.SetExactPermissionSet('BIFROST LicAdm ori');
        LowerPermissions.AddPermissionSet('QM Setup Test ori');

        // [WHEN] The real page invokes registration, before any direct registry warm-up.
        SetupPage.OpenView();
        IsEditable := SetupPage.Editable();
        CanWriteSetup := BifrostSetup.WritePermission();
        SetupPage.Close();
        AppRegistry.GetApps(TempApps);
        IsRegistered := TempApps.Get(AppId);
        LowerPermissions.SetOutsideO365Scope();
        GlobalLanguage(PreviousLanguage);

        // [THEN] Registration succeeds while the administrator boundary remains intact.
        Assert.IsTrue(IsRegistered, 'Quality Management must be registered for the licence administrator.');
        Assert.IsFalse(IsEditable, 'A licence administrator must not edit Bifrost Setup.');
        Assert.IsFalse(CanWriteSetup, 'Opening setup must not grant direct setup-write permission.');
    end;

    /// <summary>
    /// Resolves the module id of Bifrost Quality Management from this test app's own dependency
    /// list, so the test never carries a hard-coded guid.
    /// </summary>
    local procedure Initialize()
    var
        TestAppInfo: ModuleInfo;
        Dependency: ModuleDependencyInfo;
    begin
        Clear(AppUnderTestId);
        NavApp.GetCurrentModuleInfo(TestAppInfo);
        foreach Dependency in TestAppInfo.Dependencies() do
            if Dependency.Name() = AppNameTok then
                AppUnderTestId := Dependency.Id();

        if IsNullGuid(AppUnderTestId) then
            Error(AppIdNotFoundErr, AppNameTok);
    end;
}
