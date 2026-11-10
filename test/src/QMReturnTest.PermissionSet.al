namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Utilities;

/// <summary>Provides test platform execution without the product execution capability.</summary>
permissionset 97214 "QM Return Test ori"
{
    Assignable = true;
    Caption = 'Return test platform', Locked = true;
    IncludedPermissionSets = "QM Setup Test ori";
    Permissions = table "Name/Value Buffer" = X;
}
