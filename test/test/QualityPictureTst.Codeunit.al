namespace Origo.Bifrost.QualityManagement.Test;

using Microsoft.QualityManagement.Document;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;
using System.Utilities;

/// <summary>Issue 11 AC01-AC06: tests the public dispatcher with generated images, rollback and strict permissions.</summary>
codeunit 97264 "Quality Picture Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        Lower: Codeunit "Library - Lower Permissions";
        Fixture: Codeunit "Quality Picture Fixture ori";

    /// <summary>A valid generated image is stored through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_png_Base64_StoresPicture()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Success('png', false);
    end;

    /// <summary>A valid generated image is stored through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_png_Staged_StoresPicture()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Success('png', true);
    end;

    /// <summary>A valid generated image is stored through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_jpg_Base64_StoresPicture()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Success('jpg', false);
    end;

    /// <summary>A valid generated image is stored through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_jpg_Staged_StoresPicture()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Success('jpg', true);
    end;

    /// <summary>A valid generated image is stored through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_bmp_Base64_StoresPicture()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Success('bmp', false);
    end;

    /// <summary>A valid generated image is stored through the public dispatcher.</summary>
    [Test]
    procedure Scenario_AC02_bmp_Staged_StoresPicture()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Success('bmp', true);
    end;

    /// <summary>A second image replaces the media field.</summary>
    [Test]
    procedure Scenario_AC02_Replacement_DoesNotKeepOldPicture()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        OldMediaId: Guid;
        NewMediaId: Guid;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Response := Invoke(Request);
        AssertSuccess(Response);
        Inspection.GetBySystemId(Inspection.SystemId);
        OldMediaId := Inspection."Most Recent Picture".MediaId();
        Request := ImageRequest(Inspection, 'bmp', false, StageId);
        Response := Invoke(Request);
        AssertSuccess(Response);
        Inspection.GetBySystemId(Inspection.SystemId);
        NewMediaId := Inspection."Most Recent Picture".MediaId();
        Cleanup(Inspection, StageId);
        Assert.AreNotEqual(OldMediaId, NewMediaId, 'Replacement must point to new media.');
    end;

    /// <summary>Invalid bytes or an oversized image preserve the previous picture and staging row.</summary>
    [Test]
    procedure Scenario_AC03_invalid_Base64_Refuses()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        RefusedImage('invalid', false);
    end;

    /// <summary>Invalid bytes or an oversized image preserve the previous picture and staging row.</summary>
    [Test]
    procedure Scenario_AC03_invalid_Staged_Refuses()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        RefusedImage('invalid', true);
    end;

    /// <summary>Invalid bytes or an oversized image preserve the previous picture and staging row.</summary>
    [Test]
    procedure Scenario_AC03_oversize_Base64_Refuses()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        RefusedImage('oversize', false);
    end;

    /// <summary>Invalid bytes or an oversized image preserve the previous picture and staging row.</summary>
    [Test]
    procedure Scenario_AC03_oversize_Staged_Refuses()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        RefusedImage('oversize', true);
    end;

    /// <summary>An image at exactly 1048576 bytes is accepted.</summary>
    [Test]
    procedure Scenario_AC02_ExactLimit_Base64_Allowed()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Success('limit', false);
    end;

    /// <summary>An image at exactly 1048576 bytes is accepted.</summary>
    [Test]
    procedure Scenario_AC02_ExactLimit_Staged_Allowed()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Success('limit', true);
    end;

    /// <summary>A typed refusal carries recovery fields and leaves the inspection unchanged.</summary>
    [Test]
    procedure Scenario_AC03_MissingId_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Remove('inspectionSystemId');
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'MissingParameter', 'inspectionSystemId');
        Assert.IsFalse(HasPicture, 'Refusal must not import media.');
    end;

    /// <summary>A typed refusal carries recovery fields and leaves the inspection unchanged.</summary>
    [Test]
    procedure Scenario_AC03_InvalidId_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Replace('inspectionSystemId', 'bad');
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'InvalidParameter', 'inspectionSystemId');
        Assert.IsFalse(HasPicture, 'Refusal must not import media.');
    end;

    /// <summary>A typed refusal carries recovery fields and leaves the inspection unchanged.</summary>
    [Test]
    procedure Scenario_AC03_NullId_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Replace('inspectionSystemId', 42);
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'InvalidParameter', 'inspectionSystemId');
        Assert.IsFalse(HasPicture, 'Refusal must not import media.');
    end;

    /// <summary>A typed refusal carries recovery fields and leaves the inspection unchanged.</summary>
    [Test]
    procedure Scenario_AC03_UnknownId_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Replace('inspectionSystemId', Format(CreateGuid(), 0, 4));
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'RecordNotFound', 'inspectionSystemId');
        Assert.IsFalse(HasPicture, 'Refusal must not import media.');
    end;

    /// <summary>A typed refusal carries recovery fields and leaves the inspection unchanged.</summary>
    [Test]
    procedure Scenario_AC03_BothSources_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Add('stagingId', Format(CreateGuid(), 0, 4));
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'InvalidParameter', 'base64');
        Assert.IsFalse(HasPicture, 'Refusal must not import media.');
    end;

    /// <summary>A typed refusal carries recovery fields and leaves the inspection unchanged.</summary>
    [Test]
    procedure Scenario_AC03_NoSource_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Remove('base64');
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'MissingParameter', 'base64');
        Assert.IsFalse(HasPicture, 'Refusal must not import media.');
    end;

    /// <summary>A typed refusal carries recovery fields and leaves the inspection unchanged.</summary>
    [Test]
    procedure Scenario_AC03_UnknownKey_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Add('unexpected', true);
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'UnknownParameter', 'unexpected');
        Assert.IsFalse(HasPicture, 'Refusal must not import media.');
    end;

    /// <summary>A typed refusal carries recovery fields and leaves the inspection unchanged.</summary>
    [Test]
    procedure Scenario_AC03_MalformedBase64_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Replace('base64', '%%%');
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'InvalidParameter', 'base64');
        Assert.IsFalse(HasPicture, 'Refusal must not import media.');
    end;

    /// <summary>A typed refusal carries recovery fields and leaves the inspection unchanged.</summary>
    [Test]
    procedure Scenario_AC03_NumericBase64_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Replace('base64', 42);
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'InvalidParameter', 'base64');
        Assert.IsFalse(HasPicture, 'Refusal must not import media.');
    end;

    /// <summary>A typed refusal carries recovery fields and leaves the inspection unchanged.</summary>
    [Test]
    procedure Scenario_AC03_UnknownStage_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Remove('base64');
        Request.Add('stagingId', Format(CreateGuid(), 0, 4));
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'RecordNotFound', 'stagingId');
        Assert.IsFalse(HasPicture, 'Refusal must not import media.');
    end;

    /// <summary>A typed refusal carries recovery fields and leaves the inspection unchanged.</summary>
    [Test]
    procedure Scenario_AC03_InvalidStage_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Remove('base64');
        Request.Add('stagingId', 'bad');
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'InvalidParameter', 'stagingId');
        Assert.IsFalse(HasPicture, 'Refusal must not import media.');
    end;

    /// <summary>A typed refusal carries recovery fields and leaves the inspection unchanged.</summary>
    [Test]
    procedure Scenario_AC03_CountMismatch_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Add('expectedCount', 2);
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'PreconditionFailed', 'expectedCount');
        Assert.IsFalse(HasPicture, 'Refusal must not import media.');
    end;

    /// <summary>A typed refusal carries recovery fields and leaves the inspection unchanged.</summary>
    [Test]
    procedure Scenario_AC03_CountText_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Add('expectedCount', '1');
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'PreconditionFailed', 'expectedCount');
        Assert.IsFalse(HasPicture, 'Refusal must not import media.');
    end;

    /// <summary>A typed refusal carries recovery fields and leaves the inspection unchanged.</summary>
    [Test]
    procedure Scenario_AC03_PathName_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Add('fileName', '../evil.png');
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'InvalidParameter', 'fileName');
        Assert.IsFalse(HasPicture, 'Refusal must not import media.');
    end;

    /// <summary>A typed refusal carries recovery fields and leaves the inspection unchanged.</summary>
    [Test]
    procedure Scenario_AC03_LongName_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Add('fileName', PadStr('', 251, 'x'));
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'InvalidParameter', 'fileName');
        Assert.IsFalse(HasPicture, 'Refusal must not import media.');
    end;

    /// <summary>A precondition failure preserves staged bytes and the media field.</summary>
    [Test]
    procedure Scenario_AC04_Finished_KeepsStaging()
    var
        Inspection: Record "Qlty. Inspection Header";
        Staging: Codeunit "Blob Staging ori";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        Exists: Boolean;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', true, StageId);
        Inspection.Status := Inspection.Status::Finished;
        Inspection.Modify();
        Commit();
        Response := Invoke(Request);
        Exists := Staging.Exists(StageId);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'PreconditionFailed', 'inspectionSystemId');
        Assert.IsTrue(Exists, 'Refusal must keep staging.');
        Assert.IsFalse(HasPicture, 'Refusal must not create media.');
    end;

    /// <summary>A precondition failure preserves staged bytes and the media field.</summary>
    [Test]
    procedure Scenario_AC04_CountMismatch_KeepsStaging()
    var
        Inspection: Record "Qlty. Inspection Header";
        Staging: Codeunit "Blob Staging ori";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        Exists: Boolean;
        HasPicture: Boolean;
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', true, StageId);
        Request.Add('expectedCount', 0);
        Commit();
        Response := Invoke(Request);
        Exists := Staging.Exists(StageId);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'PreconditionFailed', 'expectedCount');
        Assert.IsTrue(Exists, 'Refusal must keep staging.');
        Assert.IsFalse(HasPicture, 'Refusal must not create media.');
    end;

    /// <summary>The dispatcher enforces the dedicated capability and native modify permission.</summary>
    [Test]
    procedure Scenario_AC05_Read_DispatcherPermission()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        PermissionCheck('BIFROST QM Read ori', false);
    end;

    /// <summary>The dispatcher enforces the dedicated capability and native modify permission.</summary>
    [Test]
    procedure Scenario_AC05_Base_DispatcherPermission()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        PermissionCheck('BIFROST Quality ori', false);
    end;

    /// <summary>The dispatcher enforces the dedicated capability and native modify permission.</summary>
    [Test]
    procedure Scenario_AC05_NoNativeModify_DispatcherPermission()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        PermissionCheck('QM Picture Test ori', false);
    end;

    /// <summary>The dispatcher enforces the dedicated capability and native modify permission.</summary>
    [Test]
    procedure Scenario_AC05_Full_DispatcherPermission()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        PermissionCheck('BIFROST QM Full ori', true);
    end;

    /// <summary>The published message ordinal remains stable.</summary>
    [Test]
    procedure Scenario_AC01_Ordinal_IsPinned()
    begin
        // Story #11 | Time: no date-dependent inputs | Risk: only owned synthetic fixtures; permissions restored.
        Assert.AreEqual(10035294, Enum::"Message Type ori"::"Quality.Inspection.AddPicture".AsInteger(), 'Published ordinal.');
    end;

    /// <summary>A native failure after media import rolls back staging and preserves the prior media reference.</summary>
    [Test]
    procedure Scenario_AC04_LateFailure_RollsBackAllWrites()
    var
        Inspection: Record "Qlty. Inspection Header";
        Staging: Codeunit "Blob Staging ori";
        Fault: Codeunit "Quality Picture Fault ori";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        UnusedId: Guid;
        OldMediaId: Guid;
        AfterMediaId: Guid;
        Exists: Boolean;
    begin
        // Story #11 AC04 | Time: no date-dependent inputs | Risk: only owned generated fixtures; subscription unbound.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, UnusedId);
        Response := Invoke(Request);
        AssertSuccess(Response);
        Inspection.GetBySystemId(Inspection.SystemId);
        OldMediaId := Inspection."Most Recent Picture".MediaId();
        Request := ImageRequest(Inspection, 'bmp', true, StageId);
        BindSubscription(Fault);
        Response := Invoke(Request);
        UnbindSubscription(Fault);
        Exists := Staging.Exists(StageId);
        Inspection.GetBySystemId(Inspection.SystemId);
        AfterMediaId := Inspection."Most Recent Picture".MediaId();
        Cleanup(Inspection, StageId);
        Assert.AreEqual('Error', Response.GetText('status'), 'Injected native refusal must propagate.');
        Assert.IsTrue(Exists, 'Late failure after media import must restore staging.');
        Assert.AreEqual(OldMediaId, AfterMediaId, 'Late failure must preserve the prior picture.');
    end;

    /// <summary>Backslash path components are rejected before media writes.</summary>
    [Test]
    procedure Scenario_AC03_BackslashPath_Refuses()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
    begin
        // Story #11 AC03 | Time: no date-dependent inputs | Risk: owned fixtures cleaned.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Add('fileName', 'folder\picture.png');
        Response := Invoke(Request);
        Cleanup(Inspection, StageId);
        AssertRefusal(Response, 'InvalidParameter', 'fileName');
    end;

    /// <summary>A 250-character file name is accepted at the exact boundary.</summary>
    [Test]
    procedure Scenario_AC02_FileNameLimit_Allowed()
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
    begin
        // Story #11 AC02 | Time: no date-dependent inputs | Risk: owned fixtures cleaned.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Request.Add('fileName', PadStr('', 250, 'x'));
        Response := Invoke(Request);
        Cleanup(Inspection, StageId);
        AssertSuccess(Response);
    end;

    /// <summary>A decoded GIF is refused even when the file name claims PNG.</summary>
    [Test]
    procedure Scenario_AC03_GifBase64_Refuses()
    begin
        // Story #11 AC03 | Time: none | Risk: owned fixtures cleaned.
        RefusedImage('gif', false);
    end;

    /// <summary>A staged decoded GIF is refused and its staged bytes remain available.</summary>
    [Test]
    procedure Scenario_AC04_GifStaging_RollsBack()
    begin
        // Story #11 AC03/AC04 | Time: none | Risk: owned fixtures cleaned.
        RefusedImage('gif', true);
    end;

    /// <summary>Omit-commit mode propagates refusal so the caller can roll back the staged Take.</summary>
    [Test]
    procedure Scenario_AC04_OmitCommit_ErrorRestoresStaging()
    var
        Inspection: Record "Qlty. Inspection Header";
        Staging: Codeunit "Blob Staging ori";
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        Request: JsonObject;
        ResponseType: Text[100];
        Serialized: Text;
        StageId: Guid;
        Exists: Boolean;
    begin
        // Story #11 AC04 | Time: none | Risk: owned staging committed before the expected rollback.
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'invalid', true, StageId);
        Request.WriteTo(Serialized);
        RequestContent.AddText(Serialized);
        asserterror Dispatcher.Execute(Enum::"Message Type ori"::"Quality.Inspection.AddPicture", Enum::"Message Version ori"::"1.0", '', 'quality11-omit', 'application/json', RequestContent, ResponseContent, ResponseType, true);
        Assert.ExpectedError('Parameter base64/stagingId is invalid.');
        Exists := Staging.Exists(StageId);
        Cleanup(Inspection, StageId);
        Assert.IsTrue(Exists, 'The caller rollback must restore staging after an omit-commit refusal.');
    end;

    local procedure Initialize(var Inspection: Record "Qlty. Inspection Header")
    var
        RunCode: Code[20];
    begin
        Lower.SetOutsideO365Scope();
        RunCode := CopyStr('BIFTQ6-P' + DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 20);
        Fixture.Seed(RunCode, Inspection);
        Commit();
    end;

    local procedure Cleanup(Inspection: Record "Qlty. Inspection Header"; StageId: Guid)
    var
        Staging: Codeunit "Blob Staging ori";
        Blob: Codeunit "Temp Blob";
    begin
        Lower.SetOutsideO365Scope();
        if not IsNullGuid(StageId) then
            Staging.Take(StageId, Blob);
        Fixture.Cleanup(Inspection."No.");
        Commit();
    end;

    local procedure ImageRequest(Inspection: Record "Qlty. Inspection Header"; FormatName: Text; Staged: Boolean; var StageId: Guid) Request: JsonObject
    var
        Staging: Codeunit "Blob Staging ori";
        Blob: Codeunit "Temp Blob";
        Input: InStream;
    begin
        Fixture.MakeImage(FormatName, Blob);
        Request.Add('inspectionSystemId', Format(Inspection.SystemId, 0, 4));
        if Staged then begin
            Blob.CreateInStream(Input);
            StageId := Staging.Create(Input, 'untrusted.gif', 'image/gif', 'quality11-tests');
            Request.Add('stagingId', Format(StageId, 0, 4));
        end else
            Request.Add('base64', Fixture.Encoded(Blob));
        Commit();
    end;

    local procedure Success(FormatName: Text; Staged: Boolean)
    var
        Inspection: Record "Qlty. Inspection Header";
        Staging: Codeunit "Blob Staging ori";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
        Exists: Boolean;
    begin
        Initialize(Inspection);
        Request := ImageRequest(Inspection, FormatName, Staged, StageId);
        Request.Add('expectedCount', 1);
        Request.Add('fileName', 'misleading.gif');
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        if Staged then
            Exists := Staging.Exists(StageId);
        Cleanup(Inspection, StageId);
        AssertSuccess(Response);
        Assert.IsTrue(HasPicture, 'Image must be stored.');
        Assert.AreEqual(Format(Inspection.SystemId, 0, 4), Response.GetText('inspectionSystemId'), 'Exact target.');
        Assert.IsFalse(Response.GetBoolean('additionalHandlingApplied'), 'No additional handling.');
        Assert.IsFalse(Exists, 'Success consumes staging.');
    end;

    local procedure RefusedImage(FormatName: Text; Staged: Boolean)
    var
        Inspection: Record "Qlty. Inspection Header";
        Staging: Codeunit "Blob Staging ori";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        UnusedId: Guid;
        OldMediaId: Guid;
        CurrentMediaId: Guid;
        Exists: Boolean;
    begin
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, UnusedId);
        Response := Invoke(Request);
        AssertSuccess(Response);
        Inspection.GetBySystemId(Inspection.SystemId);
        OldMediaId := Inspection."Most Recent Picture".MediaId();
        Request := ImageRequest(Inspection, FormatName, Staged, StageId);
        Response := Invoke(Request);
        Inspection.GetBySystemId(Inspection.SystemId);
        CurrentMediaId := Inspection."Most Recent Picture".MediaId();
        if Staged then
            Exists := Staging.Exists(StageId);
        Cleanup(Inspection, StageId);
        if Staged then begin
            AssertRefusal(Response, 'InvalidParameter', 'stagingId');
            Assert.IsTrue(Exists, 'Failure after Take must roll back staging consumption.');
        end else
            AssertRefusal(Response, 'InvalidParameter', 'base64');
        Assert.AreEqual(OldMediaId, CurrentMediaId, 'Refusal must preserve the previous picture.');
    end;

    local procedure PermissionCheck(Role: Code[20]; Allowed: Boolean)
    var
        Inspection: Record "Qlty. Inspection Header";
        Request: JsonObject;
        Response: JsonObject;
        StageId: Guid;
        HasPicture: Boolean;
    begin
        Initialize(Inspection);
        Request := ImageRequest(Inspection, 'png', false, StageId);
        Lower.SetExactPermissionSet('BIFROST API ori');
        Lower.AddPermissionSet(Role);
        Response := Invoke(Request);
        Lower.SetOutsideO365Scope();
        Inspection.GetBySystemId(Inspection.SystemId);
        HasPicture := Inspection."Most Recent Picture".HasValue();
        Cleanup(Inspection, StageId);
        if Allowed then
            AssertSuccess(Response)
        else
            AssertRefusal(Response, 'PermissionDenied', 'permissionSet');
        Assert.AreEqual(Allowed, HasPicture, 'Only the Full role with native modify may write.');
    end;

    local procedure Invoke(Request: JsonObject) Response: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        ResponseType: Text[100];
        Serialized: Text;
    begin
        Request.WriteTo(Serialized);
        RequestContent.AddText(Serialized);
        Dispatcher.Execute(Enum::"Message Type ori"::"Quality.Inspection.AddPicture", Enum::"Message Version ori"::"1.0", '', 'quality11-tests', 'application/json', RequestContent, ResponseContent, ResponseType, false);
        ResponseContent.GetSubText(Serialized, 1);
        Response.ReadFrom(Serialized);
    end;

    local procedure AssertSuccess(Response: JsonObject)
    var
        Serialized: Text;
    begin
        Response.WriteTo(Serialized);
        Assert.AreEqual('Success', Response.GetText('status'), Serialized);
    end;

    local procedure AssertRefusal(Response: JsonObject; Code: Text; Parameter: Text)
    var
        Serialized: Text;
    begin
        Response.WriteTo(Serialized);
        Assert.AreEqual('Error', Response.GetText('status'), Serialized);
        Assert.AreEqual(Code, Response.GetText('code'), Serialized);
        Assert.AreEqual(Parameter, Response.GetText('parameter'), Serialized);
        Assert.IsTrue(Response.GetText('expected') <> '', Serialized);
        Assert.IsTrue(Response.GetText('nextStep') <> '', Serialized);
    end;
}
