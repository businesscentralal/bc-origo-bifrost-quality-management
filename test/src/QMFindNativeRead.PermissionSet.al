namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Document;

/// <summary>Supplies native inspection read permission separately from the Bifrost Read role.</summary>
permissionset 97263 "QM Find Read ori"
{
    Assignable = true;
    Caption = 'Find native read', Locked = true;
    Permissions = tabledata "Qlty. Inspection Header" = R;
}
