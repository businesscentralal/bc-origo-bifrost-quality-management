namespace Origo.Bifrost.QualityManagement;

/// <summary>Capability granted only to the quality inventory disposition permission set. Stores no records.</summary>
table 10035271 "Quality Move Access ori"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Caption = 'Quality inventory movement', Comment = 'is-IS=Birgðaflutningur gæðastjórnunar';
    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key', Comment = 'is-IS=Aðallykill';
        }
    }
    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
