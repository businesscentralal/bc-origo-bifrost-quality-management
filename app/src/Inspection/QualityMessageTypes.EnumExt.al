namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers the inspection creation operation.</summary>
enumextension 10035241 "Quality Message Types ori" extends "Message Type ori"
{
    /// <summary>Creates an inspection through the standard Business Central action.</summary>
    value(10035250; "Quality.Inspection.Create")
    {
        Caption = 'Quality.Inspection.Create', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Create Impl ori", "Msg Discovery ori" = "Quality Create Impl ori", "Msg Contract ori" = "Quality Create Impl ori";
    }
}
