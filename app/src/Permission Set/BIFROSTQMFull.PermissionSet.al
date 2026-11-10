namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Permissions;

/// <summary>
/// Grants inspection reopen execution together with Microsoft Quality Admin data permissions.
/// Microsoft ReopenInspection still requires the Quality Admin role, or SUPER, to be assigned to the user.
/// </summary>
permissionset 10035237 "BIFROST QM Full ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Quality Full', MaxLength = 30, Comment = 'is-IS=Bifröst - gæði fullur aðgangur';
    IncludedPermissionSets = "BIFROST Quality ori", "QltyMgmt - Admin";
    Permissions = codeunit "Quality Reopen Impl ori" = X,
        table "Quality Reopen Access ori" = X,
        tabledata "Quality Reopen Access ori" = RIMD;
}
