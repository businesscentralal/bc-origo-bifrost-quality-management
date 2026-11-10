namespace Origo.Bifrost.QualityManagement;

/// <summary>
/// Grants Quality Management scaffold execution without access to Microsoft business data.
/// </summary>
permissionset 10035236 "BIFROST Quality ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Quality Management', MaxLength = 30, Comment = 'is-IS=Bifröst - gæðastjórnun';
    Permissions = codeunit "Quality Registration ori" = X,
        table "Quality Reinspect Access ori" = X,
        tabledata "Quality Reinspect Access ori" = R,
        codeunit "Quality Reinspect Impl ori" = X,
        codeunit "Quality Reinspect Proc ori" = X;
}
