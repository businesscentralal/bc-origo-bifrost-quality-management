namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers creation of inspection put-away documents.</summary>
enumextension 10035306 "Quality PutAway Types ori" extends "Message Type ori"
{
    value(10035306; "Quality.Disposition.CreatePutAway")
    {
        Caption = 'Quality.Disposition.CreatePutAway', Locked = true;
        Implementation = "Msg Interface ori" = "Quality PutAway Impl ori", "Msg Discovery ori" = "Quality PutAway Impl ori", "Msg Contract ori" = "Quality PutAway Impl ori";
    }
}
