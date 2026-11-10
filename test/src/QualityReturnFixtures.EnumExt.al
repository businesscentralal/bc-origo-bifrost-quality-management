namespace Origo.Bifrost.QualityManagement.Test;

using Origo.Bifrost;

/// <summary>Registers a test-only owned fixture lifecycle for reproducible MCP acceptance.</summary>
enumextension 97213 "Quality Return Fixtures ori" extends "Message Type ori"
{
    /// <summary>Creates or removes an isolated quality fixture on a CRONUS company.</summary>
    value(97213; "Test.Quality.ReturnFixture")
    {
        Caption = 'Test.Quality.ReturnFixture', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Return Fixture ori";
    }
}
