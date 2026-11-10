namespace Origo.Bifrost.QualityManagement.Test;

using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>Checks issue 34 typed SetTestValue refusals through the public dispatcher in both languages.</summary>
codeunit 97207 "Quality Value Errors Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>Checks Missing input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC01_Missing_1033()
    begin
        // Story #34, AC01 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('missing', 'MissingParameter', 1033);
    end;

    /// <summary>Checks Missing input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC01_Missing_1039()
    begin
        // Story #34, AC01 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('missing', 'MissingParameter', 1039);
    end;

    /// <summary>Checks Empty input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC01_Empty_1033()
    begin
        // Story #34, AC01 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('empty', 'MissingParameter', 1033);
    end;

    /// <summary>Checks Empty input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC01_Empty_1039()
    begin
        // Story #34, AC01 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('empty', 'MissingParameter', 1039);
    end;

    /// <summary>Checks Unknown input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC02_Unknown_1033()
    begin
        // Story #34, AC02 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('notFound', 'RecordNotFound', 1033);
    end;

    /// <summary>Checks Unknown input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC02_Unknown_1039()
    begin
        // Story #34, AC02 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('notFound', 'RecordNotFound', 1039);
    end;

    /// <summary>Checks Malformed input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_Malformed_1033()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('guid', 'InvalidParameter', 1033);
    end;

    /// <summary>Checks Malformed input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_Malformed_1039()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('guid', 'InvalidParameter', 1039);
    end;

    /// <summary>Checks ZeroGuid input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_ZeroGuid_1033()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('zero', 'InvalidParameter', 1033);
    end;

    /// <summary>Checks ZeroGuid input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_ZeroGuid_1039()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('zero', 'InvalidParameter', 1039);
    end;

    /// <summary>Checks NonText input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_NonText_1033()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('number', 'InvalidParameter', 1033);
    end;

    /// <summary>Checks NonText input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_NonText_1039()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('number', 'InvalidParameter', 1039);
    end;

    /// <summary>Checks Null input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_Null_1033()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('null', 'InvalidParameter', 1033);
    end;

    /// <summary>Checks Null input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_Null_1039()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('null', 'InvalidParameter', 1039);
    end;

    /// <summary>Checks Array input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_Array_1033()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('array', 'InvalidParameter', 1033);
    end;

    /// <summary>Checks Array input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_Array_1039()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('array', 'InvalidParameter', 1039);
    end;

    /// <summary>Checks Object input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_Object_1033()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('object', 'InvalidParameter', 1033);
    end;

    /// <summary>Checks Object input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_Object_1039()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('object', 'InvalidParameter', 1039);
    end;

    /// <summary>Checks LongCode input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_LongCode_1033()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('longCode', 'InvalidParameter', 1033);
    end;

    /// <summary>Checks LongCode input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_LongCode_1039()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('longCode', 'InvalidParameter', 1039);
    end;

    /// <summary>Checks LongValue input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_LongValue_1033()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('longValue', 'InvalidParameter', 1033);
    end;

    /// <summary>Checks LongValue input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_LongValue_1039()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('longValue', 'InvalidParameter', 1039);
    end;

    /// <summary>Checks MissingCode input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_MissingCode_1033()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('missingCode', 'MissingParameter', 1033);
    end;

    /// <summary>Checks MissingCode input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_MissingCode_1039()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('missingCode', 'MissingParameter', 1039);
    end;

    /// <summary>Checks EmptyCode input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_EmptyCode_1033()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('emptyCode', 'MissingParameter', 1033);
    end;

    /// <summary>Checks EmptyCode input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_EmptyCode_1039()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('emptyCode', 'MissingParameter', 1039);
    end;

    /// <summary>Checks MissingValue input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_MissingValue_1033()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('missingValue', 'MissingParameter', 1033);
    end;

    /// <summary>Checks MissingValue input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_MissingValue_1039()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('missingValue', 'MissingParameter', 1039);
    end;

    /// <summary>Checks NonTextCode input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_NonTextCode_1033()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('numberCode', 'InvalidParameter', 1033);
    end;

    /// <summary>Checks NonTextCode input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_NonTextCode_1039()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('numberCode', 'InvalidParameter', 1039);
    end;

    /// <summary>Checks NonTextValue input with structured guidance in LCID 1033.</summary>
    [Test]
    procedure Scenario_AC03_NonTextValue_1033()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('numberValue', 'InvalidParameter', 1033);
    end;

    /// <summary>Checks NonTextValue input with structured guidance in LCID 1039.</summary>
    [Test]
    procedure Scenario_AC03_NonTextValue_1039()
    begin
        // Story #34, AC03 | Time: no date-dependent inputs | Risk: no business fixtures
        VerifyRefusal('numberValue', 'InvalidParameter', 1039);
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
        NullToken: JsonToken;
        StructuredErrors: JsonToken;
        StructuredError: JsonToken;
    begin
        // [GIVEN] Fresh nonexistent identifiers and request values created by this test.
        UnknownId := CreateGuid();
        Request.Add('inspectionSystemId', Format(UnknownId, 0, 4));
        Request.Add('testCode', 'TEMP');
        Request.Add('value', '20');
        ExpectedParameter := 'inspectionSystemId';
        case Scenario of
            'missing': Request.Remove('inspectionSystemId');
            'empty': Request.Replace('inspectionSystemId', '');
            'guid': Request.Replace('inspectionSystemId', 'not-a-guid');
            'zero': Request.Replace('inspectionSystemId', '00000000-0000-0000-0000-000000000000');
            'number': Request.Replace('inspectionSystemId', 12);
            'null': begin
                NullToken.ReadFrom('null');
                Request.Replace('inspectionSystemId', NullToken);
            end;
            'array': begin
                NullToken.ReadFrom('[]');
                Request.Replace('inspectionSystemId', NullToken);
            end;
            'object': begin
                NullToken.ReadFrom('{}');
                Request.Replace('inspectionSystemId', NullToken);
            end;
            'longCode', 'missingCode', 'emptyCode', 'numberCode': begin
                ExpectedParameter := 'testCode';
                case Scenario of
                    'longCode': Request.Replace('testCode', PadStr('x', 21, 'x'));
                    'missingCode': Request.Remove('testCode');
                    'emptyCode': Request.Replace('testCode', '');
                    'numberCode': Request.Replace('testCode', 12);
                end;
            end;
            'longValue', 'missingValue', 'numberValue': begin
                ExpectedParameter := 'value';
                case Scenario of
                    'longValue': Request.Replace('value', PadStr('x', 251, 'x'));
                    'missingValue': Request.Remove('value');
                    'numberValue': Request.Replace('value', 12);
                end;
            end;
        end;
        Request.WriteTo(RequestText);
        RequestContent.AddText(RequestText);
        // [WHEN] The real dispatcher executes the message, including its rollback/error boundary.
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Quality.Inspection.SetTestValue", Enum::"Message Version ori"::"1.0", '', 'quality34-tests', 'application/json', RequestContent, TaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
        // [THEN] Both the top-level refusal and error item retain typed, actionable metadata.
        Assert.AreEqual('Error', ReadText(Response, 'status'), 'Refusal status');
        Assert.AreEqual(ExpectedCode, ReadText(Response, 'code'), 'Typed code');
        Assert.AreEqual(ExpectedParameter, ReadText(Response, 'parameter'), 'Parameter identity');
        Assert.IsTrue(ReadText(Response, 'expected') <> '', 'Expected input guidance');
        Assert.IsTrue(Response.Get('errors', StructuredErrors), 'Structured error collection');
        Assert.AreEqual(1, StructuredErrors.AsArray().Count(), 'One owned refusal');
        StructuredErrors.AsArray().Get(0, StructuredError);
        Assert.AreEqual(ExpectedCode, ReadText(StructuredError.AsObject(), 'code'), 'Error item code');
        Assert.AreEqual(ExpectedParameter, ReadText(StructuredError.AsObject(), 'parameter'), 'Error item parameter');
        if LanguageId = 1039 then begin
            Assert.IsTrue(ReadText(Response, 'expected').Contains('text') or ReadText(Response, 'expected').Contains('skoðunar'), 'Icelandic expected guidance');
            Assert.IsTrue(ReadText(Response, 'nextStep').Contains('Leiðréttu') or ReadText(Response, 'nextStep').Contains('Lestu'), 'Icelandic recovery guidance');
        end else
            Assert.IsTrue(ReadText(Response, 'nextStep').Contains('Correct') or ReadText(Response, 'nextStep').Contains('Read'), 'English recovery guidance');
        if Scenario = 'notFound' then
            Assert.AreEqual(Format(UnknownId, 0, 4), ReadText(Response, 'received'), 'Unknown SystemId must be preserved exactly');
    end;

    local procedure ReadText(Response: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Response.Get(PropertyName, Token), 'Missing response field: ' + PropertyName);
        exit(Token.AsValue().AsText());
    end;
}
