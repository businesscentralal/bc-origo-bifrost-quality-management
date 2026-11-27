namespace Origo.Bifrost.QualityManagement;

using Microsoft.QualityManagement.Configuration.GenerationRule.JobQueue;
using System.Automation;
using System.Security.AccessControl;
using System.Threading;
using System.Utilities;

/// <summary>Native scheduling grants included by Quality Full; separate from app capabilities for role composition.</summary>
permissionset 10035331 "BIFROST QM Schedule ori"
{
    Access = Public;
    Assignable = false;
    Caption = 'Bifrost Quality Scheduling', MaxLength = 30, Comment = 'is-IS=Bifröst - tímaáætlun gæða';
    IncludedPermissionSets = "Job Queue - Admin";
    Permissions = tabledata Workflow = R,
        tabledata "Workflow Step" = R,
        tabledata "Workflow Event" = R,
        tabledata "Error Message" = RIMD,
        tabledata "Error Message Register" = RIMD,
        codeunit "Job Queue - Enqueue" = X,
        codeunit "Job Queue Dispatcher" = X,
        report "Qlty. Schedule Inspection" = X;
}
