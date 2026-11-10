namespace Origo.Bifrost.QualityManagement.Test;

using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>Verifies issue 31 typed purchase-return refusals through the public dispatcher in both languages.</summary>
codeunit 97215 "Quality Return Errors Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>Checks missing input and actionable structured error fields in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC01_Missing_1033()
    begin
        VerifyRefusal('missing', 'MissingParameter', 1033);
    end;

    /// <summary>Checks missing input and actionable structured error fields in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC01_Missing_1039()
    begin
        VerifyRefusal('missing', 'MissingParameter', 1039);
    end;

    /// <summary>Checks empty input and actionable structured error fields in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC01_Empty_1033()
    begin
        VerifyRefusal('empty', 'MissingParameter', 1033);
    end;

    /// <summary>Checks empty input and actionable structured error fields in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC01_Empty_1039()
    begin
        VerifyRefusal('empty', 'MissingParameter', 1039);
    end;

    /// <summary>Checks notFound input and actionable structured error fields in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC02_Unknown_1033()
    begin
        VerifyRefusal('notFound', 'RecordNotFound', 1033);
    end;

    /// <summary>Checks notFound input and actionable structured error fields in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC02_Unknown_1039()
    begin
        VerifyRefusal('notFound', 'RecordNotFound', 1039);
    end;

    /// <summary>Checks guid input and actionable structured error fields in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_Malformed_1033()
    begin
        VerifyRefusal('guid', 'InvalidParameter', 1033);
    end;

    /// <summary>Checks guid input and actionable structured error fields in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_Malformed_1039()
    begin
        VerifyRefusal('guid', 'InvalidParameter', 1039);
    end;

    /// <summary>Checks number input and actionable structured error fields in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_NonText_1033()
    begin
        VerifyRefusal('number', 'InvalidParameter', 1033);
    end;

    /// <summary>Checks number input and actionable structured error fields in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_NonText_1039()
    begin
        VerifyRefusal('number', 'InvalidParameter', 1039);
    end;

    /// <summary>Checks null input and actionable structured error fields in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_Null_1033()
    begin
        VerifyRefusal('null', 'InvalidParameter', 1033);
    end;

    /// <summary>Checks null input and actionable structured error fields in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_Null_1039()
    begin
        VerifyRefusal('null', 'InvalidParameter', 1039);
    end;

    /// <summary>Checks longReason input and actionable structured error fields in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_LongReason_1033()
    begin
        VerifyRefusal('longReason', 'InvalidParameter', 1033);
    end;

    /// <summary>Checks longReason input and actionable structured error fields in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_LongReason_1039()
    begin
        VerifyRefusal('longReason', 'InvalidParameter', 1039);
    end;

    /// <summary>Checks option input and actionable structured error fields in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_NonTextOption_1033()
    begin
        VerifyRefusal('option', 'InvalidParameter', 1033);
    end;

    /// <summary>Checks option input and actionable structured error fields in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_NonTextOption_1039()
    begin
        VerifyRefusal('option', 'InvalidParameter', 1039);
    end;

    local procedure VerifyRefusal(Scenario: Text; ExpectedCode: Text; LanguageId: Integer)
    var
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        Request: JsonObject;
        Response: JsonObject;
        MessageId: Guid;
        TaskId: Guid;
        UnknownId: Guid;
        RequestText: Text;
        ResponseText: Text;
        ResponseContentType: Text[100];
        ResponseTime: Duration;
        ExpectedParameter: Text;
    begin
        // [GIVEN] Self-created request values and a fresh nonexistent SystemId; no business fixtures.
        UnknownId := CreateGuid();
        Request.Add('inspectionSystemId', Format(UnknownId, 0, 4));
        ExpectedParameter := 'inspectionSystemId';
        case Scenario of
            'missing': begin
                Request.Remove('inspectionSystemId');
                Request.Add('reasonCode', '');
            end;
            'empty': Request.Replace('inspectionSystemId', '');
            'guid': Request.Replace('inspectionSystemId', 'not-a-guid');
            'number': Request.Replace('inspectionSystemId', 12);
            'null': Request.ReadFrom('{"inspectionSystemId":null}');
            'longReason': begin
                Request.Add('reasonCode', 'TOO-LONG-REASON');
                ExpectedParameter := 'reasonCode';
            end;
            'option': begin
                Request.Add('reasonCode', true);
                ExpectedParameter := 'reasonCode';
            end;
        end;
        Request.WriteTo(RequestText);
        RequestContent.AddText(RequestText);
        // [WHEN] Foundation executes the actual message type with its normal rollback boundary.
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Quality.Disposition.CreatePurchaseReturn", Enum::"Message Version ori"::"1.0", '', 'quality31-tests', 'application/json', RequestContent, TaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
        // [THEN] The language-neutral code identifies the problem; translated fields explain recovery.
        Assert.AreEqual('Error', ReadText(Response, 'status'), 'Refusal status');
        Assert.AreEqual(ExpectedCode, ReadText(Response, 'code'), 'Typed code');
        Assert.AreEqual(ExpectedParameter, ReadText(Response, 'parameter'), 'Parameter identity');
        Assert.IsTrue(ReadText(Response, 'expected') <> '', 'Expected input guidance');
        Assert.IsTrue(ReadText(Response, 'nextStep') <> '', 'Recovery guidance');
        if LanguageId = 1039 then begin
            Assert.IsTrue(ReadText(Response, 'expected').Contains('text') or ReadText(Response, 'expected').Contains('skoðunar'), 'Icelandic expected guidance');
            Assert.IsTrue(ReadText(Response, 'nextStep').Contains('Leiðréttu') or ReadText(Response, 'nextStep').Contains('Lestu'), 'Icelandic next step');
        end else
            Assert.IsTrue(ReadText(Response, 'nextStep').Contains('Correct') or ReadText(Response, 'nextStep').Contains('Read'), 'English next step');
        if Scenario = 'notFound' then
            Assert.AreEqual(Format(UnknownId, 0, 4), ReadText(Response, 'received'), 'Unknown SystemId must be returned exactly');
    end;

    local procedure ReadText(Response: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Response.Get(PropertyName, Token), 'Missing response field: ' + PropertyName);
        exit(Token.AsValue().AsText());
    end;
}
