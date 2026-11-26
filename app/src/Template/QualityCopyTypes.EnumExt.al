namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers Quality.Template.Copy with Foundation.</summary>
enumextension 10035316 "Quality Copy Types ori" extends "Message Type ori"
{
    value(10035316; "Quality.Template.Copy")
    {
        Caption = 'Quality.Template.Copy', Locked = true;
        Implementation = "Msg Interface ori" = "Quality Copy Impl ori",
                          "Msg Discovery ori" = "Quality Copy Impl ori",
                          "Msg Contract ori" = "Quality Copy Impl ori";
    }
}
