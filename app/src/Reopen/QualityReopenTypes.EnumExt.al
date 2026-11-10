namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers Quality.Inspection.Reopen with Foundation.</summary>
enumextension 10035255 "Quality Reopen Types ori" extends "Message Type ori"
{
    value(10035255; "Quality.Inspection.Reopen")
    {
        Caption = 'Quality.Inspection.Reopen', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Reopen Impl ori",
                          "Msg Discovery ori" = "Quality Reopen Impl ori",
                          "Msg Contract ori" = "Quality Reopen Impl ori";
    }
}
