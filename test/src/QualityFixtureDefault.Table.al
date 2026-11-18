namespace Origo.Bifrost.QualityManagement.Test;

/// <summary>Records native Quality Management defaults created while seeding an owned test fixture, so cleanup removes only those records.</summary>
table 97216 "Quality Fixture Default ori"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Fixture Code"; Code[20]) { }
        field(2; "Table No."; Integer) { }
        field(3; "Record SystemId"; Guid) { }
        field(4; "Delete Order"; Integer) { }
    }
    keys
    {
        key(PK; "Fixture Code", "Table No.", "Record SystemId") { Clustered = true; }
        key(Order; "Fixture Code", "Delete Order") { }
    }
}
