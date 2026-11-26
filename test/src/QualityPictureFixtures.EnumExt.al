namespace Origo.Bifrost.QualityManagement.Test;

using Origo.Bifrost;

/// <summary>Registers an owned demo-only fixture for repeatable MCP picture checks.</summary>
enumextension 97267 "Quality Picture Fixtures ori" extends "Message Type ori"
{
    /// <summary>Controls only generated picture test data.</summary>
    value(97267; "Test.Quality.PictureFixture")
    {
        Caption = 'Test.Quality.PictureFixture', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Picture Fixture ori";
    }
}
