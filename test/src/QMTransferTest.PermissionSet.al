namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Utilities;

/// <summary>Platform-only dispatch support; never grants the app transfer capability or inventory data rights.</summary>
permissionset 97270 "QM Transfer Test ori"
{
    Assignable = true;
    Caption = 'Transfer test platform', Locked = true;
    IncludedPermissionSets = "QM Setup Test ori";
    Permissions = table "Name/Value Buffer" = X;
}
