namespace Origo.Bifrost.QualityManagement;

/// <summary>
/// Grants Quality Management scaffold execution without access to Microsoft business data.
/// </summary>
permissionset 10035237 "BIFROST QM Full ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Quality Full', MaxLength = 30, Comment = 'is-IS=Bifröst - gæði fullur aðgangur';
    IncludedPermissionSets = "BIFROST Quality ori";
    Permissions = tabledata "Quality Reinspect Access ori" = RIMD;
}
