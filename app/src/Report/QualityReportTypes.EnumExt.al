namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers the inspection report print message type with Foundation.</summary>
enumextension 10035318 "Quality Report Types ori" extends "Message Type ori"
{
    value(10035318; "Quality.Report.Print")
    {
        Caption = 'Quality.Report.Print', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Report Impl ori", "Msg Discovery ori" = "Quality Report Impl ori", "Msg Contract ori" = "Quality Report Impl ori";
    }
}
