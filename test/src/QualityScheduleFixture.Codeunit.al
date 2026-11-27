namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.GenerationRule.JobQueue;
using Microsoft.QualityManagement.Document;
using Origo.Bifrost;
using System.Threading;

/// <summary>Owns CRONUS test rules and mocks only platform scheduling for BIFTQ20 report jobs.</summary>
codeunit 97293 "Quality Schedule Fixture ori" implements "Msg Interface ori"
{
    /// <summary>Restricts fixtures to CRONUS demo companies.</summary>
    procedure IsEnabled(): Boolean
    begin
        exit(CompanyName().StartsWith('CRONUS'));
    end;

    /// <summary>No generic record selection.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>Describes the test lifecycle.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit('Test-only owned scheduling fixtures. action=create/read/cleanup; scheduleGroup must start BIFTQ20-.');
    end;

    /// <summary>Fixture writes are inbound.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Creates, inspects or removes only this test run data.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Job: Record "Job Queue Entry";
        Rule: Record "Qlty. Inspection Gen. Rule";
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        GroupCode: Code[20];
        GroupText: Text;
        JobId: Guid;
        WithFilter: Boolean;
    begin
        if not IsEnabled() then
            Error('CRONUS required.');
        Request := Argument.GetRequestJson();
        GroupText := Request.GetText('scheduleGroup');
        if not GroupText.StartsWith('BIFTQ20-') or (StrLen(GroupText) > 20) then
            Error('Use an owned BIFTQ20- group, at most 20 characters.');
        GroupCode := CopyStr(GroupText, 1, 20);
        case Request.GetText('action') of
            'create': begin
                Rule.SetRange("Schedule Group", GroupCode);
                if not Rule.IsEmpty() then
                    Error('Fixture exists.');
                WithFilter := true;
                if Request.Contains('unfiltered') then
                    WithFilter := not Request.GetBoolean('unfiltered');
                Seed(GroupCode, WithFilter);
            end;
            'read': begin
                Evaluate(JobId, Request.GetText('jobQueueEntryId'));
                Job.Get(JobId);
                if not OwnsJob(Job, GroupCode) then
                    Error('This job is not owned by the fixture.');
                Response.Add('reportId', Job."Object ID to Run");
                Response.Add('reportParameters', Job.GetReportParameters());
                Response.Add('recurring', Job."Recurring Job");
                Response.Add('startTime', Format(Job."Starting Time", 0, 9));
                Response.Add('repeatEveryMinutes', Job."No. of Minutes between Runs");
                Response.Add('monday', Job."Run on Mondays");
                Response.Add('sunday', Job."Run on Sundays");
                Response.Add('jobStatus', Job.Status);
                Response.Add('schedulerMocked', not IsNullGuid(Job."System Task ID"));
            end;
            'cleanup': Cleanup(GroupCode);
            else Error('Use create, read or cleanup.');
        end;
        Rule.SetRange("Schedule Group", GroupCode);
        Response.Add('remainingRules', Rule.Count());
        Response.Add('inspectionCount', Inspection.Count());
        Response.Add('status', 'Success');
        Argument.SetResponseJson(Response);
    end;

    /// <summary>Seeds a disabled rule with a nonmatching item filter; never creates inspections.</summary>
    procedure Seed(GroupCode: Code[20]; WithFilter: Boolean)
    var
        Rule: Record "Qlty. Inspection Gen. Rule";
        EntryNo: Integer;
    begin
        if not IsEnabled() or (CopyStr(GroupCode, 1, 8) <> 'BIFTQ20-') then
            Error('Owned CRONUS fixture required.');
        Rule.LockTable();
        if Rule.FindLast() then
            EntryNo := Rule."Entry No.";
        Rule.Init();
        Rule."Entry No." := EntryNo + 1;
        Rule."Schedule Group" := GroupCode;
        Rule."Source Table No." := Database::Item;
        Rule."Activation Trigger" := Rule."Activation Trigger"::Disabled;
        if WithFilter then
            Rule."Item Filter" := 'WHERE(No.=CONST(BIFTQ20-NONEXISTENT))'
        else
            Rule."Item Filter" := '';
        Rule."Condition Filter" := '';
        Rule."Item Attribute Filter" := '';
        Rule.Insert(false);
    end;

    /// <summary>Deletes only jobs whose report parameters name the owned group, then its rules.</summary>
    procedure Cleanup(GroupCode: Code[20])
    var
        Job: Record "Job Queue Entry";
        Rule: Record "Qlty. Inspection Gen. Rule";
    begin
        if not IsEnabled() or (CopyStr(GroupCode, 1, 8) <> 'BIFTQ20-') then
            Error('Owned CRONUS fixture required.');
        Job.SetRange("Object Type to Run", Job."Object Type to Run"::Report);
        Job.SetRange("Object ID to Run", Report::"Qlty. Schedule Inspection");
        if Job.FindSet(true) then
            repeat
                if OwnsJob(Job, GroupCode) then
                    Job.Delete(true);
            until Job.Next() = 0;
        Rule.SetRange("Schedule Group", GroupCode);
        Rule.DeleteAll(false);
    end;

    local procedure OwnsJob(var Job: Record "Job Queue Entry"; GroupCode: Code[20]): Boolean
    begin
        exit((Job."Object ID to Run" = Report::"Qlty. Schedule Inspection") and Job.Description.EndsWith(GroupCode) and Job.GetReportParameters().Contains(GroupCode));
    end;

    // Mock only TaskScheduler.CreateTask, after the standard enqueue and permission path.
    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnBeforeScheduleTask', '', false, false)]
    local procedure MockOwnedSchedule(var JobQueueEntry: Record "Job Queue Entry"; var TaskGUID: Guid; var IsHandled: Boolean)
    begin
        if IsEnabled() and (JobQueueEntry."Object ID to Run" = Report::"Qlty. Schedule Inspection") and JobQueueEntry.GetReportParameters().Contains('BIFTQ20-') then begin
            TaskGUID := CreateGuid();
            IsHandled := true;
        end;
    end;
}
