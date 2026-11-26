namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers the inspection item tracking change disposition.</summary>
enumextension 10035310 "Quality Track Types ori" extends "Message Type ori"
{
    value(10035310; "Quality.Disposition.ChangeItemTracking")
    {
        Caption = 'Quality.Disposition.ChangeItemTracking', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Track Impl ori", "Msg Discovery ori" = "Quality Track Impl ori", "Msg Contract ori" = "Quality Track Impl ori";
    }
}
