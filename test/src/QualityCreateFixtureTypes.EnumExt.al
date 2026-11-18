namespace Origo.Bifrost.QualityManagement.Test;

using Origo.Bifrost;

/// <summary>Registers a test-only lifecycle for self-seeded MCP acceptance data.</summary>
enumextension 97211 "Quality Create Fixtures ori" extends "Message Type ori"
{
    /// <summary>Seeds and cleans one owned source and its inspection setup.</summary>
    value(97211; "Test.Quality.CreateFixture")
    {
        Caption = 'Test.Quality.CreateFixture', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Create Fixture Mgt ori";
    }
}
