namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers read-only source inspection matching.</summary>
enumextension 10035290 "Quality Find Types ori" extends "Message Type ori"
{
    /// <summary>Finds inspections without creating or changing business records.</summary>
    value(10035291; "Quality.Inspection.FindForRecord")
    {
        Caption = 'Quality.Inspection.FindForRecord', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Find Impl ori", "Msg Discovery ori" = "Quality Find Impl ori", "Msg Contract ori" = "Quality Find Impl ori";
    }
}
