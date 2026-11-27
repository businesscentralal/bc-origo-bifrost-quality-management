namespace Origo.Bifrost.QualityManagement.Test;

using Origo.Bifrost;

/// <summary>Test-only lifecycle for owned CRONUS scheduling fixtures.</summary>
enumextension 97294 "Quality Schedule Fixtures ori" extends "Message Type ori"
{
    /// <summary>Seeds, inspects and cleans BIFTQ20 fixtures without executing a job.</summary>
    value(97294; "Test.Quality.ScheduleFixture")
    {
        Caption = 'Test.Quality.ScheduleFixture', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Schedule Fixture ori";
    }
}
