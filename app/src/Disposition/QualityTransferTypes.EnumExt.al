namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers the inspection transfer order disposition.</summary>
enumextension 10035298 "Quality Transfer Types ori" extends "Message Type ori"
{
    value(10035298; "Quality.Disposition.CreateTransferOrder")
    {
        Caption = 'Quality.Disposition.CreateTransferOrder', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Transfer Impl ori", "Msg Discovery ori" = "Quality Transfer Impl ori", "Msg Contract ori" = "Quality Transfer Impl ori";
    }
}
