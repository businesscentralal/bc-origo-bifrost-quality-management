namespace Origo.Bifrost.QualityManagement;

/// <summary>Permission marker for reopening an inspection. The table stores no business rows.</summary>
table 10035258 "Quality Reopen Access ori"
{
    Access = Internal;
    Caption = 'Quality reopen access', Comment = 'is-IS=Aðgangur að enduropnun skoðunar';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary key', Comment = 'is-IS=Aðallykill';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
