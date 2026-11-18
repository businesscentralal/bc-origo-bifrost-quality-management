namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>
/// Registers Quality.Inspection.Finish.
/// Writing Status through Data.Records.Set would skip the result and item-tracking checks
/// that FinishInspection runs on the quality inspection header.
/// </summary>
enumextension 10035280 "Qlty Finish MsgType ori" extends "Message Type ori"
{
    /// <summary>Finishes one quality inspection through the standard FinishInspection procedure.</summary>
    value(10035280; "Quality.Inspection.Finish")
    {
        Caption = 'Quality.Inspection.Finish', Locked = true;
        Implementation = "Msg Interface ori" = "Qlty Insp Finish Impl ori",
                      "Msg Discovery ori" = "Qlty Insp Finish Impl ori",
                      "Msg Contract ori" = "Qlty Insp Finish Impl ori";
    }
}
