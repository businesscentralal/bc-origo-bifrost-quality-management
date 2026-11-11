namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Permissions;

/// <summary>
/// Grants inspection creation, reopen, test-value and purchase-return execution, app write capabilities and Microsoft Quality Admin and Inspector permissions.
/// Microsoft ReopenInspection still requires the Quality Admin role, or SUPER, to be assigned to the user.
/// </summary>
permissionset 10035237 "BIFROST QM Full ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Quality Full', MaxLength = 30, Comment = 'is-IS=Bifröst - gæði fullur aðgangur';
    IncludedPermissionSets = "BIFROST Quality ori", "QltyMgmt - Admin", "QltyMgmt - Inspector";
    Permissions = codeunit "Quality Create Impl ori" = X,
        codeunit "Quality Create Context ori" = X,
        codeunit "Quality Set Value Impl ori" = X,
        table "Quality Write Access ori" = X,
        tabledata "Quality Write Access ori" = RIMD,
        codeunit "Quality Reopen Impl ori" = X,
        table "Quality Reopen Access ori" = X,
        tabledata "Quality Reopen Access ori" = RIMD,
        codeunit "Quality Purch Return Impl ori" = X,
        codeunit "Quality Return Receipt ori" = X,
        table "Quality Return Access ori" = X,
        tabledata "Quality Return Access ori" = RIMD;
}
