namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>
/// Includes the matching Quality Management permissions in the Foundation role.
/// </summary>
permissionsetextension 10035240 "Quality Read Role ori" extends "BIFROST Read ori"
{
    IncludedPermissionSets = "BIFROST QM Read ori";
}
