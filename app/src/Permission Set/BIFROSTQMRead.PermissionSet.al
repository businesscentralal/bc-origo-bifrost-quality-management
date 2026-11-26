namespace Origo.Bifrost.QualityManagement;

/// <summary>
/// Grants discovery and inspection lookup execution; native business-data read permissions remain required.
/// </summary>
permissionset 10035238 "BIFROST QM Read ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Quality Read', MaxLength = 30, Comment = 'is-IS=Bifröst - gæði lesaðgangur';
    Permissions = codeunit "Quality Find Impl ori" = X;
    IncludedPermissionSets = "BIFROST Quality ori";
}
