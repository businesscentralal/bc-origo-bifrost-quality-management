namespace Origo.Bifrost.QualityManagement.Test;

/// <summary>Explicit, test-only UI entry point for creating the worker-owned MCP inventory fixture.</summary>
page 97225 "Quality Move MCP Fixture ori"
{
    PageType = Card;
    Caption = 'Owned quality MCP fixture', Locked = true;
    ApplicationArea = All;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            group(Instructions)
            {
                Caption = 'Owned development verification', Locked = true;
                field(FixtureReference; FixtureReferenceLbl)
                {
                    Caption = 'Fixture reference', Locked = true;
                    ToolTip = 'Specifies the isolated fixture prefix. Use this page only in the recorded worker-owned development container.', Locked = true;
                    Editable = false;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(CreateOwnedFixture)
            {
                Caption = 'Create owned fixture', Locked = true;
                ToolTip = 'Creates only the Q12M-D7 test inventory, inspection and journal setup. Existing fixtures are refused. Does not change write guards, licensing or consent.', Locked = true;
                Image = CreateDocument;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"Quality Move MCP Seed ori");
                end;
            }
        }
    }
    var
        FixtureReferenceLbl: Label 'Q12M-D7', Locked = true;
}
