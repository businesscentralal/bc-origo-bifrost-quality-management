namespace Origo.Bifrost.QualityManagement;

/// <summary>Capability granted only to the quality put-away disposition permission set. Stores no records.</summary>
table 10035307 "Quality PutAway Access ori"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Caption = 'Quality put-away', Comment = 'is-IS=Frágangur gæðastjórnunar';
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
