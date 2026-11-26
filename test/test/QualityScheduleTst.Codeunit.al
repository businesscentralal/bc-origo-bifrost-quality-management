namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.GenerationRule.JobQueue;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;
using System.Threading;

/// <summary>Issue 20 dispatcher tests: creation, refusals, counts, roles and bilingual contracts.</summary>
codeunit 97292 "Quality Schedule Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;
    var
        Assert: Codeunit "Library Assert";
        Fixture: Codeunit "Quality Schedule Fixture ori";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>AC01 OrdinalAndBilingualWriteContract.</summary>
    [Test]
    procedure Scenario_AC01_OrdinalAndBilingualWriteContract()
    var
        Contract: Interface "Msg Contract ori";
        Effect: JsonObject;
        Parameters: JsonArray;
        OverviewEnglish: Text;
        OverviewIcelandic: Text;
        OldLanguage: Integer;
    begin
        // AC01 | Time: none | Risk: language restored.
        LowerPermissions.SetOutsideO365Scope();
        Assert.AreEqual(10035328, Enum::"Message Type ori"::"Quality.GenerationRule.Schedule".AsInteger(), 'Published ordinal');
        Contract := Enum::"Message Type ori"::"Quality.GenerationRule.Schedule";
        OldLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        Contract.GetOverview(OverviewEnglish);
        Contract.GetEffect(Effect);
        Contract.GetParameters(Parameters);
        GlobalLanguage(1039);
        Contract.GetOverview(OverviewIcelandic);
        GlobalLanguage(OldLanguage);
        Assert.AreEqual('write', Effect.GetText('effect'), 'Write discovery');
        Assert.AreEqual(6, Parameters.Count(), 'All six parameters');
        Assert.AreNotEqual(OverviewEnglish, OverviewIcelandic, 'Icelandic overview');
    end;

    /// <summary>AC02 DefaultOnHoldRecurrenceAndXml.</summary>
    [Test]
    procedure Scenario_AC02_DefaultOnHoldRecurrenceAndXml()
    var
        Job: Record "Job Queue Entry";
        Rule: Record "Qlty. Inspection Gen. Rule";
        Response: JsonObject;
        Request: JsonObject;
        Document: XmlDocument;
        Node: XmlNode;
        GroupCode: Code[20];
        JobId: Guid;
    begin
        // AC02 | Time: fixed 08:00 | Risk: owned records cleaned; no task scheduled.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Response := Invoke(Request);
        AssertSuccess(Response);
        Evaluate(JobId, Response.GetText('jobQueueEntryId'));
        Job.Get(JobId);
        XmlDocument.ReadFrom(Job.GetReportParameters(), Document);
        Assert.IsTrue(Document.SelectSingleNode('/ReportParameters/DataItems/DataItem[@name="CurrentInspectionGenerationRule"]', Node), 'Native data item');
        Rule.SetView(Node.AsXmlElement().InnerText());
        Assert.AreEqual(GroupCode, Rule.GetRangeMin("Schedule Group"), 'Exact group filter');
        Assert.AreEqual(Report::"Qlty. Schedule Inspection", Job."Object ID to Run", 'Native report');
        Assert.AreEqual(Job."Object Type to Run"::Report, Job."Object Type to Run", 'Report type');
        Assert.AreEqual(Job.Status::"On Hold", Job.Status, 'Default status');
        Assert.AreEqual(080000T, Job."Starting Time", 'Start time');
        Assert.AreEqual(1440, Job."No. of Minutes between Runs", 'Default daily recurrence');
        Assert.IsTrue(Job."Recurring Job" and Job."Run on Mondays" and Job."Run on Sundays", 'Default all days');
        Assert.IsTrue(IsNullGuid(Job."System Task ID"), 'No platform task on hold');
        Assert.AreEqual('On Hold', Response.GetText('jobStatus'), 'Response status');
        Assert.IsTrue(Response.Contains('inspectionCreationOption'), 'Creation option returned');
        Cleanup(GroupCode);
    end;

    /// <summary>AC02 ExplicitActivationUsesSchedulerMock.</summary>
    [Test]
    procedure Scenario_AC02_ExplicitActivationUsesSchedulerMock()
    var
        Job: Record "Job Queue Entry";
        Inspection: Record "Qlty. Inspection Header";
        Response: JsonObject;
        Request: JsonObject;
        Days: JsonArray;
        GroupCode: Code[20];
        JobId: Guid;
        BeforeCount: Integer;
    begin
        // AC02/AC05 | Time: fixed 08:00 | Risk: only platform scheduler mocked, report never executed.
        GroupCode := Initialize();
        BeforeCount := Inspection.Count();
        Request := NewRequest(GroupCode);
        Days.Add(1);
        Days.Add(5);
        Request.Add('daysOfWeek', Days);
        Request.Add('repeatEveryMinutes', 60);
        Request.Add('activate', true);
        Response := Invoke(Request);
        AssertSuccess(Response);
        Evaluate(JobId, Response.GetText('jobQueueEntryId'));
        Job.Get(JobId);
        Assert.AreEqual(Job.Status::Ready, Job.Status, 'Native Ready status');
        Assert.AreEqual('Ready', Response.GetText('jobStatus'), 'Response Ready');
        Assert.IsFalse(IsNullGuid(Job."System Task ID"), 'Native enqueue reached the scheduling mock');
        Assert.AreEqual(60, Job."No. of Minutes between Runs", 'Hourly');
        Assert.IsTrue(Job."Run on Mondays" and Job."Run on Fridays" and not Job."Run on Sundays", 'Selected weekdays');
        Assert.AreEqual(BeforeCount, Inspection.Count(), 'No inspections executed');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 AnyUnfilteredRuleRefuses.</summary>
    [Test]
    procedure Scenario_AC03_AnyUnfilteredRuleRefuses()
    var
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: owned rules only, including a second unsafe rule.
        GroupCode := Initialize();
        Fixture.Seed(GroupCode, false);
        Commit();
        AssertRefusal(NewRequest(GroupCode), 'PreconditionFailed', 'scheduleGroup');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 NoRulesRefuses.</summary>
    [Test]
    procedure Scenario_AC03_NoRulesRefuses()
    var
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: fixture removed before invocation.
        GroupCode := Initialize();
        Cleanup(GroupCode);
        AssertRefusal(NewRequest(GroupCode), 'PreconditionFailed', 'scheduleGroup');
    end;

    /// <summary>AC03 DuplicateRefusesWithoutReplacing.</summary>
    [Test]
    procedure Scenario_AC03_DuplicateRefusesWithoutReplacing()
    var
        Job: Record "Job Queue Entry";
        Request: JsonObject;
        Response: JsonObject;
        GroupCode: Code[20];
        JobId: Guid;
    begin
        // AC03 | Time: none | Risk: original job must survive unchanged.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Response := Invoke(Request);
        AssertSuccess(Response);
        Evaluate(JobId, Response.GetText('jobQueueEntryId'));
        AssertRefusal(Request, 'PreconditionFailed', 'scheduleGroup');
        Job.Get(JobId);
        Assert.AreEqual(Job.Status::"On Hold", Job.Status, 'Original untouched');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 MissingTime RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_MissingTime_RefusesWithoutWrite()
    var
        Request: JsonObject;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('startTime');
        AssertRefusal(Request, 'MissingParameter', 'startTime');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 InvalidTime RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_InvalidTime_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('startTime');
        Token.ReadFrom('"25:00:00"');
        Request.Add('startTime', Token);
        AssertRefusal(Request, 'InvalidParameter', 'startTime');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 ShortTime RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_ShortTime_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('startTime');
        Token.ReadFrom('"8:00"');
        Request.Add('startTime', Token);
        AssertRefusal(Request, 'InvalidParameter', 'startTime');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 NullTime RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_NullTime_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('startTime');
        Token.ReadFrom('null');
        Request.Add('startTime', Token);
        AssertRefusal(Request, 'InvalidParameter', 'startTime');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 UnknownKey RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_UnknownKey_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('surprise');
        Token.ReadFrom('true');
        Request.Add('surprise', Token);
        AssertRefusal(Request, 'UnknownParameter', 'surprise');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 LongGroup RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_LongGroup_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('scheduleGroup');
        Token.ReadFrom('"BIFTQ20-1234567890123"');
        Request.Add('scheduleGroup', Token);
        AssertRefusal(Request, 'InvalidParameter', 'scheduleGroup');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 BlankGroup RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_BlankGroup_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('scheduleGroup');
        Token.ReadFrom('"  "');
        Request.Add('scheduleGroup', Token);
        AssertRefusal(Request, 'InvalidParameter', 'scheduleGroup');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 NumericGroup RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_NumericGroup_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('scheduleGroup');
        Token.ReadFrom('42');
        Request.Add('scheduleGroup', Token);
        AssertRefusal(Request, 'InvalidParameter', 'scheduleGroup');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 NullGroup RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_NullGroup_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('scheduleGroup');
        Token.ReadFrom('null');
        Request.Add('scheduleGroup', Token);
        AssertRefusal(Request, 'InvalidParameter', 'scheduleGroup');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 InvalidDay RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_InvalidDay_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('daysOfWeek');
        Token.ReadFrom('[0,8]');
        Request.Add('daysOfWeek', Token);
        AssertRefusal(Request, 'InvalidParameter', 'daysOfWeek');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 DuplicateDays RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_DuplicateDays_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('daysOfWeek');
        Token.ReadFrom('[1,1]');
        Request.Add('daysOfWeek', Token);
        AssertRefusal(Request, 'InvalidParameter', 'daysOfWeek');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 EmptyDays RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_EmptyDays_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('daysOfWeek');
        Token.ReadFrom('[]');
        Request.Add('daysOfWeek', Token);
        AssertRefusal(Request, 'InvalidParameter', 'daysOfWeek');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 StringDays RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_StringDays_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('daysOfWeek');
        Token.ReadFrom('["1"]');
        Request.Add('daysOfWeek', Token);
        AssertRefusal(Request, 'InvalidParameter', 'daysOfWeek');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 NullDays RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_NullDays_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('daysOfWeek');
        Token.ReadFrom('null');
        Request.Add('daysOfWeek', Token);
        AssertRefusal(Request, 'InvalidParameter', 'daysOfWeek');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 FractionalMinutes RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_FractionalMinutes_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('repeatEveryMinutes');
        Token.ReadFrom('1.5');
        Request.Add('repeatEveryMinutes', Token);
        AssertRefusal(Request, 'InvalidParameter', 'repeatEveryMinutes');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 ZeroMinutes RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_ZeroMinutes_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('repeatEveryMinutes');
        Token.ReadFrom('0');
        Request.Add('repeatEveryMinutes', Token);
        AssertRefusal(Request, 'InvalidParameter', 'repeatEveryMinutes');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 TooManyMinutes RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_TooManyMinutes_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('repeatEveryMinutes');
        Token.ReadFrom('2147483648');
        Request.Add('repeatEveryMinutes', Token);
        AssertRefusal(Request, 'InvalidParameter', 'repeatEveryMinutes');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 StringMinutes RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_StringMinutes_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('repeatEveryMinutes');
        Token.ReadFrom('"60"');
        Request.Add('repeatEveryMinutes', Token);
        AssertRefusal(Request, 'InvalidParameter', 'repeatEveryMinutes');
        Cleanup(GroupCode);
    end;

    /// <summary>AC03 StringActivation RefusesWithoutWrite.</summary>
    [Test]
    procedure Scenario_AC03_StringActivation_RefusesWithoutWrite()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
    begin
        // AC03 | Time: none | Risk: all validation failures preserve job count.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Remove('activate');
        Token.ReadFrom('"true"');
        Request.Add('activate', Token);
        AssertRefusal(Request, 'InvalidParameter', 'activate');
        Cleanup(GroupCode);
    end;

    /// <summary>AC04 MismatchRefuses.</summary>
    [Test]
    procedure Scenario_AC04_MismatchRefuses()
    var
        Request: JsonObject;
        GroupCode: Code[20];
    begin
        // AC04 | Time: none | Risk: zero writes.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Replace('expectedCount', 2);
        AssertRefusal(Request, 'ConfirmationMismatch', 'expectedCount');
        Cleanup(GroupCode);
    end;

    /// <summary>AC04 MissingCountReadsOne.</summary>
    [Test]
    procedure Scenario_AC04_MissingCountReadsOne()
    var
        Request: JsonObject;
        Response: JsonObject;
        GroupCode: Code[20];
        Previous: Boolean;
    begin
        // AC04 | Time: none | Risk: restore confirmation setting.
        GroupCode := Initialize();
        Previous := SetConfirmation(true);
        Request := NewRequest(GroupCode);
        Request.Remove('expectedCount');
        Response := Invoke(Request);
        SetConfirmation(Previous);
        Assert.AreEqual('ConfirmationRequired', Response.GetText('code'), Serialize(Response));
        Assert.AreEqual('1', Response.GetText('expected'), 'One future job');
        AssertNoJob(GroupCode);
        Cleanup(GroupCode);
    end;

    /// <summary>AC04 DisabledConfirmationAllowsOmission.</summary>
    [Test]
    procedure Scenario_AC04_DisabledConfirmationAllowsOmission()
    var
        Request: JsonObject;
        Response: JsonObject;
        GroupCode: Code[20];
        Previous: Boolean;
    begin
        // AC04 | Time: none | Risk: confirmation setting restored before asserts.
        GroupCode := Initialize();
        Previous := SetConfirmation(false);
        Request := NewRequest(GroupCode);
        Request.Remove('expectedCount');
        Response := Invoke(Request);
        SetConfirmation(Previous);
        AssertSuccess(Response);
        Cleanup(GroupCode);
    end;

    /// <summary>AC02 BoundariesMidnightAndOneMinute.</summary>
    [Test]
    procedure Scenario_AC02_BoundariesMidnightAndOneMinute()
    var
        Request: JsonObject;
        Response: JsonObject;
        GroupCode: Code[20];
    begin
        // AC02/AC03 | Time: midnight is native 0T | Risk: On Hold only.
        GroupCode := Initialize();
        Assert.AreEqual(20, StrLen(GroupCode), 'Max-length boundary');
        Request := NewRequest(GroupCode);
        Request.Replace('startTime', '00:00:00');
        Request.Add('repeatEveryMinutes', 1);
        Response := Invoke(Request);
        AssertSuccess(Response);
        Cleanup(GroupCode);
    end;

    /// <summary>AC02 AlwaysCreateOptionsReturnWarning.</summary>
    [Test]
    procedure Scenario_AC02_AlwaysCreateOptionsReturnWarning()
    var
        Setup: Record "Qlty. Management Setup";
        PreviousOption: Enum "Qlty. Inspect. Creation Option";
        Response: JsonObject;
        GroupCode: Code[20];
        OptionIndex: Integer;
    begin
        // AC02 | Time: none | Risk: setup restored before assertions for each option.
        for OptionIndex := 1 to 2 do begin
            GroupCode := Initialize();
            Setup.Get();
            PreviousOption := Setup."Inspection Creation Option";
            if OptionIndex = 1 then
                Setup."Inspection Creation Option" := Setup."Inspection Creation Option"::"Always create new inspection"
            else
                Setup."Inspection Creation Option" := Setup."Inspection Creation Option"::"Always create re-inspection";
            Setup.Modify(false);
            Commit();
            Response := Invoke(NewRequest(GroupCode));
            Setup.Get();
            Setup."Inspection Creation Option" := PreviousOption;
            Setup.Modify(false);
            Commit();
            AssertSuccess(Response);
            Assert.IsTrue(Response.Contains('warning'), 'Always-create warning');
            Cleanup(GroupCode);
        end;
    end;

    /// <summary>AC05 ReadRoleRefusesThroughDispatcher.</summary>
    [Test]
    procedure Scenario_AC05_ReadRoleRefusesThroughDispatcher()
    begin
        // AC05 | Time: none | Risk: permissions restored before assertions.
        AssertRoleRefusal('BIFROST QM Read ori');
    end;

    /// <summary>AC05 BaseRoleRefusesThroughDispatcher.</summary>
    [Test]
    procedure Scenario_AC05_BaseRoleRefusesThroughDispatcher()
    begin
        // AC05 | Time: none | Risk: permissions restored before assertions.
        AssertRoleRefusal('BIFROST Quality ori');
    end;

    /// <summary>AC05 FullRoleCreatesThroughDispatcher.</summary>
    [Test]
    procedure Scenario_AC05_FullRoleCreatesThroughDispatcher()
    var
        Response: JsonObject;
        Request: JsonObject;
        GroupCode: Code[20];
    begin
        // AC05 | Time: none | Risk: actual product role supplies capability and native grants.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Add('activate', true);
        LowerPermissions.SetExactPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet('BIFROST QM Full ori');
        LowerPermissions.AddPermissionSet('QM Schedule Test ori');
        Response := Invoke(Request);
        LowerPermissions.SetOutsideO365Scope();
        AssertSuccess(Response);
        Cleanup(GroupCode);
    end;

    /// <summary>AC04 malformed confirmation counts refuse without any job.</summary>
    [Test]
    procedure Scenario_AC04_MalformedCountsRefuse()
    var
        Request: JsonObject;
        Token: JsonToken;
        GroupCode: Code[20];
        CountTexts: List of [Text];
        CountText: Text;
    begin
        // AC04 | Time: none | Risk: count and write remain unchanged.
        GroupCode := Initialize();
        CountTexts.Add('"1"');
        CountTexts.Add('1.5');
        CountTexts.Add('-1');
        CountTexts.Add('null');
        CountTexts.Add('true');
        foreach CountText in CountTexts do begin
            Request := NewRequest(GroupCode);
            Token.ReadFrom(CountText);
            Request.Replace('expectedCount', Token);
            AssertRefusal(Request, 'InvalidParameterFormat', 'expectedCount');
        end;
        Cleanup(GroupCode);
    end;

    /// <summary>AC02 accepts the native integer upper bound and last valid second on hold.</summary>
    [Test]
    procedure Scenario_AC02_MaximumMinutesAndLastSecond()
    var
        Job: Record "Job Queue Entry";
        Request: JsonObject;
        Response: JsonObject;
        Days: JsonArray;
        GroupCode: Code[20];
        JobId: Guid;
    begin
        // AC02/AC03 | Time: upper 23:59:59 boundary | Risk: On Hold, no task execution.
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        Request.Replace('startTime', '23:59:59');
        Request.Add('repeatEveryMinutes', 2147483647);
        Days.Add(7);
        Request.Add('daysOfWeek', Days);
        Response := Invoke(Request);
        AssertSuccess(Response);
        Evaluate(JobId, Response.GetText('jobQueueEntryId'));
        Job.Get(JobId);
        Assert.AreEqual(2147483647, Job."No. of Minutes between Runs", 'Native integer boundary');
        Assert.AreEqual(235959T, Job."Starting Time", 'Last valid second');
        Assert.IsTrue(Job."Run on Sundays" and not Job."Run on Mondays", 'Upper day boundary');
        Cleanup(GroupCode);
    end;

    local procedure SetConfirmation(Enabled: Boolean) Previous: Boolean
    var
        Setup: Record "Setup ori";
        Dispatcher: Codeunit "Dispatcher ori";
        Input: BigText;
        Output: BigText;
        SetupRef: RecordRef;
        ConfirmationField: FieldRef;
        MessageType: Enum "Message Type ori";
        ContentType: Text[100];
        Payload: JsonObject;
        Fields: JsonObject;
        Result: JsonObject;
        ResponseText: Text;
        TypeIndex: Integer;
    begin
        Setup.Get();
        SetupRef.GetTable(Setup);
        ConfirmationField := SetupRef.Field(36);
        Previous := ConfirmationField.Value();
        SetupRef.Close();
        Fields.Add('Require Irreversible Confirm', Enabled);
        Payload.Add('fields', Fields);
        Input.AddText(Serialize(Payload));
        TypeIndex := MessageType.Names().IndexOf('Test.Setup.Set');
        Assert.IsTrue(TypeIndex > 0, 'Foundation Tests must be installed for approved setup changes.');
        MessageType := Enum::"Message Type ori".FromInteger(MessageType.Ordinals().Get(TypeIndex));
        Dispatcher.Execute(MessageType, Enum::"Message Version ori"::"1.0", '', 'quality20-test-setup', 'application/json', Input, Output, ContentType, false);
        Output.GetSubText(ResponseText, 1);
        Result.ReadFrom(ResponseText);
        Assert.AreEqual('Success', Result.GetText('status'), ResponseText);
    end;

    local procedure AssertRoleRefusal(RoleName: Code[20])
    var
        Request: JsonObject;
        Response: JsonObject;
        GroupCode: Code[20];
    begin
        GroupCode := Initialize();
        Request := NewRequest(GroupCode);
        LowerPermissions.SetExactPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet(RoleName);
        Response := Invoke(Request);
        LowerPermissions.SetOutsideO365Scope();
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual('PermissionDenied', Response.GetText('code'), Serialize(Response));
        AssertNoJob(GroupCode);
        Cleanup(GroupCode);
    end;

    local procedure Initialize() GroupCode: Code[20]
    var
        Setup: Record "Setup ori";
        QualitySetup: Record "Qlty. Management Setup";
    begin
        LowerPermissions.SetOutsideO365Scope();
        Setup.InsertIfNotExists();
        QualitySetup.Get();
        GroupCode := CopyStr('BIFTQ20-' + DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 20);
        Fixture.Seed(GroupCode, true);
        Commit();
    end;

    local procedure Cleanup(GroupCode: Code[20])
    begin
        Fixture.Cleanup(GroupCode);
        Commit();
    end;

    local procedure NewRequest(GroupCode: Code[20]) Request: JsonObject
    begin
        Request.Add('scheduleGroup', GroupCode);
        Request.Add('startTime', '08:00:00');
        Request.Add('expectedCount', 1);
    end;

    local procedure Invoke(Request: JsonObject) Response: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        Input: BigText;
        Output: BigText;
        ContentType: Text[100];
        ResponseText: Text;
    begin
        Input.AddText(Serialize(Request));
        Dispatcher.Execute(Enum::"Message Type ori"::"Quality.GenerationRule.Schedule", Enum::"Message Version ori"::"1.0", '', 'quality20-tests', 'application/json', Input, Output, ContentType, false);
        Output.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
    end;

    local procedure AssertRefusal(Request: JsonObject; ExpectedCode: Text; ParameterName: Text)
    var
        Job: Record "Job Queue Entry";
        Response: JsonObject;
        BeforeCount: Integer;
    begin
        BeforeCount := Job.Count();
        Response := Invoke(Request);
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual(ExpectedCode, Response.GetText('code'), Serialize(Response));
        Assert.AreEqual(ParameterName, Response.GetText('parameter'), Serialize(Response));
        Assert.IsTrue(Response.GetText('expected') <> '', 'Expected provided');
        Assert.IsTrue(Response.GetText('nextStep') <> '', 'Actionable next step');
        Assert.AreEqual(BeforeCount, Job.Count(), 'No job written');
    end;

    local procedure AssertNoJob(GroupCode: Code[20])
    var
        Job: Record "Job Queue Entry";
    begin
        Job.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection");
        if Job.FindSet() then
            repeat
                Assert.IsFalse(Job.GetReportParameters().Contains(GroupCode), 'No owned job');
            until Job.Next() = 0;
    end;

    local procedure AssertSuccess(Response: JsonObject)
    begin
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual(1, Response.GetInteger('noOfRecords'), 'One job');
    end;

    local procedure Serialize(Request: JsonObject) Result: Text
    begin
        Request.WriteTo(Result);
    end;
}
