namespace Origo.Bifrost.QualityManagement.Test;

using Origo.Bifrost.QualityManagement;

/// <summary>Lowers the report size limit while bound, so the oversize refusal can be tested.</summary>
codeunit 97256 "Quality Report Limit ori"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Quality Report Proc ori", 'OnGetMaxSizeBytes', '', false, false)]
    local procedure LowerLimit(var Limit: Integer)
    begin
        Limit := 100;
    end;
}
