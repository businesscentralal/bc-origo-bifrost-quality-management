namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>
/// Includes the matching Quality Management permissions in the Foundation role.
/// </summary>
permissionsetextension 10035239 "Quality Full Role ori" extends "BIFROST Full ori"
{
    IncludedPermissionSets = "BIFROST QM Full ori";
}
