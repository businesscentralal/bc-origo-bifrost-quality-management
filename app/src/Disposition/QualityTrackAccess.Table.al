namespace Origo.Bifrost.QualityManagement;

/// <summary>Capability granted only to the item tracking change permission set. Stores no records.</summary>
table 10035312 "Quality Track Access ori"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Caption = 'Quality item tracking change', Comment = 'is-IS=Breyting rakningar í gæðastjórnun';
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
