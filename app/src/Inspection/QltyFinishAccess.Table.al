namespace Origo.Bifrost.QualityManagement;

/// <summary>Empty capability table that enforces the app Full role even when Foundation grants wildcard codeunit execution.</summary>
table 10035284 "Qlty Finish Access ori"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Caption = 'Quality inspection finish', Comment = 'is-IS=Ljúka gæðaskoðun';

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
