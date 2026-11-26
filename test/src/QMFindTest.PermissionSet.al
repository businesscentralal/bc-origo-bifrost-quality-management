namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;

/// <summary>Grants only owned source and source-configuration reads, never native inspection reads.</summary>
permissionset 97261 "QM Find Test ori"
{
    Assignable = true;
    Caption = 'Find test source', Locked = true;
    IncludedPermissionSets = "QM Setup Test ori";
    Permissions = tabledata Item = R,
        table "Quality Find Source ori" = X,
        tabledata "Quality Find Source ori" = R,
        tabledata "Qlty. Inspect. Source Config." = R,
        tabledata "Qlty. Inspect. Src. Fld. Conf." = R;
}
