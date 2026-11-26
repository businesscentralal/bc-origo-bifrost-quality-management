namespace Origo.Bifrost.QualityManagement.Test;

using Origo.Bifrost.QualityManagement;
using Microsoft.QualityManagement.Document;

/// <summary>Grants the app capability without native inspection modify permission, for a strict-user negative test.</summary>
permissionset 97266 "QM Picture Test ori"
{
    Assignable = true;
    Caption = 'Picture test capability', Locked = true;
    Permissions = table "Quality Picture Access ori" = X,
        tabledata "Quality Picture Access ori" = RIMD,
        tabledata "Qlty. Inspection Header" = R;
}
