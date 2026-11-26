namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers the approved generation-rule scheduling message.</summary>
enumextension 10035328 "Quality Schedule Types ori" extends "Message Type ori"
{
    /// <summary>Creates one scheduled-inspection job, on hold unless explicitly activated.</summary>
    value(10035328; "Quality.GenerationRule.Schedule")
    {
        Caption = 'Quality.GenerationRule.Schedule', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Schedule Impl ori",
                          "Msg Discovery ori" = "Quality Schedule Impl ori",
                          "Msg Contract ori" = "Quality Schedule Impl ori";
    }
}
