namespace Origo.Bifrost.QualityManagement;

/// <summary>
/// Grants Quality Management registration and capability discovery without write access or Microsoft business data.
/// </summary>
permissionset 10035236 "BIFROST Quality ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Quality Management', MaxLength = 30, Comment = 'is-IS=Bifröst - gæðastjórnun';
    Permissions = codeunit "Quality Registration ori" = X,
        codeunit "Quality Reopen Impl ori" = X,
        table "Quality Reopen Access ori" = X,
        tabledata "Quality Reopen Access ori" = R;
}
