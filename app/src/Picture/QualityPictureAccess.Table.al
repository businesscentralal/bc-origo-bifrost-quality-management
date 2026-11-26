namespace Origo.Bifrost.QualityManagement;

/// <summary>Permission marker for replacing an inspection picture. The table stores no business rows.</summary>
table 10035296 "Quality Picture Access ori"
{
    Access = Internal;
    Caption = 'Quality picture access', Comment = 'is-IS=Aðgangur að mynd skoðunar';
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
