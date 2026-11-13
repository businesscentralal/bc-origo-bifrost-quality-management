namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers the inspection inventory disposition.</summary>
enumextension 10035270 "Quality Move Types ori" extends "Message Type ori"
{
    value(10035270; "Quality.Disposition.MoveInventory")
    {
        Caption = 'Quality.Disposition.MoveInventory', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Move Impl ori", "Msg Discovery ori" = "Quality Move Impl ori", "Msg Contract ori" = "Quality Move Impl ori";
    }
}
