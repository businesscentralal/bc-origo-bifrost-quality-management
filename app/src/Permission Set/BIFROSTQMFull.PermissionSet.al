namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Permissions;

/// <summary>
/// Grants inspection finish, reopen, test-value, purchase-return and inventory disposition execution with Microsoft Quality Admin and Inspector permissions; other Microsoft business-data permissions remain required.
/// Microsoft ReopenInspection still requires the Quality Admin role, or SUPER, to be assigned to the user.
/// With Quality Admin write access, Microsoft offers to assign a modified inspection to the user in interactive sessions,
/// which reads the user's own My Notifications setting; the read grant lets finish run under this role alone.
/// </summary>
permissionset 10035237 "BIFROST QM Full ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Quality Full', MaxLength = 30, Comment = 'is-IS=Bifröst - gæði fullur aðgangur';
    IncludedPermissionSets = "BIFROST Quality ori", "QltyMgmt - Admin", "QltyMgmt - Inspector", "BIFROST QM Notify ori";
    Permissions = codeunit "Quality Set Value Impl ori" = X,
        table "Quality Write Access ori" = X,
        tabledata "Quality Write Access ori" = RIMD,
        codeunit "Quality Reopen Impl ori" = X,
        table "Quality Reopen Access ori" = X,
        tabledata "Quality Reopen Access ori" = RIMD,
        codeunit "Quality Purch Return Impl ori" = X,
        codeunit "Quality Return Receipt ori" = X,
        table "Quality Return Access ori" = X,
        tabledata "Quality Return Access ori" = RIMD,
        table "Qlty Finish Access ori" = X,
        tabledata "Qlty Finish Access ori" = RIMD,
        codeunit "Qlty Insp Finish Ctr ori" = X,
        codeunit "Qlty Insp Finish Impl ori" = X,
        codeunit "Qlty Insp Finish Proc ori" = X,
        codeunit "Quality Move Impl ori" = X,
        codeunit "Quality Move Posting ori" = X,
        table "Quality Move Access ori" = X,
        tabledata "Quality Move Access ori" = RIMD,
        table "Quality Reinspect Access ori" = X,
        tabledata "Quality Reinspect Access ori" = RIMD;
}
