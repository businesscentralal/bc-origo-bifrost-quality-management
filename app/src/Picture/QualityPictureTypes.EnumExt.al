namespace Origo.Bifrost.QualityManagement;

using Origo.Bifrost;

/// <summary>Registers the inspection picture write contract.</summary>
enumextension 10035294 "Quality Picture Types ori" extends "Message Type ori"
{
    /// <summary>Replaces the most recent picture of one open inspection.</summary>
    value(10035294; "Quality.Inspection.AddPicture")
    {
        Caption = 'Quality.Inspection.AddPicture', Locked = true, Comment = 'is-IS=Quality.Inspection.AddPicture';
        Implementation = "Msg Interface ori" = "Quality Picture Impl ori",
                          "Msg Discovery ori" = "Quality Picture Impl ori",
                          "Msg Contract ori" = "Quality Picture Impl ori";
    }
}
