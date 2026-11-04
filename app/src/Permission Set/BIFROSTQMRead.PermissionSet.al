namespace Origo.Bifrost.QualityManagement;

/// <summary>
/// Grants Quality Management scaffold execution without access to Microsoft business data.
/// </summary>
permissionset 10035238 "BIFROST QM Read ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Quality Read', MaxLength = 30, Comment = 'is-IS=Bifröst - gæði lesaðgangur';
    IncludedPermissionSets = "BIFROST Quality ori";
}
