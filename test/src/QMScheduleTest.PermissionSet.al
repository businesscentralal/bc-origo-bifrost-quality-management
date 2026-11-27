namespace Origo.Bifrost.QualityManagement.Test;

/// <summary>Only test subscriber execution; no production capability or native data grants.</summary>
permissionset 97295 "QM Schedule Test ori"
{
    Assignable = true;
    Caption = 'Schedule test subscriber', Locked = true;
    Permissions = codeunit "Quality Schedule Fixture ori" = X;
}
