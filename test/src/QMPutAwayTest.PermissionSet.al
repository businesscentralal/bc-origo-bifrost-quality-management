namespace Origo.Bifrost.QualityManagement.Test;

/// <summary>Platform support only; does not grant any put-away capability or business data permission.</summary>
permissionset 97278 "QM PutAway Test ori"
{
    Assignable = true;
    Caption = 'Put-away test platform', Locked = true;
    IncludedPermissionSets = "QM Move Test ori";
}
