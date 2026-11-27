namespace Origo.Bifrost.QualityManagement;

/// <summary>Capability granted only to the quality negative adjustment permission set. Stores no records.</summary>
table 10035302 "Quality Neg Adj Access ori"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Caption = 'Quality negative adjustment', Comment = 'is-IS=Neikvæð leiðrétting gæðastjórnunar';
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
