namespace Origo.Bifrost.QualityManagement;

/// <summary>Empty capability table; only the Quality Full role grants scheduling writes.</summary>
table 10035330 "Quality Schedule Access ori"
{
    Access = Internal;
    Caption = 'Quality schedule access', Comment = 'is-IS=Aðgangur að tímaáætlun gæða';
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary key', Comment = 'is-IS=Aðallykill';
            ToolTip = 'Specifies the permission capability key. No business records are stored.', Comment = 'is-IS=Tilgreinir lykil aðgangsheimildar. Engar viðskiptafærslur eru geymdar.';
        }
    }
    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
