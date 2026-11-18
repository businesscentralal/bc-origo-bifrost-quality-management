namespace Origo.Bifrost.QualityManagement.Test;

/// <summary>Retains the original setup fields for owned test fixture cleanup across MCP sessions.</summary>
table 97215 "Quality Create Fixture ori"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; "Setup Existed"; Boolean) { }
        field(3; "Previous Series"; Code[20]) { }
        field(4; "Previous Creation Option"; Integer) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}
