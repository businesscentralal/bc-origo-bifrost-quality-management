namespace Origo.Bifrost.QualityManagement;

/// <summary>Permission marker for copying an inspection template. The table stores no business rows.</summary>
table 10035314 "Quality Copy Access ori"
{
    Access = Internal;
    Caption = 'Quality template copy access', Comment = 'is-IS=Aðgangur að afritun skoðunarsniðmáts';
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
