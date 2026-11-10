namespace Origo.Bifrost.QualityManagement;

/// <summary>Permission capability for quality writes. No records are stored in this table.</summary>
table 10035243 "Quality Write Access ori"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Caption = 'Quality Write Access', Comment = 'is-IS=Skrifaðgangur að gæðastjórnun';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key', Comment = 'is-IS=Aðallykill';
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
