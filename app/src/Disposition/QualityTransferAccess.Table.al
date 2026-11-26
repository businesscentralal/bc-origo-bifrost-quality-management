namespace Origo.Bifrost.QualityManagement;

/// <summary>Capability granted only to the quality transfer order permission set. Stores no records.</summary>
table 10035300 "Quality Transfer Access ori"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Caption = 'Quality transfer order', Comment = 'is-IS=Millilagerfærsla gæðastjórnunar';
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
