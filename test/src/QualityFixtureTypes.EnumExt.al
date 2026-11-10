namespace Origo.Bifrost.QualityManagement.Test;

using Origo.Bifrost;

/// <summary>Registers a test-only owned fixture lifecycle for reproducible MCP acceptance.</summary>
enumextension 97205 "Quality Fixture Types ori" extends "Message Type ori"
{
    /// <summary>Creates or removes an isolated quality fixture on a CRONUS company.</summary>
    value(97205; "Test.Quality.ValueFixture")
    {
        Caption = 'Test.Quality.ValueFixture', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Value Fixture ori";
    }
}
