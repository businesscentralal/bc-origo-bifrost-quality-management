namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers the inspection test-value operation.</summary>
enumextension 10035241 "Quality Message Types ori" extends "Message Type ori"
{
    /// <summary>Validates a test value and recalculates the inspection result.</summary>
    value(10035242; "Quality.Inspection.SetTestValue")
    {
        Caption = 'Quality.Inspection.SetTestValue', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Set Value Impl ori", "Msg Discovery ori" = "Quality Set Value Impl ori", "Msg Contract ori" = "Quality Set Value Impl ori";
    }
}
