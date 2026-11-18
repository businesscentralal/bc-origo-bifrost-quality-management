namespace Origo.Bifrost.QualityManagement;

using System.Environment.Configuration;

/// <summary>
/// Reads the current user's own notification settings, which Microsoft Quality Management checks
/// before offering to assign a modified inspection to the user in interactive sessions.
/// Included by BIFROST QM Full ori; not assignable on its own.
/// </summary>
permissionset 10035285 "BIFROST QM Notify ori"
{
    Assignable = false;
    Access = Public;
    Caption = 'Bifrost Quality Notifications', MaxLength = 30, Comment = 'is-IS=Bifröst - gæði tilkynningar';
    Permissions = tabledata "My Notifications" = R;
}
