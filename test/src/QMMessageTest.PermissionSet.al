namespace Origo.Bifrost.QualityManagement.Test;

using System.Utilities;

/// <summary>Supplies platform execution for the dispatcher tests without product or business-data grants.</summary>
permissionset 97204 "QM Message Test ori"
{
    Assignable = true;
    Caption = 'Message test platform', Locked = true;
    IncludedPermissionSets = "QM Setup Test ori";
    Permissions = table "Name/Value Buffer" = X;
}
