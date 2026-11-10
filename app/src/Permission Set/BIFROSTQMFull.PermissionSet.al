namespace Origo.Bifrost.QualityManagement;

/// <summary>
/// Grants execution of Quality Management message types.
/// Table permission on Microsoft quality inspections stays with the caller's own Business Central role.
/// </summary>
permissionset 10035237 "BIFROST QM Full ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Quality Full', MaxLength = 30, Comment = 'is-IS=Bifröst - gæði fullur aðgangur';
    IncludedPermissionSets = "BIFROST Quality ori";
    Permissions =
        table "Qlty Finish Access ori" = X,
        tabledata "Qlty Finish Access ori" = RIMD,
        codeunit "Qlty Insp Finish Ctr ori" = X,
        codeunit "Qlty Insp Finish Impl ori" = X,
        codeunit "Qlty Insp Finish Proc ori" = X;
}
