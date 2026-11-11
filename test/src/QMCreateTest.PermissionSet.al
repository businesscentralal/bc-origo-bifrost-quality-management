namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Inventory.Item;
using Microsoft.Utilities;
using System.Environment.Configuration;

/// <summary>Platform and source reads for permission tests; grants no product write capability.</summary>
permissionset 97244 "QM Create Test ori"
{
    Assignable = true;
    Caption = 'Create test platform', Locked = true;
    IncludedPermissionSets = "QM Setup Test ori";
    Permissions = table "Name/Value Buffer" = X, tabledata Item = R, tabledata "Record Link" = R,
        table "Quality Create Fixture ori" = X,
        tabledata "Quality Create Fixture ori" = RIMD;
}
