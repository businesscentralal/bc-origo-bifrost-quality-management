namespace Origo.Bifrost.QualityManagement.Test;

/// <summary>Owned source records for issue 9, isolated from native documents and external services.</summary>
table 97262 "Quality Find Source ori"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.', Locked = true;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.', Locked = true;
        }
        field(3; "Lot No."; Code[50])
        {
            Caption = 'Lot No.', Locked = true;
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
