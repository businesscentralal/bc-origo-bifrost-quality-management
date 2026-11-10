namespace Origo.Bifrost.QualityManagement;

/// <summary>
/// Grants Quality Management scaffold execution without access to Microsoft business data.
/// </summary>
permissionset 10035237 "BIFROST QM Full ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Quality Full', MaxLength = 30, Comment = 'is-IS=Bifröst - gæði fullur aðgangur';
    Permissions = codeunit "Quality Create Impl ori" = X,
        codeunit "Quality Create Context ori" = X,
        table "Quality Write Access ori" = X,
        tabledata "Quality Write Access ori" = IMD;
    IncludedPermissionSets = "BIFROST Quality ori";
}
