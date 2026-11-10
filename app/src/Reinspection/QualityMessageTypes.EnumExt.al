namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers the standard re-inspection action with Foundation.</summary>
enumextension 10035244 "Quality Message Types ori" extends "Message Type ori"
{
    value(10035244; "Quality.Inspection.CreateReinspection")
    {
        Caption = 'Quality.Inspection.CreateReinspection', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Reinspect Impl ori", "Msg Discovery ori" = "Quality Reinspect Impl ori", "Msg Contract ori" = "Quality Reinspect Impl ori";
    }
}
