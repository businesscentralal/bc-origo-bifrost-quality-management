namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers the inspection creation and test-value operations.</summary>
enumextension 10035241 "Quality Message Types ori" extends "Message Type ori"
{
    /// <summary>Validates a test value and recalculates the inspection result.</summary>
    value(10035242; "Quality.Inspection.SetTestValue")
    {
        Caption = 'Quality.Inspection.SetTestValue', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Set Value Impl ori", "Msg Discovery ori" = "Quality Set Value Impl ori", "Msg Contract ori" = "Quality Set Value Impl ori";
    }
    /// <summary>Creates an inspection through the standard Business Central action.</summary>
    value(10035250; "Quality.Inspection.Create")
    {
        Caption = 'Quality.Inspection.Create', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Create Impl ori", "Msg Discovery ori" = "Quality Create Impl ori", "Msg Contract ori" = "Quality Create Impl ori";
    }
}
