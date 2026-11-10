namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers the purchase return disposition.</summary>
enumextension 10035244 "Quality Return Types ori" extends "Message Type ori"
{
    /// <summary>Creates an unposted purchase return for the failed quantity.</summary>
    value(10035245; "Quality.Disposition.CreatePurchaseReturn")
    {
        Caption = 'Quality.Disposition.CreatePurchaseReturn', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Purch Return Impl ori", "Msg Discovery ori" = "Quality Purch Return Impl ori", "Msg Contract ori" = "Quality Purch Return Impl ori";
    }
}
