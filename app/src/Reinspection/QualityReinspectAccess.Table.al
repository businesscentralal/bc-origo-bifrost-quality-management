namespace Origo.Bifrost.QualityManagement;

/// <summary>Permission marker for Quality Management actions; contains no business records.</summary>
table 10035320 "Quality Reinspect Access ori"
{
    Caption = 'Quality action access', Comment = 'is-IS=Aðgangur að gæðaaðgerðum';
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
        key(PK; "Primary Key") { Clustered = true; }
    }
}
