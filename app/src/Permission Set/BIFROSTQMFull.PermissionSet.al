namespace Origo.Bifrost.QualityManagement;

/// <summary>
/// Grants Quality Management inventory disposition execution; Microsoft business-data permissions remain required.
/// </summary>
permissionset 10035237 "BIFROST QM Full ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Quality Full', MaxLength = 30, Comment = 'is-IS=Bifröst - gæði fullur aðgangur';
    IncludedPermissionSets = "BIFROST Quality ori";
    Permissions = codeunit "Quality Move Impl ori" = X,
        codeunit "Quality Move Posting ori" = X,
        table "Quality Move Access ori" = X,
        tabledata "Quality Move Access ori" = RIMD;
}
