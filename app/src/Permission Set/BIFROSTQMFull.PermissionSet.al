namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Permissions;

/// <summary>
/// Grants inspection test-value and purchase-return execution with Microsoft inspector permissions.
/// </summary>
permissionset 10035237 "BIFROST QM Full ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Quality Full', MaxLength = 30, Comment = 'is-IS=Bifröst - gæði fullur aðgangur';
    IncludedPermissionSets = "BIFROST Quality ori", "QltyMgmt - Inspector";
    Permissions = codeunit "Quality Set Value Impl ori" = X,
        table "Quality Write Access ori" = X,
        tabledata "Quality Write Access ori" = RIMD,
        codeunit "Quality Purch Return Impl ori" = X,
        codeunit "Quality Return Receipt ori" = X,
        table "Quality Return Access ori" = X,
        tabledata "Quality Return Access ori" = RIMD;
}
