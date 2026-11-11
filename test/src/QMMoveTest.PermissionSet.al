namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Utilities;

/// <summary>Platform-only dispatch support; never grants the app movement capability or inventory data rights.</summary>
permissionset 97252 "QM Move Test ori"
{
    Assignable = true;
    Caption = 'Movement test platform', Locked = true;
    IncludedPermissionSets = "QM Setup Test ori";
    Permissions = table "Name/Value Buffer" = X;
}
