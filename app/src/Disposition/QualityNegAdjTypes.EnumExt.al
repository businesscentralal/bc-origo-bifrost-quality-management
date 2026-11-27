namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers the negative inventory adjustment disposition.</summary>
enumextension 10035304 "Quality Neg Adj Types ori" extends "Message Type ori"
{
    value(10035302; "Quality.Disposition.CreateNegativeAdjustment")
    {
        Caption = 'Quality.Disposition.CreateNegativeAdjustment', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Neg Adj Impl ori", "Msg Discovery ori" = "Quality Neg Adj Impl ori", "Msg Contract ori" = "Quality Neg Adj Impl ori";
    }
}
